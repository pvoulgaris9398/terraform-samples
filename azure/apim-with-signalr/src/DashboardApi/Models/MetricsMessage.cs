namespace DashboardApi.Models;

public class MetricMessage
{
    public string ServiceName { get; set; } = string.Empty;
    public double CpuUsage { get; set; }
    public double MemoryUsage { get; set; }
    public DateTime Timestamp { get; set; }
}