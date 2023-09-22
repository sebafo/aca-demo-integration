using Microsoft.Extensions.Azure;
using Azure.Identity;
using System.Text.Json;

using ServiceBus;

var builder = WebApplication.CreateBuilder();

builder.Services.AddApplicationMonitoring();

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options => {
    options.AddDefaultPolicy(builder =>
    {
        builder.AllowAnyOrigin();
        builder.AllowAnyHeader();
        builder.AllowAnyMethod();
    });
});

builder.Services.AddAzureClients(cfg =>
{
  cfg.AddServiceBusClientWithNamespace(builder.Configuration.GetValue<string>("ServiceBusNamespace"))
    .WithCredential(new DefaultAzureCredential(
        new DefaultAzureCredentialOptions { ManagedIdentityClientId = builder.Configuration.GetValue<string>("ClientId")}
    ));
});

builder.Services.AddSingleton<IServiceBusService, ServiceBusService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();

app.MapGet("/", async context =>
{
    await context.Response.WriteAsync("Hit the /albums endpoint to retrieve a list of albums!");
});

app.MapGet("/albums", () =>
{
    return Album.GetAll();
})
.WithName("GetAlbums");

// Uncomment to activate Streaming Endpoint in Application
app.MapPut("/albums/{id}", async (int id, IServiceBusService serviceBusService) =>
{
    var album = Album.GetAll().Where(ele => ele.Id == id).FirstOrDefault();
    await serviceBusService.SendMessageAsync(JsonSerializer.Serialize(album));
    return Results.Accepted();
});

app.Run();

record Album(int Id, string Title, string Artist, double Price, string Image_url)
{
     public static List<Album> GetAll(){
         var albums = new List<Album>(){
            new Album(1, "You, Me and an App Id", "Daprize", 10.99, "https://aka.ms/albums-daprlogo"),
            new Album(2, "Seven Revision Army", "The Blue-Green Stripes", 13.99, "https://aka.ms/albums-containerappslogo"),
            new Album(3, "Scale It Up", "KEDA Club", 13.99, "https://aka.ms/albums-kedalogo"),
            new Album(4, "Lost in Translation", "MegaDNS", 12.99,"https://aka.ms/albums-envoylogo"),
            new Album(5, "Lock Down Your Love", "V is for VNET", 12.99, "https://aka.ms/albums-vnetlogo"),
            new Album(6, "Sweet Container O' Mine", "Guns N Probeses", 14.99, "https://aka.ms/albums-containerappslogo")
         };

        return albums; 
     }
}