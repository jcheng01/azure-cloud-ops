const { app } = require("@azure/functions");
const {
  environment,
  escapeKusto,
  queryResources,
} = require("../lib/azure");
const { handleError, json } = require("../lib/http");

app.http("overview", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "overview",

  handler: async (_request, context) => {
    try {
      const config = environment();
      const groups = [
        config.labResourceGroup,
        config.productionResourceGroup,
      ];
      const groupList = groups
        .map((name) => `'${escapeKusto(name)}'`)
        .join(", ");

      const rows = await queryResources(`
        Resources
        | where resourceGroup in~ (${groupList})
        | summarize resourceCount = count(), regions = make_set(location)
      `);

      return json(200, {
        environment: "Azure CloudOps portfolio",
        status: "Live Azure data",
        regions: rows[0]?.regions || [],
        resources: Number(rows[0]?.resourceCount || 0),
        resourceGroupCount: groups.length,
        iac: "Terraform",
        cicd: "GitHub Actions with OIDC",
        monthlyBudget: config.monthlyBudget,
        generatedAt: new Date().toISOString(),
      });
    } catch (error) {
      return handleError(context, "overview", error);
    }
  },
});
