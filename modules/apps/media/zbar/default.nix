{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.media.zbar";
  description = "ZBar barcode and QR code reader utility";

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      zbar
    ];
  };
}
