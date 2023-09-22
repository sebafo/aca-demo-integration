namespace ServiceBus;

using Azure.Messaging.ServiceBus;

public interface IServiceBusService
{
    Task SendMessageAsync(string message);
}

public class ServiceBusService : IServiceBusService
{
    private readonly ServiceBusClient _client;
    private readonly ServiceBusSender _sender;

    public ServiceBusService(IConfiguration configuration, ServiceBusClient client)
    {
        _client = client;
        _sender = _client.CreateSender(configuration.GetValue<string>("ServiceBusTopicName"));
    }

    public async Task SendMessageAsync(string message)
    {
        await _sender.SendMessageAsync(new ServiceBusMessage(message));
    }
}