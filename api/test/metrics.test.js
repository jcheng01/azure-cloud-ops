const test = require("node:test");
const assert = require("node:assert/strict");

const {
  averageMetric,
  findMetric,
  sumMetric,
  summarizeMetrics,
} = require("../src/lib/metrics");

const payload = {
  value: [
    {
      name: { value: "Requests" },
      timeseries: [{ data: [{ total: 8 }, { total: 12 }] }],
    },
    {
      name: { value: "Http5xx" },
      timeseries: [{ data: [{ total: 1 }, { total: 0 }] }],
    },
    {
      name: { value: "AverageResponseTime" },
      timeseries: [{ data: [{ average: 0.1 }, { average: 0.2 }] }],
    },
  ],
};

test("findMetric matches Azure metric names case-insensitively", () => {
  assert.equal(findMetric(payload, "requests").name.value, "Requests");
});

test("metric helpers aggregate time-series data", () => {
  assert.equal(sumMetric(findMetric(payload, "Requests")), 20);
  assert.equal(
    averageMetric(findMetric(payload, "AverageResponseTime")),
    0.15
  );
});

test("summarizeMetrics returns dashboard-ready values", () => {
  assert.deepEqual(summarizeMetrics(payload), {
    requests: 20,
    failures: 1,
    averageResponseMs: 150,
    successRate: 95,
  });
});

test("summarizeMetrics handles an empty Azure response", () => {
  assert.deepEqual(summarizeMetrics({ value: [] }), {
    requests: 0,
    failures: 0,
    averageResponseMs: 0,
    successRate: 100,
  });
});
