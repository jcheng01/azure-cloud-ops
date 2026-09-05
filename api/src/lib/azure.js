const { DefaultAzureCredential } = require("@azure/identity");
const { ResourceGraphClient } = require("@azure/arm-resourcegraph");

let credential;
let resourceGraphClient;

function getSubscriptionId() {
  const subscriptionId = process.env.AZURE_SUBSCRIPTION_ID;
  if (!subscriptionId) {
    throw new Error("AZURE_SUBSCRIPTION_ID is not configured.");
  }
  return subscriptionId;
}

function getCredential() {
  if (!credential) {
    credential = new DefaultAzureCredential();
  }
  return credential;
}

function getResourceGraphClient() {
  if (!resourceGraphClient) {
    resourceGraphClient = new ResourceGraphClient(
      getCredential(),
      getSubscriptionId()
    );
  }
  return resourceGraphClient;
}

function escapeKusto(value) {
  return String(value).replaceAll("'", "''");
}

function normalizeRows(data) {
  if (Array.isArray(data)) {
    return data;
  }

  if (data && Array.isArray(data.rows) && Array.isArray(data.columns)) {
    const names = data.columns.map((column) => column.name);
    return data.rows.map((row) =>
      Object.fromEntries(names.map((name, index) => [name, row[index]]))
    );
  }

  return [];
}

async function queryResources(query) {
  const result = await getResourceGraphClient().resources({
    subscriptions: [getSubscriptionId()],
    query,
  });

  return normalizeRows(result.data);
}

async function armGet(path) {
  const token = await getCredential().getToken(
    "https://management.azure.com/.default"
  );
  const url = path.startsWith("https://")
    ? path
    : `https://management.azure.com${path}`;

  const response = await fetch(url, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${token.token}`,
    },
  });

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Azure Resource Manager returned HTTP ${response.status}: ${detail}`);
  }

  return response.json();
}

function environment() {
  return {
    subscriptionId: getSubscriptionId(),
    labResourceGroup:
      process.env.RESOURCE_GROUP_NAME || "rg-cloudops-lab",
    productionResourceGroup:
      process.env.PRODUCTION_RESOURCE_GROUP_NAME || "rg-azure-cloudops-prod",
    functionResourceId: process.env.FUNCTION_RESOURCE_ID,
    monthlyBudget: Number(process.env.MONTHLY_BUDGET || 5),
  };
}

module.exports = {
  armGet,
  environment,
  escapeKusto,
  normalizeRows,
  queryResources,
};
