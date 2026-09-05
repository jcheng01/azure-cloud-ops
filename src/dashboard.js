const API_BASE =
  "https://func-azure-cloudops-jcheng01.azurewebsites.net/api";

const pageTitles = {
  overview: "Overview",
  architecture: "Architecture",
  networking: "Networking",
  security: "Security",
  monitoring: "Monitoring",
  governance: "Governance",
};

const state = {};

function setText(id, value) {
  const element = document.getElementById(id);
  if (element) element.textContent = value ?? "—";
}

function number(value) {
  return new Intl.NumberFormat().format(Number(value || 0));
}

function money(value) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(Number(value || 0));
}

function showPage(name) {
  const page = pageTitles[name] ? name : "overview";
  document.querySelectorAll(".page").forEach((section) => {
    section.classList.toggle("active", section.id === `page-${page}`);
  });
  document.querySelectorAll("[data-page]").forEach((link) => {
    link.classList.toggle("active", link.dataset.page === page);
  });
  setText("page-title", pageTitles[page]);
  window.scrollTo({ top: 0, behavior: "smooth" });
}

async function fetchArea(area) {
  const response = await fetch(`${API_BASE}/${area}`, {
    headers: { Accept: "application/json" },
  });
  if (!response.ok) throw new Error(`${area} returned HTTP ${response.status}`);
  return response.json();
}

function renderOverview(data) {
  setText("overview-resources", number(data.resources));
  setText("overview-groups", number(data.resourceGroupCount));
  setText("overview-budget", money(data.monthlyBudget));
  setText(
    "overview-regions",
    Array.isArray(data.regions) && data.regions.length
      ? data.regions.join(", ")
      : "Azure"
  );
}

function renderNetworking(data) {
  setText("network-vnets", number(data.virtualNetworkCount));
  setText("network-subnets", number(data.subnetCount));
  setText("network-nsgs", number(data.networkSecurityGroupCount));
  setText("network-protected", number(data.protectedSubnetCount));
  setText("network-rules", `${number(data.customRuleCount)} rules`);
}

function renderSecurity(data) {
  setText("security-identity", data.identity?.type);
  setText("security-role", data.identity?.role);
  setText("security-scopes", number(data.identity?.scopedResourceGroupCount));
  setText(
    "security-creds",
    data.identity?.storedCloudCredentials ? "Present" : "None"
  );
  setText("security-allow", number(data.networkControls?.allowRules));
  setText("security-deny", number(data.networkControls?.denyRules));
  setText(
    "security-nsgs",
    number(data.networkControls?.networkSecurityGroupCount)
  );
  setText("security-tls", data.transport?.minimumTls);
}

function renderMonitoring(data) {
  setText("monitor-requests", number(data.requests));
  setText("monitor-response", number(data.averageResponseMs));
  setText("monitor-failures", number(data.failures));
  setText("monitor-success", `${Number(data.successRate || 0).toFixed(2)}%`);
  setText("monitor-retention", `${data.telemetry?.retentionDays || 0} days`);
  setText("monitor-quota", `${data.telemetry?.dailyQuotaGb || 0} GB`);
  setText("monitor-alert", data.alert?.enabled ? "Enabled" : "Disabled");
  setText("monitor-condition", data.alert?.condition);
}

function renderGovernance(data) {
  setText("gov-assignments", number(data.policyAssignmentCount));
  setText("gov-resources", number(data.resourcesEvaluated));
  setText("gov-budget", money(data.budget?.amount));
  setText("gov-effect", data.policyEffect);
  setText(
    "location-status",
    data.locationCompliance?.compliant ? "Compliant" : "Review"
  );
  setText(
    "invalid-locations",
    number(data.locationCompliance?.invalidResourceCount)
  );

  const coverage = document.getElementById("tag-coverage");
  coverage.replaceChildren();
  (data.requiredTags || []).forEach((item) => {
    const row = document.createElement("div");
    row.className = "coverage-row";

    const label = document.createElement("b");
    label.textContent = item.tag;

    const track = document.createElement("span");
    track.className = "track";
    const fill = document.createElement("i");
    fill.style.width = `${Math.max(0, Math.min(100, item.percent))}%`;
    track.append(fill);

    const value = document.createElement("span");
    value.textContent = `${item.percent}%`;

    row.append(label, track, value);
    coverage.append(row);
  });
}

const renderers = {
  overview: renderOverview,
  networking: renderNetworking,
  security: renderSecurity,
  monitoring: renderMonitoring,
  governance: renderGovernance,
};

async function refresh() {
  const button = document.getElementById("refresh");
  button.disabled = true;
  button.textContent = "Refreshing…";
  setText("sidebar-status", "Querying Azure");

  const areas = Object.keys(renderers);
  const results = await Promise.allSettled(
    areas.map(async (area) => {
      const data = await fetchArea(area);
      state[area] = data;
      renderers[area](data);
      return data;
    })
  );

  const failures = results.filter((result) => result.status === "rejected");
  if (failures.length) {
    console.error("Some dashboard queries failed:", failures);
    setText(
      "sidebar-status",
      failures.length === areas.length ? "API unavailable" : "Partial telemetry"
    );
  } else {
    setText("sidebar-status", "Azure connected");
  }

  const timestamps = Object.values(state)
    .map((area) => Date.parse(area.generatedAt))
    .filter(Number.isFinite);
  if (timestamps.length) {
    const latest = new Date(Math.max(...timestamps));
    setText("last-updated", `Updated ${latest.toLocaleTimeString()}`);
  }

  button.disabled = false;
  button.textContent = "Refresh data";
}

window.addEventListener("hashchange", () => {
  showPage(location.hash.slice(1));
});

document.getElementById("refresh").addEventListener("click", refresh);
showPage(location.hash.slice(1));
refresh();
