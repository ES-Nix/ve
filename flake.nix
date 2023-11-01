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
        # Really proud of this hack :fire:
        system = if (nixpkgs { system = "x86_64-linux"; }).stdenv.isAarch64 then "aarch64-linux" else "x86_64-linux";
        modules = [
          # Build this VM with nix build  ./#nixosConfigurations.vm.config.system.build.vm
          # Then run is with: ./result/bin/run-nixos-vm
          # To be able to connect with ssh enable port forwarding with:
          # export QEMU_NET_OPTS="hostfwd=tcp::10022-:2200" ./result/bin/run-nixos-vm
          # export QEMU_NET_OPTS="hostfwd=tcp::2200-:10022" && nix run .#vm
          # Then connect with ssh -p 2200 nixuser@localhost
          # ps -p $(pgrep -f qemu-kvm) -o args | tr ' ' '\n'
          # ssh-keygen -R '[localhost]:2200' 1>/dev/null 2>/dev/null; \
          # ssh -X -Y -o StrictHostKeyChecking=no -o GlobalKnownHostsFile=/dev/null \
          # -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -p 2200 nixuser@localhost
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
              #
              # virtualisation.useNixStoreImage = true;
              # virtualisation.writableStore = true; # TODO
              # Options for the screen
              virtualisation.vmVariant = {

                # virtualisation.virtualbox.host.enable = true;
                # virtualisation.virtualbox.host.enableExtensionPack = true;
                # users.extraGroups.vboxusers.members = [ "nixuser" ];
                # virtualisation.virtualbox.guest.enable = true;
                # virtualisation.virtualbox.guest.x11 = true;

                virtualisation.useNixStoreImage = true;
                virtualisation.writableStore = true; # TODO: hardening

                virtualisation.docker.enable = true;
                virtualisation.podman.enable = true;

                # networking.useDHCP = false;
                # networking.interfaces.enp0s3 = { useDHCP = true; };
                # networking.interfaces.ens3.useDHCP = true;

                # networking.firewall.checkReversePath = false; # https://releases.nixos.org/nix-dev/2016-January/019069.html
                # For dhcp to work and probably also want:
                # networking.firewall.trustedInterfaces = [ "virbr0" ];

                /*
                          Enables libvirtd
                          https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653

                          NixOS + Virt-Manager + Windows 11 = easy?
                          https://www.youtube.com/watch?v=rCVW8BGnYIc
                          # virt-manager --connect qemu:///system

                          Is this why? So to blame is xfce4?
                          $XDG_CONFIG_HOME/libvirt/qemu.conf
                          https://github.com/NixOS/nixpkgs/issues/115996#issuecomment-797597587
                          https://nixos.wiki/wiki/Virt-manager

                          https://blog.wikichoon.com/2016/01/qemusystem-vs-qemusession.html
                          https://serverfault.com/a/861853

                          https://libvirt.org/drvqemu.html#location-of-configuration-files
                          For now it is an must:
                          virt-manager --connect qemu:///session

                          - about permissions on debian https://unix.stackexchange.com/a/704334 + https://wiki.debian.org/KVM#Installation
                          - investigate kernel modules   boot.initrd.availableKernelModules =
                           [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];
                          - Update this flake and test it
                           + https://github.com/NixOS/nixpkgs/issues/42433
                           + https://github.com/NixOS/nixpkgs/issues/54150#issuecomment-1700312140
                           + https://github.com/NixOS/nixpkgs/issues/257171
                           + https://github.com/dzintars/infra/issues/28#issuecomment-749713920
                          - adding packages to libvirtd path https://github.com/NixOS/nixpkgs/issues/51152#issuecomment-1115749067
                          - read it about .xml https://github.com/vagrant-libvirt/vagrant-libvirt/issues/272#issuecomment-214385409
                          - https://www.dwarmstrong.org/kvm-qemu-libvirt/
                          - default network https://github.com/NixOS/nixpkgs/issues/223594
                          + https://github.com/NixOS/nixpkgs/issues/223594
                          + https://discourse.nixos.org/t/networkd-libvirt-bridged-networking-how/11769/6


                          virsh nodeinfo
                          virsh net-list
                          virsh list --all

                          stat /var/run/libvirt/libvirt-sock

                          export VIRSH_DEFAULT_CONNECT_URI=qemu:///system
                          https://askubuntu.com/a/1198894

                          TODO: Test it!
                          https://github.com/NixOS/nixpkgs/issues/52777#issuecomment-449860200

                          http://www.billyrayvalentine.com/opensuse-kvm-getting-started-notes.html#opensuse-kvm-getting-started-notes
                          https://wiki.archlinux.org/title/Libvirt#Authenticate_with_file-based_permissions
                          https://askubuntu.com/a/585270
                          unix_sock_group = "libvirt"
                          unix_sock_ro_perms = "0770"
                          unix_sock_rw_perms = "0770"
                          auth_unix_ro = "none"
                          auth_unix_rw = "none"

                          Really customised:
                          https://codeberg.org/municorn/nixos-config/src/commit/78456a592777c437a999b3e01d11008055846c02/vfio.nix
                          https://adamsimpson.net/writing/windows-11-as-kvm-guest
                          https://nixos.wiki/wiki/Libvirt
                          https://project-insanity.org/2021/05/17/using-virtio-fs-directory-sharing-together-with-nixops-libvirtd-backend/

                          # https://lists.gnu.org/archive/html/guix-devel/2018-09/msg00099.html
                          # https://gist.github.com/techhazard/1be07805081a4d7a51c527e452b87b26?permalink_comment_id=2087168#gistcomment-2087168
                          virtualisation.libvirtd.qemuVerbatimConfig = ''
                          nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
                          user = "1000"
                          '';
                        */
                virtualisation.libvirtd.enable = true;

                #  virtualisation.libvirtd = {
                #    enable = true;
                #    allowedBridges = [ "nm-bridge" "virbr0" ];
                #    onBoot = "ignore";
                #    onShutdown = "shutdown";
                #    qemu = {
                #      package = pkgs.qemu_kvm;
                #      ovmf.enable = true; # https://myme.no/posts/2021-11-25-nixos-home-assistant.html
                #      # ovmf.package = (pkgs.OVMFFull.override { secureBoot = true; tpmSupport = true; });
                #      runAsRoot = true;
                #    };
                #    extraConfig = ''
                #      unix_sock_group="libvirtd"
                #      unix_sock_rw_perms="0770"
                #      log_filters="1:qemu"
                #      log_outputs="1:journald"
                #    '';
                #  };

                programs.dconf.enable = true;
                # security.polkit.enable = true;

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

                systemd.services.libvirtd = {
                  # Add binaries to path so that hooks can use it
                  path =
                    let
                      env = pkgs.buildEnv {
                        name = "qemu-hook-env";
                        paths = with pkgs; [
                          bash
                          libvirt
                          kmod
                          systemd
                          ripgrep
                          sd
                        ];
                      };
                    in
                    [ env ];
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

              # services.nfs.server.enable = true;

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
              boot.kernelModules = [
                "kvm-amd"
                "kvm-intel"
                "xt_mark"
                "xt_comment"
                "xt_multiport"
                "iptable_nat"
                "iptable_filter"
                "xt_nat"
              ];

              /*
                        https://discuss.linuxcontainers.org/t/podman-wont-run-containers-in-lxd-cgroup-controller-pids-unavailable/13049/2
                        https://github.com/NixOS/nixpkgs/issues/73800#issuecomment-729206223
                        https://github.com/canonical/microk8s/issues/1691#issuecomment-977543458
                        https://github.com/grahamc/nixos-config/blob/35388280d3b06ada5882d37c5b4f6d3baa43da69/devices/petunia/configuration.nix#L36
                        https://stackoverflow.com/a/76340714
                        "cgroup_enable=memory"
                        "cgroup_memory=1"
                        "cgroup_no_v1=all"

                        About virt-host-validate
                        https://github.com/dzintars/infra/issues/28#issuecomment-749713920
                        +
                        By default with cgroups v2 all controllers are enabled only for the root cgroup and usually only a subset of controllers are enabled for other cgroups. When running virt-host-validate it checks cgroups available for the current process which is executed in some sub-cgroup where most controllers are not enabled.
                        The fix is fairly simple except for devices controller. With cgroups v2 there is no devices controller, eBPF should be used instead, but there is no simple detection if eBPF is available. Currently libvirt tries to query eBPF programs but this will work only as root because regular user usually doesn't have permissions to do that operation.
                        https://gitlab.com/libvirt/libvirt/-/issues/94
                        +
                        https://discussion.fedoraproject.org/t/qemu-warnings-lxc-failurse-for-libvirt-on-fedora-33-silverblue/25223/2
                        +
                        Update to test "latest" virt-host-validate



                       boot.kernelParams = [
                        # "console=ttyAMA0,115200n8" # https://nixos.wiki/wiki/NixOS_on_ARM#Enable_UART
                        "swapaccount=0"
                        "systemd.unified_cgroup_hierarchy=0"
                        "group_enable=memory"
                        "cgroup_enable=cpuset"
                        "cgroup_memory=1"
                        "cgroup_enable=memory"
                        "cgroup_enable=freeze"
                        "intel_iommu=on"
                        "cgroup_no_v1=all"
                      ];
                      */

              # https://www.reddit.com/r/NixOS/comments/wcxved/i_gave_an_adhoc_lightning_talk_at_mch2022/
              # Matthew Croughan - Use flake.nix, not Dockerfile - MCH2022
              # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

              # services.qemuGuest.enable = true;

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

              # Enable ssh
              services.sshd.enable = true;

              # Included packages here
              nixpkgs.config.allowUnfree = true;
              nix = {
                # package = nixpkgs.pkgs.nix;
                extraOptions = "experimental-features = nix-command flakes";
                readOnlyStore = true;

                package = pkgs.nixVersions.nix_2_10;

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
                # python3Full
                # git
                direnv # misses the config
                libcgroup
              ];

              system.stateVersion = "22.11";
            })

        ];
        specialArgs = { inherit nixpkgs; };
      };
    };
}
