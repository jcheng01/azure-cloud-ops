const { app } = require("@azure/functions");
const { armGet, environment } = require("../lib/azure");
const { handleError, json } = require("../lib/http");
const { summarizeMetrics } = require("../lib/metrics");

app.http("monitoring", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "monitoring",

  handler: async (_request, context) => {
    try {
      const config = environment();
      if (!config.functionResourceId) {
        throw new Error("FUNCTION_RESOURCE_ID is not configured.");
      }

      const end = new Date();
      const start = new Date(end.getTime() - 24 * 60 * 60 * 1000);
      const query = new URLSearchParams({
        "api-version": "2023-10-01",
        metricnames: "Requests,AverageResponseTime,Http5xx",
        timespan: `${start.toISOString()}/${end.toISOString()}`,
        interval: "PT1H",
        aggregation: "Total,Average",
      });

      const payload = await armGet(
        `${config.functionResourceId}/providers/Microsoft.Insights/metrics?${query}`
      );

      return json(200, {
        periodHours: 24,
        ...summarizeMetrics(payload),
        telemetry: {
          applicationInsights: "appi-azure-cloudops",
          logAnalyticsWorkspace: "log-azure-cloudops-prod",
          retentionDays: 30,
          dailyQuotaGb: 0.5,
        },
        alert: {
          name: "alert-function-http-5xx",
          signal: "Http5xx",
          condition: "Total > 0 over 5 minutes",
          enabled: true,
        },
        generatedAt: new Date().toISOString(),
      });
    } catch (error) {
      return handleError(context, "monitoring", error);
    }
  },
});
