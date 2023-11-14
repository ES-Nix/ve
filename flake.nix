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
              # Broken
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

                virtualisation.useNixStoreImage = true;
                virtualisation.writableStore = true; # TODO: hardening

                virtualisation.docker.enable = true;
                virtualisation.podman.enable = false; # Enabling k8s breaks podman

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

                virtualisation.memorySize = 1024 * 10; # Use MiB memory.
                virtualisation.diskSize = 1024 * 25; # Use MiB memory.
                virtualisation.cores = 10; # Number of cores.
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
                  "kubernetes"
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

                  (
                    writeScriptBin "load-vagrant-images" ''
                      vagrant box add generic/alpine316 "${alpine316}" --force --provider libvirt \
                      && vagrant box add generic/ubuntu2304 "${ubuntu2304}" --force --provider libvirt \
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

                              # wget -qO- http://ix.io/4Bqg | sh -
                            '

                            mkdir -pv /etc/sudoers.d \
                            && echo 'vagrant:123' | chpasswd \
                            && echo 'vagrant ALL=(ALL) PASSWD:SETENV: ALL' > /etc/sudoers.d/vagrant

                        SHELL
                        end
                      '';

                    in
                    writeScriptBin "copy-vagrantfiles" ''
                      mkdir -pv /home/nixuser/vagrant-examples/{alpine,ubuntu}

                      cp -v "${vagrantfileAlpine}" /home/nixuser/vagrant-examples/alpine/Vagrantfile
                      chmod 0664 -v /home/nixuser/vagrant-examples/alpine/Vagrantfile

                      cp -v "${vagrantfileUbuntu}" /home/nixuser/vagrant-examples/ubuntu/Vagrantfile
                      chmod 0664 -v /home/nixuser/vagrant-examples/ubuntu/Vagrantfile
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

                  (
                    writeScriptBin "fix-k8s-cluster-admin-key" ''
                      #! ${pkgs.runtimeShell} -e
                      sudo chmod 0660 -v /var/lib/kubernetes/secrets/cluster-admin-key.pem
                      sudo chown root:kubernetes -v /var/lib/kubernetes/secrets/cluster-admin-key.pem
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
                fonts = with pkgs; [
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
                enableDefaultFonts = true;
                enableGhostscriptFonts = true;
              };

              # Hack to fix annoying zsh warning, too overkill probably
              # https://www.reddit.com/r/NixOS/comments/cg102t/how_to_run_a_shell_command_upon_startup/eudvtz1/?utm_source=reddit&utm_medium=web2x&context=3
              systemd.services.fix-zsh-warning = {
                script = ''
                  echo "Fixing a zsh warning"
                  # https://stackoverflow.com/questions/638975/how-wdo-i-tell-if-a-regular-file-does-not-exist-in-bash#comment25226870_638985
                  test -f /home/nixuser/.zshrc || touch /home/nixuser/.zshrc && chown nixuser: -Rv /home/nixuser
                '';
                wantedBy = [ "multi-user.target" ];
              };

              # journalctl -u fix-k8s.service -b
              systemd.services.fix-k8s = {
                script = ''
                  echo "Fixing k8s"

                  CLUSTER_ADMIN_KEY_PATH=/var/lib/kubernetes/secrets/cluster-admin-key.pem

                  while ! test -f "$CLUSTER_ADMIN_KEY_PATH"; do echo $(date +'%d/%m/%Y %H:%M:%S:%3N'); sleep 0.5; done

                  chmod 0660 -v "$CLUSTER_ADMIN_KEY_PATH"
                  chown root:kubernetes -v "$CLUSTER_ADMIN_KEY_PATH"
                '';
                wantedBy = [ "multi-user.target" ];
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
              # nixos-option boot.binfmt.emulatedSystems
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

                # Looks like kubernetes needs atleast all this
                kubectl
                kubernetes
                #
                cni
                cni-plugins
                conntrack-tools
                cri-o
                cri-tools
                ebtables
                ethtool
                flannel
                iptables
                socat

                (
                  writeScriptBin "fix-k8s-cluster-admin-key" ''
                    #! ${pkgs.runtimeShell} -e
                    sudo chmod 0660 -v /var/lib/kubernetes/secrets/cluster-admin-key.pem
                    sudo chown root:kubernetes -v /var/lib/kubernetes/secrets/cluster-admin-key.pem
                  ''
                )
              ];

              # Is this ok to kubernetes?
              # Why free -h still show swap stuff but with 0?
              swapDevices = pkgs.lib.mkForce [ ];

              # Is it a must for k8s?
              # Take a look into:
              # https://github.com/NixOS/nixpkgs/blob/9559834db0df7bb274062121cf5696b46e31bc8c/nixos/modules/services/cluster/kubernetes/kubelet.nix#L255-L259
              boot.kernel.sysctl = {
                # If it is enabled it conflicts with what kubelet is doing
                # "net.bridge.bridge-nf-call-ip6tables" = 1;
                # "net.bridge.bridge-nf-call-iptables" = 1;

                # https://docs.projectcalico.org/v3.9/getting-started/kubernetes/installation/migration-from-flannel
                # https://access.redhat.com/solutions/53031
                "net.ipv4.conf.all.rp_filter" = 1;
                # https://www.tenable.com/audits/items/CIS_Debian_Linux_8_Server_v2.0.2_L1.audit:bb0f399418f537997c2b44741f2cd634
                # "net.ipv4.conf.default.rp_filter" = 1;
                "vm.swappiness" = 0;
              };

              environment.variables.KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";

              #  environment.etc."containers/registries.conf" = {
              #    mode = "0644";
              #    text = ''
              #      [registries.search]
              #      registries = ['docker.io', 'localhost']
              #    '';
              #  };

              services.kubernetes.roles = [ "master" "node" ];
              services.kubernetes.masterAddress = "nixos";
              services.kubernetes = {
                flannel.enable = true;
              };

              environment.etc."kubernets/kubernetes-examples/appvia/deployment.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/deployment.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/service.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/service.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/ingress.yaml" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/ingress.yaml}";
              };

              environment.etc."kubernets/kubernetes-examples/appvia/notes.md" = {
                mode = "0644";
                text = "${builtins.readFile ./kubernetes-examples/appvia/notes.md}";
              };

              # journalctl -u move-kubernetes-examples.service -b
              systemd.services.move-kubernetes-examples = {
                script = ''
                  echo "Started move-kubernets-examples"

                  # cp -rv ''\${./kubernetes-examples} /home/nixuser/
                  cp -Rv /etc/kubernets/kubernetes-examples/ /home/nixuser/

                  chown -Rv nixuser:nixgroup /home/nixuser/kubernetes-examples

                  kubectl \
                    apply \
                    --file /home/nixuser/kubernetes-examples/deployment.yaml \
                    --file /home/nixuser/kubernetes-examples/service.yaml \
                    --file /home/nixuser/kubernetes-examples/ingress.yaml
                '';
                wantedBy = [ "multi-user.target" ];
              };

              boot.kernelParams = [
                "swapaccount=0"
                "systemd.unified_cgroup_hierarchy=0"
                "group_enable=memory"
                "cgroup_enable=cpuset"
                "cgroup_memory=1"
                "cgroup_enable=memory"
              ];

              # ulimit -n
              # https://github.com/NixOS/nixpkgs/issues/159964#issuecomment-1050080111
              security.pam.loginLimits = [
                {
                  domain = "*";
                  type = "-";
                  item = "nofile";
                  value = "9192";
                }
              ];

              system.stateVersion = "22.11";
            })

        ];
        specialArgs = { inherit nixpkgs; };
      };
    };
}
