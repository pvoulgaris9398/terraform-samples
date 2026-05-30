using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

var dashboardApiUrl = Environment.GetEnvironmentVariable("DASHBOARD_API_URL")
                      ?? "http://localhost:5000";

var httpClient = new HttpClient();

app.MapGet("/generate", async () =>
{
    var random = new Random();

    var payload = new
    {
        serviceName = "orders-api",
        cpuUsage = random.NextDouble() * 100,
        memoryUsage = random.NextDouble() * 100,
        timestamp = DateTime.UtcNow
    };

    var content = new StringContent(
        JsonSerializer.Serialize(payload),
        Encoding.UTF8,
        "application/json");

    var response = await httpClient.PostAsync(
        $"{dashboardApiUrl}/metrics",
        content);

    return Results.Ok(await response.Content.ReadAsStringAsync());
});

app.Run();