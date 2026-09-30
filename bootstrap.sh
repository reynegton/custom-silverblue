#!/bin/bash
set -euo pipefail

# ==============================================================================
# Script: bootstrap.sh
# Repositório: https://github.com/reynegton/custom-silverblue
# Descrição: Provisionador mestre de primeiro boot / pós-formatação para
#            Fedora Silverblue. Configura rebase OCI, kargs, initramfs,
#            Btrfs, swapfile, GRUB e permissões de hardware em um único comando.
# ==============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}    BOOTSTRAP MESTRE: FEDORA SILVERBLUE DECLARATIVO OCI         ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# 0. Verificação de Ambiente
if [ ! -f /run/ostree-booted ]; then
    echo -e "${RED}[ERRO] Este script foi projetado para sistemas OSTree (Fedora Silverblue / Atomic). Abortando.${NC}"
    exit 1
fi

echo -e "${CYAN}Solicitando privilégios administrativos (sudo)...${NC}"
sudo -v

# ------------------------------------------------------------------------------
# 1. Rebase para a Imagem OCI Declarativa (GHCR)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[1/7] Configurando política de assinatura Cosign e imagem OCI declarativa...${NC}"

# Garantir diretórios de políticas e chave pública no host
sudo mkdir -p /etc/pki/containers /etc/containers/registries.d

# Baixar chave pública e registrar política de verificação criptográfica
sudo curl -fsSL https://raw.githubusercontent.com/reynegton/custom-silverblue/main/rootfs/etc/pki/containers/custom-silverblue.pub -o /etc/pki/containers/custom-silverblue.pub
sudo curl -fsSL https://raw.githubusercontent.com/reynegton/custom-silverblue/main/rootfs/etc/containers/registries.d/custom-silverblue.yaml -o /etc/containers/registries.d/custom-silverblue.yaml
sudo curl -fsSL https://raw.githubusercontent.com/reynegton/custom-silverblue/main/rootfs/etc/containers/policy.json -o /etc/containers/policy.json

IMAGE_TARGET="ostree-image-signed:docker://ghcr.io/reynegton/custom-silverblue:latest"

if rpm-ostree status | grep -q "ostree-image-signed:docker://ghcr.io/reynegton/custom-silverblue:latest"; then
    echo -e "${GREEN}✓ O sistema já está configurado ou rebased para custom-silverblue assinada.${NC}"
else
    echo -e "${CYAN}Executando rebase verificado para: $IMAGE_TARGET...${NC}"
    rpm-ostree rebase "$IMAGE_TARGET"
    echo -e "${GREEN}✓ Rebase verificado agendado com sucesso.${NC}"
fi

# ------------------------------------------------------------------------------
# 2. Injeção de Parâmetros de Kernel (Kargs)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[2/7] Otimizando parâmetros do Kernel (Kargs)...${NC}"
CURRENT_KARGS=$(rpm-ostree kargs)

KARGS_TO_ADD=()
for arg in \
    "mitigations=off" \
    "tpm_tis.interrupts=0" \
    "iommu=pt" \
    "rd.driver.blacklist=nouveau" \
    "modprobe.blacklist=nouveau" \
    "nouveau.modeset=0" \
    "systemd.tpm2_wait=0" \
    "audit=0" \
    "rootflags=compress=zstd:3,noatime,discard=async,commit=60"; do
    if ! echo "$CURRENT_KARGS" | grep -q "$arg"; then
        KARGS_TO_ADD+=("--append=$arg")
    fi
done

if [ ${#KARGS_TO_ADD[@]} -gt 0 ]; then
    echo -e "${CYAN}Aplicando novos kargs:${NC} ${KARGS_TO_ADD[*]}"
    rpm-ostree kargs "${KARGS_TO_ADD[@]}"
    echo -e "${GREEN}✓ Parâmetros de boot atualizados.${NC}"
else
    echo -e "${GREEN}✓ Todos os parâmetros de boot recomendados já estão presentes.${NC}"
fi

# ------------------------------------------------------------------------------
# 3. Compilação Hostonly do Initramfs (Aceleração de Boot)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[3/7] Otimizando Initramfs para o hardware local (Hostonly)...${NC}"
if rpm-ostree status | grep -q "\-\-hostonly"; then
    echo -e "${GREEN}✓ Initramfs hostonly já está ativo.${NC}"
else
    echo -e "${CYAN}Ativando compilação hostonly (reduz de ~235MB para ~35MB)...${NC}"
    sudo rpm-ostree initramfs --enable --arg="--hostonly"
    echo -e "${GREEN}✓ Initramfs configurado para compilação local compacta.${NC}"
fi

# ------------------------------------------------------------------------------
# 4. Configuração do GRUB (Rollback Seguro com 10s)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[4/7] Configurando tempo de espera do GRUB...${NC}"
sudo grub2-editenv - set timeout=10 2>/dev/null || true
sudo grub2-editenv - set menu_auto_hide=0 2>/dev/null || true
if [ ! -f /boot/grub2/custom.cfg ] || ! grep -q "timeout=10" /boot/grub2/custom.cfg 2>/dev/null; then
    echo "set timeout=10" | sudo tee /boot/grub2/custom.cfg > /dev/null
fi
echo -e "${GREEN}✓ GRUB configurado com menu visível por 10 segundos.${NC}"

# ------------------------------------------------------------------------------
# 5. Otimização do FSTAB (ComposeFS + noatime)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[5/7] Otimizando pontos de montagem Btrfs no /etc/fstab...${NC}"
# ComposeFS fix
if grep -q " / btrfs subvol=root" /etc/fstab; then
    sudo sed -i 's| / btrfs subvol=root| /sysroot btrfs subvol=root|' /etc/fstab
    echo -e "${GREEN}✓ Corrigida montagem ComposeFS (raiz -> /sysroot).${NC}"
fi

# noatime em /home e /var
if grep -q "subvol=home,compress=zstd:1" /etc/fstab && ! grep -q "subvol=home,compress=zstd:1,noatime" /etc/fstab; then
    sudo sed -i 's|subvol=home,compress=zstd:1|subvol=home,compress=zstd:1,noatime|' /etc/fstab
    echo -e "${GREEN}✓ Flag noatime adicionada em /home.${NC}"
fi

if grep -q "subvol=var,compress=zstd:1" /etc/fstab && ! grep -q "subvol=var,compress=zstd:1,noatime" /etc/fstab; then
    sudo sed -i 's|subvol=var,compress=zstd:1|subvol=var,compress=zstd:1,noatime|' /etc/fstab
    echo -e "${GREEN}✓ Flag noatime adicionada em /var.${NC}"
fi

# Remontar com noatime
sudo mount -o remount,noatime /home 2>/dev/null || true
sudo mount -o remount,noatime /var 2>/dev/null || true

# ------------------------------------------------------------------------------
# 6. Swapfile Btrfs de Contingência (/var/swapfile)
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[6/7] Verificando Swapfile de segurança em /var...${NC}"
if [ ! -f /var/swapfile ]; then
    echo -e "${CYAN}Criando swapfile de 4GB em /var/swapfile...${NC}"
    sudo btrfs filesystem mkswapfile --size 4G --uuid clear /var/swapfile
    sudo swapon /var/swapfile 2>/dev/null || true
fi

if ! grep -q "/var/swapfile" /etc/fstab; then
    echo "/var/swapfile    none    swap    defaults,pri=10    0 0" | sudo tee -a /etc/fstab > /dev/null
    echo -e "${GREEN}✓ /var/swapfile adicionado ao /etc/fstab (prioridade 10).${NC}"
else
    echo -e "${GREEN}✓ /var/swapfile já configurado no /etc/fstab.${NC}"
fi

# ------------------------------------------------------------------------------
# 7. Shell Padrão do Usuário e Grupos de Hardware
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[7/7] Configurando shell do usuário e grupos de hardware...${NC}"
# Grupo adbusers
sudo groupadd -r adbusers 2>/dev/null || true
sudo usermod -aG adbusers "$USER" 2>/dev/null || true
echo -e "${GREEN}✓ Usuário $USER adicionado ao grupo adbusers.${NC}"

# Shell Zsh padrão
if [ -x /usr/bin/zsh ]; then
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        sudo chsh -s /usr/bin/zsh "$USER" 2>/dev/null || true
        echo -e "${GREEN}✓ Shell padrão alterado para Zsh (/usr/bin/zsh).${NC}"
    else
        echo -e "${GREEN}✓ Shell padrão já é Zsh.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}          BOOTSTRAP DO SISTEMA CONCLUÍDO COM SUCESSO!           ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e "A sua máquina está 100% preparada."
echo ""
echo -e "${YELLOW}Próximo passo obrigatório:${NC}"
echo -e "1. Reinicie agora o computador com o comando: ${CYAN}systemctl reboot${NC}"
echo -e "2. Após o boot, clone seu repositório privado de usuário:"
echo -e "   ${CYAN}gh repo clone reynegton/Arquivos-Pessoais ~/Documentos/GitHub/Arquivos-Pessoais${NC}"
echo -e "3. Rode o configurador da Home:"
echo -e "   ${CYAN}cd ~/Documentos/GitHub/Arquivos-Pessoais/linux && ./setup.sh${NC}"
echo ""
