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
          pkgsAllowUnfree = import nixpkgs { system = suportedSystem; config = { allowUnfree = true; }; };

        in
        {
          # packages.vm = self.nixosConfigurations."${suportedSystem}".vm.config.system.build.toplevel;

          formatter = pkgsAllowUnfree.nixpkgs-fmt;

          # Utilized by `nix run .#<name>`
          apps.vm = {
            type = "app";
            program = "${self.nixosConfigurations.vm.config.system.build.vm}/bin/run-nixos-vm";
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              bashInteractive
              coreutils
              file
              nixpkgs-fmt
              which

              docker
              podman

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
              gitkraken
              jetbrains.pycharm-community
              keepassxc
              obsidian
              okular
              peek
              postman
              qbittorrent
              slack
              spotify
              tdesktop
              virt-manager
              vlc
              vscodium
              xorg.xclock
              yt-dlp
            ];

            shellHook = ''
              export TMPDIR=/tmp

              # Too much hardcoded?
              export DOCKER_HOST=ssh://nixuser@localhost:2200
            '';
          };
        }
      )

    // {
      nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
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
                url = "https://app.vagrantup.com/generic/boxes/alpine316/versions/4.2.10/providers/libvirt.box";
                hash = "sha256-2h68dE9u6t+m8+gOT3YYD2fxb+/upRb3z79eth9uzEI=";
              };
              # ubuntu2304 = pkgs.fetchurl {
              #   url = "https://app.vagrantup.com/generic/boxes/ubuntu2304/versions/4.3.4/providers/libvirt/amd64/vagrant.box";
              #   hash = "sha256-MRYXoDg/xCuxcNsh0OpY6e9XlPU+JER2tPUBuZ1y9QI=";
              # };

            in
            {
              # Internationalisation options
              # i18n.defaultLocale = "en_US.UTF-8";
              i18n.defaultLocale = "pt_BR.UTF-8";
              console.keyMap = "br-abnt2";

              virtualisation.vmVariant = {

                # users.extraGroups.vboxusers.members = [ "nixuser" ];
                # virtualisation.virtualbox.guest.enable = true;
                # virtualisation.virtualbox.guest.x11 = true;
                # virtualisation.virtualbox.host.enable = true;
                # virtualisation.virtualbox.host.enableExtensionPack = true;

                virtualisation.useNixStoreImage = true;
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
                  VIRSH_DEFAULT_CONNECT_URI = "qemu:///session";
                  # programs.dconf.profiles = pkgs.writeText "org/virt-manager/virt-manager/connections" ''
                  #  autoconnect = ["qemu:///system"];
                  #  uris = ["qemu:///system"];
                  # '';

                };

                virtualisation.memorySize = 1024 * 8; # Use MiB memory.
                virtualisation.diskSize = 1024 * 16; # Use MiB memory.
                virtualisation.cores = 8; # Number of cores.
                virtualisation.graphics = true;
                # virtualisation.forwardPorts = [
                #   { from = "host"; host.port = 8888; guest.port = 80; }
                # ];

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
                  "-vga virtio"
                  "-display gtk,zoom-to-fit=false"
                  # Enable copy/paste
                  # https://www.kraxel.org/blog/2021/05/qemu-cut-paste/
                  "-chardev qemu-vdagent,id=ch1,name=vdagent,clipboard=on"
                  "-device virtio-serial-pci"
                  "-device virtserialport,chardev=ch1,id=ch1,name=com.redhat.spice.0"

                  # https://serverfault.com/a/1119403
                  # "-device intel-iommu,intremap=on"
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
                  "podman"
                  "qemu-libvirtd"
                  "wheel"
                ];
                packages = with pkgs; [
                  btop
                  coreutils
                  direnv
                  file
                  gnumake
                  openssh
                  virt-manager
                  which

                  (
                    writeScriptBin "load-vagrant-images" ''
                      # && vagrant box add generic/ubuntu2304 "${ubuntu2304}" --provider libvirt \
                      vagrant box add generic/alpine316 "${alpine316}" --provider libvirt \
                      && vagrant box list
                    ''
                  )

                  (
                    let
                      vagrantfileAlpine = pkgs.writeText "vagrantfile-alpine" ''
                        # All Vagrant configuration is done below. The "2" in Vagrant.configure
                        # configures the configuration version (we support older styles for
                        # backwards compatibility). Please don't change it unless you know what
                        # you're doing.
                        Vagrant.configure("2") do |config|
                          # Every Vagrant development environment requires a box. You can search for
                          # boxes at https://vagrantcloud.com/search.
                          config.vm.box = "generic/alpine316"

                          config.vm.provider :libvirt do |v|
                            v.cpus=8
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
                            apk add --no-cache tzdata
                            test -d /etc || mkdir -pv /etc
                            echo 'America/Recife' > /etc/timezone

                            # https://unix.stackexchange.com/a/400140
                            echo
                            df -h /tmp && sudo mount -o remount,size=2G /tmp/ && df -h /tmp
                            echo

                            echo 'vagrant:123' | chpasswd

                            su vagrant -lc \
                            '
                              env | sort
                              echo

                              wget -qO- http://ix.io/4Cj0 | sh -

                              echo $PATH
                              export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                              echo $PATH

                              wget -qO- http://ix.io/4Bqg | sh -
                            '
                        SHELL
                        end
                      '';

                      vagrantfileUbuntu = pkgs.writeText "vagrantfile-alpine" ''
                        Vagrant.configure("2") do |config|
                          # Every Vagrant development environment requires a box. You can search for
                          # boxes at https://vagrantcloud.com/search.
                          config.vm.box = "generic/ubuntu2304"

                          config.vm.provider :libvirt do |v|
                            v.cpus=8
                            v.memory = "3072"
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

                              wget -qO- http://ix.io/4Cj0 | sh -

                              echo $PATH
                              export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                              echo $PATH

                              wget -qO- http://ix.io/4Bqg | sh -
                            '
                        SHELL
                        end
                      '';

                    in
                    writeScriptBin "copy-vagrantfiles" ''
                      mkdir -pv /home/nixuser/vagrant-examples/{alpine,ubuntu}

                      cp -v "${vagrantfileAlpine}" /home/nixuser/vagrant-examples/alpine/Vagrantfile
                      chmod 0664 -v /home/nixuser/vagrant-examples/alpine/Vagrantfile

                      # cp -v "''${vagrantfileUbuntu}" /home/nixuser/vagrant-examples/ubuntu/Vagrantfile
                      # chmod 0664 -v /home/nixuser/vagrant-examples/ubuntu/Vagrantfile
                    ''
                  )

                  (
                    writeScriptBin "prepare-vagrant" ''
                      copy-vagrantfiles && load-vagrant-images \
                      && echo

                      # cd /home/nixuser/vagrant-examples/alpine \
                      # && vagrant up

                      cd /home/nixuser/vagrant-examples/ubuntu \
                      && vagrant up

                      echo
                      vagrant global-status
                    ''
                  )

                ];
                shell = pkgs.bashInteractive;
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

              # Enable ssh
              services.sshd.enable = true;

              # https://github.com/NixOS/nixpkgs/issues/21332#issuecomment-268730694
              services.openssh = {
                allowSFTP = true;
                kbdInteractiveAuthentication = false;
                enable = true;
                forwardX11 = false;
                passwordAuthentication = false;
                permitRootLogin = "yes";
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
              # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

              services.qemuGuest.enable = true;

              # X configuration
              services.xserver.enable = true;
              services.xserver.layout = "br";

              services.xserver.displayManager.autoLogin.user = "nixuser";

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
              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                package = pkgs.nixVersions.nix_2_10;
                readOnlyStore = true;
                registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
              };

              environment.etc."channels/nixpkgs".source = nixpkgs.outPath;

              environment.systemPackages = with pkgs; [
                bashInteractive
                # hello
                # pkgsCross.aarch64-multiplatform.pkgsStatic.hello
                openssh
                virt-manager
                # gnome3.dconf-editor

                vagrant
                direnv # misses the config
              ];

              system.stateVersion = "22.11";
            })

        ];
        specialArgs = { inherit nixpkgs; };
      };
    };
}
