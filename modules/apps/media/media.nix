{
  pkgs,
  selfLib,
  inputs,
  ...
}:

selfLib.mkModule {
  name = "apps.media.media";
  description = "user media configuration (mpv, yt-dlp, obs)";

  hmConfig = hmOpts: {
    home.packages = with pkgs; [
      ffmpeg
      zbar
      inputs.torlink.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    programs.gallery-dl = {
      enable = true;
      settings = {
        "extractor" = {
          "base-directory" = "~/CloudStorage/gdrive-akbar-68-decrypted/Gallery/";
          "archive" = "~/.local/share/gallery-dl/archive.sqlite3";

          "directory" = [
            "{category}"
            "{user[name]|username|id}"
          ];

          "facebook" = {
            "directory" = [
              "facebook"
              "{username|author|group|group_id|id}"
            ];
          };

          "pixiv" = {
            "ugoira" = "original";
            "postprocessors" = [
              {
                "name" = "ugoira";
                "extension" = "mp4";
                "ffmpeg-location" = "ffmpeg";
              }
              { "name" = "mtime"; }
            ];
          };
        };

        "cookies" = [ "firefox" ];

        "cache" = {
          "file" = "~/.local/share/gallery-dl/cache.sqlite3";
        };
      };
    };

    programs.mpv = {
      enable = true;
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
        autoload
        mpris
        webtorrent-mpv-hook
        quality-menu
        mpv-playlistmanager
      ];
      config = {
        vo = "gpu";
        gpu-context = "wayland";
        gpu-api = "opengl";
        hwdec = "vaapi-copy";
        osc = false;
        osd-bar = false;
        border = false;
        msg-level = "ffmpeg/video=error,ffmpeg=fatal,audio=error";
        profile = "fast";
        video-sync = "audio";
        cache = "yes";
        demuxer-max-bytes = "800MiB";
        demuxer-readahead-secs = 120;
        save-position-on-quit = true;
        hr-seek-framedrop = "yes";
        framedrop = "decoder";
        network-timeout = 100;
        # stream-lavf-o = "reconnect=1,reconnect_streamed=1,reconnect_delay_max=5,reconnect_at_eof=1";
        ytdl-format = "bestvideo[height<=1080][vcodec^=avc]+bestaudio/best[height<=1080][vcodec^=avc]/bestvideo[height<=720][vcodec^=avc]+bestaudio/best";
        ytdl-raw-options = "cookies-from-browser=firefox";
      };
      bindings = {
        RIGHT = "seek 2";
        LEFT = "seek -2";
      };
      scriptOpts = {
        ytdl_hook = {
          ytdl_path = "${pkgs.yt-dlp}/bin/yt-dlp";
        };
      };
    };

    programs.aria2 = {
      enable = true;
      settings = {
        # --- Kecepatan & Multi-Threading ---
        max-connection-per-server = 4; # Maksimal koneksi ke satu server
        split = 4; # Membagi satu file menjadi 4 bagian saat diunduh
        min-split-size = "10M"; # Jangan pisahkan file yang ukurannya di bawah 10MB
        max-concurrent-downloads = 5; # Maksimal jumlah file yang diunduh bersamaan (antrean)
        optimize-concurrent-downloads = true;

        # --- Manajemen File & Penyimpanan ---
        continue = true; # Otomatis melanjutkan (resume) unduhan yang terputus
        file-allocation = "falloc"; # Mengalokasikan ruang disk seketika (sangat cepat untuk ext4/btrfs)
        allow-overwrite = false; # Jangan timpa file jika sudah ada dengan nama yang sama
        auto-file-renaming = true; # Tambahkan angka (misal: file.1.zip) jika file sudah ada

        user-agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36";

        # --- Opsional: RPC (AriaNg) ---
        # enable-rpc = true;
        # rpc-listen-all = false;
        # rpc-allow-origin-all = true;
        # rpc-secret = "yondaktau";
      };
    };

    programs.yt-dlp = {
      enable = true;
      settings = {
        # --- Format & Output ---
        format = "'bv+ba/b'";
        merge-output-format = "mkv";
        output = "'%(title)s [%(id)s].%(ext)s'";

        cookies-from-browser = "firefox";

        # --- Metadata & Thumbnail ---
        embed-metadata = true; # Pengganti add-metadata
        embed-thumbnail = true;
        embed-chapters = true; # Memasukkan penanda bab/chapter video

        # --- Subtitle ---
        embed-subs = true;
        sub-langs = "en,id,-live_chat"; # Mengunduh sub Inggris & Indonesia, abaikan live chat

        # --- Optimasi & Ekstra ---
        concurrent-fragments = 4; # Mempercepat download (multi-koneksi)
        no-mtime = true; # Memudahkan pencarian file baru di File Manager
        sponsorblock-mark = "all"; # Menandai segmen sponsor sebagai chapter di MKV
        sponsorblock-remove = "sponsor";

        # extractor-args = "youtube:player-client=web";
        # impersonate = "Chrome-142:Macos-26";
      };
    };
  };
}
