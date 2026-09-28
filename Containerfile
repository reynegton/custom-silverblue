# ==============================================================================
# Fedora Silverblue 44 - Imagem OCI Declarativa Personalizada
# Baseada na imagem oficial do Fedora Atomic Desktops
# ==============================================================================
FROM quay.io/fedora-ostree-desktops/silverblue:44

LABEL org.opencontainers.image.title="custom-silverblue" \
      org.opencontainers.image.description="Fedora Silverblue 44 declarativo personalizado" \
      org.opencontainers.image.vendor="reynegton"

# 1. Remover navegadores base (utilizando Firefox via Flatpak para manter isolamento)
RUN dnf -y remove firefox firefox-langpacks || true

# 2. Injetar pacotes essenciais do sistema, visual e hardware
RUN dnf -y install \
    adw-gtk3-theme \
    android-tools \
    distrobox \
    fastfetch \
    ffmpegthumbnailer \
    gnome-tweaks \
    lm_sensors \
    nethogs \
    rEFInd \
    steam-devices \
    sysstat \
    zsh \
    && dnf clean all

# 3. Habilitar serviços de sistema essenciais
RUN systemctl enable sysstat

# 4. Finalizar o commit do OSTree para o bootc / rpm-ostree
RUN ostree container commit
