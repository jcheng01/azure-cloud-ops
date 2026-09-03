const { app } = require('@azure/functions');

/**
 * GET /api/overview
 *
 * Returns the environment summary shown on the dashboard's Overview page.
 *
 * Right now it returns static sample data, so the site works before any Azure
 * wiring exists. When you're ready to pull live data:
 *   1. In the API folder, run:
 *        npm install @azure/identity @azure/arm-resourcegraph
 *   2. Give this Function App's system-assigned managed identity the built-in
 *      "Reader" role on your resource group (or subscription).
 *   3. Uncomment the LIVE DATA block below and delete the sample values you
 *      no longer need.
 */
app.http('overview', {
  methods: ['GET'],
  authLevel: 'anonymous',
  route: 'overview',
  handler: async (request, context) => {
    // ---------- SAMPLE DATA (replace once live) ----------
    const data = {
      environment: 'Portfolio lab',
      status: 'Sample data',
      region: 'East US',
      resources: 11,
      lastDeploymentMinutes: 4,
      iac: 'Terraform',
      cicd: 'GitHub Actions',
      monthlyBudget: 5
    };

    // ---------- LIVE DATA (enable later) ----------
    // const { DefaultAzureCredential } = require('@azure/identity');
    // const { ResourceGraphClient } = require('@azure/arm-resourcegraph');
    //
    // const resourceGroup = process.env.TARGET_RESOURCE_GROUP; // e.g. rg-cloudops-eastus
    // const credential = new DefaultAzureCredential();          // uses the managed identity in Azure
    // const client = new ResourceGraphClient(credential);
    //
    // const countResult = await client.resources({
    //   query: `Resources | where resourceGroup =~ '${resourceGroup}' | summarize total = count()`
    // });
    // data.resources = countResult.data[0].total;

    context.log(`overview requested — returning ${data.resources} resources`);

    return {
      jsonBody: data,
      headers: { 'Cache-Control': 'no-store' }
    };
  }
});
