{
  baseSettings,
  common,
  amoAddons,
  resolveAddons,
  ...
}:
{
  id = 1;
  settings = baseSettings // {
    "zen.urlbar.behavior" = "normal";
  };

  extensions.packages = resolveAddons (
    with amoAddons;
    [
      auto-tab-discard
      bitwarden
      ublock-origin
      privacy-badger
      canvasblocker
      localcdn
      proton-vpn
      ghost-downloader
    ]
  );

  mods = [
    "a6335949-4465-4b71-926c-4a52d34bc9c0" # Better Find Bar
    "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
    "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
    "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
    "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
  ];

  presets.betterfox.enable = true;

  containersForce = true;
  containers = common.mkAccountContainers {
    startId = 1;
    count = 10;
  };

  spacesForce = true;
  spaces = {
    "Personal" = {
      id = "c6de089c-410d-4206-961d-ab11f988d40a";
      position = 1000;
      icon = "🏠";
    };
    "Work" = {
      id = "cdd10fab-4fc5-494b-9041-325e5759195b";
      position = 2000;
      icon = "💼";
      container = 1;
    };
    "Social Media" = {
      id = "7bdd26e1-de81-4e0d-9aac-b0b737d5a0aa";
      position = 3000;
      icon = "📱";
      container = 2;
    };
    "AI" = {
      id = "60ac123a-9a5d-4941-9fa6-ffd84d80d9a4";
      position = 4000;
      icon = "🤖";
      container = 3;
    };
    "Secrets" = {
      id = "e26d72f6-8f7c-4d7b-8c62-67c82311edcb";
      position = 5000;
      container = 20;
    };
  };

  liveFolders = {
    "My Pull Requests" = {
      id = "b7a3d5c1-9e2f-4a68-b0d4-6f1c8e5a2d93";
      kind = "github:pull-requests";
      workspace = "cdd10fab-4fc5-494b-9041-325e5759195b";
      position = 401;
      github = {
        assignedMe = true;
        reviewRequested = true;
      };
    };
    "NixOS News" = {
      id = "0f3f2f66-64bc-4a43-8f86-01c2a134c4f4";
      kind = "rss";
      feedUrl = "https://nixos.org/blog/announcements-rss.xml";
      workspace = "c6de089c-410d-4206-961d-ab11f988d40a";
      maxItems = 10;
    };
  };

  spaceRouting = {
    force = true;
    routes = {
      # Social Media
      "twitter" = {
        reference = "x.com";
        openIn = "7bdd26e1-de81-4e0d-9aac-b0b737d5a0aa";
      };
      "facebook" = {
        reference = "facebook.com";
        openIn = "7bdd26e1-de81-4e0d-9aac-b0b737d5a0aa";
      };
      "whatsapp" = {
        reference = "web.whatsapp.com";
        openIn = "7bdd26e1-de81-4e0d-9aac-b0b737d5a0aa";
      };
      "reddit" = {
        reference = "reddit.com";
        openIn = "7bdd26e1-de81-4e0d-9aac-b0b737d5a0aa";
      };
      "youtube" = {
        reference = "youtube.com";
        openIn = "7bdd26e1-de81-4e0d-9aac-b0b737d5a0aa";
      };
      "instagram" = {
        reference = "instagram.com";
        openIn = "7bdd26e1-de81-4e0d-9aac-b0b737d5a0aa";
      };

      # AI Assistants
      "chatgpt" = {
        reference = "chatgpt.com";
        openIn = "60ac123a-9a5d-4941-9fa6-ffd84d80d9a4";
      };
      "claude" = {
        reference = "claude.ai";
        openIn = "60ac123a-9a5d-4941-9fa6-ffd84d80d9a4";
      };
      "gemini" = {
        reference = "gemini.google.com";
        openIn = "60ac123a-9a5d-4941-9fa6-ffd84d80d9a4";
      };

      # Work / Git
      "github" = {
        reference = "github.com";
        openIn = "cdd10fab-4fc5-494b-9041-325e5759195b";
      };
      "gitlab" = {
        reference = "gitlab.com";
        openIn = "cdd10fab-4fc5-494b-9041-325e5759195b";
      };
    };
  };
}
