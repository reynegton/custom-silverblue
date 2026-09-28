#!/bin/bash

# ==============================================================================
# Script: clean.sh (antigo fullclean.sh)
# Descrição: Limpeza completa do sistema com suporte a múltiplos gerenciadores
# ==============================================================================

# Cores para feedback visual
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis globais
DRY_RUN=false
START_TIME=$(date +%s)

# --- Funções Auxiliares ---

print_header() { echo -e "${CYAN}=== $1 ===${NC}"; }
print_success() { echo -e "${GREEN}[OK] $1${NC}"; }
print_error() { echo -e "${RED}[ERRO] $1${NC}"; }
print_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
print_warn() { echo -e "${YELLOW}[AVISO] $1${NC}"; }

show_help() {
    echo "Uso: fullclean.sh [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -h, --help     Exibe esta mensagem de ajuda"
    echo "  -d, --dry-run  Simula a execução sem alterar nada no sistema"
    echo ""
}

run_cmd() {
    local msg="$1"
    local cmd="$2"
    print_info "$msg"
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[Simulação] Executaria: $cmd${NC}"
    else
        eval "$cmd"
    fi
}

# --- Funções de Limpeza ---

limpar_ostree() {
    print_header "Gerenciador: rpm-ostree"
    run_cmd "Limpando metadados e deployments pendentes..." "rpm-ostree cleanup -m -p -b"
}

limpar_dnf() {
    print_header "Gerenciador: DNF"
    run_cmd "Removendo pacotes órfãos..." "sudo dnf autoremove -y"
    run_cmd "Limpando cache de pacotes..." "sudo dnf clean all"
}

limpar_apt() {
    print_header "Gerenciador: APT"
    run_cmd "Removendo pacotes não utilizados..." "sudo apt autoremove -y"
    
    # Limpar arquivos residuais (apenas se existirem)
    local residuais=$(dpkg -l | grep "^rc" | awk '{print $2}')
    if [ -n "$residuais" ]; then
        run_cmd "Limpando arquivos residuais (configurações)..." "sudo apt-get remove --purge $residuais"
    else
        print_info "Nenhum arquivo residual para limpar."
    fi

    run_cmd "Limpando cache local de pacotes baixados..." "sudo apt autoclean"
    run_cmd "Limpando diretório /var/cache/apt/archives/..." "sudo apt clean"
    run_cmd "Corrigindo dependências quebradas..." "sudo apt install -f -y"
}

limpar_snap() {
    if command -v snap &>/dev/null; then
        print_header "Gerenciador: Snap"
        print_info "Verificando revisões antigas (disabled) de snaps..."
        
        local old_snaps=$(snap list --all | awk '/disabled/{print $1, $3}')
        local count=$(echo "$old_snaps" | grep -v "^$" | wc -l)
        
        if [ "$count" -gt 0 ]; then
            print_info "Removendo $count revisão(ões) antiga(s)..."
            if [ "$DRY_RUN" = true ]; then
                 echo -e "${YELLOW}[Simulação] Removeria $count revisões do Snap.${NC}"
            else
                echo "$old_snaps" | while read snapname revision; do
                    sudo snap remove "$snapname" --revision="$revision"
                done
            fi
        else
            print_info "Nenhuma revisão antiga para remover."
        fi
    fi
}

limpar_flatpak() {
    if command -v flatpak &>/dev/null; then
        print_header "Gerenciador: Flatpak"
        # Verifica se há algo não utilizado antes de tentar remover
        local unused=$(flatpak remove --unused --dry-run 2>/dev/null)
        if [[ "$unused" == *"Nothing to do"* ]]; then
            print_info "Nenhum runtime flatpak não utilizado encontrado."
        else
            run_cmd "Removendo runtimes flatpak não utilizadas..." "flatpak remove --unused -y"
        fi
    fi
}

limpar_brew() {
    if command -v brew &>/dev/null; then
        print_header "Gerenciador: Homebrew"
        run_cmd "Removendo fórmulas não utilizadas..." "brew autoremove"
    fi
}

limpar_system_logs() {
    print_header "Sistema: Logs do Journald"
    if [ "$DRY_RUN" = false ]; then
        local disk_usage=$(journalctl --disk-usage 2>/dev/null | cut -d ' ' -f 7-)
        print_info "Espaço atual em disco ocupado pelos logs: $disk_usage"
    fi
    run_cmd "Limpando logs do sistema com mais de 7 dias..." "sudo journalctl --vacuum-time=7d"
    run_cmd "Limitando logs do sistema a 500MB..." "sudo journalctl --vacuum-size=500M"
}

limpar_thumbnails() {
    print_header "Usuário: Cache de Miniaturas"
    local thumb_dir="$HOME/.cache/thumbnails"
    if [ -d "$thumb_dir" ] && [ "$(ls -A "$thumb_dir" 2>/dev/null)" ]; then
        local size=$(du -sh "$thumb_dir" | cut -f1)
        run_cmd "Removendo $size de cache de miniaturas (thumbnails)..." "rm -rf $thumb_dir/*"
    else
        print_info "Cache de miniaturas já está limpo."
    fi
}

limpar_npm_cache() {
    if command -v npm &>/dev/null; then
        print_header "Ecossistema: Cache do NPM"
        
        # Caminho padrão do cache do npm
        local cache_dir=$(npm config get cache 2>/dev/null || echo "$HOME/.npm")
        
        if [ -d "$cache_dir" ] && [ "$(ls -A "$cache_dir" 2>/dev/null)" ]; then
            local cache_size=$(du -sh "$cache_dir" | cut -f1)
            run_cmd "Limpando cache do NPM ($cache_size)..." "npm cache clean --force"
        else
            print_info "Cache do NPM já está vazio. Pulando."
        fi
    fi
}

# --- Processamento de Argumentos ---

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help; exit 0 ;;
        -d|--dry-run) DRY_RUN=true; shift ;;
        *) print_error "Opção desconhecida: $1"; show_help; exit 1 ;;
    esac
done

# --- Orquestrador Principal ---

main() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}    INICIANDO LIMPEZA DO SISTEMA          ${NC}"
    echo -e "${BLUE}==========================================${NC}"

    if [ "$DRY_RUN" = true ]; then
        print_warn "MODO SIMULAÇÃO ATIVADO - Nenhuma alteração será feita."
    fi

    # Solicita sudo antecipadamente
    if [ "$DRY_RUN" = false ]; then
        print_info "Solicitando acesso root..."
        sudo -v
    fi

    # Detectar Gerenciador de Pacotes do Sistema
    if [ -f /run/ostree-booted ]; then
        limpar_ostree
    elif [ -f /etc/redhat-release ]; then
        limpar_dnf
    elif [ -f /etc/debian_version ]; then
        limpar_apt
    fi

    # Limpezas Universais
    limpar_snap
    limpar_flatpak
    limpar_brew

    # Limpezas de Sistema e Usuário
    limpar_system_logs
    limpar_thumbnails
    limpar_npm_cache

    # Cálculo de tempo
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo -e "${BLUE}==========================================${NC}"
    print_success "Limpeza concluída em ${DURATION} segundos."
    echo -e "${BLUE}==========================================${NC}"
}

main
