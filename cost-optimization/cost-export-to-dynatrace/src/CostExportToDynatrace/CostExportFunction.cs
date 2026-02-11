using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO.Compression;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using CsvHelper;
using CsvHelper.Configuration;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace CostExportToDynatrace
{
    public class CostExportFunction
    {
        private readonly ILogger _logger;
        private readonly HttpClient _httpClient;

        // Dynatrace configuration
        private readonly string _dynatraceUrl;
        private readonly string _dynatraceToken;

        public CostExportFunction(ILoggerFactory loggerFactory, IHttpClientFactory httpClientFactory)
        {
            _logger = loggerFactory.CreateLogger<CostExportFunction>();
            _httpClient = httpClientFactory.CreateClient();

            _dynatraceUrl = Environment.GetEnvironmentVariable("DYNATRACE_URL") ?? "";
            _dynatraceToken = Environment.GetEnvironmentVariable("DYNATRACE_API_TOKEN") ?? "";
        }

        [Function("ProcessCostExport")]
        public async Task Run(
            [BlobTrigger("%CostExportContainerName%/{name}", Connection = "CostExportStorageConnection")] Stream stream, 
            string name)
        {
            _logger.LogInformation($"Processing blob: {name}");

            if (string.IsNullOrEmpty(_dynatraceUrl) || string.IsNullOrEmpty(_dynatraceToken))
            {
                _logger.LogError("Dynatrace configuration is missing (DYNATRACE_URL or DYNATRACE_API_TOKEN).");
                return;
            }

            // Determine file type
            bool isGzip = name.EndsWith(".gz", StringComparison.OrdinalIgnoreCase);
            bool isCsv = name.EndsWith(".csv", StringComparison.OrdinalIgnoreCase);

            if (!isCsv && !isGzip)
            {
                _logger.LogInformation($"Skipping unsupported file extension: {name}");
                return;
            }

            try
            {
                Stream processingStream = stream;
                
                // If GZip, wrap in decompression stream
                if (isGzip)
                {
                    _logger.LogInformation("Detected GZip file, decompression enabled.");
                    processingStream = new GZipStream(stream, CompressionMode.Decompress);
                }

                using var reader = new StreamReader(processingStream);
                using var csv = new CsvReader(reader, new CsvConfiguration(CultureInfo.InvariantCulture)
                {
                    HasHeaderRecord = true,
                    // Cost Exports sometimes have metadata lines at top, or just headers. 
                    // Standard Cost Export usually starts with headers.
                    // If there are skipped lines, configuration might need adjustment.
                    BadDataFound = null,
                    MissingFieldFound = null
                });

                // Read records dynamically as dynamic objects to handle varying schemas
                var records = csv.GetRecordsAsync<dynamic>();
                
                var logBatch = new List<object>();
                const int batchSize = 500;
                int count = 0;

                await foreach (var record in records)
                {
                    var recordDict = (IDictionary<string, object>)record;
                    
                    var logEntry = new
                    {
                        content = JsonSerializer.Serialize(recordDict),
                        timestamp = DateTime.UtcNow.ToString("o"),
                        severity = "INFO",
                        attributes = new Dictionary<string, object>(recordDict)
                        {
                            { "log.source", "azure-cost-export" },
                            { "azure.resource_id", "/SUBSCRIPTIONS/COST-EXPORT" }, // Placeholder or derived from data
                            { "blob.name", name }
                        }
                    };

                    logBatch.Add(logEntry);
                    count++;

                    if (logBatch.Count >= batchSize)
                    {
                        await SendToDynatraceAsync(logBatch);
                        logBatch.Clear();
                    }
                }

                if (logBatch.Count > 0)
                {
                    await SendToDynatraceAsync(logBatch);
                }

                _logger.LogInformation($"Successfully processed {count} records from {name}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing blob {name}");
                throw; // Rethrow to ensure retries or dead-lettering
            }
        }

        private async Task SendToDynatraceAsync(List<object> logs)
        {
            try
            {
                var jsonContent = JsonSerializer.Serialize(logs);
                var request = new HttpRequestMessage(HttpMethod.Post, _dynatraceUrl);
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Api-Token", _dynatraceToken);
                request.Content = new StringContent(jsonContent, Encoding.UTF8, "application/json");

                var response = await _httpClient.SendAsync(request);
                
                if (!response.IsSuccessStatusCode)
                {
                    var responseBody = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Failed to send logs to Dynatrace. Status: {response.StatusCode}, Response: {responseBody}");
                    throw new Exception($"Dynatrace API error: {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Exception sending logs to Dynatrace");
                throw;
            }
        }
    }
}
