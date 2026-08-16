{
  config,
  pkgs,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  userName = config.my.user.name;
  tavilyPkg = inputs.nix-mcp.packages.${system}.tavily-mcp;
  tavilyKeyPath = config.sops.secrets."tavily-api-key".path;
  secretsFile = ../../secrets.yaml;
in
{
  name = "tavily";

  geminiServer = {
    command = "${tavilyPkg}/bin/tavily-mcp";
    args = [ ];
    env = {
      TAVILY_API_KEY = config.sops.placeholder."tavily-api-key";
    };
  };

  opencodeServer = {
    type = "local";
    command = [ "${tavilyPkg}/bin/tavily-mcp" ];
    environment = {
      TAVILY_API_KEY = "{file:${tavilyKeyPath}}";
    };
  };

  sopsSecrets = {
    "tavily-api-key" = {
      sopsFile = secretsFile;
      owner = userName;
      mode = "0400";
    };
  };
}
