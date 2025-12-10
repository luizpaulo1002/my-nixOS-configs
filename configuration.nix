{ config, pkgs, ... }:

{
  # -----------------------------------------------------------
  # 1. BASE SYSTEM AND IMPORTS
  # -----------------------------------------------------------
  imports =
    [
      ./hardware-configuration.nix
    ];

  # ... (Configurações base) ...
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Bahia";
  i18n.defaultLocale = "pt_BR.UTF-8";

  system.stateVersion = "25.11";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # LUKS
  boot.initrd.luks.devices."luks-6de8cb75-c105-4641-b40d-6184f68e251e".device = "/dev/disk/by-uuid/6de8cb75-c105-4641-b40d-6184f68e251e";

  # Melhora de desempenho nos jogos
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;
  };

  # -----------------------------------------------------------
  # GESTÃO DE DISCOS (MONTAGEM AUTOMÁTICA)
  # -----------------------------------------------------------

  # Meu HD de BACKUPS
  fileSystems."/mnt/backup-hd" = {
    device = "/dev/disk/by-uuid/B489-CA7F";
    fsType = "exfat";
    options = [ "nofail" "x-systemd.automount" "uid=1000" "gid=100" "umask=0022" ];
  };

  # 2. DISCO 1
  fileSystems."/mnt/extra-1" = {
    device = "/dev/disk/by-uuid/20D9-DA63";
    fsType = "exfat"; # Se der erro, troque para "vfat" (FAT32) ou verifique com lsblk -f
    options = [ "nofail" "x-systemd.automount" "uid=1000" "gid=100" "umask=0022" ];
  };

  # 3. DISCO 2
  fileSystems."/mnt/extra-2" = {
    device = "/dev/disk/by-uuid/44E89DE3E89DD390";
    fsType = "ntfs";
    # uid=1000 garante que você é o dono. umask=0022 permite leitura/escrita.
    options = [ "nofail" "x-systemd.automount" "uid=1000" "gid=100" "umask=0022" ];
  };


  # -----------------------------------------------------------
  # 2. DRIVERS E GRÁFICOS NVIDIA
  # -----------------------------------------------------------
  hardware.nvidia.open = true;
  nixpkgs.config.allowUnfree = true;

  boot.extraModulePackages = [ config.boot.kernelPackages.nvidiaPackages.stable ];

  # Força o modesetting (essencial para Wayland)
  boot.initrd.kernelModules = [ "nvidia_modeset" ];

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # -----------------------------------------------------------
  # 3. AMBIENTE DE DESKTOP
  # -----------------------------------------------------------

  # KWallet
  security.pam.services."login".kwallet.enable = true;

  # Plasma + SDDM
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = { layout = "br"; variant = ""; };
  console.keyMap = "br-abnt2";

  # -----------------------------------------------------------
  # 4. ÁUDIO E OUTROS SERVIÇOS
  # -----------------------------------------------------------
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.printing.enable = true;
  services.flatpak.enable = true;

  # Banco de Dados
  services.mysql.package = pkgs.mariadb;
  services.mysql.enable = true;

  # -----------------------------------------------------------
  # 5. ESTRATÉGIA DE BACKUP (RESTIC)
  # -----------------------------------------------------------
  services.restic.backups = {
    backup-sistema = {
      initialize = true;
      user = "root";

      # Aponta para o ponto de montagem do backup
      repository = "/mnt/backup-hd/nixos";

      passwordFile = "/etc/nixos/restic-password";

      paths = [
        "/home/luiz"
        "/etc/nixos"
        "/var/backup-mysql"
      ];

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

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
      ];

      timerConfig = {
        OnCalendar = "19:00";
        Persistent = true;
      };
    };
  };

  # -----------------------------------------------------------
  # 6. USUÁRIOS E PACOTES
  # -----------------------------------------------------------
  users.users.luiz = {
    isNormalUser = true;
    description = "Luiz";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  environment.systemPackages = with pkgs; [
    # Ferramentas de Sistema
    flatpak
    nano
    wget
    git

    # Ferramentas de Backup e Disco
    restic
    exfatprogs # Para discos exFAT
    ntfs3g     # ADICIONADO: Para discos NTFS (melhor compatibilidade)

    # Desenvolvimento e Browsers
    vscode
    brave
    firefox
    nodejs_24
    javaPackages.compiler.openjdk21
    cmake
    gcc

    # Multimídia
    obs-studio
    mpv
  ];

  programs.firefox.enable = true;
}
