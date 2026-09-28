# ==============================================================================
# Configuração de PATH e Ambiente Pessoal (Híbrido)
# ==============================================================================
if [ -d "/var/home/reynegton/Documentos/GitHub/Arquivos-Pessoais/linux" ]; then
    export LINUX_ROOT="/var/home/reynegton/Documentos/GitHub/Arquivos-Pessoais/linux"
    export PATH="$PATH:$LINUX_ROOT"
    export PATH="$PATH:$LINUX_ROOT/scripts/system"
    export PATH="$PATH:$LINUX_ROOT/scripts/network"
    export PATH="$PATH:$LINUX_ROOT/scripts/startup"
    if [ -d "$LINUX_ROOT/scripts/distro/fedora" ]; then
        export PATH="$PATH:$LINUX_ROOT/scripts/distro/fedora"
    fi
fi

[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.npm-global/bin" ] && export PATH="$HOME/.npm-global/bin:$PATH"
[ -d "$HOME/Android/Sdk/platform-tools" ] && export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
export EDITOR=nano
