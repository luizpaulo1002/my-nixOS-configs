{ config, pkgs, lib, ... }:

let
  # Versão v0.6.0 do nix-flatpak
  nix-flatpak = builtins.fetchTarball "https://github.com/gmodena/nix-flatpak/archive/v0.6.0.tar.gz";
in
{
  # -----------------------------------------------------------
  # 1. SISTEMA BASE E IMPORTS
  # -----------------------------------------------------------
  imports = [
    ./hardware-configuration.nix
    "${nix-flatpak}/modules/nixos.nix"
  ];

  # -----------------------------------------------------------
  # CONFIGURAÇÕES DE SISTEMA
  # -----------------------------------------------------------
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Bahia";
  i18n.defaultLocale = "pt_BR.UTF-8";

  system.stateVersion = "25.11";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS (disco criptografado)
  boot.initrd.luks.devices."luks-6de8cb75-c105-4641-b40d-6184f68e251e".device = "/dev/disk/by-uuid/6de8cb75-c105-4641-b40d-6184f68e251e";

  # Melhora de desempenho nos jogos
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
  };

  # --- CORREÇÃO CONTROLE GAMESIR ---
  # Carrega o driver xpad (Xbox)
  boot.kernelModules = [ "xpad" ];

  # -----------------------------------------------------------
  # MONTAGEM DO HD (exFAT)
  # -----------------------------------------------------------
  fileSystems."/mnt/backup-hd" = {
    device = "/dev/disk/by-uuid/B489-CA7F";
    fsType = "exfat";
    options = [ "nofail" "x-systemd.automount" "uid=1000" "gid=100" "umask=0022" ];
  };

  # -----------------------------------------------------------
  # 2. DRIVERS E GRÁFICOS NVIDIA
  # -----------------------------------------------------------
  hardware.nvidia.open = true;
  nixpkgs.config.allowUnfree = true;

  boot.extraModulePackages = [ config.boot.kernelPackages.nvidiaPackages.stable ];

  boot.initrd.kernelModules = [ "nvidia_modeset" ];

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # --- C++23 DEV ENVIRONMENT ---
    CC = "${pkgs.llvmPackages_latest.clang}/bin/clang";
    CXX = "${pkgs.llvmPackages_latest.clang}/bin/clang++";
    CPLUS_INCLUDE_PATH = "${pkgs.gcc-unwrapped}/include/c++/${pkgs.gcc.version}:${pkgs.gcc-unwrapped}/include/c++/${pkgs.gcc.version}/x86_64-unknown-linux-gnu";
  };

  # -----------------------------------------------------------
  # 3. AMBIENTE DE DESKTOP E INPUTS
  # -----------------------------------------------------------
  security.pam.services."login".kwallet.enable = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = { layout = "br"; variant = ""; };
  console.keyMap = "br-abnt2";

  # --- CORREÇÃO CONTROLE GAMESIR (UDEV) ---
  hardware.steam-hardware.enable = true;
  services.udev.packages = [ pkgs.game-devices-udev-rules ];

  # -----------------------------------------------------------
  # 4. ÁUDIO, SEGURANÇA E OUTROS SERVIÇOS
  # -----------------------------------------------------------

  # Firewall ativado (Padrão NixOS)
  networking.firewall.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.printing.enable = true;

  # --- CONFIGURAÇÃO FLATPAK DECLARATIVA ---
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

  services.mysql.package = pkgs.mariadb;
  services.mysql.enable = true;

  # -----------------------------------------------------------
  # 5. ESTRATÉGIA DE BACKUP (RESTIC)
  # -----------------------------------------------------------
  services.restic.backups = {
    backup-sistema = {
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
  };

  # -----------------------------------------------------------
  # 6. USUÁRIOS E PACOTES
  # -----------------------------------------------------------
  users.users.luiz = {
    isNormalUser = true;
    description = "Luiz";
    extraGroups = [ "networkmanager" "wheel" "input" ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  environment.systemPackages = with pkgs; [
    # Sistema
    flatpak
    appimage-run
    nano
    wget
    git
    protonup-qt
    restic
    exfatprogs
    firewalld-gui

    # Dev / Apps
    vscode
    brave
    firefox
    nodejs_24
    javaPackages.compiler.openjdk21
    jetbrains.clion

    # C++ Toolchain
    cmake
    lomiri.cmake-extras
    ninja
    gdb
    llvmPackages_latest.clang
    llvmPackages_latest.bintools
    llvmPackages_latest.clang-tools

    # Media
    obs-studio
    mpv
  ];

  programs.firefox.enable = true;
}
