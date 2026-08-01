{ lib }:
{
  # Helper generator akun kontainer standar dengan opsi kustomisasi startId dan count
  mkAccountContainers =
    {
      startId ? 1,
      count ? 20,
    }:
    builtins.listToAttrs (
      builtins.genList (i: {
        name = "Account ${if i + 1 < 10 then "0" + toString (i + 1) else toString (i + 1)}";
        value = {
          id = i + startId;
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
      }) count
    );
}
