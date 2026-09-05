function json(status, jsonBody, cacheSeconds = 30) {
  return {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": `public, max-age=${cacheSeconds}`,
    },
    jsonBody,
  };
}

function handleError(context, area, error) {
  context.error(`${area} query failed.`, error);

  return json(
    500,
    {
      status: "Azure query failed",
      area,
      message: error.message,
      generatedAt: new Date().toISOString(),
    },
    0
  );
}

module.exports = { handleError, json };
