using System;
using Microsoft.Azure.WebJobs;
//using Microsoft.Azure.WebJobs.Host;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
//using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.PowerPlatform.Dataverse.Client;
using Microsoft.Crm.Sdk.Messages;

namespace azd.Dataverse.Function
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder){}
    }

    public class ProcessServiceBusMessage
    {
        private readonly ServiceClient _client;

        public ProcessServiceBusMessage()
        {
            // Initialize variables
            string environmentUrl = System.Environment.GetEnvironmentVariable("ENVIRONMENT-URL", EnvironmentVariableTarget.Process);
            string clientId = System.Environment.GetEnvironmentVariable("CLIENT-ID", EnvironmentVariableTarget.Process);
            string clientSecret = System.Environment.GetEnvironmentVariable("CLIENT-SECRET", EnvironmentVariableTarget.Process);

            // Create a connection (service client) for the considered environment
            string additionalConnectionStringParameters = $";AuthType=ClientSecret;ClientId={clientId};ClientSecret={clientSecret}";
            string connectionString = $"Url={environmentUrl};RedirectUri=http://localhost;LoginPrompt=Auto{additionalConnectionStringParameters}";

            this._client = new ServiceClient(connectionString);
        }

        [FunctionName("ProcessServiceBusMessage")]
        public void Run([ServiceBusTrigger("dataverse-inbound", Connection = "ServiceBusConnection")]string myQueueItem, ILogger log)
        {
            log.LogInformation($"C# ServiceBus queue trigger function processed message: {myQueueItem}");

            // Send a WhoAmI request to obtain information about the logged on user
            WhoAmIResponse whoAmIResponse = new WhoAmIResponse();
            whoAmIResponse = (WhoAmIResponse)_client.Execute(new WhoAmIRequest());

            string userId = whoAmIResponse.UserId.ToString();

            log.LogInformation($"Logged on user id: {userId}");
        }
    }
}
