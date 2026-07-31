{ baseSettings, lib }:
{
  isDefault = true;
  id = 0;
  settings = baseSettings;

  presets.betterfox.enable = true;

  mods = [
    "803c7895-b39b-458e-84f8-a521f4d7a064" # Hide Inactive Workspaces
    "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
  ];

  containersForce = true;
  containers = builtins.listToAttrs (
    builtins.genList (i: {
      name = "Account ${if i + 1 < 10 then "0" + toString (i + 1) else toString (i + 1)}";
      value = {
        id = i + 6;
        color = builtins.elemAt [
          "blue"
          "turquoise"
          "green"
          "yellow"
          "orange"
          "red"
          "pink"
          "purple"
        ] (lib.mod i 8);
        icon = builtins.elemAt [
          "fingerprint"
          "briefcase"
          "dollar"
          "cart"
          "circle"
          "gift"
          "vacation"
          "food"
        ] (lib.mod i 8);
      };
    }) 20
  );

  spacesForce = true;
  spaces = {
    "Space" = {
      id = "e51c3712-06c5-4620-a0e5-7edf3ba57de6";
      position = 1000;
      icon = "🏠";
    };
    "Sosmed" = {
      id = "5d740fa4-6944-493c-bb2c-3803ce55c5b9";
      position = 2000;
      icon = "📱";
    };
    "dataset" = {
      id = "fb0b187b-9500-475c-b8f7-9cf84677ebf2";
      position = 3000;
      icon = "📂";
    };
    "AI" = {
      id = "2e6b7294-75e3-49f4-9998-659018ea8bbd";
      position = 4000;
      icon = "🤖";
      container = 3;
    };
    "Localhost" = {
      id = "4dd78e5e-05e0-48e2-a337-f69466eff97d";
      position = 5000;
      icon = "🌐";
    };
  };

  spaceRouting = {
    force = true;
    routes = {
      # Localhost
      "localhost" = {
        reference = "localhost";
        openIn = "4dd78e5e-05e0-48e2-a337-f69466eff97d";
      };
      "0.0.0.0" = {
        reference = "0.0.0.0";
        openIn = "4dd78e5e-05e0-48e2-a337-f69466eff97d";
      };
      "127.0.0.1" = {
        reference = "127.0.0.1";
        openIn = "4dd78e5e-05e0-48e2-a337-f69466eff97d";
      };
      "192.168.5" = {
        reference = "192.168.5.";
        openIn = "4dd78e5e-05e0-48e2-a337-f69466eff97d";
      };

      # Dataset
      "kaggle" = {
        reference = "kaggle.com";
        openIn = "fb0b187b-9500-475c-b8f7-9cf84677ebf2";
      };
      "google colab" = {
        reference = "colab.research.google.com";
        openIn = "fb0b187b-9500-475c-b8f7-9cf84677ebf2";
      };
      "roboflow" = {
        reference = "roboflow.com";
        openIn = "fb0b187b-9500-475c-b8f7-9cf84677ebf2";
      };

      # Social Media
      "twitter" = {
        reference = "x.com";
        openIn = "5d740fa4-6944-493c-bb2c-3803ce55c5b9";
      };
      "facebook" = {
        reference = "facebook.com";
        openIn = "5d740fa4-6944-493c-bb2c-3803ce55c5b9";
      };
      "whatsapp" = {
        reference = "web.whatsapp.com";
        openIn = "5d740fa4-6944-493c-bb2c-3803ce55c5b9";
      };
      "reddit" = {
        reference = "reddit.com";
        openIn = "5d740fa4-6944-493c-bb2c-3803ce55c5b9";
      };
      "youtube" = {
        reference = "youtube.com";
        openIn = "5d740fa4-6944-493c-bb2c-3803ce55c5b9";
      };
      "instagram" = {
        reference = "instagram.com";
        openIn = "5d740fa4-6944-493c-bb2c-3803ce55c5b9";
      };

      # AI
      "chatgpt" = {
        reference = "chatgpt.com";
        openIn = "2e6b7294-75e3-49f4-9998-659018ea8bbd";
      };
      "claude" = {
        reference = "claude.ai";
        openIn = "2e6b7294-75e3-49f4-9998-659018ea8bbd";
      };
      "gemini" = {
        reference = "gemini.google.com";
        openIn = "2e6b7294-75e3-49f4-9998-659018ea8bbd";
      };
      "huggingface" = {
        reference = "huggingface.co";
        openIn = "2e6b7294-75e3-49f4-9998-659018ea8bbd";
      };

      # Work / Git
      "google" = {
        reference = "google.com";
        openIn = "e51c3712-06c5-4620-a0e5-7edf3ba57de6";
      };
      "github" = {
        reference = "github.com";
        openIn = "e51c3712-06c5-4620-a0e5-7edf3ba57de6";
      };
      "gitlab" = {
        reference = "gitlab.com";
        openIn = "e51c3712-06c5-4620-a0e5-7edf3ba57de6";
      };
    };
  };
}
