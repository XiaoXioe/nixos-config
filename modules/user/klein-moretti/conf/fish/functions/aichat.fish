function aichat
    # 1. Mengekstrak 'isi' dari file SOPS ke dalam variabel lingkungan sementara
    set -lx GEMINI_API_KEY (cat /run/secrets/gemini-api-key)

    # 2. Menjalankan aichat yang asli beserta semua argumennya
    command aichat $argv
end
