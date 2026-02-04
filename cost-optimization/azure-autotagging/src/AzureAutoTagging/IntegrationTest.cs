using System;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace AzureAutoTagging
{
    public class IntegrationTest
    {
        public static async Task Main(string[] args)
        {
            Console.WriteLine("=== Azure Auto-Tagging Integration Test ===\n");
            
            // Set debug mode
            Environment.SetEnvironmentVariable("DEBUG_MODE", "true");
            
            // Setup logger
            using var loggerFactory = LoggerFactory.Create(builder =>
            {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Information);
            });
            
            var function = new TaggingFunction(loggerFactory);
            
            // Get test resource from command line or use default
            string subscriptionId = args.Length > 0 ? args[0] : "<subscription-id>";
            string resourceGroup = args.Length > 1 ? args[1] : "rg-autotagging";
            string resourceName = args.Length > 2 ? args[2] : "test123123123321321";
            
            Console.WriteLine($"Testing with:");
            Console.WriteLine($"  Subscription: {subscriptionId}");
            Console.WriteLine($"  Resource Group: {resourceGroup}");
            Console.WriteLine($"  Resource: {resourceName}");
            Console.WriteLine();
            
            // Create a mock Event Grid event
            var mockEvent = $$"""
            {
              "subject": "/subscriptions/{{subscriptionId}}/resourceGroups/{{resourceGroup}}/providers/Microsoft.Storage/storageAccounts/{{resourceName}}",
              "eventType": "Microsoft.Resources.ResourceWriteSuccess",
              "id": "test-{{Guid.NewGuid()}}",
              "data": {
                "authorization": {
                  "scope": "/subscriptions/{{subscriptionId}}/resourceGroups/{{resourceGroup}}/providers/Microsoft.Storage/storageAccounts/{{resourceName}}",
                  "action": "Microsoft.Storage/storageAccounts/write"
                },
                "claims": {
                  "name": "Test User",
                  "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name": "test.user@example.com",
                  "aud": "https://management.core.windows.net/",
                  "iss": "https://sts.windows.net/test-tenant-id/",
                  "iat": "{{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}}",
                  "nbf": "{{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}}",
                  "exp": "{{DateTimeOffset.UtcNow.AddHours(1).ToUnixTimeSeconds()}}"
                },
                "correlationId": "test-correlation-id",
                "httpRequest": {
                  "clientRequestId": "test-request-id",
                  "clientIpAddress": "127.0.0.1",
                  "method": "PUT"
                },
                "resourceProvider": "Microsoft.Storage",
                "resourceUri": "/subscriptions/{{subscriptionId}}/resourceGroups/{{resourceGroup}}/providers/Microsoft.Storage/storageAccounts/{{resourceName}}",
                "operationName": "Microsoft.Storage/storageAccounts/write",
                "status": "Succeeded",
                "subscriptionId": "{{subscriptionId}}",
                "tenantId": "test-tenant-id"
              },
              "dataVersion": "2",
              "metadataVersion": "1",
              "eventTime": "{{DateTime.UtcNow:O}}",
              "topic": "/subscriptions/{{subscriptionId}}"
            }
            """;
            
            Console.WriteLine("Mock Event Grid payload:");
            Console.WriteLine(mockEvent);
            Console.WriteLine("\n" + new string('=', 80) + "\n");
            
            try
            {
                var eventJson = JsonDocument.Parse(mockEvent);
                await function.Run(eventJson.RootElement);
                
                Console.WriteLine("\n" + new string('=', 80));
                Console.WriteLine("✓ Test completed successfully!");
                Console.WriteLine("\nNote: If running locally, ensure you are logged in with Azure CLI:");
                Console.WriteLine("  az login --tenant <your-tenant-id>");
                Console.WriteLine("\nTo test with a different resource, run:");
                Console.WriteLine("  dotnet run --project src/AzureAutoTagging/AzureAutoTagging.csproj <subscription-id> <resource-group> <resource-name>");
            }
            catch (Exception ex)
            {
                Console.WriteLine("\n" + new string('=', 80));
                Console.WriteLine("✗ Test failed with error:");
                Console.WriteLine(ex.ToString());
                Environment.Exit(1);
            }
        }
    }
}
