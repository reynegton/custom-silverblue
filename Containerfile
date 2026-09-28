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

# 3. Garantir grupo adbusers para depuração Android
RUN groupadd -r adbusers || true

# 4. Copiar árvore de arquivos e customizações do sistema (rootfs)
COPY rootfs/ /

# 5. Ajustar permissões dos scripts executáveis
RUN chmod +x /usr/bin/flatpak-provisioning.sh /usr/local/bin/*.sh

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
    flatpak-provisioning.service

# 9. Finalizar o commit do OSTree para o bootc / rpm-ostree
RUN ostree container commit
