{ config, pkgs, lib, ... }:

let
  # Versão v0.6.0 do nix-flatpak (Fixada para estabilidade)
  nix-flatpak = builtins.fetchTarball "https://github.com/gmodena/nix-flatpak/archive/v0.6.0.tar.gz";
in
{
  imports = [
    ./hardware-configuration.nix
    "${nix-flatpak}/modules/nixos.nix"
  ];

  # ===========================================================
  # 1. SISTEMA, BOOT E LOCALIZAÇÃO
  # ===========================================================
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Bahia";
  i18n.defaultLocale = "pt_BR.UTF-8";
  console.keyMap = "br-abnt2";


  system.stateVersion = "25.11";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Descriptografia LUKS
  boot.initrd.luks.devices."luks-6de8cb75-c105-4641-b40d-6184f68e251e".device = "/dev/disk/by-uuid/6de8cb75-c105-4641-b40d-6184f68e251e";

  # Otimizações de Kernel e Jogos
  boot.kernel.sysctl = { "kernel.split_lock_mitigate" = 0; };
  boot.kernelModules = [ "xpad" ]; # Driver Xbox/GameSir

  # ===========================================================
  # 2. ARMAZENAMENTO SECUNDÁRIO
  # ===========================================================
  fileSystems."/mnt/backup-hd" = {
    device = "/dev/disk/by-uuid/B489-CA7F";
    fsType = "exfat";
    options = [ "nofail" "x-systemd.automount" "uid=1000" "gid=100" "umask=0022" ];
  };

  # ===========================================================
  # 3. GRÁFICOS (NVIDIA) E AMBIENTE
  # ===========================================================
  nixpkgs.config.allowUnfree = true;

  # Habilita suporte gráfico moderno (necessário para Steam/Jogos)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Configuração Nvidia
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true; # Utilizar 'false' se a placa for antiga (pré-RTX 2000 series)
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Variáveis de Sessão (Wayland + Nvidia)
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # Desktop (KDE Plasma 6) e Display Manager
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.enable = true;
  services.xserver.xkb = { layout = "br"; variant = ""; };

  # Integração KDE Wallet
  security.pam.services."login".kwallet.enable = true;

  # ===========================================================
  # 4. ÁUDIO, REDE E DISPOSITIVOS
  # ===========================================================
  # Áudio (Pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Firewall

  # Desabilitado para garantir compatibilidade total com jogos online e não ser necessário configuração manual.
  networking.firewall.enable = false;

  # Impressão
  services.printing.enable = true;

  # Suporte a Hardware de Jogos (Udev rules)
  hardware.steam-hardware.enable = true;
  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  # Banco de Dados
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  # ===========================================================
  # 5. GERENCIAMENTO DE PACOTES (FLATPAK)
  # ===========================================================
  services.flatpak = {
    enable = true;
    remotes = lib.mkOptionDefault [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];
    packages = [
      "com.atlauncher.ATLauncher"
      "com.github.Matoking.protontricks"
      "com.valvesoftware.Steam"
      "dev.vencord.Vesktop"
      "io.github.peazip.PeaZip"
      "it.mijorus.gearlever"
      "net.davidotek.pupgui2"
      "org.blender.Blender"
    ];
  };

  # ===========================================================
  # 6. BACKUP (RESTIC)
  # ===========================================================
  services.restic.backups.backup-sistema = {
    initialize = true;
    user = "root";
    repository = "/mnt/backup-hd/nixos";
    passwordFile = "/etc/nixos/restic-password";
    paths = [ "/home/luiz" "/etc/nixos" "/var/backup-mysql" ];
    exclude = [
      "/home/luiz/Downloads"
      "/home/luiz/.cache"
      "/home/luiz/.local/share/Trash"
      "/home/luiz/**/node_modules"
      "/home/luiz/**/target"
      ".git"
    ];
    backupPrepareCommand = ''
      mkdir -p /var/backup-mysql
      ${pkgs.mariadb}/bin/mysqldump --all-databases --single-transaction --quick --lock-tables=false > /var/backup-mysql/dump_completo.sql
    '';
    pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 12" ];
    timerConfig = { OnCalendar = "19:00"; Persistent = true; };
  };

  # ===========================================================
  # 7. USUÁRIOS E PACOTES DO SISTEMA
  # ===========================================================
  users.users.luiz = {
    isNormalUser = true;
    description = "Luiz";
    extraGroups = [ "networkmanager" "wheel" "input" ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    # Utilitários do Sistema
    flatpak
    appimage-run
    nano
    wget
    git
    restic
    exfatprogs

    # Navegadores e Dev Básico
    vscode
    brave
    nodejs_24
    javaPackages.compiler.openjdk21
    jetbrains.clion

    # Ferramentas C++ (Disponíveis globalmente, utilizando o shell.nix para compilar)
    cmake
    ninja
    gdb
    llvmPackages_latest.clang
    llvmPackages_latest.bintools

    # Mídia
    obs-studio
    mpv
  ];
}
