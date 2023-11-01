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
              ubuntu2304 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/generic/boxes/ubuntu2304/versions/4.3.4/providers/libvirt/amd64/vagrant.box";
                hash = "sha256-MRYXoDg/xCuxcNsh0OpY6e9XlPU+JER2tPUBuZ1y9QI=";
              };

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

                virtualisation.memorySize = 1024 * 3; # Use MiB memory.
                virtualisation.diskSize = 1024 * 16; # Use MiB memory.
                virtualisation.cores = 8; # Number of cores.
                virtualisation.graphics = true;
                # virtualisation.forwardPorts = [
                #   { from = "host"; host.port = 8888; guest.port = 80; }
                # ];

                virtualisation.resolution = {
                  x = 1280;
                  y = 1024;
                };

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
                  "podman"
                  "kvm"
                  "libvirtd"
                  "qemu-libvirtd"
                  "wheel"
                  "docker"
                ];
                packages = with pkgs; [
                  direnv
                  file
                  gnumake
                  which
                  coreutils
                  openssh
                  virt-manager

                  (
                    writeScriptBin "load-vagrant-images" ''
                      vagrant box add generic/alpine316 "${alpine316}" --provider libvirt \
                      && vagrant box add generic/ubuntu2304 "${ubuntu2304}" --provider libvirt \
                      && vagrant box list
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

              # services.qemuGuest.enable = true;

              # X configuration
              services.xserver.enable = true;
              services.xserver.layout = "br";

              services.xserver.displayManager.autoLogin.user = "nixuser";

              # services.xserver.desktopManager.xfce.enable = true;
              # services.xserver.desktopManager.xfce.enableScreensaver = false;

              # https://nixos.wiki/wiki/KDE
              services.xserver.displayManager.sddm.enable = true;
              services.xserver.desktopManager.plasma5.enable = true;
              services.xserver.displayManager.sddm.autoNumlock = true;

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
