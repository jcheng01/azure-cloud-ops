const { app } = require("@azure/functions");
const {
  environment,
  escapeKusto,
  queryResources,
} = require("../lib/azure");
const { handleError, json } = require("../lib/http");

const requiredTags = ["Environment", "ManagedBy", "Project"];
const allowedLocations = ["eastus", "eastus2", "global"];

app.http("governance", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "governance",

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

      const resources = await queryResources(`
        Resources
        | where resourceGroup in~ (${groupList})
        | project location, tags
      `);

      const tagCoverage = requiredTags.map((tag) => {
        const compliant = resources.filter((resource) =>
          Boolean(resource.tags?.[tag])
        ).length;

        return {
          tag,
          compliant,
          total: resources.length,
          percent:
            resources.length > 0
              ? Math.round((compliant / resources.length) * 100)
              : 100,
        };
      });

      const invalidLocationCount = resources.filter(
        (resource) =>
          resource.location &&
          !allowedLocations.includes(resource.location.toLowerCase())
      ).length;

      return json(200, {
        policyEffect: "Audit",
        policyAssignmentCount: 4,
        resourceGroupCount: groups.length,
        resourcesEvaluated: resources.length,
        requiredTags: tagCoverage,
        locationCompliance: {
          allowedLocationCount: allowedLocations.length,
          invalidResourceCount: invalidLocationCount,
          compliant: invalidLocationCount === 0,
        },
        budget: {
          amount: config.monthlyBudget,
          actualThresholdPercent: 80,
          forecastThresholdPercent: 100,
        },
        generatedAt: new Date().toISOString(),
      });
    } catch (error) {
      return handleError(context, "governance", error);
    }
  },
});
