
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

