const { app } = require("@azure/functions");
const {
  environment,
  escapeKusto,
  queryResources,
} = require("../lib/azure");
const { handleError, json } = require("../lib/http");

app.http("networking", {
  methods: ["GET"],
  authLevel: "anonymous",
  route: "networking",

  handler: async (_request, context) => {
    try {
      const { labResourceGroup } = environment();
      const rows = await queryResources(`
        Resources
        | where resourceGroup =~ '${escapeKusto(labResourceGroup)}'
        | where type in~ (
            'microsoft.network/virtualnetworks',
            'microsoft.network/networksecuritygroups'
          )
        | project type, location, properties
      `);

      const vnets = rows.filter(
        (row) => row.type?.toLowerCase() === "microsoft.network/virtualnetworks"
      );
      const nsgs = rows.filter(
        (row) =>
          row.type?.toLowerCase() ===
          "microsoft.network/networksecuritygroups"
      );
      const subnetCount = vnets.reduce(
        (total, vnet) => total + (vnet.properties?.subnets || []).length,
        0
      );
      const attachedSubnetCount = vnets.reduce(
        (total, vnet) =>
          total +
          (vnet.properties?.subnets || []).filter(
            (subnet) => subnet.properties?.networkSecurityGroup?.id
          ).length,
        0
      );
      const customRuleCount = nsgs.reduce(
        (total, nsg) =>
          total + (nsg.properties?.securityRules || []).length,
        0
      );

      return json(200, {
        virtualNetworkCount: vnets.length,
        subnetCount,
        networkSecurityGroupCount: nsgs.length,
        protectedSubnetCount: attachedSubnetCount,
        customRuleCount,
        regions: [...new Set(vnets.map((vnet) => vnet.location))],
        design: {
          tiers: ["Web", "Application", "Data"],
          segmentation: "One network security group per subnet",
          defaultPosture: "Explicit allow rules with deny boundaries",
        },
        generatedAt: new Date().toISOString(),
      });
    } catch (error) {
      return handleError(context, "networking", error);
    }
  },
});
