{
  config,
  pkgs,
  ...
}:

let
  port = config.my.services.documents.stirling-pdf.port or 8080;
  endpointUrl = "http://127.0.0.1:${toString port}/mcp";
in
{
  name = "stirling-pdf";

  commonSpec = {
    command = "${pkgs.nodejs}/bin/npx";
    args = [
      "-y"
      "mcp-remote"
      endpointUrl
    ];
    env = {
      STIRLING_ENDPOINT = endpointUrl;
    };
  };
}
