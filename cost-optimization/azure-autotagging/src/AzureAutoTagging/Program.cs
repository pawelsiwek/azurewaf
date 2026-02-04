using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using AzureAutoTagging;
using System;

// Check for integration test mode
if (args.Length > 0 && args[0] == "--integration-test")
{
    Console.WriteLine("[Program] Running in Integration Test mode");
    var testArgs = args.Length > 1 ? args[1..] : Array.Empty<string>();
    await IntegrationTest.Main(testArgs);
    Console.WriteLine("[Program] Integration Test finished. Exiting.");
    return;
}

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureServices(services =>
    {
        // Add services here if needed
    })
    .Build();

host.Run();
