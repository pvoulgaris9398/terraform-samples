import { useAzureMonitor } from "@azure/monitor-opentelemetry";
import * as opentelemetry from "@opentelemetry/api";

// 1. Bootstraps the OpenTelemetry engine and auto-detects the connection string variable
useAzureMonitor();

// 2. Capture a Custom Business Metric (e.g., tracking user logins)
const meter = opentelemetry.metrics.getMeter("crm-business-metrics");
const loginCounter = meter.createCounter("user_logins_total", {
    description: "Counts total successful user authentications"
});

// Use this inside your application API routes
loginCounter.add(1, { environment: "production" });

// 3. Capture an explicit Distributed Trace (Span)
const tracer = opentelemetry.trace.getTracer("crm-request-tracer");
const span = tracer.startSpan("process-cosmos-db-query");

try {
    // Your actual database code executes here
    span.setAttribute("database.system", "cosmosdb");
} finally {
    span.end(); // Marks the trace block complete and ships it immediately
}
