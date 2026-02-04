using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Azure;
using Azure.Core;
using Azure.Identity;
using Azure.ResourceManager;
using Azure.ResourceManager.Resources;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AzureAutoTagging
{
    public class TaggingFunction
    {
        private readonly ILogger _logger;
        private readonly ArmClient _armClient;
        private readonly TokenCredential _credential;
        private static readonly HttpClient _httpClient = new HttpClient();

        public TaggingFunction(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<TaggingFunction>();
            _credential = new DefaultAzureCredential();
            _armClient = new ArmClient(_credential);
        }

        [Function("AutoTagResource")]
        public async Task Run([EventGridTrigger] JsonElement eventGridEvent)
        {
            var debugMode = Environment.GetEnvironmentVariable("DEBUG_MODE") == "true";
            
            try
            {
                if (debugMode) _logger.LogInformation($"[DEBUG] Raw event: {eventGridEvent.GetRawText()}");
                _logger.LogInformation($"Processing event: {eventGridEvent.GetRawText().Substring(0, Math.Min(200, eventGridEvent.GetRawText().Length))}...");

                string? eventType = GetProperty(eventGridEvent, "eventType");
                string? subject = GetProperty(eventGridEvent, "subject");
                
                if (debugMode) _logger.LogInformation($"[DEBUG] EventType: {eventType}, Subject: {subject}");
                
                if (eventType != "Microsoft.Resources.ResourceWriteSuccess")
                {
                    _logger.LogInformation("Event type is not ResourceWriteSuccess. Skipping.");
                    return;
                }

                if (string.IsNullOrEmpty(subject))
                {
                    _logger.LogError("Subject is null or empty.");
                    return;
                }

                if (subject.Contains("/config") || subject.Contains("/secrets") || subject.Contains("/providers/Microsoft.Authorization/"))
                {
                    _logger.LogInformation($"Skipping non-taggable resource type: {subject}");
                    return;
                }

                if (!eventGridEvent.TryGetProperty("data", out JsonElement data))
                {
                    _logger.LogError("Event data is missing.");
                    return;
                }

                if (debugMode) _logger.LogInformation($"[DEBUG] Claims: {data.GetProperty("claims")}");
                
                string? caller = GetCallerFromClaims(data);
                if (string.IsNullOrEmpty(caller))
                {
                    _logger.LogWarning("Could not determine caller from claims. Skipping tagging.");
                    if (debugMode) _logger.LogWarning($"[DEBUG] Available claims keys: {string.Join(", ", data.GetProperty("claims").EnumerateObject().Select(p => p.Name))}");
                    return;
                }

                _logger.LogInformation($"Detected change on {subject} by {caller}");

                ResourceIdentifier resourceId = new ResourceIdentifier(subject);
                var resource = _armClient.GetGenericResource(resourceId);
                
                Response<GenericResource> resourceResponse;
                try 
                {
                    resourceResponse = await resource.GetAsync();
                }
                catch (RequestFailedException ex)
                {
                    _logger.LogError(ex, $"Failed to get resource {subject}. It might have been deleted.");
                    return;
                }
                
                GenericResource genericResource = resourceResponse.Value;
                IDictionary<string, string> currentTags = genericResource.Data.Tags;

                if (debugMode) _logger.LogInformation($"[DEBUG] Current tags: {string.Join(", ", currentTags.Select(t => $"{t.Key}={t.Value}"))}");

                bool isModified = false;
                
                // Logic for created-by:
                // 1. If it exists, leave it alone.
                // 2. If it is missing, try to get it from SystemData (ARM metadata).
                // 3. If SystemData is missing, do NOT backfill with current caller to avoid incorrectly labeling an update as creation.
                if (!currentTags.ContainsKey("created-by"))
                {
                    var systemCreatedBy = genericResource.Data.SystemData?.CreatedBy;
                    if (!string.IsNullOrEmpty(systemCreatedBy))
                    {
                        currentTags["created-by"] = systemCreatedBy;
                        isModified = true;
                    }
                    else
                    {
                        // Fallback: If this looks like a genuine creation event (how to tell?), we could use 'caller'.
                        // But avoiding false positives on updates is safer.
                        // We will check if the resource is very young (created in last 5 mins).
                        // Note: SystemData might be null if provider doesn't support it, so we can't check CreatedOn.
                        // We'll skip setting created-by if we can't be sure.
                        if (debugMode) _logger.LogInformation("[DEBUG] SystemData.CreatedBy key is missing. Skipping created-by tag to avoid incorrect attribute on potential update.");
                    }
                }

                if (!currentTags.ContainsKey("modified-by") || currentTags["modified-by"] != caller)
                {
                    currentTags["modified-by"] = caller;
                    isModified = true;
                }

                if (isModified)
                {
                    _logger.LogInformation($"Applying tags to {subject}: created-by={currentTags["created-by"]}, modified-by={currentTags["modified-by"]}");
                    
                    string tagsApiUrl = $"https://management.azure.com{subject}/providers/Microsoft.Resources/tags/default?api-version=2021-04-01";
                    
                    try 
                    {
                        if (debugMode) _logger.LogInformation($"[DEBUG] Tags API URL: {tagsApiUrl}");
                        
                        var token = await _credential.GetTokenAsync(new TokenRequestContext(new[] { "https://management.azure.com/.default" }), default);
                        
                        if (debugMode) _logger.LogInformation($"[DEBUG] Got auth token, expires: {token.ExpiresOn}");
                        
                        var tagsPayload = new
                        {
                            properties = new
                            {
                                tags = currentTags
                            }
                        };
                        
                        if (debugMode) _logger.LogInformation($"[DEBUG] Payload: {JsonSerializer.Serialize(tagsPayload)}");
                        
                        var content = new StringContent(JsonSerializer.Serialize(tagsPayload), Encoding.UTF8, "application/json");
                        var request = new HttpRequestMessage(HttpMethod.Put, tagsApiUrl);
                        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Token);
                        request.Content = content;
                        
                        var tagsResponse = await _httpClient.SendAsync(request);
                        
                        if (debugMode) _logger.LogInformation($"[DEBUG] Response status: {tagsResponse.StatusCode}");
                        
                        if (!tagsResponse.IsSuccessStatusCode)
                        {
                            var responseBody = await tagsResponse.Content.ReadAsStringAsync();
                            _logger.LogError($"Tags API failed with status {tagsResponse.StatusCode}: {responseBody}");
                        }
                        
                        tagsResponse.EnsureSuccessStatusCode();
                        
                        _logger.LogInformation("Tags updated successfully.");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to update tags.");
                    }
                }
                else
                {
                    _logger.LogInformation("Tags are already up to date. No action needed.");
                }

            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing event.");
                throw;
            }
        }

        private string? GetProperty(JsonElement element, string propertyName)
        {
            if (element.TryGetProperty(propertyName, out JsonElement value))
            {
                return value.GetString();
            }
            return null;
        }

        private string? GetCallerFromClaims(JsonElement data)
        {
            if (data.TryGetProperty("claims", out JsonElement claims))
            {
                string[] userKeysToLookFor = new[] 
                { 
                    "name", 
                    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", 
                    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn",
                    "email",
                    "upn"
                };

                foreach (var key in userKeysToLookFor)
                {
                    if (claims.TryGetProperty(key, out JsonElement claimValue))
                    {
                        return claimValue.GetString();
                    }
                }

                if (claims.TryGetProperty("principalType", out JsonElement principalType) && 
                    principalType.GetString() == "ServicePrincipal")
                {
                    if (claims.TryGetProperty("appid", out JsonElement appId))
                    {
                        return $"ServicePrincipal:{appId.GetString()}";
                    }
                }
            }
            
            return null;
        }
    }
}
