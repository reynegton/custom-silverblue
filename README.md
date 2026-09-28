# Custom Fedora Silverblue 44 (Declarative OCI)

Imagem declarativa personalizada do **Fedora Silverblue 44**, construída automaticamente via **GitHub Actions** e publicada no **GitHub Container Registry (GHCR)**.

## 📦 O que está incluído nesta imagem?

* **Base:** Imagem oficial do Fedora Atomic Desktops (`quay.io/fedora-ostree-desktops/silverblue:44`).
* **Pacotes do Sistema e Hardware:**
  * `steam-devices` (Regras de udev para compatibilidade total de controles de jogos na Steam Flatpak).
  * `ffmpegthumbnailer` (Miniaturas de vídeo integradas ao Nautilus/GNOME Files).
  * `gnome-tweaks` (Ajustes finos da interface GNOME).
  * `adw-gtk3-theme` (Tema escuro Libadwaita para aplicações GTK3 legadas).
  * `zsh` (Shell padrão do usuário).
  * `lm_sensors` (Leitura de sensores e temperaturas de hardware para a extensão Vitals).
  * `distrobox` (Gestão de contêineres e integração com BoxBuddy).
  * `sysstat` (Métricas de sistema com daemon habilitado).
  * `nethogs` (Monitoramento de tráfego de rede por processo).
  * `rEFInd` (Ferramentas de manutenção do boot manager UEFI).
  * `android-tools` (`adb` e `fastboot` para depuração USB).
  * `fastfetch` (Informações do sistema no terminal).
* **Remoções da Imagem Base:**
  * `firefox` e `firefox-langpacks` (Uso exclusivo do Firefox via Flatpak para manter o isolamento).
* **Serviços Ativos por Padrão:**
  * `sysstat.service`

---

## 🚀 Como migrar seu sistema (Rebase)

Assim que o primeiro build no GitHub Actions for concluído com sucesso e o pacote estiver disponível no GHCR, execute no terminal do seu Silverblue:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/reynegton/custom-silverblue:latest
```

Após o download da imagem e preparação do estágio, reinicie o computador:

```bash
systemctl reboot
```

---

## 🔄 Como atualizar no dia a dia

Com o sistema migrado para a imagem OCI, as atualizações funcionam da mesma forma que antes, puxando a imagem mais recente compilada pelo GitHub Actions:

```bash
rpm-ostree upgrade
```

*(Ou automaticamente caso você utilize o `rpm-ostreed-automatic.timer` configurado para `stage`).*

---

## 🛡️ Rollback de Segurança

Se qualquer atualização na imagem apresentar problemas, você pode retornar à versão anterior instantaneamente:

```bash
rpm-ostree rollback
```

Ou voltar para a imagem base oficial do Fedora a qualquer momento:

```bash
rpm-ostree rebase fedora:fedora/44/x86_64/silverblue
```
