using DashboardApi.Hubs;
using DashboardApi.Models;
using Microsoft.AspNetCore.SignalR;

var builder = WebApplication.CreateBuilder(args);

builder.Services
    .AddSignalR()
    .AddAzureSignalR(builder.Configuration["SignalR:ConnectionString"]);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.MapPost("/metrics", async (
    MetricMessage metric,
    IHubContext<MetricsHub> hubContext) =>
{
    await hubContext.Clients.All.SendAsync("metricReceived", metric);

    return Results.Ok();
});

app.MapHub<MetricsHub>("/hubs/metrics");

app.Run();