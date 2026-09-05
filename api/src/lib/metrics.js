function points(metric) {
  return (metric?.timeseries || []).flatMap((series) => series.data || []);
}

function sumMetric(metric) {
  return points(metric).reduce(
    (total, point) => total + Number(point.total ?? point.count ?? 0),
    0
  );
}

function averageMetric(metric) {
  const values = points(metric)
    .map((point) => point.average)
    .filter((value) => Number.isFinite(Number(value)))
    .map(Number);

  if (!values.length) {
    return 0;
  }

  return values.reduce((total, value) => total + value, 0) / values.length;
}

function findMetric(payload, name) {
  return (payload?.value || []).find(
    (metric) =>
      metric.name?.value?.toLowerCase() === name.toLowerCase() ||
      metric.name?.localizedValue?.toLowerCase() === name.toLowerCase()
  );
}

function summarizeMetrics(payload) {
  const requests = sumMetric(findMetric(payload, "Requests"));
  const failures = sumMetric(findMetric(payload, "Http5xx"));
  const averageResponseSeconds = averageMetric(
    findMetric(payload, "AverageResponseTime")
  );

  return {
    requests: Math.round(requests),
    failures: Math.round(failures),
    averageResponseMs: Math.round(averageResponseSeconds * 1000),
    successRate:
      requests > 0
        ? Number((((requests - failures) / requests) * 100).toFixed(2))
        : 100,
  };
}

module.exports = {
  averageMetric,
  findMetric,
  points,
  sumMetric,
  summarizeMetrics,
};
