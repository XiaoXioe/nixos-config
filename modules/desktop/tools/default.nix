{
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  # 1. Skrip Pemindai Teks (OCR) Presisi Tinggi (ImageMagick Pre-processing + Tesseract --psm 6)
  scanOcrText =
    selfLib.mkApp pkgs "wayland-scan-ocr"
      ''
        TMP_RAW=$(mktemp /tmp/ocr_raw_XXXXXX.png)
        TMP_PROC=$(mktemp /tmp/ocr_proc_XXXXXX.png)

        # Tangkap area layar
        grim -g "$(slurp)" "$TMP_RAW" || { rm -f "$TMP_RAW" "$TMP_PROC"; exit 0; }

        # Pra-pemrosesan ImageMagick (Scale 2.5x & Grayscale agar akurasi Tesseract 98%+)
        magick "$TMP_RAW" -resize 250% -colorspace gray -normalize "$TMP_PROC" 2>/dev/null || cp "$TMP_RAW" "$TMP_PROC"

        # Tesseract OCR dengan mode Uniform Block Text (--psm 6)
        TEXT_RESULT=$(tesseract "$TMP_PROC" stdout --psm 6 -l eng+ind 2>/dev/null)
        TRIMMED=$(echo "$TEXT_RESULT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        if [ -n "$TRIMMED" ]; then
          echo -n "$TRIMMED" | wl-copy
          notify-send -a "OCR Scanner" "Teks Terdeteksi (OCR)" "$TRIMMED"
        else
          notify-send -a "OCR Scanner" "Gagal" "Tidak ada teks yang terdeteksi."
        fi

        rm -f "$TMP_RAW" "$TMP_PROC"
      ''
      [
        pkgs.grim
        pkgs.slurp
        pkgs.imagemagick
        pkgs.tesseract
        pkgs.wl-clipboard
        pkgs.libnotify
        pkgs.gnused
        pkgs.coreutils
      ];

  # 2. Skrip Pemindai QR Code / Barcode Instan
  scanQrCode =
    selfLib.mkApp pkgs "wayland-scan-qr"
      ''
        TMP_RAW=$(mktemp /tmp/qr_raw_XXXXXX.png)

        # Tangkap area layar
        grim -g "$(slurp)" "$TMP_RAW" || { rm -f "$TMP_RAW"; exit 0; }

        # Baca QR Code / Barcode via zbarimg
        QR_RESULT=$(zbarimg -q --raw "$TMP_RAW" 2>/dev/null)

        if [ -n "$QR_RESULT" ]; then
          echo -n "$QR_RESULT" | wl-copy
          notify-send -a "QR Scanner" "QR Code Terdeteksi!" "$QR_RESULT"
        else
          notify-send -a "QR Scanner" "Gagal" "Tidak terdeteksi QR Code pada area ini."
        fi

        rm -f "$TMP_RAW"
      ''
      [
        pkgs.grim
        pkgs.slurp
        pkgs.zbar
        pkgs.wl-clipboard
        pkgs.libnotify
        pkgs.coreutils
      ];

  # 3. Skrip Anotasi Screenshot Interaktif (Satty)
  scanAnnotate =
    selfLib.mkApp pkgs "wayland-scan-annotate"
      ''
        grim -g "$(slurp)" - | satty --filename -
      ''
      [
        pkgs.grim
        pkgs.slurp
        pkgs.satty
      ];
in
selfLib.mkModule {
  name = "desktop.tools";
  description = "Shared Wayland screenshot, OCR, QR scanner, and annotation utilities";

  options = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable shared Wayland desktop tools.";
    };
  };

  nixosConfig = {
    environment.systemPackages = with pkgs; [
      grim
      slurp
      satty
      wl-clipboard
      libnotify
      zbar
      tesseract
      imagemagick
      scanOcrText
      scanQrCode
      scanAnnotate
    ];
  };
}
