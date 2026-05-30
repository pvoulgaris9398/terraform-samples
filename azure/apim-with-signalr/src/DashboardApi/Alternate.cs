using Microsoft.AspNetCore.SignalR;

var builder = WebApplication.CreateBuilder(args);

// Add SignalR and configure CORS to allow your APIM/Dashboard domain
builder.Services.AddSignalR();
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("https://your-dashboard-domain.com", "https://azure-api.net")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials(); // Crucial for SignalR
    });
});

var app = builder.Build();

app.UseCors();

// Map the real-time dashboard Hub endpoint
app.MapHub<DashboardHub>("/api/dashboardHub");

// Background worker thread simulating real-time metric updates
Task.Run(async () =>
{
    while (true)
    {
        var random = new Random();
        var metrics = new { 
            cpuUsage = random.Next(20, 95), 
            activeUsers = random.Next(150, 2000),
            timestamp = DateTime.UtcNow 
        };
        
        // Broadcast metrics to all connected clients every 2 seconds
        var hubContext = app.Services.GetRequiredService<IHubContext<DashboardHub>>();
        await hubContext.Clients.All.SendAsync("ReceiveMetrics", metrics);
        
        await Task.Delay(2000);
    }
});

app.Run();

// Minimal Hub Definition
public class DashboardHub : Hub 
{
    public override async Task OnConnectedAsync()
    {
        await Clients.Caller.SendAsync("ReceiveLog", "Connected securely to real-time stream.");
        await base.OnConnectedAsync();
    }
}
