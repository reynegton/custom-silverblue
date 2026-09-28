#!/bin/bash
set -euo pipefail

LIST_FILE="/usr/share/custom-silverblue/flatpaks.list"
[ ! -f "$LIST_FILE" ] && exit 0

# Garante que o Flathub está configurado no sistema
flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# Itera sobre os aplicativos declarados e instala apenas os que estiverem ausentes
grep -vE '^\s*#|^\s*$' "$LIST_FILE" | while read -r app; do
    if ! flatpak info "$app" &>/dev/null; then
        echo "[Flatpak Provisioning] Instalando $app..."
        flatpak install --system -y --noninteractive flathub "$app" 2>/dev/null || true
    fi
done
