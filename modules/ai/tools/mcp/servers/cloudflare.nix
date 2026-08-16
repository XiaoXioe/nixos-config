{ config, ... }:
let
  userName = config.my.user.name;
  secretsFile = ../../secrets.yaml;
in
{
  name = "cloudflare-api";

  geminiServer = {
    url = "https://mcp.cloudflare.com/mcp";
    headers = {
      Authorization = "Bearer ${config.sops.placeholder.cloudflare-token}";
    };
  };

  sopsSecrets = {
    "cloudflare-token" = {
      sopsFile = secretsFile;
      owner = userName;
      mode = "0400";
    };
  };
}
