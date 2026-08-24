{
  config,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "ai.tools.kaggle";
  description = "Kaggle CLI & SDK setup";

  nixosConfig = {
    sops.secrets."kaggle-token" = {
      sopsFile = ./secrets.yaml;
      owner = config.my.user.name;
      mode = "0400";
    };
    sops.templates."access_token" = {
      path = "/home/${config.my.user.name}/.kaggle/access_token";
      owner = config.my.user.name;
      mode = "0600";
      content = ''
        ${config.sops.placeholder.kaggle-token}
      '';
    };
  };

  hmConfig = {
    home.packages = [
      (selfLib.fetchCachePinned "kaggle")
    ];
  };
}
