# 🚀 Custom Fedora Silverblue 44 (Declarative OCI)

Imagem declarativa personalizada do **Fedora Silverblue 44**, construída de forma automatizada via **GitHub Actions (CI/CD)** e hospedada no **GitHub Container Registry (GHCR)**:
👉 `ghcr.io/reynegton/custom-silverblue:latest`

---

## 🏗️ Filosofia e Arquitetura Híbrida

Este ecossistema foi projetado para extrair o potencial máximo da imutabilidade do Fedora Silverblue (*Atomic Desktops*), dividindo as responsabilidades em duas camadas independentes:

1. **Camada de Sistema Declarativa (Repositório Público `custom-silverblue` - Este Repo):**
   Cuida de 100% da imagem base imutável: pacotes nativos (zero layering local), extensões do GNOME, banco de dados Dconf compilado, otimizações de Kernel, ZRAM LZ4, regras de Udev para hardware, controle de congestionamento TCP BBR e mascaramento de serviços desnecessários.
2. **Camada de Usuário & Segurança (Repositório Privado `Arquivos-Pessoais`):**
   Isola em um ambiente privado dados confidenciais (chaves SSH, credenciais, VPNs), configurações da `$HOME` (`~/.config`), dotfiles do terminal (Zsh + Powerlevel10k) e scripts pessoais de usuário.

---

## 📦 O que está embutido nativamente nesta imagem?

### 1. Pacotes do Sistema e Utilitários Nativos
- **Ferramentas de Desenvolvimento & Git:** `gh` (GitHub CLI nativo em `/usr/bin/gh`), `git-lfs`, `zsh`, `distrobox`.
- **Hardware & Multimídia:** `steam-devices` (regras Udev para controles), `ffmpegthumbnailer` (miniaturas de vídeo no Nautilus), `lm_sensors` (temperaturas e sensores), `nethogs` (tráfego de rede por PID), `sysstat` (métricas de CPU/memória), `android-tools` (`adb` e `fastboot`), `rEFInd`.
- **Interface Visual:** `gnome-tweaks`, `adw-gtk3-theme`, `fastfetch`.
- **Limpeza do Sistema:** `firefox` e `firefox-langpacks` do sistema base foram removidos (utilização exclusiva via Flatpak para manter o isolamento).

### 2. Extensões do GNOME Shell Nativas do Sistema
Instaladas diretamente em `/usr/share/gnome-shell/extensions/`, ativas globalmente e independentes de downloads de usuário:
- **Vitals:** Monitor de hardware leve (CPU, frequência, RAM, swap, temperatura).
- **Weather O'Clock:** Clima integrado ao relógio central do painel.
- **AppIndicator and KStatusNotifierItem Support:** Bandeja de ícones para mensageiros e ferramentas de segundo plano.
- **Clipboard Indicator:** Histórico de área de transferência.
- **Just Perfection:** Ajuste fino da interface e velocidade das animações.

### 3. Banco de Dados Dconf do Sistema Compilado (`00-custom-gnome`)
- Animações aceleradas em **0.6x** (*Faster*) sem engasgos.
- Tema escuro preferencial (`prefer-dark`) com estilo Adwaita Dark.
- Renderização e nitidez de fontes com antialiasing subpixel **RGBA** (`rgba`/`rgb`).
- Sensores calibrados no Vitals com taxa de atualização de **5 segundos** (evita micro-travas no laço do GJS).
- Desativação do background autônomo da GNOME Software no boot (economia de ~500 MB de RAM e 100% de CPU no primeiro minuto).
- Otimização do Tracker/Localsearch restrito às pastas de mídia do usuário.

### 4. Flatpaks Declarativos & Overrides Globais
- **Instalação Automática:** Serviço `flatpak-provisioning.service` que no primeiro boot instala e garante a presença dos aplicativos de [`flatpaks.list`](rootfs/usr/share/custom-silverblue/flatpaks.list) (Chrome, Firefox, Steam, VLC, Kate, Thincast Client, GearLever, Obsidian, Vesktop, etc.).
- **Overrides de Permissões (`/etc/flatpak/overrides/`):**
  - *Global:* Integração visual forçando `Breeze Dark` e fontes nativas `Adwaita Sans` para qualquer Flatpak Qt/KDE.
  - *Google Chrome:* Aceleração por hardware VA-API, pipeline Wayland e acesso às pastas do usuário.
  - *Thincast Client:* Cursor Adwaita normalizado (tamanho 24) para sincronização perfeita de ponteiro no RDP.

### 5. Kernel, Memória & Rede
- **ZRAM 1:1 com LZ4:** Compactação em memória física com algoritmo **`lz4`** (~3 GB/s de descompressão, ideal para processadores dual-core).
- **Sysctl Otimizado:** `vm.swappiness = 100`, `vm.page-cluster = 0`, dirty pages calibradas, `vm.vfs_cache_pressure = 50` e `inotify.max_user_watches = 524288`.
- **TCP BBR + FQ:** Controle de congestionamento BBR aliado ao agendador de pacotes Fair Queueing (`fq`) e TCP Fast Open.
- **Mutter Realtime KMS:** Limites PAM em tempo real concedidos para a thread de apresentação gráfica do Mutter (evita micro-quedas de quadros sob carga pesada).

### 6. Hardware & Drivers (Udev & Modprobe)
- **Ejeção da NVIDIA 920M:** Regras de Udev (`00-remove-nvidia.rules`) que cortam a energia e forçam auto-suspend/remove da GPU dedicada + blacklist completa do `nouveau`.
- **Escalonamento Inteligente de I/O (`60-ioschedulers.rules`):** Escalonador **`mq-deadline`** para SSDs SATA/NVMe (baixa latência e menor CPU) e **`bfq`** para HDDs mecânicos rotacionais.
- **RAPL Powercap (`99-powercap.rules`):** Permite leitura não-root do consumo em Watts do processador Intel.
- **Wi-Fi Atheros (`ath9k`):** Coexistência Bluetooth ativada e gerenciamento agressivo de energia corrigido.

### 7. Proteção do SSD e Serviços Mascarados
- **Systemd Journald Blindado:** Gravações agrupadas em memória com persistência a cada 15 minutos, tamanho máximo travado em 200 MB e supressão de floods repetitivos (`RateLimitBurst=3`), preservando o TBW do SSD.
- **Throttling do fwupd:** Daemon de atualização de firmware executando com prioridade ociosa (`Nice=19`, `IOSchedulingClass=idle`).
- **Serviços Mascarados:** `cups`, `cups-browsed`, `avahi-daemon`, `pcscd`, `ModemManager`, `auditd`, `passim`, `fedora-atomic-desktop-appstream-cache-refresh`.
- **Serviços Habilitados:** `thermald`, `sysstat`, `fstrim.timer`, `rpm-ostreed-automatic.timer` e `flatpak-provisioning.service`.
- **Repositórios Dispensáveis Desativados:** `fedora-updates-archive.repo` desativado (elimina sincronização de 42.000 pacotes antigos e destrava o diálogo de desligamento do GNOME).

---

## ⚡ Passo a Passo de Replicação (Pós-Formatação)

Se você acabou de formatar o computador a partir de uma ISO oficial limpa do Fedora Silverblue, não é necessário executar nenhum comando manual de particionamento, kargs ou rebase.

### Método 1: Bootstrap Automatizado em 1 Comando (Recomendado)

Abra o terminal do sistema recém-instalado e execute:

```bash
curl -fsSL https://raw.githubusercontent.com/reynegton/custom-silverblue/main/bootstrap.sh | bash
```

Ao término da execução, reinicie o computador:

```bash
systemctl reboot
```

> **O que o `bootstrap.sh` faz por você automaticamente:**
> 1. Configura a validação criptográfica (Cosign) e executa o rebase assinado (`ostree-image-signed:docker://ghcr.io/reynegton/custom-silverblue:latest`).
> 2. Injeta os parâmetros de Kernel recomendados (`mitigations=off`, `tpm_tis.interrupts=0`, `iommu=pt`, blacklist do `nouveau`, `systemd.tpm2_wait=0`, `audit=0`, `rootflags` Btrfs).
> 3. Habilita a compilação local compacta do Initramfs (`--hostonly`, ~35 MB).
> 4. Ajusta o GRUB com menu visível por 10 segundos para segurança máxima de rollback.
> 5. Corrige a montagem ComposeFS (`/sysroot`) e injeta a flag `noatime` em `/home` e `/var` no `/etc/fstab`.
> 6. Cria o swapfile Btrfs de contingência de 4GB em `/var/swapfile` (prioridade 10).
> 7. Adiciona seu usuário ao grupo `adbusers` e altera seu shell padrão para `/usr/bin/zsh`.

---

### Método 2: Rebase Manual com Verificação Assinada

Caso queira configurar a verificação e fazer o rebase manualmente:

```bash
# 1. Configurar política de assinatura e chave pública
sudo mkdir -p /etc/pki/containers /etc/containers/registries.d
sudo curl -fsSL https://raw.githubusercontent.com/reynegton/custom-silverblue/main/rootfs/etc/pki/containers/custom-silverblue.pub -o /etc/pki/containers/custom-silverblue.pub
sudo curl -fsSL https://raw.githubusercontent.com/reynegton/custom-silverblue/main/rootfs/etc/containers/registries.d/custom-silverblue.yaml -o /etc/containers/registries.d/custom-silverblue.yaml
sudo curl -fsSL https://raw.githubusercontent.com/reynegton/custom-silverblue/main/rootfs/etc/containers/policy.json -o /etc/containers/policy.json

# 2. Executar o rebase assinado (sem flag unverified)
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/reynegton/custom-silverblue:latest
systemctl reboot
```

---

## 🔄 Próximo Passo: Configurar a Home do Usuário

Após reiniciar o computador na imagem declarativa:
> **💡 Nota:** No primeiro boot, o serviço nativo `flatpak-provisioning.service` é acionado automaticamente em segundo plano para instalar todos os seus Flatpaks declarados em `flatpaks.list` (Thincast, Chrome, Steam, Obsidian, etc.).

1. Autentique o GitHub:
   ```bash
   gh auth login
   ```
2. Clone seu repositório privado de usuário:
   ```bash
   gh repo clone reynegton/Arquivos-Pessoais ~/Documentos/GitHub/Arquivos-Pessoais
   ```
3. Execute o orquestrador da Home:
   ```bash
   cd ~/Documentos/GitHub/Arquivos-Pessoais/linux && ./setup.sh
   source ~/.bashrc
   ```

---

## 🧰 Manutenção do Dia a Dia

- **Atualizar o Sistema:**
  ```bash
  rpm-ostree upgrade
  ```
  *(Ou silenciosamente via `AutomaticUpdatePolicy=stage`, que prepara as atualizações em segundo plano).*
- **Inspecionar novidades antes de reiniciar:**
  ```bash
  rpm-ostree db diff
  ```
- **Rollback instantâneo:**
  ```bash
  rpm-ostree rollback
  ```
- **Fixar versão atual eternamente (Pinning):**
  ```bash
  sudo ostree admin pin 0
  ```
- **Voltar para a imagem oficial pura do Fedora Silverblue:**
  ```bash
  rpm-ostree rebase fedora:fedora/44/x86_64/silverblue
  ```
