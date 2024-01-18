{
  description = "Virtualization and Emulation with nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];
    in
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs {
            system = suportedSystem;
            config = {
              allowUnfree = true;
              # Re test it!
              overlays = [
                (final: prev: {
                  sl = final.hello;
                })
              ];
            };
          };
          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {
          packages.vm = self.nixosConfigurations.vm.config.system.build.toplevel;

          packages.automatic-vm = pkgsAllowUnfree.writeShellApplication {
            name = "run-nixos-vm";
            runtimeInputs = with pkgsAllowUnfree; [ curl virt-viewer ];
            /*
              Pode ocorrer uma condição de corrida de seguinte forma:
              a VM inicializa (o processo não é bloqueante, executa em background)
              o spice/VNC interno a VM inicializa
              o remote-viewer tenta conectar, mas o spice não está pronto ainda

              TODO: idealmente não deveria ser preciso ter mais uma dependência (o curl)
                    para poder sincronizar o cliente e o server. Será que no caso de
                    ambos estarem na mesma máquina seria melhor usar virt-viewer -fw?
              https://unix.stackexchange.com/a/698488
            */
            text = ''
              ${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm & PID_QEMU="$!"

              export VNC_PORT=3001

              for _ in web{0..50}; do
                if [[ $(curl --fail --silent http://localhost:"$VNC_PORT") -eq 1 ]];
                then
                  break
                fi
                # date +'%d/%m/%Y %H:%M:%S:%3N'
                sleep 0.2
              done;

              remote-viewer spice://localhost:"$VNC_PORT"

              kill $PID_QEMU
            '';
          };

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          apps.run-github-runner = {
            type = "app";
            program = "${self.packages."${suportedSystem}".automatic-vm}/bin/run-nixos-vm";
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              bashInteractive
              coreutils
              file
              nixpkgs-fmt
              which
              sl

              # docker
              # podman
              pleaseKeepMyInputs
            ];

            shellHook = ''
              export TMPDIR=/tmp

              # Too much hardcoded?
              export DOCKER_HOST=ssh://nixuser@localhost:2200

              test -d .profiles || mkdir -v .profiles

              test -L .profiles/dev \
              || nix develop .# --profile .profiles/dev --command true

              test -L .profiles/dev-shell-default \
              || nix build $(nix eval --impure --raw .#devShells."$system".default.drvPath) --out-link .profiles/dev-shell-"$system"-default

              test -L .profiles/nixosConfigurations."$system".vm.config.system.build.vm \
              || nix build --impure --out-link .profiles/nixosConfigurations."$system".vm.config.system.build.vm .#nixosConfigurations.vm.config.system.build.vm
            '';
          };
        }
      )

    // {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
        # About system and maybe --impure
        # https://www.youtube.com/watch?v=90aB_usqatE&t=3483s
        # system = "${suportedSystem}";
        # Really proud/scared of this hack :fire:
        # nix --system aarch64-linux eval --json nixpkgs#stdenv.isx86_64
        # nix --system x86_64-linux eval --json nixpkgs#stdenv.isx86_64
        # system = if (import nixpkgs { system = "x86_64-linux"; }).stdenv.isx86_64 then "x86_64-linux" else "aarch64-linux";
        # system = let
        #             e = (import nixpkgs { system = "aarch64-linux"; }).stdenv.isAarch64;
        #          in
        #             if (builtins.tryEval (builtins.deepSeq e e)).success then "aarch64-linux" else "x86_64-linux";
        system = builtins.currentSystem;

        modules = [
          # export QEMU_NET_OPTS="hostfwd=tcp::2200-:10022" && nix run .#vm
          # Then connect with ssh -p 2200 nixuser@localhost
          # ps -p $(pgrep -f qemu-kvm) -o args | tr ' ' '\n'
          ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
            let
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExR+PSB/jBwJYKfpLN+MMXs3miRn70oELTV3sXdgzpr";
              pedroKeys = "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i pedroalencarregis@hotmail.com";

              alpine316 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/generic/boxes/alpine316/versions/4.3.8/providers/libvirt.box";
                hash = "sha256-2h68dE9u6t+m8+gOT3YYD2fxb+/upRb3z79eth9uzEI=";
              };

              archlinux = pkgs.fetchurl {
                url = "https://app.vagrantup.com/archlinux/boxes/archlinux/versions/20231015.185166/providers/libvirt.box";
                hash = "sha256-al0x2BVLB9XoOBu3Z0/ANg2Ut1Bik9uT6xYz8DDc7L8=";
              };

              ubuntu2204 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/generic/boxes/ubuntu2204/versions/4.3.8/providers/libvirt.box";
                hash = "sha256-ZkzHC1WJITQWSxKCn9VsuadabZEnu+1lR4KD58PVGrQ=";
              };

              ubuntu2304 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/generic/boxes/ubuntu2304/versions/4.3.8/providers/libvirt/amd64/vagrant.box";
                hash = "sha256-NJSYFp7RmL0BlY8VBltSFPCCdajk5J5wMD2++aBnxCw=";
              };

              #
              vagrantfileAlpine = pkgs.writeText "vagrantfile-alpine" ''
                Vagrant.configure("2") do |config|
                  # Every Vagrant development environment requires a box. You can search for
                  # boxes at https://vagrantcloud.com/search.
                  config.vm.box = "generic/alpine316"

                  config.vm.provider :libvirt do |v|
                    v.cpus=3
                    v.memory = "2048"
                  end

                  config.vm.synced_folder '.', '/home/vagrant/code'

                  config.vm.provision "shell", inline: <<-SHELL

                    apk add --no-cache xz shadow \
                    && addgroup vagrant wheel \
                    && addgroup vagrant kvm \
                    && chown -v root:kvm /dev/kvm \
                    && usermod --append --groups kvm vagrant

                    # https://stackoverflow.com/a/59103173
                    echo 'Start tzdata stuff' \
                    && apk add --no-cache tzdata \
                    && (test -d /etc || mkdir -pv /etc) \
                    && cp -v /usr/share/zoneinfo/America/Recife /etc/localtime \
                    && echo America/Recife > /etc/timezone \
                    && apk del tzdata shadow \
                    && echo 'End tzdata stuff!'


                    # https://unix.stackexchange.com/a/400140
                    echo
                    df -h /tmp && sudo mount -o remount,size=2G /tmp/ && df -h /tmp
                    echo

                    su vagrant -lc \
                    '
                      env | sort
                      echo

                      wget -qO- http://ix.io/4Cj0 | sh -

                      echo $PATH
                      export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                      echo $PATH

                      # wget -qO- http://ix.io/4Bqg | sh -
                    '

                    mkdir -pv /etc/sudoers.d \
                    && echo 'vagrant:123' | chpasswd \
                    && echo 'vagrant ALL=(ALL) PASSWD:SETENV: ALL' > /etc/sudoers.d/vagrant
                  SHELL
                end
              '';

              vagrantfileArchlinux = pkgs.writeText "vagrantfile-archlinux" ''
                Vagrant.configure("2") do |config|
                  config.vm.box = "archlinux/archlinux"

                  config.vm.provider :libvirt do |v|
                    v.cpus=3
                    v.memory = "2048"
                  end

                  config.vm.synced_folder '.', '/home/vagrant/code'

                  config.vm.provision "shell", inline: <<-SHELL
                    su vagrant -lc \
                    '
                      env | sort
                      echo

                      # curl -L http://ix.io/4Cj0 | sh -

                      echo $PATH
                      export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                      echo $PATH

                      # wget -qO- http://ix.io/4Bqg | sh -
                    '

                    mkdir -pv /etc/sudoers.d \
                    && echo 'vagrant:123' | chpasswd \
                    && echo 'vagrant ALL=(ALL) PASSWD:SETENV: ALL' > /etc/sudoers.d/vagrant
                  SHELL
                end
              '';

              vagrantfileUbuntu = pkgs.writeText "vagrantfile-ubuntu" ''
                Vagrant.configure("2") do |config|
                  # config.vm.box = "generic/ubuntu2204"
                  config.vm.box = "generic/ubuntu2304"

                  config.vm.provider :libvirt do |v|
                    v.cpus=3
                    v.memory = "2048"
                    # v.memorybacking :access, :mode => "shared"
                    # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1460
                  end

                  config.vm.synced_folder '.', '/home/vagrant/code'

                  config.vm.provision "shell", inline: <<-SHELL

                    # TODO: revise it
                    # https://unix.stackexchange.com/a/400140
                    # https://stackoverflow.com/a/69288266
                    RAM_IN_GIGAS=$(expr $(sed -n '/^MemTotal:/ s/[^0-9]//gp' /proc/meminfo) / 1024 / 1024)
                    echo "$RAM_IN_GIGAS"
                    # df -h /tmp && sudo mount -o remount,size="$RAM_IN_GIGAS"G /tmp/ && df -h /tmp

                    su vagrant -lc \
                    '
                      env | sort
                      echo

                      # wget -qO- http://ix.io/4Cj0 | sh -

                      echo $PATH
                      export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                      echo $PATH

                      # wget -qO- http://ix.io/4Bqg | sh -
                    '

                    mkdir -pv /etc/sudoers.d \
                    && echo 'vagrant:123' | chpasswd \
                    && echo 'vagrant ALL=(ALL) PASSWD:SETENV: ALL' > /etc/sudoers.d/vagrant

                  SHELL
                end
              '';

            in
            {
              # Internationalisation options
              i18n.defaultLocale = "en_US.UTF-8";
              # i18n.defaultLocale = "pt_BR.UTF-8";
              console.keyMap = "br-abnt2";

              # Why
              # nix flake show --impure .#
              # break if it does not exists?
              # Use systemd boot (EFI only)
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/hda1"; };

              virtualisation.vmVariant = {
                # It does not work for ARM tested it too
                # users.extraGroups.vboxusers.members = [ "nixuser" ];
                # virtualisation.virtualbox.guest.enable = true;
                # virtualisation.virtualbox.guest.x11 = true;
                # virtualisation.virtualbox.host.enable = true;
                # virtualisation.virtualbox.host.enableExtensionPack = true;

                virtualisation.useNixStoreImage = false;
                virtualisation.writableStore = true; # TODO: hardening

                virtualisation.docker.enable = true;
                virtualisation.podman.enable = true;

                virtualisation.libvirtd.enable = true;

                programs.dconf.enable = true;
                # security.polkit.enable = true; # TODO: hardening?

                environment.variables = {
                  VAGRANT_DEFAULT_PROVIDER = "libvirt";

                  # programs.dconf.enable = true;
                  # VIRSH_DEFAULT_CONNECT_URI="qemu:///system";
                  # VIRSH_DEFAULT_CONNECT_URI = "qemu:///session";
                  # programs.dconf.profiles = pkgs.writeText "org/virt-manager/virt-manager/connections" ''
                  #  autoconnect = ["qemu:///system"];
                  #  uris = ["qemu:///system"];
                  # '';

                };

                virtualisation.memorySize = 1024 * 4; # Use MiB memory.
                virtualisation.diskSize = 1024 * 50; # Use MiB memory.
                virtualisation.cores = 8; # Number of cores.
                virtualisation.graphics = true;
                /*
                export QEMU_NET_OPTS="hostfwd=tcp::10022-:2200"
                virtualisation.forwardPorts = [
                  { from = "host"; host.port = 8888; guest.port = 80; }
                ];
                */

                /*
                xdpyinfo | grep dimensions

                xrandr --current
                */
                # virtualisation.resolution = { x = (1024 - 250); y = (768 - 250); };
                virtualisation.resolution = lib.mkForce { x = 1024; y = 768; };

                virtualisation.qemu.options = [
                  # Better display option
                  # TODO: -display sdl,gl=on
                  # https://gitlab.com/qemu-project/qemu/-/issues/761
                  #"-vga virtio"
                  #"-display gtk,zoom-to-fit=false"
                  # Enable copy/paste
                  # https://www.kraxel.org/blog/2021/05/qemu-cut-paste/
                  #"-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on"
                  #"-device virtio-serial-pci"
                  #"-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0"
                  # https://serverfault.com/a/1119403
                  # "-device intel-iommu,intremap=on"
                  # https://www.spice-space.org/spice-user-manual.html#Running_qemu_manually
                  # remote-viewer spice://localhost:3001

                  # "-daemonize" # How to save the QEMU PID?
                  "-machine vmport=off"
                  "-vga qxl"
                  "-spice port=3001,disable-ticketing=on"
                  "-device virtio-serial"
                  "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
                  "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
                ];
              };

              users.users.root = {
                password = "root";
                initialPassword = "root";
                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "${toString nixuserKeys}" }"
                  "${ pkgs.writeText "pedro-keys.pub" "${toString pedroKeys}" }"
                ];
              };

              # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
              users.extraGroups.nixgroup.gid = 999;

              security.sudo.wheelNeedsPassword = false; # TODO: hardening
              users.users.nixuser = {
                isSystemUser = true;
                password = "101"; # TODO: hardening
                createHome = true;
                home = "/home/nixuser";
                homeMode = "0700";
                description = "The VM tester user";
                group = "nixgroup";
                extraGroups = [
                  "docker"
                  "kvm"
                  "libvirtd"
                  "nixgroup"
                  "podman"
                  "qemu-libvirtd"
                  "root"
                  "wheel"
                ];
                packages = with pkgs; [

                  # Graphical packages
                  # anydesk
                  # blender
                  # brave
                  # dbeaver
                  # discord
                  # ghidra
                  # gimp
                  # google-chrome
                  # inkscape
                  # insomnia
                  # kolourpaint
                  # libreoffice
                  # rustdesk

                  # gitkraken
                  # jetbrains.pycharm-community
                  # keepassxc
                  # obsidian
                  # okular
                  # peek
                  # postman
                  # qbittorrent
                  # slack
                  # spotify
                  # tdesktop
                  # virt-manager
                  # vlc
                  # vscodium
                  # xorg.xclock
                  # yt-dlp

                  btop
                  firefox
                  git
                  tilix
                  starship
                  coreutils
                  direnv
                  file
                  gnumake
                  openssh
                  virt-manager
                  which
                  awscli
                  sl
                  nix-info

                  (
                    writeScriptBin "prepare-vagrant-vms" ''
                      #! ${pkgs.runtimeShell} -e

                      # $(vagrant global-status | grep -q alpine) || cd /home/nixuser/vagrant-examples/alpine && vagrant up
                      $(vagrant global-status | grep -q ubuntu) || cd /home/nixuser/vagrant-examples/ubuntu && vagrant up
                    ''
                  )

                ];
                # shell = pkgs.bashInteractive;
                shell = pkgs.zsh;
                uid = 1234;
                autoSubUidGidRange = true;

                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "${toString nixuserKeys}" }"
                  "${ pkgs.writeText "pedro-keys.pub" "${toString pedroKeys}" }"
                ];

                openssh.authorizedKeys.keys = [
                  "${toString nixuserKeys}"
                  "${toString pedroKeys}"
                ];
              };

              # https://github.com/NixOS/nixpkgs/blob/3a44e0112836b777b176870bb44155a2c1dbc226/nixos/modules/programs/zsh/oh-my-zsh.nix#L119
              # https://discourse.nixos.org/t/nix-completions-for-zsh/5532
              # https://github.com/NixOS/nixpkgs/blob/09aa1b23bb5f04dfc0ac306a379a464584fc8de7/nixos/modules/programs/zsh/zsh.nix#L230-L231
              programs.zsh = {
                enable = true;
                shellAliases = {
                  vim = "nvim";
                  shebang = "echo '#!/usr/bin/env bash'"; # https://stackoverflow.com/questions/10376206/what-is-the-preferred-bash-shebang#comment72209991_10383546
                  nfmt = "nix run nixpkgs#nixpkgs-fmt **/*.nix *.nix";
                };
                enableCompletion = true;
                autosuggestions.enable = true;
                syntaxHighlighting.enable = true;
                interactiveShellInit = ''
                  export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
                  export ZSH_THEME="agnoster"
                  export ZSH_CUSTOM=${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions
                  plugins=(
                            colored-man-pages
                            docker
                            git
                            #zsh-autosuggestions # Why this causes an warn?
                            #zsh-syntax-highlighting
                          )

                  # https://nixos.wiki/wiki/Fzf
                  source $ZSH/oh-my-zsh.sh

                  export DIRENV_LOG_FORMAT=""
                  eval "$(direnv hook zsh)"

                  eval "$(starship init zsh)"

                  export FZF_BASE=$(fzf-share)
                  source "$(fzf-share)/completion.zsh"
                  source "$(fzf-share)/key-bindings.zsh"
                '';

                ohMyZsh.custom = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
                promptInit = "";
              };

              # Probably solve many warns about fonts
              # https://gist.github.com/kendricktan/8c33019cf5786d666d0ad64c6a412526
              # https://discourse.nixos.org/t/imagemagicks-convert-command-fails-due-to-fontconfig-error/20518/5
              # https://github.com/NixOS/nixpkgs/issues/176081#issuecomment-1145825623
              fonts = {
                fontDir.enable = true;
                packages = with pkgs; [
                  # fontconfig

                  powerline
                  powerline-fonts
                  # noto-fonts-cjk
                  # noto-fonts-emoji
                  # liberation_ttf
                  # fira-code
                  # fira-code-symbols
                  # mplus-outline-fonts.githubRelease
                  # dina-font
                  # proggyfonts
                ];
                enableDefaultPackages = true;
                enableGhostscriptFonts = true;
              };

              systemd.user.services.populate-history-vagrant = {
                script = ''
                  echo "Started"

                  echo "cd /home/nixuser/vagrant-examples" >> /home/nixuser/.zsh_history
                  echo "vagrant ssh" >> /home/nixuser/.zsh_history
                  echo "vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh" >> /home/nixuser/.zsh_history
                  echo "cd /home/nixuser/vagrant-examples/ubuntu && vagrant up && vagrant ssh && sleep 10 && vagrant ssh" >> /home/nixuser/.zsh_history
                  echo "vagrant global-status" >> /home/nixuser/.zsh_history
                  echo "vagrant box list" >> /home/nixuser/.zsh_history
                  echo "prepare-vagrant-vms" >> /home/nixuser/.zsh_history
                  echo "journalctl --user --unit copy-vagrant-examples-vagrant-up.service -b -f" >> /home/nixuser/.zsh_history

                  echo "Ended"
                '';
                wantedBy = [ "default.target" ];
              };

              # journalctl --user --unit copy-vagrant-examples-vagrant-up.service -b -f
              systemd.user.services.copy-vagrant-examples-vagrant-up = {
                path = with pkgs; [
                  curl
                  gnutar
                  gzip
                  procps
                  vagrant
                  xz
                ];
                /*
                     generic/ubuntu2204 \
                     "${ubuntu2204}" \
                     --force \
                     --provider \
                     $PROVIDER \
                && vagrant \
                     box \
                     add \
                     generic/alpine316 \
                     "${alpine316}" \
                */
                script = ''
                  #! ${pkgs.runtimeShell} -e

                    BASE_DIR=/home/nixuser/vagrant-examples
                    mkdir -pv "$BASE_DIR"/{alpine,archlinux,ubuntu}

                    cd "$BASE_DIR"

                    cp -v "${vagrantfileAlpine}" alpine/Vagrantfile

                    cp -v "${vagrantfileArchlinux}" archlinux/Vagrantfile

                    cp -v "${vagrantfileUbuntu}" ubuntu/Vagrantfile

                    PROVIDER=libvirt
                    vagrant \
                         box \
                         add \
                         generic/ubuntu2304 \
                         "${ubuntu2304}" \
                         --force \
                         --provider \
                         $PROVIDER \
                    && echo 000 \
                    && vagrant box list \
                    && echo 111
                '';
                wantedBy = [ "default.target" ];
              };

              # Hack to fix annoying zsh warning, too overkill probably
              # https://www.reddit.com/r/NixOS/comments/cg102t/how_to_run_a_shell_command_upon_startup/eudvtz1/?utm_source=reddit&utm_medium=web2x&context=3
              systemd.user.services.fix-zsh-warning = {
                script = ''
                  echo "Fixing a zsh warning"
                  # https://stackoverflow.com/questions/638975/how-wdo-i-tell-if-a-regular-file-does-not-exist-in-bash#comment25226870_638985
                  test -f /home/nixuser/.zshrc || touch /home/nixuser/.zshrc && chown nixuser: -Rv /home/nixuser
                '';
                wantedBy = [ "default.target" ];
              };

              # Enable ssh
              services.sshd.enable = true;

              # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
              services.openssh = {
                allowSFTP = true;
                settings.KbdInteractiveAuthentication = false;
                enable = true;
                settings.X11Forwarding = false;
                settings.PasswordAuthentication = false;
                settings.PermitRootLogin = "yes";
                ports = [ 10022 ];
                authorizedKeysFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "${toString nixuserKeys}" }"
                  "${ pkgs.writeText "pedro-keys.pub" "${toString pedroKeys}" }"
                ];
              };

              # https://nixos.wiki/wiki/Libvirt
              # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
              boot.extraModprobeConfig = "options kvm_intel nested=1";

              # https://www.reddit.com/r/NixOS/comments/wcxved/i_gave_an_adhoc_lightning_talk_at_mch2022/
              # Matthew Croughan - Use flake.nix, not Dockerfile - MCH2022
              # file $(readlink -f $(which hello))
              # nixos-option boot.binfmt.emulatedSystems
              # https://github.com/ryan4yin/nixos-and-flakes-book/blob/main/docs/development/cross-platform-compilation.md#custom-build-toolchain
              # https://github.com/ryan4yin/nixos-and-flakes-book/blob/fb2fe1224a4277374cde01404237acc5fecf895a/docs/development/cross-platform-compilation.md#linux-binfmt_misc
              # boot.binfmt.emulatedSystems = [ "aarch64-linux" "riscv64-linux" ];

              services.qemuGuest.enable = true;

              # X configuration
              services.xserver.enable = true;
              services.xserver.layout = "br";

              services.xserver.displayManager.autoLogin.user = "nixuser";
              services.xserver.displayManager.sessionCommands = ''
                exo-open \
                  --launch TerminalEmulator \
                  --zoom=-3 \
                  --geometry 154x40
              '';

              # journalctl --user --unit create-custom-desktop-icons.service -b -f
              systemd.user.services.create-custom-desktop-icons = {
                script = ''
                  #! ${pkgs.runtimeShell} -e

                  echo "Started"

                  ln \
                    -sfv \
                    "${pkgs.xfce.xfce4-settings}"/share/applications/xfce4-terminal-emulator.desktop \
                    /home/nixuser/Desktop/xfce4-terminal-emulator.desktop

                  ln \
                    -sfv \
                    "${pkgs.firefox}"/share/applications/firefox.desktop \
                    /home/nixuser/Desktop/firefox.desktop

                  echo "Ended"
                '';
                wantedBy = [ "xfce4-notifyd.service" ];
              };

              # https://nixos.org/manual/nixos/stable/#sec-xfce
              services.xserver.desktopManager.xfce.enable = true;
              services.xserver.desktopManager.xfce.enableScreensaver = false;

              # https://nixos.wiki/wiki/KDE
              # services.xserver.displayManager.sddm.enable = true;
              # services.xserver.desktopManager.plasma5.enable = true;
              # services.xserver.displayManager.sddm.autoNumlock = true;

              services.xserver.videoDrivers = [ "qxl" ];

              # For copy/paste to work
              services.spice-vdagentd.enable = true;

              nixpkgs.config.allowUnfree = true;

              boot.readOnlyNixStore = true;

              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                package = pkgs.nixVersions.nix_2_10;
                registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
                /*
                  echo $NIX_PATH
                  nixpkgs=/nix/store/mzdg05xhylnw743qapcd80c10f0vfbnl-059pc9vdgzwgd0xsm2i8hsysxlxs2al7-source

                  nix eval --raw nixpkgs#pkgs.path
                  /nix/store/375da3gc24ijmjz622h0wdsqnzvkajbh-b1l1kkp1g07gy67wglfpwlwaxs1rqkpx-source

                  nix-info -m | grep store | cut -d'`' -f2

                  nix eval --impure --expr '<nixpkgs>'
                  nix eval --impure --raw --expr '(builtins.getFlake "nixpkgs").outPath'
                  nix-instantiate --eval --attr 'path' '<nixpkgs>'
                  nix-instantiate --eval --attr 'pkgs.path' '<nixpkgs>'
                  nix-instantiate --eval --expr 'builtins.findFile builtins.nixPath "nixpkgs"'

                  nix eval nixpkgs#path
                  nix eval nixpkgs#pkgs.path
                */
                nixPath = [ "nixpkgs=${pkgs.path}" ]; # TODO: test it
                /*
                nixPath = [
                  "nixpkgs=/etc/channels/nixpkgs"
                  "nixos-config=/etc/nixos/configuration.nix"
                  # "/nix/var/nix/profiles/per-user/root/channels"
                ];
                */
              };

              # environment.etc."channels/nixpkgs".source = nixpkgs.outPath;
              # environment.etc."channels/nixpkgs".source = "${pkgs.path}";
              environment.etc."channels/nixpkgs".source = "${pkgs.path}";

              environment.systemPackages = with pkgs; [
                bashInteractive
                # hello
                # pkgsCross.aarch64-multiplatform.pkgsStatic.hello
                # pkgsCross.riscv64.pkgsStatic.hello
                openssh
                virt-manager
                # gnome3.dconf-editor
                # gnome2.dconf-editor

                vagrant
                direnv
                nix-direnv
                fzf
                neovim
                nixos-option
                oh-my-zsh
                zsh
                zsh-autosuggestions
                zsh-completions
              ];

              system.stateVersion = "22.11";
            })

        ];
        specialArgs = { inherit nixpkgs; };
      };
    };
}
