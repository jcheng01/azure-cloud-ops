const { app } = require("@azure/functions");
const { DefaultAzureCredential } = require("@azure/identity");
const { ResourceGraphClient } = require("@azure/arm-resourcegraph");

app.http("overview", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "overview",

  handler: async (request, context) => {
    const subscriptionId = process.env.AZURE_SUBSCRIPTION_ID;
    const resourceGroupName =
      process.env.RESOURCE_GROUP_NAME || "rg-cloudops-lab";

    if (!subscriptionId) {
      return {
        status: 500,
        jsonBody: {
          status: "Configuration error",
          message: "AZURE_SUBSCRIPTION_ID is not configured.",
        },
      };
    }

    try {
      const credential = new DefaultAzureCredential();

      const resourceGraphClient = new ResourceGraphClient(
        credential,
        subscriptionId
      );

      const query = `
        Resources
        | where resourceGroup =~ '${resourceGroupName}'
        | summarize resourceCount = count()
      `;

      const result = await resourceGraphClient.resources({
        subscriptions: [subscriptionId],
        query,
      });

      const rows = Array.isArray(result.data) ? result.data : [];
      const resourceCount = Number(rows[0]?.resourceCount ?? 0);

      return {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "no-store",
        },
        jsonBody: {
          environment: "Portfolio lab",
          status: "Live Azure data",
          region: "East US",
          resources: resourceCount,
          lastDeploymentMinutes: 4,
          iac: "Terraform",
          cicd: "GitHub Actions",
          monthlyBudget: 5,
          generatedAt: new Date().toISOString(),
        },
      };
    } catch (error) {
      context.error("Azure Resource Graph query failed.", error);

      return {
        status: 500,
        jsonBody: {
          status: "Azure query failed",
          message: error.message,
        },
      };
    }
  },
});