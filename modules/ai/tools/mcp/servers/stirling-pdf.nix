{
  config,
  selfLib,
  ...
}:

let
  port = config.my.services.documents.stirling-pdf.port or 8080;
  endpointUrl = "http://127.0.0.1:${toString port}/mcp";
  apiKey = "stirling-local-internal-mcp-key";
  mcpProxy = selfLib.fetchCachePinned "mcp_proxy";
in
{
  name = "stirling-pdf";
  enable = config.my.services.documents.stirling-pdf.enable or false;

  commonSpec = {
    command = "${mcpProxy}/bin/mcp-proxy";
    args = [
      "--transport"
      "streamablehttp"
      "--headers"
      "X-API-KEY"
      apiKey
      endpointUrl
    ];
    env = {
      STIRLING_ENDPOINT = endpointUrl;
    };
  };
}
