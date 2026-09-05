const { app } = require("@azure/functions");
const {
  environment,
  escapeKusto,
  queryResources,
} = require("../lib/azure");
const { handleError, json } = require("../lib/http");

app.http("security", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "security",

  handler: async (_request, context) => {
    try {
      const { labResourceGroup } = environment();
      const nsgRows = await queryResources(`
        Resources
        | where resourceGroup =~ '${escapeKusto(labResourceGroup)}'
        | where type =~ 'microsoft.network/networksecuritygroups'
        | project properties
      `);

      const rules = nsgRows.flatMap(
        (nsg) => nsg.properties?.securityRules || []
      );
      const allowRules = rules.filter(
        (rule) => rule.properties?.access?.toLowerCase() === "allow"
      ).length;
      const denyRules = rules.filter(
        (rule) => rule.properties?.access?.toLowerCase() === "deny"
      ).length;

      return json(200, {
        identity: {
          type: "System-assigned managed identity",
          role: "Reader",
          scopedResourceGroupCount: 2,
          storedCloudCredentials: false,
        },
        transport: {
          httpsOnly: true,
          minimumTls: "1.2",
          corsRestrictedToDashboard: true,
        },
        networkControls: {
          networkSecurityGroupCount: nsgRows.length,
          customRuleCount: rules.length,
          allowRules,
          denyRules,
        },
        deploymentIdentity: {
          authentication: "GitHub Actions OIDC",
          longLivedClientSecret: false,
        },
        generatedAt: new Date().toISOString(),
      });
    } catch (error) {
      return handleError(context, "security", error);
    }
  },
});
