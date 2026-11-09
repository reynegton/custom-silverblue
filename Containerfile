# ==============================================================================
# Fedora Silverblue - Imagem OCI Declarativa Personalizada
# Baseada na imagem oficial do Fedora Atomic Desktops
# ==============================================================================
ARG FEDORA_MAJOR_VERSION=45
FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION=45
LABEL org.opencontainers.image.title="custom-silverblue" \
      org.opencontainers.image.description="Fedora Silverblue ${FEDORA_MAJOR_VERSION} declarativo personalizado" \
      org.opencontainers.image.vendor="reynegton"

# 1. Remover navegadores base (utilizando Firefox via Flatpak para manter isolamento)
RUN dnf -y remove firefox firefox-langpacks || true

# 2. Injetar pacotes essenciais do sistema, visual, hardware e wallpapers dinâmicos oficiais
RUN dnf -y install \
    adw-gtk3-theme \
    android-tools \
    distrobox \
    fastfetch \
    ffmpegthumbnailer \
    gh \
    git-lfs \
    gnome-tweaks \
    lm_sensors \
    nethogs \
    rEFInd \
    steam-devices \
    sysstat \
    zsh \
    f36-backgrounds-gnome \
    f37-backgrounds-gnome \
    f38-backgrounds-gnome \
    f39-backgrounds-gnome \
    f40-backgrounds-gnome \
    f41-backgrounds-gnome \
    f42-backgrounds-gnome \
    f43-backgrounds-gnome \
    f44-backgrounds-gnome \
    && dnf clean all

# 3. Garantir grupo adbusers para depuração Android
RUN groupadd -r adbusers || true

# 4. Copiar árvore de arquivos e customizações do sistema (rootfs)
COPY rootfs/ /

# 5. Ajustar permissões dos scripts executáveis
RUN chmod +x /usr/bin/flatpak-provisioning.sh /usr/bin/clean.sh /usr/bin/memory_clean.sh

# 6. Compilar os esquemas GSettings do GNOME e gerar o banco Dconf do sistema
RUN glib-compile-schemas /usr/share/glib-2.0/schemas && dconf update

# 7. Desativar / Mascarar serviços desnecessários para poupar bateria e recursos
RUN systemctl mask \
    fedora-atomic-desktop-appstream-cache-refresh.service \
    ModemManager.service \
    cups.socket cups.path cups.service cups-browsed.service \
    avahi-daemon.socket avahi-daemon.service \
    pcscd.socket pcscd.service \
    auditd.service \
    passim.service

# 8. Habilitar serviços e timers essenciais de manutenção e otimização
RUN systemctl enable \
    thermald.service \
    sysstat.service \
    fstrim.timer \
    rpm-ostreed-automatic.timer \
    flatpak-provisioning.service \
    && systemctl --global enable oo7-daemon.service || true

# 9. Finalizar o commit do OSTree para o bootc / rpm-ostree
RUN ostree container commit
