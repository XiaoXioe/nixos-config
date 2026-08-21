{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.terminal.utilities.functions.custom-functions";
  description = "Migrated custom bash scripts (cek_ip, wayres, softsub, mpv-wrapper)";

  hmConfig = hmOpts: {
    home.packages = [
      (selfLib.mkApp pkgs "wayres"
        ''
          if [ $# -eq 0 ]; then
              echo "❌ Gunakan: wayres [portrait|p], atau [auto|reset]"
              exit 1
          fi

          case "$1" in
              p|portrait)
                  echo "📱 Mengubah ke Mode PORTRAIT..."
                  waydroid prop set persist.waydroid.width 540
                  waydroid prop set persist.waydroid.height 1010
                  waydroid prop set persist.waydroid.density 240
                  ;;
              a|auto|reset)
                  echo "🔄 Mengembalikan ke Mode DEFAULT (Auto-Detect)..."
                  waydroid prop set persist.waydroid.width ""
                  waydroid prop set persist.waydroid.height ""
                  waydroid prop set persist.waydroid.density ""
                  ;;
              *)
                  echo "❌ Opsi tidak dikenal. Gunakan 'p', 'l', atau 'a' (auto)."
                  exit 1
                  ;;
          esac

          echo "🔄 Merestart sesi Waydroid..."
          waydroid session stop
          echo "✅ Selesai! Silakan jalankan Waydroid kembali."
        ''
        [
          pkgs.waydroid
          pkgs.coreutils
        ]
      )

      (selfLib.mkApp pkgs "softsub"
        ''
          if [ $# -lt 2 ]; then
              echo "❌ Error: Argumen kurang."
              echo "💡 Cara pakai: softsub <video_sumber> <subtitle.srt> [video_hasil]"
              exit 1
          fi

          video="$1"
          srt="$2"
          output="''${3:-output_softsub.mkv}"

          echo "🎬 Memulai proses softsub ke $output..."

          if [[ "$output" =~ \.[Mm][Pp]4$ ]]; then
              ffmpeg -hide_banner -loglevel error -stats -i "$video" -i "$srt" -c:v copy -c:a copy -c:s mov_text "$output"
          else
              ffmpeg -hide_banner -loglevel error -stats -i "$video" -i "$srt" -c copy "$output"
          fi

          ffmpeg_status=$?
          echo ""

          if [ $ffmpeg_status -eq 0 ]; then
              echo "✅ Selesai! File disimpan sebagai: $output"
          else
              echo "❌ Gagal memproses video. Pastikan file tidak rusak atau coba output ke .mkv."
              rm -f "$output"
              exit 1
          fi
        ''
        [
          pkgs.ffmpeg
          pkgs.coreutils
        ]
      )

      (selfLib.mkApp pkgs "mpv-wrapper"
        ''
          custom_res=0
          mpv_args=()
          skip_next=0
          args=("$@")
          for ((i=0; i<''${#args[@]}; i++)); do
              if [ $skip_next -eq 1 ]; then
                  skip_next=0
                  continue
              fi
              if [ "''${args[i]}" = "-r" ]; then
                  next_idx=$((i + 1))
                  if [ $next_idx -lt ''${#args[@]} ]; then
                      custom_res="''${args[next_idx]}"
                      skip_next=1
                  else
                      echo "Error: -r butuh nilai (contoh: 1080, 480, best)"
                      exit 1
                  fi
              else
                  mpv_args+=("''${args[i]}")
              fi
          done

          if [ "$custom_res" != "0" ]; then
              echo "Override Resolusi ke: $custom_res [Prioritas Codec: AVC/H.264]"
              if [ "$custom_res" = "best" ]; then
                  exec mpv --ytdl-format="bestvideo[vcodec^=avc]+(bestaudio[language=id]/bestaudio[language=ind]/bestaudio)/bestvideo+bestaudio/best" "''${mpv_args[@]}"
              else
                  exec mpv --ytdl-format="bestvideo[height<=$custom_res][vcodec^=avc]+(bestaudio[language=id]/bestaudio[language=ind]/bestaudio)/bestvideo[height<=$custom_res]+bestaudio/best" "''${mpv_args[@]}"
              fi
          else
              exec mpv "''${mpv_args[@]}"
          fi
        ''
        [
          hmOpts.config.programs.mpv.finalPackage
          pkgs.coreutils
        ]
      )
    ];
  };
}
