{
  description = "Virtualization and Emulation with nix";
  /*
    nix \
    flake \
    lock \
    --override-input nixpkgs github:NixOS/nixpkgs/d24e7fdcfaecdca496ddd426cae98c9e2d12dfe8 \
    --override-input flake-utils github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a \
    --override-input nixos-generators github:nix-community/nixos-generators/d14b286322c7f4f897ca4b1726ce38cb68596c94

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/ae2fc9e0e42caaf3f068c1bfdc11c71734125e06' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input nixos-generators 'github:nix-community/nixos-generators/0dd0205bc3f6d602ddb62aaece5f62a8715a9e85'

    nix \
    flake \
    lock \
    --override-input nixpkgs 'github:NixOS/nixpkgs/345c263f2f53a3710abe117f28a5cb86d0ba4059' \
    --override-input flake-utils 'github:numtide/flake-utils/b1d9ab70662946ef0850d488da1c9019f3a9752a' \
    --override-input nixos-generators 'github:nix-community/nixos-generators/0dd0205bc3f6d602ddb62aaece5f62a8715a9e85'
  */
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = allAttrs@{ self, nixpkgs, flake-utils, nixos-generators, ... }:
    let
      suportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

      classicOCIImages = { };

    in
    {
      inherit (self) outputs;

      overlays.default = final: prev: {
        inherit self final prev classicOCIImages;

        foo-bar = prev.hello;

        # it is not working!
        sudo = prev.sudo.override { withInsults = true; }; # Just to remember you :]

        customNix =
          let
            extraPreConfigure = ''

              sed -i 's@getDataDir() + "/nix/root";@getStateDir() + "/nix";@' \
                src/libstore/store-api.cc
            '';
          in
          prev.pkgsStatic.nix.overrideAttrs (oldAttrs: {
            preConfigure = (oldAttrs.preConfigure or "") + extraPreConfigure;
          });


        # podman inspect docker.io/library/hello-world | nix run nixpkgs#jq ".[].Digest"
        # docker inspect --format json docker.io/library/hello-world | nix run nixpkgs#jq -- ".[].Id"
        cachedOCIImageHello1 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:4bd78111b6914a99dbc560e6a20eab57ff6655aea4a80c50b0c5491968cbc2e6";
          imageName = "docker.io/library/hello-world";
          name = "docker.io/library/hello-world";
          sha256 = "sha256-pi33xlJgmjrPI9CqmwG1FW6mXN9tuUh69JT1hjH+uRc=";
        };

        cachedOCIImageHello2 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:3fb4bd2f5de0584452ff4db9b5c44edb595812c994cc522ecde4ae252e93bdef";
          imageName = "quay.io/podman/hello";
          name = "quay.io/podman/hello";
          sha256 = "sha256-O6BvbVZqqhry/lXxsTZX0IuFS/0fAagV261wMr3rpXI=";
        };

        # docker manifest inspect alpine:3.20.3
        cachedOCIImage0 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-arm64";
          imageDigest = "sha256:9cee2b382fe2412cd77d5d437d15a93da8de373813621f2e4d406e3df0cf0e7c";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-UslbIYjEyuCaRJPY5KbfndUtoEFhmNvP5/iPahqW7BI=";
          os = "linux";
          arch = "arm64";
        };

        cachedOCIImage02 = prev.dockerTools.pullImage {
          finalImageTag = "3.20.3-amd64";
          imageDigest = "sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d";
          imageName = "docker.io/library/alpine";
          name = "docker.io/library/alpine";
          sha256 = "sha256-MyuP5ZMP0SbCsyAOxwJnzdjbOPCeoaQmQTWCSFNDEjU=";
          os = "linux";
          arch = "amd64";
        };

        cachedOCIImage00 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:66e11bea77a5ea9d6f0fe79b57cd2b189b5d15b93a2bdb925be22949232e4e55";
          imageName = "tonistiigi/binfmt";
          name = "tonistiigi/binfmt";
          sha256 = "sha256-Fax1Xf7OUch5hnFaW4SarIfkHJPNyoNoQfhsCw6f2NM=";
        };

        cachedOCIImage01 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:a629e796d77a7b2ff82186ed15d01a493801c020eed5ce6adaa2704356f15a1c";
          imageName = "docker.io/library/debian";
          name = "docker.io/library/debian";
          sha256 = "sha256-s5GAsCFCCcVd7O1BNgTssVakr2yJwrL4zGO5j/Ry8Ek=";
        };

        cachedOCIImageAndroid = prev.dockerTools.pullImage {
          finalImageTag = "emulator_14.0";
          imageDigest = "sha256:d547ba327ac1e05336a2eb51d044eeb53d851fd6bdb7d15b6d5a5b6d20c3f028";
          imageName = "budtmo/docker-android";
          name = "budtmo/docker-android";
          sha256 = "";
        };

        cachedOCIImage1 = prev.dockerTools.pullImage {
          finalImageTag = "22.04";
          imageDigest = "sha256:e9569c25505f33ff72e88b2990887c9dcf230f23259da296eb814fc2b41af999";
          imageName = "docker.io/library/ubuntu";
          name = "docker.io/library/ubuntu";
          sha256 = "sha256-EuRsM8blXIuuXsrWoCfMsUu/oS2UuNiF3Je/8rEwq7A=";
        };

        cachedOCIImage2 = prev.dockerTools.pullImage {
          finalImageTag = "24.04";
          imageDigest = "sha256:36fa0c7153804946e17ee951fdeffa6a1c67e5088438e5b90de077de5c600d4c";
          imageName = "docker.io/library/ubuntu";
          name = "docker.io/library/ubuntu";
          sha256 = "sha256-saru9GIEIw1ZtwvyHKfRTOOc9BHD65MxVB1L3l/xEtA=";
        };

        cachedOCIImage3 = prev.dockerTools.pullImage {
          finalImageTag = "bookworm-20240130";
          imageDigest = "sha256:79becb70a6247d277b59c09ca340bbe0349af6aacb5afa90ec349528b53ce2c9";
          imageName = "docker.io/library/debian";
          name = "docker.io/library/debian";
          sha256 = "sha256-veUB5jeFEoDd29Q4IryjP8ghRGO3lOndw1jLAp5nhNQ=";
        };

        cachedOCIImage4 = prev.dockerTools.pullImage {
          finalImageTag = "40";
          imageDigest = "sha256:22612832a0af4990b79cc6fb3c8b88d5ea70a0f30b3f87d83a0ae5efe30a7a65";
          imageName = "docker.io/library/fedora";
          name = "docker.io/library/fedora";
          sha256 = "sha256-PegMlCkSpRLc2fAtF9gA0jIfmGzJc/QXdcWFYQdt4BU=";
        };

        cachedOCIImage5 = prev.dockerTools.pullImage {
          finalImageTag = "9.3-20231124";
          imageDigest = "sha256:d7f8aa1c5ff918565fa1114d16e27b03fe10944a422e2943a66f6f4a275fa22c";
          imageName = "docker.io/library/almalinux";
          name = "docker.io/library/almalinux";
          sha256 = "sha256-+ZiFULLYziIn50KyJ6GDzxWa21gyT77x6B5YuOzixHg=";
        };

        cachedOCIImage6 = prev.dockerTools.pullImage {
          finalImageTag = "15.5";
          imageDigest = "sha256:bd0fcef5afdc37936fd102ade71522d30b68364e724cb84083bc64d036b995b4";
          imageName = "docker.io/opensuse/leap";
          name = "docker.io/opensuse/leap";
          sha256 = "sha256-wu92eBqpNNvwl8i6ZjcFVZgO2/sRM1dfPyLGFOSMfmw=";
        };

        cachedOCIImage7 = prev.dockerTools.pullImage {
          finalImageTag = "9.3-13";
          imageDigest = "sha256:d72202acf3073b61cb407e86395935b7bac5b93b16071d2b40b9fb485db2135d";
          imageName = "registry.access.redhat.com/ubi9/ubi-micro";
          name = "registry.access.redhat.com/ubi9/ubi-micro";
          sha256 = "sha256-gM27gBdFYxzdloABHGExappLCR5TrFBUAbVov1GZ3pQ=";
        };

        cachedOCIImage8 = prev.dockerTools.pullImage {
          finalImageTag = "9.3-1552";
          imageDigest = "sha256:1fafb0905264413501df60d90a92ca32df8a2011cbfb4876ddff5ceb20c8f165";
          imageName = "registry.access.redhat.com/ubi9/ubi";
          name = "registry.access.redhat.com/ubi9/ubi";
          sha256 = "sha256-h8nS/On6+ZzIbA/HdsIVoyQiVbExanOvWTzh6QYfmpM=";
        };

        cachedOCIImage9 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:ab7306ccfa8168ad63f4e91a6217a73decdd641c49c7274212a93df19ee88938";
          imageName = "docker.io/nixos/nix";
          name = "docker.io/nixos/nix";
          sha256 = "sha256-LSaFuoul5w8ukd6QPaQ5gDIDht+W0IgQ3uJYJqopRO0=";
        };

        # docker.nix-community.org/nixpkgs/nix-flakes
        # sha256:0bf7db1664ec847869879e275703e3e5c5aff6ca16a9451c4d9d701190dabf75

        cachedOCIImage10 = prev.dockerTools.pullImage {
          finalImageTag = "15.0";
          imageDigest = "sha256:f03654b5540e28cd9263580519844d531e68bc5885a4bfcc70a335871e23f433";
          imageName = "docker.io/aclemons/slackware";
          name = "docker.io/aclemons/slackware";
          sha256 = "sha256-HyCl6OVBQdfNMt37An4jpA5/njvFzVihwnlprLU4QUY=";
        };

        cachedOCIImage11 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:26ba972f0c06beadcec4796ec3037e0bec32af4d255edb68a528bd98304c74f4";
          imageName = "docker.io/voidlinux/voidlinux";
          name = "docker.io/voidlinux/voidlinux";
          sha256 = "sha256-P3AQID4vWQkcxTpQceoZDfnYSqAfz+aMEHehPelNAoY=";
        };

        cachedOCIImage12 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:0d33aceef1475d7b61c1e7966eaa3328fafc6d0808824859cb825c4befcf58ca";
          imageName = "docker.io/osuosl/gentoo";
          name = "docker.io/osuosl/gentoo";
          sha256 = "sha256-iYkjYYRYItw35TZ7sjGm3gKbHsdDkVla/bvbe7aKy5w=";
        };

        #
        cachedOCIImageT1 = prev.dockerTools.pullImage {
          finalImageTag = "7.0.15-bookworm";
          imageDigest = "sha256:20a6f887aab57c17958378af10e0942d09d1b33b63dc3c690db5cdc3564358a6";
          imageName = "docker.io/library/redis";
          name = "docker.io/library/redis";
          sha256 = "sha256-UMp3zMVB09PczktXxKl/0HgAg9y/jCuHPmlo6BzirSE=";
        };

        cachedOCIImageT2 = prev.dockerTools.pullImage {
          finalImageTag = "7.2.4-alpine3.19";
          imageDigest = "sha256:1b503bb77079ba644371969e06e1a6a1670bb34c2251107c0fc3a21ef9fdaeca";
          imageName = "docker.io/library/redis";
          name = "docker.io/library/redis";
          sha256 = "sha256-UMp3zMVB09PczktXxKl/0HgAg9y/jCuHPmlo6BzirSE=";
        };

        cachedOCIImageT3 = prev.dockerTools.pullImage {
          finalImageTag = "1.25.3-bookworm";
          imageDigest = "sha256:84c52dfd55c467e12ef85cad6a252c0990564f03c4850799bf41dd738738691f";
          imageName = "docker.io/library/nginx";
          name = "docker.io/library/nginx";
          sha256 = "sha256-P4K5HoROtIrAd1H2tqAmD2gyNlocHpE1tDC6xvZyZHA=";
        };

        cachedOCIImageT4 = prev.dockerTools.pullImage {
          finalImageTag = "1.25.3-alpine-slim";
          imageDigest = "sha256:4b4bc9f88bd63fb3abc8fd4f5ad7f16554589ca1fca8d3a53416ff55b59b6f80";
          imageName = "docker.io/library/nginx";
          name = "docker.io/library/nginx";
          sha256 = "sha256-AizG6WEYk6Dg4V0ZJAe4Ge3pV+S93qFpVuj9DzJ1Pms=";
        };

        cachedOCIImageT5 = prev.dockerTools.pullImage {
          finalImageTag = "25.0.3-dind-rootless";
          imageDigest = "sha256:a67a4f149cd62d8c2023778ddd65e82e3895b21c10b8a5a19fd18b3dd1c3c96a";
          imageName = "docker.io/library/docker";
          name = "docker.io/library/docker";
          sha256 = "sha256-4GE62SX+nhbEEBnKegKDGzRKZSJwgj6dayNa28Z0uXE=";
        };

        cachedOCIImageT6 = prev.dockerTools.pullImage {
          finalImageTag = "v4.9.0";
          imageDigest = "sha256:dd135e0fa4e1fe80c533187959c62005f1255d0b2a58b736f7ddfe8a4f39cb80";
          imageName = "quay.io/podman/stable";
          name = "quay.io/podman/stable";
          sha256 = "sha256-O2R7ZMIV4d4CrQeqDvnUJ9TOaV9nORWdIngpl6pAbtU=";
        };

        cachedOCIImageT7 = prev.dockerTools.pullImage {
          finalImageTag = "1.36.1-musl";
          imageDigest = "sha256:bc6e0c5c7fdd36de6af8274b26b60d1a1c5d2cef748bebcba5395227d8525050";
          imageName = "docker.io/library/busybox";
          name = "docker.io/library/busybox";
          sha256 = "sha256-/Op6lJ6Thb7nt70q4JeLZSBZx05M2pORbqW6Q3IBrn8=";
        };

        cachedOCIImageT8 = prev.dockerTools.pullImage {
          finalImageTag = "0.8.10";
          imageDigest = "sha256:5b8b598812628009da5273dfac076ad4fa2af505c6efdf5e24b99ab41ed4eab9";
          imageName = "docker.io/tianon/toybox";
          name = "docker.io/tianon/toybox";
          sha256 = "sha256-04UxzXCPhMzgo4cbcAAsJgcWCS24xnNkfSSZ3vVPcGw=";
        };

        cachedOCIImageT9 = prev.dockerTools.pullImage {
          finalImageTag = "nixos-23.11";
          imageDigest = "sha256:925f524987672b6922b21ab415765373481e94eac2f1e8731dc5303e19052ddb";
          imageName = "docker.io/nixpkgs/nix-flakes";
          name = "docker.io/nixpkgs/nix-flakes";
          sha256 = "sha256-P1dQWdvcs1tZupsJ37+l7y8gLOMyxi7yrV8wC2o0DwM=";
        };

        cachedOCIImageT10 = prev.dockerTools.pullImage {
          finalImageTag = "1.75.0";
          imageDigest = "sha256:764e13f0abe8075a127c262f32e42cd04f14f3452dcf3f6ccf6a6d31bb71ac37";
          imageName = "docker.io/library/rust";
          name = "docker.io/library/rust";
          sha256 = "";
        };

        cachedOCIImageT11 = prev.dockerTools.pullImage {
          finalImageTag = "1.75.0-alpine3.18";
          imageDigest = "sha256:73adfdb2cb99fedbdb6b3c888de0c953e15b775da7cf772349fdc127d0db6b3a";
          imageName = "docker.io/library/rust";
          name = "docker.io/library/rust";
          sha256 = "";
        };

        cachedOCIImageT12 = prev.dockerTools.pullImage {
          finalImageTag = "alpine3.19-jdk21";
          imageDigest = "sha256:ce9efab6ebd26398aad3394088078bba4e25ce605d96dc4b802e9a972abd4566";
          imageName = "jenkins/jenkins";
          name = "jenkins/jenkins";
          sha256 = "";
        };

        cachedOCIImageT13 = prev.dockerTools.pullImage {
          finalImageTag = "latest";
          imageDigest = "sha256:95f36213b7a015ac3efe1d743cc3e2f7feea0ba19d4d80aa866fbf226c1e1453";
          imageName = "ollama/ollama";
          name = "ollama/ollama";
          sha256 = "sha256-4JpCYrmE0BOccXhLZ0ftxusfErBpWN5dQkWwJp3tTmg=";
        };
        #

        # nix --option sandbox-dev-shm-size 87% show-config | grep shm-size
        cachedOCIImageJupyter = prev.dockerTools.pullImage {
          finalImageTag = "2024-01-08";
          imageDigest = "sha256:113439c25115736fbc26ad0c740349816079003587d1bc63d7eaf48a0b3a55c3";
          imageName = "quay.io/jupyter/scipy-notebook";
          name = "quay.io/jupyter";
          sha256 = "sha256-w84jkrU8sYKS/GaA3NhNyYoWFnpIFJsux2IjLa3y128=";
        };

        ##
        nixOsOCI = nixos-generators.nixosGenerate {
          # pkgs = final.pkgs;
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            # "${path}/nixos/tests/common/x11.nix"
            ({ pkgs, ... }: {
              users.users.nixuser = {
                createHome = true;
                description = "nix user";
                home = "/home/nixuser";
                homeMode = "0700";
                initialPassword = "1"; # TODO: hardening
                isSystemUser = true; # isNormalUser = true;
                shell = pkgs.bashInteractive; # What other would be best? None for hardening?!
                uid = 1234;

                extraGroups = [
                  "kvm"
                  "nixgroup"
                  "wheel"
                ];

                packages = with pkgs; [
                  hello
                  xorg.xclock
                ];
              };

              users.users.nixuser.group = "nixgroup";
              users.groups.nixgroup.gid = 5678;
              users.groups.nixgroup = { };

              users.users."root".initialPassword = "r00t"; # https://discourse.nixos.org/t/how-to-disable-root-user-account-in-configuration-nix/13235/7

              services.getty.autologinUser = "nixuser"; # "root";
              networking = {
                hostName = "nixos";
                nameservers = [ "1.1.1.1" "8.8.8.8" ]; # TODO: Why? Why the root user does not need it?
                networkmanager.enable = true;
                useDHCP = false; # TODO: Why?
              };

              # nixpkgs.config.allowUnfree = true;

              nix = {
                extraOptions = "experimental-features = nix-command flakes repl-flake";
                package = pkgs.nixVersions.nix_2_10; # package = pkgsCross.aarch64-multiplatform-musl.pkgsStatic.nix;
                registry.nixpkgs.flake = nixpkgs;
                settings = {
                  keep-build-log = true;
                  keep-derivations = true;
                  keep-env-derivations = true;
                  keep-failed = false;
                  keep-going = true;
                  keep-outputs = true;
                };
              };

              boot.readOnlyNixStore = true;
              boot.tmp.useTmpfs = true;
              boot.tmp.cleanOnBoot = true;
              boot.tmp.tmpfsSize = "85%";

                #boot.kernelModules = [
                #  "binfmt_misc"
                #];

              environment.etc."channels/nixpkgs".source = nixpkgs.outPath;

              environment.systemPackages = with pkgs; [
                #bashInteractive
                #cacert
                #coreutils
                #figlet
                hello
                nodejs
                #sudo
                #xorg.xclock
              ];

              environment.variables = {
                DISPLAY = ":0";
                NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
                SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
              };

              # Enable the X11 windowing system.
              services.xserver.enable = true;

              # https://github.com/NixOS/nixpkgs/issues/102137#issuecomment-721298401
              environment.noXlibs = prev.lib.mkForce false;

              # https://nixos.org/manual/nixos/stable/#sec-xfce
              # services.xserver.desktopManager.xfce.enable = true;
              # services.xserver.desktopManager.xfce.enableScreensaver = false;

              system.stateVersion = "23.11"; # TODO: document it.
            })
          ];
          format = "docker";
        };

        cachedOCIImageDockerToolsExample0 = prev.dockerTools.examples.bash;
        cachedOCIImageDockerToolsExample1 = prev.dockerTools.examples.bashLayeredWithUser;
        cachedOCIImageDockerToolsExample2 = prev.dockerTools.examples.redis;
        cachedOCIImageDockerToolsExample3 = prev.dockerTools.examples.nix;
        cachedOCIImageDockerToolsExample4 = prev.dockerTools.examples.editors;
        cachedOCIImageDockerToolsExample5 = prev.dockerTools.examples.no-store-paths;

        cachedOCIImageK3sPause =
          let
            imageEnv = prev.buildEnv {
              name = "k3s-pause";
              paths = with prev.pkgsStatic; [ tini (hiPrio coreutils) busybox ];
              pathsToLink = [ "/bin" ];
            };

            pauseImage = prev.dockerTools.buildImage {
              name = "k3s-pause";
              tag = "latest";
              copyToRoot = imageEnv;
              config.Entrypoint = [ "/bin/tini" "--" "/bin/sleep" "inf" ];
            };
          in
          pauseImage;

        # Inspired by: https://github.com/NixOS/nixpkgs/issues/176081
        cachedOCIImageChromium = prev.dockerTools.streamLayeredImage {
          name = "chromium";
          tag = "${prev.chromium.version}";
          config = {
            copyToRoot = [
              (prev.runCommand "tmp" { } "mkdir -pv $out/tmp $out/var/tmp")
            ];

            # Entrypoint = [ "${prev.steam-run}/bin/steam-run" ];
            Cmd = [
              "${prev.chromium}/bin/chromium"
              "--headless=new"
              "--no-default-browser-check"
              "--no-first-run"
              "--disable-extensions"
              "--disable-background-networking"
              "--disable-background-timer-throttling"
              "--disable-backgrounding-occluded-windows"
              "--disable-renderer-backgrounding"
              "--disable-breakpad"
              "--disable-client-side-phishing-detection"
              "--disable-crash-reporter"
              "--disable-default-apps"
              "--disable-dev-shm-usage"
              "--disable-device-discovery-notifications"
              "--disable-namespace-sandbox"
              "--user-data-dir=/tmp/chrome-data-dir"
              "--disable-translate"
              "--autoplay-policy=no-user-gesture-required"
              "--window-size=1366x768"
              "--remote-debugging-address=127.0.0.1"
              "--remote-allow-origins=*"
              "--remote-debugging-port=0"
              "--no-sandbox"
              "--disable-gpu"
            ];
            Env = [
              "FONTCONFIG_FILE=${prev.fontconfig.out}/etc/fonts/fonts.conf"
              "FONTCONFIG_PATH=${prev.fontconfig.out}/etc/fonts/"
              "HOME=/tmp"
              "DISPLAY=:0"
            ];
          };
        };

        /*
          (prev.runCommand "tmp" { } "mkdir -pv $out/tmp $out/var")

          docker \
          run \
          --interactive=true \
          --rm=true \
          --mount=type=tmpfs,destination=/tmp \
          --tty=true \
          nix \
          --option build-users-group "" \
          --extra-experimental-features nix-command \
          --extra-experimental-features flakes \
          run \
          nixpkgs#hello


          docker.io/library/

          ls -alh "$HOME"/.nix-profile/bin

          nix --store /home/abcuser/.local/share/nix/root show-config
          nix --store /home/abcuser/.local/share/nix/root profile list


          nix --store /home/abcuser/.local/share/nix/root profile install nixpkgs#hello


          strace -f -s99999 -e trace=execve nix build nixpkgs#hello

          strace -f -s99999 -e trace=execve nix shell nixpkgs#hello --command hello

          strace -f -s99999 -e trace=execve nix run nixpkgs#hello

          strace -f -s99999 -e trace=execve nix profile install nixpkgs#hello

          nix \
          --store ~/.local/share/nix/root \
          shell \
          nix \
          --command \
          sh \
          -c \
          '
          nix \
          --store ~/.local/share/nix/root \
          profile \
          install \
          --profile \
          ~/.local/share/nix/root/nix/var/nix/profiles/per-user/$(id -nu) nixpkgs#hello
          '


          NIX_STORE="$HOME"/.local/share/nix/root
          NIX_PROFILES="$NIX_STORE"/nix/var/nix/profiles/per-user


          ls -alh "$NIX_STORE"$(readlink "$NIX_PROFILES"$(readlink "$NIX_PROFILES"/$USER))
          ls -alh "$NIX_PROFILES"/$(readlink "$NIX_PROFILES"/$USER)

          ln \
          -fsv \
          "$NIX_STORE"$(readlink "$NIX_PROFILES"$(readlink "$NIX_PROFILES"/$USER)) \
          "$NIX_PROFILES"/$(readlink "$NIX_PROFILES"/$USER)

          ln -fsv \
          /home/abcuser/.local/share/nix/root/nix/store/63l345l7dgcfz789w1y93j1540czafqh-hello-2.12.1/bin/hello \
          $(readlink -f /home/abcuser/.nix-profile)/bin/hello

          nix \
          --option nix-path nixpkgs=flake:nixpkgs \
          eval --impure --expr 'builtins.nixPath'



          nix run home-manager/release-23.11 -- init --switch
          cd "$HOME"/.config/home-manager/
          rm -fv flake.lock

          nix \
          flake \
          update \
          --override-input nixpkgs github:NixOS/nixpkgs/c5101e457206dd437330d283d6626944e28794b3 \
          --override-input home-manager github:nix-community/home-manager/652fda4ca6dafeb090943422c34ae9145787af37

        */
        cachedOCIImageBaseNix = prev.dockerTools.streamLayeredImage {
          name = "nix";
          tag = "latest";
          config = {
            Env = [
              "NIX_SSL_CERT_FILE=${prev.cacert}/etc/ssl/certs/ca-bundle.crt"
              "SSL_CERT_FILE=${prev.cacert}/etc/ssl/certs/ca-bundle.crt"
              # "NIX_PATH=nixpkgs=''${prev.path}"
              "PATH=${prev.pkgsStatic.busybox}/bin:${prev.pkgsStatic.nix}/bin"
              "USER=root"
            ];
            Entrypoint = [ "nix" ];
            User = "0:0";
          };
        };

        # docker run --interactive=true --rm=true --tty=true base-enva sh -c 'ls -alh /'
        cachedOCIImageBaseA = prev.dockerTools.buildImage {
          name = "base-enva";
          tag = "latest";
          # enableFakechroot = true;
          runAsRoot = ''
            mkdir -pv ./bin
            cp -v ${prev.pkgsStatic.zsh.out}/bin/zsh ./bin/

            # rm -frv /nix
          '';
          config = {
            # Entrypoint = [ "${prev.pkgsStatic.busybox}/bin/busybox" ];
            # Cmd = [ "busybox" ];
            User = "0:0";
            Env = [
              "PATH=/bin"
              "USER=root"
            ];
            #            contents = prev.buildEnv {
            #              name = "busybox-env";
            #              paths = with prev.pkgsStatic; [
            #                busybox
            #              ];
            #              pathsToLink = [ "/bin" ];
            #            };
          };

          #includeStorePaths = false;
          #          extraCommands = ''
          #            mkdir -pv ./bin
          #            cp -v ${prev.pkgsStatic.zsh}/bin/zsh ./bin/
          #            rm -frv /nix
          #          '';
          # enableFakechroot = true;
          # fakeRootCommands = ''
          #   mkdir /bin
          #   ln -sv ${prev.pkgsStatic.busybox}/bin/busybox /bin/busybox
          # '';
        };

        cachedOCIImageBaseB = prev.dockerTools.streamLayeredImage {
          name = "base-envb";
          tag = "latest";
          config.copyToRoot = prev.buildEnv {
            name = "zsh";
            # extraPrefix = "/bin";
            pathsToLink = [ "/bin" ];
            paths = [
              prev.pkgsStatic.zsh # the binary with $out/bin/zsh
            ];
          };
          config.Env = [
            "PATH=/bin"
            "USER=root"
          ];
          # config.Cmd = [ "busybox" ];
          includeStorePaths = true;
          #extraCommands = ''
          #  mkdir -pv /bin
          #  ln -fsv ${prev.pkgsStatic.busybox}/bin/busybox /bin/busybox
          #'';
          # enableFakechroot = false;
        };

        cachedOCIImageBaseW = prev.dockerTools.buildImage {
          name = "base-envw";
          tag = "latest";
          config = {
            # Entrypoint = [ "/bin/busybox" ];
            Cmd = [ "busybox" ]; # TODO
            User = "0:0";
            Env = [
              "PATH=/bin:/bin/busybox"
              "USER=root"
            ];
            #            copyToRoot = prev.buildEnv {
            #              name = "busybox-env";
            #              paths = with prev.pkgsStatic; [
            #                busybox
            #              ];
            #              pathsToLink = [ "/bin" ];
            #            };

            extraCommands = ''
              # mkdir /bin
              ln -fsv ${prev.pkgsStatic.busybox}/bin/busybox /bin/busybox
            '';
          };
        };

        cachedOCIImageBasex =
          let
            nonRootShadowSetup = { user, group ? user, uid, gid ? uid }: with prev; [
              (
                writeTextDir "etc/shadow" ''
                  root:!x:::::::
                  ${user}:!:::::::
                ''
              )
              (
                writeTextDir "etc/passwd" ''
                  root:x:0:0::/root:${runtimeShell}
                  ${user}:x:${toString uid}:${toString gid}:${toString group}:/home/${user}:/bin/sh
                ''
              )
              (
                writeTextDir "etc/group" ''
                  root:x:0:
                  ${user}:x:${toString gid}:
                ''
              )
              (
                writeTextDir "etc/gshadow" ''
                  root:x::
                  ${user}:x::
                ''
              )
            ];
          in
          prev.dockerTools.streamLayeredImage {
            name = "base-env0";
            tag = "latest";
            config = {
              #            contents = prev.buildEnv {
              #              name = "base-env";
              #              paths = with prev.dockerTools; [
              #                # fakeNss
              #                # (prev.runCommand "tmp" { } "mkdir -pv $out/tmp $out/var")
              #              ];
              #              pathsToLink = [ "/bin" "/tmp" "/var" "/etc" ];
              #            } ;

              extraCommands = ''
                cp -Lrv ${prev.pkgsStatic.busybox}/* .
                cp -Lrv ${prev.pkgsStatic.busybox}/* ./aaa
                cp -Lrv ${prev.pkgsStatic.busybox}/* ./bbb

                rm -frv /nix
              '';

              Env = [
                "PATH=${prev.pkgsStatic.busybox}/bin:"
              ];

              Entrypoint = [ "sh" ];
              Tty = true;
              User = "appuser:appgroup";
            };
          };

        # https://ryantm.github.io/nixpkgs/builders/images/dockertools/#ssec-pkgs-dockerTools-helpers
        cachedOCIImageBase1 = prev.dockerTools.streamLayeredImage {
          name = "base-env1";
          tag = "latest";
          config = {
            contents = prev.buildEnv {
              name = "base-env";
              paths = with prev.dockerTools; [
                binSh
                caCertificates
                fakeNss
                usrBinEnv
              ];
            };

            Env = [
              "PATH=${(prev.lib.getBin prev.pkgsStatic.bashInteractive)}/bin:${(prev.lib.getBin prev.pkgsStatic.coreutils)}/bin"
            ];
            User = "1234";
          };
        };

        /*
        docker run --privileged --interactive=true \
        --rm=true --tty=true \
        --runtime=nvidia --gpus all cuda-env-docker:latest
        */
        cachedOCIImageCUDA = prev.dockerTools.buildImage {
          name = "cuda-env-docker";
          tag = "latest";
          copyToRoot = prev.buildEnv {
            name = "image-root";
            pathsToLink = [ "/bin" ];
            paths = with prev; [
              cudaPackages.cudatoolkit
              # linuxKernel.packages.linux_6_1.nvidia_x11
              python3Packages.pytorchWithCuda.cudaPackages.cudatoolkit
              python3Packages.pytorchWithCuda.cudaPackages.cudatoolkit.lib
              stdenv.cc.cc.lib
            ];
          };
          config = {
            Env = [
              # "LD_LIBRARY_PATH=/usr/lib64/"
              "LD_LIBRARY_PATH=${prev.stdenv.cc.cc.lib}/lib:${prev.python3Packages.pytorchWithCuda.cudaPackages.cudatoolkit}/lib:${prev.python3Packages.pytorchWithCuda.cudaPackages.cudatoolkit.lib}/lib:/usr/lib64"
              "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
              "NVIDIA_VISIBLE_DEVICES=all"
            ];
            Cmd = [ "/bin/nvidia-smi" ];
          };
        };

        cachedOCIImageGlued =
          let
            sudo = prev.pkgsStatic.sudo.override {
              pam = null;
              withInsults = true;
            };
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "glued";
            tag = "latest";
            includeStorePaths = false;
            extraCommands = ''

              mkdir -pv -m1777 ./tmp
              mkdir -pv ./etc/ssl/certs
              mkdir -pv -m0700 ./home/${user}/.local/bin
              mkdir -pv -m1777 ./home/${user}/tmp
              mkdir -pv -m1735 ./nix/var/nix

              mkdir -pv ./bin/{bash/bin,coreutils/bin}
              cp -aTrv ${prev.pkgsStatic.bashInteractive}/bin/ ./bin/bash/bin/
              cp -aTrv ${prev.pkgsStatic.coreutils}/bin/ ./bin/coreutils/bin/

              cp -aTrv ${prev.pkgsStatic.nix}/bin/ ./home/${user}/.local/bin/
              cp -v ${prev.cacert}/etc/ssl/certs/ca-bundle.crt ./etc/ssl/certs/

              cp -aTrv ${prev.path}/ ./home/${user}/nixpkgs

              # cp -v ''\${sudo}/bin/sudo ./bin/

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              # chmod -v 4755 ./bin/sudo
              chown -Rv "${uid}:${gid}" ./nix ./home/${user}/
            '';

            config.Entrypoint = [ "/bin/bash/bin/bash" ];
            # config.Entrypoint = [ "/home/${user}/.local/bin/nix" ];
            config.User = "${user}:${group}";
            config.WorkingDir = "/home/${user}";
            # config.Cmd = [ "-l" ];
            config.Env = [
              "PATH=/bin:/home/${user}/.local/bin:/bin/bash/bin:/bin/coreutils/bin"
              # "PATH=/bin:/home/${user}/.local/bin:/bin/bash/bin:/bin/coreutils/bin"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "TMPDIR=/home/${user}"
              # "SSL_CERT_FILE=''\${prev.cacert}/etc/ssl/certs/ca-bundle.crt"
              # "TZDIR=''\${pkgs.tzdata}/share/zoneinfo" # https://www.reddit.com/r/NixOS/comments/16zkur1/buildlayeredimage_and_timezones_in_generated/
              # "NIX_PATH=nixpkgs=''\${prev.path}"
            ];
          };

        /*
          cat > Containerfile << 'EOF'
          FROM static-nix-cacert:latest as develop-hello

          RUN \
           nix \
           develop \
           nixpkgs#python3Full \
           --profile /home/appuser/develop-hello \
           --command \
           sh \
           -c \
           'source $stdenv/setup && cd "$(mktemp -d)" && genericBuild'

          EOF

          docker \
          build \
          --file Containerfile \
          --tag develop-hello-nix \
          .


          docker \
          run \
          --interactive=true \
          --network=none \
          --privileged=false \
          --rm=true \
          --tty=false \
          develop-hello-nix:latest \
          build --no-link --rebuild --print-out-paths nixpkgs#pkgsStatic.hello


          docker \
          run \
          --interactive=true \
          --network=none \
          --privileged=false \
          --rm=true \
          --tty=false \
          develop-hello-nix:latest \
           develop \
           /home/appuser/develop-hello \
           --command \
           sh \
           -c \
           'source $stdenv/setup && cd "$(mktemp -d)" && genericBuild'

          podman \
          run \
          --device=/dev/fuse \
          --device=/dev/kvm \
          --env="DISPLAY=${DISPLAY:-:0.0}" \
          --interactive=true \
          --mount=type=tmpfs,tmpfs-size=5G,destination=/tmp \
          --privileged=true \
          --publish=5000:5000 \
          --rm=true \
          --tty=true \
          localhost/busybox-ca-certificates-nix:latest \
          nix \
          shell \
          nixpkgs#pkgsStatic.nix \
          -c \
          sh
        */

        cachedOCIImageStaticNixCacert =
          let
            sudo = prev.pkgsStatic.sudo.override {
              pam = null;
              withInsults = true;
            };
            user = "appuser";
            group = "appgroup";
            uid = "1234";
            gid = "9876";
          in
          prev.dockerTools.buildLayeredImage {
            name = "static-nix-cacert";
            tag = "latest";
            includeStorePaths = false;
            extraCommands = ''

              mkdir -pv -m1777 ./tmp
              mkdir -pv ./etc/ssl/certs
              mkdir -pv -m0700 ./bin ./home/${user}/.local/bin
              mkdir -pv -m1777 ./home/${user}/tmp
              mkdir -pv -m1735 ./nix/var/nix

              cp -aTrv ${prev.pkgsStatic.busybox-sandbox-shell}/bin/busybox ./bin/sh
              cp -aTrv ${prev.pkgsStatic.nix}/bin/ ./home/${user}/.local/bin/
              cp -v ${prev.cacert}/etc/ssl/certs/ca-bundle.crt ./etc/ssl/certs/

              echo 'root:x:0:0::/root:/bin/sh' >> ./etc/passwd
              echo "${user}:x:${uid}:${gid}:${group}:/home/${user}:/bin/sh" >> ./etc/passwd

              echo 'root:x:0:' >> ./etc/group
              echo "${group}:x:${gid}:${user}" >> ./etc/group
            '';

            fakeRootCommands = ''
              chown -Rv "${uid}:${gid}" ./nix ./home/${user}/
            '';

            config.Entrypoint = [ "/home/${user}/.local/bin/nix" ];
            config.User = "${user}:${group}";
            # config.Cmd = [ "nix" ];
            config.WorkingDir = "/home/${user}";
            config.Env = [
              "PATH=/bin:/home/${user}/.local/bin"
              "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
              "NIX_CONFIG=extra-experimental-features = nix-command flakes"
              "TMPDIR=/home/${user}"
            ];
          };

        cachedOCIImagepkgsStaticCoreutilsBashInteractive = prev.dockerTools.buildLayeredImage {
          name = "static-bash-interactive-coreutils";
          tag = "latest";
          includeStorePaths = false;
          extraCommands = ''
            mkdir -pv ./bin/{bash/bin,coreutils/bin}
            cp -aTrv ${prev.pkgsStatic.bashInteractive}/bin/ ./bin/bash/bin/
            cp -aTrv ${prev.pkgsStatic.coreutils}/bin/ ./bin/coreutils/bin/
          '';
          config.Entrypoint = [ "/bin/bash/bin/bash" ];
          config.Cmd = [ "-l" ];
          config.Env = [
            "PATH=/bin:/bin/bash/bin:/bin/coreutils/bin"
          ];
        };

        cachedOCIImageStaticPython3 = prev.dockerTools.buildLayeredImage {
          name = "static-python3";
          tag = "latest";
          includeStorePaths = false;
          extraCommands = ''
            cp -aTrv ${prev.python3} .
          '';
          config.Entrypoint = [ "python" ];
          config.Cmd = [ "-c 'import this'" ];
        };

        cachedOCIImageStaticBusyboxSandboxShell = prev.dockerTools.buildLayeredImage {
          name = "static-busybox-sandbox-shell";
          tag = "${prev.pkgsStatic.busybox-sandbox-shell.version}";
          includeStorePaths = false;
          extraCommands = ''
            cp -aTrv ${prev.pkgsStatic.busybox-sandbox-shell} .
          '';
          config.Entrypoint = [ "sh" ];
          config.Cmd = [ "-l" ];
        };

        cachedOCIImageStaticBusybox = prev.dockerTools.buildLayeredImage {
          name = "static-busybox";
          tag = "latest";
          includeStorePaths = false;
          extraCommands = ''
            cp -aTrv ${prev.pkgsStatic.busybox} .
          '';
          config.Entrypoint = [ "sh" ];
          config.Cmd = [ "-l" ];
        };

        cachedOCIImageStaticBash = prev.dockerTools.buildLayeredImage {
          name = "static-bash";
          tag = "latest";
          includeStorePaths = false;
          extraCommands = ''
            mkdir -pv ./bin
            cp -aTv ${prev.pkgsStatic.bash}/ .
          '';
          config.Entrypoint = [ "bash" ];
          config.Cmd = [ "--login" ];
        };

        cachedOCIImageStaticBashInteractive = prev.dockerTools.buildLayeredImage {
          name = "static-bash-interactive";
          tag = "latest";
          includeStorePaths = false;
          extraCommands = ''
            mkdir -pv ./bin
            cp -aTv ${prev.pkgsStatic.bashInteractive}/ .
          '';
          config.Entrypoint = [ "bash" ];
          config.Cmd = [ "--login" ];
        };

        cachedOCIImageStaticZsh = prev.dockerTools.buildLayeredImage {
          name = "static-zsh";
          tag = "latest";
          includeStorePaths = false;
          extraCommands = ''
            mkdir -pv ./bin
            cp -aTv ${prev.pkgsStatic.zsh}/bin/ ./bin/
          '';
          config.Entrypoint = [ "zsh" ];
          config.Cmd = [ "--login" ];
        };

        cachedOCIImageStaticRedis = prev.dockerTools.buildLayeredImage {
          name = "static-redis";
          tag = "latest";
          includeStorePaths = false;
          extraCommands = ''
            mkdir -pv ./bin
            cp -aTv ${prev.pkgsStatic.redis}/bin/ ./bin/
          '';
          config.Cmd = [ "redis-server" ];
        };

        cachedOCIImageStaticXorgXclock = prev.dockerTools.streamLayeredImage {
          # https://github.com/NixOS/nixpkgs/issues/176081
          name = "static-xorg-xclock";
          tag = "latest";
          config = {
            copyToRoot = prev.buildEnv {
              name = "xclock-env";
              paths = with prev.pkgsStatic; [
                # busybox-sandbox-shell
                bashInteractive
                coreutils
                hello
                xorg.xclock
                (prev.runCommand "tmp" { } "mkdir -pv $out/tmp $out/var")
              ]
              ++
              [
                prev.fontconfig

                (prev.symlinkJoin {
                  name = "fake-nss";
                  paths = [
                    (writeTextDir "etc/passwd" ''nixuser:x:12345:56789:nixgroup:/var/empty:/bin/sh'')
                    (writeTextDir "etc/group" ''nixgroup:x:56789:nixuser'')
                    (writeTextDir "etc/xpto" ''nixgroup:x:56789:nixuser'')
                    (runCommand "var-empty" { } ''mkdir -pv $out/var/empty'')
                  ];
                })

              ];
              pathsToLink = [ "/bin" "/tmp" "/var" "/etc" ];
            };

            Env = [
              "FONTCONFIG_FILE=${prev.fontconfig.out}/etc/fonts/fonts.conf"
              "FONTCONFIG_PATH=${prev.fontconfig.out}/etc/fonts/"
              # "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              # "PATH=${pkgs.coreutils}/bin:${pkgs.hello}/bin:${pkgs.findutils}/bin"
              # :${pkgs.coreutils}/bin:${pkgs.fontconfig}/bin
              "PATH=/bin:${prev.bashInteractive}/bin:${prev.coreutils}/bin"

              # https://access.redhat.com/solutions/409033
              # https://github.com/nix-community/home-manager/issues/703#issuecomment-489470035
              # https://bbs.archlinux.org/viewtopic.php?pid=1805678#p1805678
              "LC_ALL=C"
              "DISPLAY=:0"
              "HOME=/var/empty"
            ];

            Cmd = [ "xclock" ];

            User = "nixuser:nixgroup";

            Tty = true;
          };
        };

        cachedOCIImageFirefox = prev.dockerTools.buildImage {
          # https://github.com/NixOS/nixpkgs/issues/176081
          name = "firefox";
          tag = "${prev.firefox.version}";
          config = {
            contents = with prev; [
              pkgsStatic.busybox-sandbox-shell
              (prev.runCommand "creates-var-tmp" { }
                "mkdir -pv  $out/tmp $out/var/tmp")
            ];

            # Tmpfs = {
            #   "/tmp" = { };
            # };

            Env = [
              "FONTCONFIG_FILE=${prev.fontconfig.out}/etc/fonts/fonts.conf"
              "FONTCONFIG_PATH=${prev.fontconfig.out}/etc/fonts/"
              "PATH=/bin:${prev.pkgsStatic.busybox-sandbox-shell}/bin:${prev.firefox}/bin"

              # https://access.redhat.com/solutions/409033
              # https://github.com/nix-community/home-manager/issues/703#issuecomment-489470035
              # https://bbs.archlinux.org/viewtopic.php?pid=1805678#p1805678
              "LC_ALL=C" # "LC_ALL=en_US.UTF-8"
              "DISPLAY=:0" # TODO: it is hardcoded
              "HOME=/var"
            ];

            WorkingDir = "/var"; # Not an must?

            # Entrypoint = [ "bash" ];
            # Entrypoint = [ "sh" ];
            maxLayers = 125;

            # User = 1234;

            Cmd = [ "firefox" ];

            Volumes = {
              "/tmp/.X11-unix:ro" = { };
            };
          };

          runAsRoot = "
            #!${prev.stdenv}
            ${prev.dockerTools.shadowSetup}

            groupadd --gid 56789 nixgroup
            useradd --no-log-init --uid 12345 --gid nixgroup nixuser

            mkdir -pv ./home/nixuser
            chmod 0700 ./home/nixuser
            chown 12345:56789 -R ./home/nixuser

            # https://www.reddit.com/r/ManjaroLinux/comments/sdkrb1/comment/hue3gnp/?utm_source=reddit&utm_medium=web2x&context=3
            mkdir -pv ./home/nixuser/.local/share/fonts
          ";
        };

        /*
          apk \
          add \
          --no-cache \
          adw-gtk3 \
          adwaita-icon-theme \
          adwaita-xfce-icon-theme \
          elogind polkit-elogind \
          gvfs \
          lightdm-gtk-greeter \
          udisks2 \
          xfce4 \
          xfce4-screensaver \
          xfce4-terminal
        */

        isos =
          let
            androidX86_64FullName = "android-x86_64-9.0-r2.iso";
            alpineAarch64FullName = "alpine-standard-3.19.1-aarch64.iso";
            alpineX86_64FullName = "alpine-standard-3.19.1-x86_64.iso";
            ubuntuArm64FullName = "ubuntu-22.04.3-live-server-arm64.iso";
            ubuntuAmd64FullName = "ubuntu-22.04.3-desktop-amd64.iso";

            alpineV3-19-X86_64 = prev.fetchurl {
              name = "${alpineAarch64FullName}";
              url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/${alpineAarch64FullName}";
              hash = "sha256-oUF2r7ZEEHG2tzOk4HY4gUWEjl31vXb2P4HU7OzOilI=";
            };

            alpineV3-19-Amd64 = prev.fetchurl {
              name = "${alpineX86_64FullName}";
              url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/${alpineX86_64FullName}";
              hash = "sha256-Y+YvWlLP5zpssTfsuxEbfUg1aGKh3+UNj92XfXJ9oZI=";
            };

            ubuntu-22-04-Arm64 = prev.fetchurl {
              name = "${ubuntuArm64FullName}";
              url = "https://cdimage.ubuntu.com/releases/22.04/release/${ubuntuArm64FullName}";
              hash = "sha256-pDX285PdpYEXJJDtqfaDwy5JUVingLWh3kIu532Y6Qk=";
            };

            ubuntu-22-04-Amd64 = prev.fetchurl {
              name = "${ubuntuAmd64FullName}";
              url = "https://releases.ubuntu.com/22.04.3/${ubuntuAmd64FullName}";
              hash = "sha256-pDX285PdpYEXJJDtqfaDwy5JUVingLWh3kIu532Y6Qk=";
            };

            androidX86_64 = prev.fetchurl {
              name = "${androidX86_64FullName}";
              url = "https://sourceforge.net/projects/android-x86/files/Release%209.0/${androidX86_64FullName}/download";
              hash = "sha256-9+uPxW8prVQyM13AVBg6zwhsU585kPC26f9YvW30YE4=";
            };

          in
          prev.runCommand "copy-isos"
            {
              nativeBuildInputs = [ prev.coreutils ];
            }
            ''
              mkdir -pv $out/isos

              # cp -v "''${androidX86_64}" $out/isos/
              cp -v "${alpineV3-19-X86_64}" $out/isos/
              cp -v "${alpineV3-19-Amd64}" $out/isos/
              # cp -v "''${ubuntu-22-04-Arm64}" $out/isos/
              # cp -v "''${ubuntu-22-04-Amd64}" $out/isos/

              # https://discourse.nixos.org/t/find-a-fetchurl-file-in-nix-store/18781/3
              # mv -v $out/isos/*-"''${androidX86_64FullName}" $out/isos/"''${androidX86_64FullName}"
              mv -v $out/isos/*-"${alpineAarch64FullName}" $out/isos/"${alpineAarch64FullName}"
              mv -v $out/isos/*-"${alpineX86_64FullName}" $out/isos/"${alpineX86_64FullName}"
              # mv -v $out/isos/*-"''${ubuntuArm64FullName}" $out/isos/"${ubuntuArm64FullName}"
              # mv -v $out/isos/*-"''${ubuntuAmd64FullName}" $out/isos/"''${ubuntuAmd64FullName}"

            '';

      };
    } //
    flake-utils.lib.eachSystem suportedSystems
      (suportedSystem:
        let
          pkgsAllowUnfree = import nixpkgs {
            overlays = [ self.overlays.default ];
            system = suportedSystem;
            config.allowUnfreePredicate = (_: true);
            config.android_sdk.accept_license = true;
            config.allowUnfree = true;
            config.cudaSupport = true;
          };

          pkgsAaarch64 = import nixpkgs {
            overlays = [ self.overlays.default ];
            system = "aarch64-linux";
          };

          # https://gist.github.com/tpwrules/34db43e0e2e9d0b72d30534ad2cda66d#file-flake-nix-L28
          pleaseKeepMyInputs = pkgsAllowUnfree.writeTextDir "bin/.please-keep-my-inputs"
            (builtins.concatStringsSep " " (builtins.attrValues allAttrs));
        in
        {
          # packages.OCIImageChromium = pkgsAllowUnfree.cachedOCIImageChromium;
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

          apps = {
            default = {
              type = "app";
              program = "${self.packages."${suportedSystem}".automatic-vm}/bin/run-nixos-vm";
            };
          };

          devShells.default = pkgsAllowUnfree.mkShell {
            buildInputs = with pkgsAllowUnfree; [
              bashInteractive
              coreutils
              file
              foo-bar
              nix-prefetch-docker
              nixpkgs-fmt
              which

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
          #          nixtheplanet.nixosModules.macos-ventura
          #          {
          #            services.macos-ventura = {
          #              enable = true;
          #              openFirewall = true;
          #              vncListenAddr = "0.0.0.0";
          #            };
          #          }

          # export QEMU_NET_OPTS="hostfwd=tcp::2200-:10022" && nix run .#vm
          # Then connect with ssh -p 2200 nixuser@localhost
          # ps -p $(pgrep -f qemu-kvm) -o args | tr ' ' '\n'
          ({ config, nixpkgs, pkgs, lib, modulesPath, ... }:
            let
              nixuserKeys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExR+PSB/jBwJYKfpLN+MMXs3miRn70oELTV3sXdgzpr";
              pedroKeys = "ssh-ed25519 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPOK55vtFrqxd5idNzCd2nhr5K3ocoyw1JKWSM1E7f9i pedroalencarregis@hotmail.com";

              # --provider libvirt
              alpine318 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/generic/boxes/alpine318/versions/4.3.12/providers/libvirt.box";
                hash = "sha256-6ZI7DMFyJchTMRq/zGUImc+KUu3OU9RbDY6HvwmdTl4=";
              };

              alpine319 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/generic/boxes/alpine319/versions/4.3.12/providers/libvirt/amd64/vagrant.box";
                hash = "sha256-eM8BTnlFnQHR2ZvmRFoauJXRkpO9e7hv/sHsnkKYvF0=";
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

              ubuntu2404 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/alvistack/boxes/ubuntu-24.04/versions/20240415.1.1/providers/libvirt/unknown/vagrant.box";
                hash = "sha256-vuaPLzdWV5ehJdlBBpWqf1nXh4twdHfPdX19bnY4yBk=";
              };

              nixos2305 = pkgs.fetchurl {
                url = "https://app.vagrantup.com/hennersz/boxes/nixos-23.05-flakes/versions/23.05.231106000354/providers/libvirt/unknown/vagrant.box";
                hash = "sha256-x76icAXDReYe9xppwr6b77hTO44EWvBtSx+j41bvMVA=";
              };

              ## Virtualbox
              ubuntu2204Virtualbox = pkgs.fetchurl {
                url = "https://app.vagrantup.com/generic/boxes/ubuntu2204/versions/4.3.8/providers/virtualbox.box";
                hash = "sha256-GYecWtGWCiA+YEYTe7Wlo2LKHk8X/3d0WXJegxK+/rk=";
              };

              # vagrantfiles
              vagrantfileAlpine = pkgs.writeText "vagrantfile-alpine" ''
                Vagrant.configure("2") do |config|
                  # Every Vagrant development environment requires a box. You can search for
                  # boxes at https://vagrantcloud.com/search.
                  config.vm.box = "generic/alpine319"

                  config.vm.provider :libvirt do |v|
                    v.cpus = 5
                    v.memory = "10240"
                  end

                  #
                  # https://stackoverflow.com/a/77347166
                  # config.vm.network "forwarded_port", guest: 5000, host: 5000
                  # https://stackoverflow.com/questions/16244601/vagrant-reverse-port-forwarding#comment23723088_16420720
                  # https://stackoverflow.com/a/77347166
                  # config.ssh.extra_args = ["-L", "5001:localhost:5000"]
                  # config.ssh.extra_args = ["-R", "5001:localhost:5000"]
                  # config.vm.synced_folder '.', '/home/vagrant/code'

                  config.vm.provision "shell", inline: <<-SHELL

                    # xz-utils -> xz-dev
                    apk add --no-cache shadow sudo \
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
                    && apk del tzdata \
                    && echo 'End tzdata stuff!'

                    # https://unix.stackexchange.com/a/400140
                    echo
                    df -h /tmp && sudo mount -o remount,size=9G /tmp/ && df -h /tmp
                    echo

                    #su vagrant -lc \
                    #'
                    #  env | sort
                    #  echo
                    #
                    #  wget -qO- http://ix.io/4Cj0 | sh -
                    #
                    #  echo $PATH
                    #  export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                    #  echo $PATH
                    #
                    #  # wget -qO- http://ix.io/4Bqg | sh -
                    #'

                    mkdir -pv /etc/sudoers.d \
                    && echo 'vagrant:1' | chpasswd \
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
                  # config.vm.box = "generic/ubuntu2304"
                  config.vm.box = "alvistack/ubuntu-24.04"

                  config.vm.provider :libvirt do |v|
                    v.cpus=5
                    v.memory = "6500"
                    # v.memorybacking :access, :mode => "shared"
                    # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1460
                  end

                  config.vm.synced_folder '.', '/home/vagrant/code'

                  config.vm.provision "shell", inline: <<-SHELL

                    # TODO: revise it, test it!
                    # https://unix.stackexchange.com/a/400140
                    # https://stackoverflow.com/a/69288266
                    RAM_IN_GIGAS=$(expr $(sed -n '/^MemTotal:/ s/[^0-9]//gp' /proc/meminfo) / 1024 / 1024)
                    echo "$RAM_IN_GIGAS"
                    # df -h /tmp && sudo mount -o remount,size="$RAM_IN_GIGAS"G /tmp/ && df -h /tmp

                    # Could not access KVM kernel module: Permission denied
                    # qemu-kvm: failed to initialize kvm: Permission denied
                    # qemu-kvm: falling back to tcg
                    echo "Start kvm stuff..." \
                    && (getent group kvm || groupadd kvm) \
                    && sudo usermod --append --groups kvm vagrant \
                    && echo "End kvm stuff!"

                    su vagrant -lc \
                    '
                      # env | sort
                      # echo
                      # wget -qO- http://ix.io/4Cj0 | sh -
                      # echo $PATH
                      # export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"
                      # echo $PATH
                      # wget -qO- http://ix.io/4Bqg | sh -
                    '

                    mkdir -pv /etc/sudoers.d \
                    && echo 'vagrant:1' | chpasswd \
                    && echo 'vagrant ALL=(ALL) PASSWD:SETENV: ALL' > /etc/sudoers.d/vagrant

                  SHELL
                end
              '';


              vagrantfileNixos = pkgs.writeText "vagrantfile-nixos" ''
                Vagrant.configure("2") do |config|
                  config.vm.box = "hennersz/nixos-23.05-flakes"

                  config.vm.provider :libvirt do |v|
                    v.cpus=3
                    v.memory = "4096"
                    # v.memorybacking :access, :mode => "shared"
                    # https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1460
                  end

                  config.vm.synced_folder '.', '/home/vagrant/code'

                  config.vm.provision "shell", inline: <<-SHELL
                    ls -alh
                  SHELL
                end
              '';

              /*
                sudo apt-get update
                sudo apt-get install -y build-essential dkms linux-headers-$(uname -r)
                && sudo mkdir -pv /mnt/cdrom \
                && sudo mount /dev/cdrom /mnt/cdrom \
                && cd /mnt/cdrom \
                && sudo ./VBoxLinuxAdditions.run

                Refs.:
                - https://stackoverflow.com/a/57513296
                - https://stackoverflow.com/a/39633781
                - https://askubuntu.com/a/1435032
              */
              vagrantfileUbuntuVirtualbox = pkgs.writeText "vagrantfile-ubuntu-virtualbox" ''
                Vagrant.configure(2) do |config|
                  config.vm.box = "generic/ubuntu2204"
                  config.vm.provider "virtualbox" do |vb|
                    # Display the VirtualBox GUI when booting the machine
                    vb.gui = true
                  end

                  # Install xfce and VirtualBox additions
                  config.vm.provision "shell", inline: <<-SHELL
                    sudo \
                    apt-get \
                    install \
                    --no-install-recommends \
                    --no-install-suggests \
                    --yes \
                    linux-headers-$(uname -r) build-essential dkms \
                    xfce4 \
                    virtualbox-guest-utils virtualbox-guest-x11
                  SHELL
                  # Permit anyone to start the GUI
                  config.vm.provision "shell", inline: <<-SHELL
                    sudo sed -i 's/allowed_users=.*$/allowed_users=anybody/' \
                      /etc/X11/Xwrapper.config
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
              # breaks if it does not exists?
              # Use systemd boot (EFI only)
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/hda1"; };

          zramSwap = {
            enable = true;
            algorithm = "zstd";
            memoryPercent = 30;
          };

#              systemd.services.docker.serviceConfig.ExecStart = [
#                ""
#                ''
#                  ${cfg.package}/bin/dockerd \
#                    --config-file=${daemonSettingsFile} \
#                    ${cfg.extraOptions}
#                ''];
#              systemd.services.docker.serviceConfig.ExecReload = [
#                ""
#                "${(import nixpkgs {
#                    overlays = [ self.overlays.default ];
#                    system = "aarch64-linux";
#                  }).procps}/bin/kill -s HUP $MAINPID"
#              ];
#              systemd.services.docker.serviceConfig.path = [
#                (import nixpkgs {
#                  overlays = [ self.overlays.default ];
#                  system = "aarch64-linux";
#                }).kmod
#              ];

              virtualisation.vmVariant =
                let
                  isLinuxAndIsx86_64 = (pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64);
                in
                {
                  # It does not work for many hardwares...
                  # About cache miss:
                  # https://www.reddit.com/r/NixOSMasterRace/comments/17e4fvw/new_user_entered_the_lobby/
                  # users.extraGroups.vboxusers.members = if isLinuxAndIsx86_64 then [ "nixuser" ] else [ ];
                  virtualisation.virtualbox.guest.enable = isLinuxAndIsx86_64;
                  # virtualisation.virtualbox.guest.x11 = isLinuxAndIsx86_64;
                  virtualisation.virtualbox.host.enable = isLinuxAndIsx86_64;
                  virtualisation.virtualbox.host.enableExtensionPack = isLinuxAndIsx86_64;
                  # https://github.com/NixOS/nixpkgs/issues/76108#issuecomment-1977580798
                  virtualisation.virtualbox.host.enableHardening = ! isLinuxAndIsx86_64;

                  virtualisation.useNixStoreImage = false;
                  virtualisation.writableStore = true; # TODO: hardening
                  virtualisation.writableStoreUseTmpfs = true; # TODO: hardening

                  virtualisation.docker.enable = true;

                  # virtualisation.docker.package = pkgs.pkgsCross.aarch64-multiplatform.docker;
                  # virtualisation.docker.enableNvidia = true; # How to test?
                  virtualisation.podman.enable = true; # Enabling k8s breaks podman

                  systemd.user.services.podman-custom-bootstrap-1 = {
                    description = "Podman Custom Bootstrap 1";
                    wantedBy = [ "default.target" ];
                    after = [ "podman.service" ];
                    path = with pkgs; [ "/run/wrappers" podman ];

                    script = ''
                      echo "Seeding podman image..."

                      # podman load <"''${pkgs.cachedOCIImageHello1}"
                      # podman load <"''${pkgs.cachedOCIImageHello2}"

                      podman load <"${pkgs.cachedOCIImage0}"
                      # podman load <"''${pkgs.cachedOCIImage1}"
                      # podman load <"''${pkgs.cachedOCIImage2}"
                      # podman load <"''${pkgs.cachedOCIImage3}"
                      # podman load <"''${pkgs.cachedOCIImage4}"
                      # podman load <"''${pkgs.cachedOCIImage5}"
                      # podman load <"''${pkgs.cachedOCIImage6}"
                      # podman load <"''${pkgs.cachedOCIImage7}"
                      # podman load <"''${pkgs.cachedOCIImage8}"
                      # podman load <"''${pkgs.cachedOCIImage9}"
                      # podman load <"''${pkgs.cachedOCIImage10}"
                      # podman load <"''${pkgs.cachedOCIImage11}"
                      # podman load <"''${pkgs.cachedOCIImage12}"

                      # podman load <"''${pkgs.cachedOCIImageT1}"
                      # podman load <"''${pkgs.cachedOCIImageT2}"
                      # podman load <"''${pkgs.cachedOCIImageT3}"
                      # podman load <"''${pkgs.cachedOCIImageT4}"
                      # podman load <"''${pkgs.cachedOCIImageT5}"
                      # podman load <"''${pkgs.cachedOCIImageT6}"
                      # podman load <"''${pkgs.cachedOCIImageT7}"
                      # podman load <"''${pkgs.cachedOCIImageT8}"
                      # podman load <"''${pkgs.cachedOCIImageT9}"
                      # podman load <"''${pkgs.cachedOCIImageT10}"
                      # podman load <"''${pkgs.cachedOCIImageT11}"
                      # podman load <"''${pkgs.cachedOCIImageT12}"

                      # podman load <"''${pkgs.cachedOCIImageDockerToolsExample0}"
                      # podman load <"''${pkgs.cachedOCIImageDockerToolsExample1}"
                      # podman load <"''${pkgs.cachedOCIImageDockerToolsExample2}"
                      # podman load <"''${pkgs.cachedOCIImageDockerToolsExample3}"
                      # podman load <"''${pkgs.cachedOCIImageDockerToolsExample4}"
                      # podman load <"''${pkgs.cachedOCIImageDockerToolsExample5}"

                      # podman load <"''${pkgs.cachedOCIImageStaticXorgXclock}"
                      # podman load <"''${pkgs.cachedOCIImageFirefox}"

                    '';

                    serviceConfig = {
                      Type = "oneshot";
                    };
                  };

                  systemd.services.docker-custom-bootstrap-1 = {
                    description = "Docker Custom Bootstrap 1";
                    wantedBy = [ "multi-user.target" ];
                    after = [ "docker.service" ];
                    path = with pkgs; [ docker ];
                    script = ''
                      # set -x
                      echo "Seeding docker image..."

                      docker load <"${pkgs.cachedOCIImage0}"
                      docker load <"${pkgs.cachedOCIImage02}"
                      docker load <"${pkgs.cachedOCIImage00}"
                      docker load <"${pkgs.cachedOCIImage01}"
                      # docker load <"''${pkgs.cachedOCIImageAndroid}"

                      docker load <"${pkgs.cachedOCIImageStaticBusyboxSandboxShell}"
                      docker load <"${pkgs.cachedOCIImageStaticBusybox}"
                      docker load <"${pkgs.cachedOCIImageGlued}"
                      # docker load <"''${pkgs.cachedOCIImageCUDA}"
                      docker load <"${pkgs.cachedOCIImageStaticNixCacert}"
                      docker load <"${pkgs.cachedOCIImageStaticBash}"
                      docker load <"${pkgs.cachedOCIImageStaticBashInteractive}"
                      docker load <"${pkgs.cachedOCIImageStaticZsh}"
                      docker load <"${pkgs.cachedOCIImageStaticPython3}"
                      #"''${pkgs.cachedOCIImageStaticRedis}" | docker load

                      "${pkgs.cachedOCIImageBaseNix}" | docker load
                      #"''${pkgs.cachedOCIImageBaseA}" | docker load
                      docker load <"${pkgs.cachedOCIImageBaseA}"
                      "${pkgs.cachedOCIImageBaseB}" | docker load

                      #docker load <"''${pkgs.cachedOCIImageHello1}"
                      #docker load <"''${pkgs.cachedOCIImageHello2}"
                      docker load <"${pkgs.cachedOCIImageBaseW}"
                      docker load <"${pkgs.cachedOCIImageT13}"
                    '';
                    serviceConfig = {
                      Type = "oneshot";
                    };
                  };

                  #systemd.services.docker-custom-bootstrap-2 = {
                  #  description = "Docker Custom Bootstrap 2";
                  #  wantedBy = [ "multi-user.target" ];
                  #  after = [ "docker.service" "podman.service" ];
                  #  path = with pkgs; [ docker ];
                  #  script = "${pkgs.cachedOCIImageChromium} | docker load";
                  #  serviceConfig = {
                  #    Type = "oneshot";
                  #  };
                  #};
                  #
                  #systemd.services.docker-custom-bootstrap-3 = {
                  #  description = "Docker Custom Bootstrap 3";
                  #  wantedBy = [ "multi-user.target" ];
                  #  after = [ "docker.service" "podman.service" ];
                  #  path = with pkgs; [ docker ];
                  #  script = "docker load <${pkgs.cachedOCIImageJupyter}";
                  #  serviceConfig = {
                  #    Type = "oneshot";
                  #  };
                  #};
                  #

                  #  systemd.services.docker-custom-oci-images = {
                  #    description = "Custom OCI images";
                  #    wantedBy = [ "multi-user.target" ];
                  #    after = [ "docker.service" ];
                  #    path = with pkgs; [ docker ];
                  #    script = ''
                  #      cat ${pkgs.nixOsOCI}/tarball/nixos-system-x86_64-linux.tar.xz \
                  #      | docker import - nixos-image:latest
                  #    '';
                  #    serviceConfig = {
                  #      Type = "oneshot";
                  #    };
                  #  };

                  /*
                      cat ${pkgs.nixOsOCI}/tarball/nixos-system-x86_64-linux.tar.xz \
                      | podman import --os "NixOS" - nixos-image:latest
                  */
                  #  systemd.services.podman-custom-oci-images = {
                  #    description = "Custom OCI images";
                  #    wantedBy = [ "multi-user.target" ];
                  #    after = [ "podman.service" ];
                  #    path = with pkgs; [ podman ];
                  #    script = ''
                  #
                  #      podman load <"${pkgs.cachedOCIImageStaticBusyboxSandboxShell}"
                  #    '';
                  #    serviceConfig = {
                  #      Type = "oneshot";
                  #    };
                  #  };

                  virtualisation.libvirtd.enable = true;
                  users.users.nixuser = {
  extraGroups = [ "libvirtd" ];
};
                  # virtualisation.services.libvirtd.serviceOverrides = { PrivateUsers="no"; };

                  programs.dconf.enable = true;
                  # security.polkit.enable = true; # TODO: hardening?

                  environment.variables = {
                    VAGRANT_DEFAULT_PROVIDER = "libvirt";
                    # VAGRANT_DEFAULT_PROVIDER = "virtualbox"; # Is it an must for vagrant snapshots?
                    /*
                    https://github.com/erictossell/nixflakes/blob/e97cdba0d6b192655d01f8aef5a6691f587c61fe/modules/virt/libvirt.nix#L29-L36
                    */
                    # programs.dconf.enable = true;
                    # VIRSH_DEFAULT_CONNECT_URI="qemu:///system";
                    # VIRSH_DEFAULT_CONNECT_URI = "qemu:///session";
                    # programs.dconf.profiles = pkgs.writeText "org/virt-manager/virt-manager/connections" ''
                    #  autoconnect = ["qemu:///system"];
                    #  uris = ["qemu:///system"];
                    # '';
                  };

                  boot.tmp.useTmpfs = true;
                  boot.tmp.cleanOnBoot = true;
                  boot.tmp.tmpfsSize = "98%";

                  virtualisation.memorySize = 1024 * 18; # Use MiB memory.
                  virtualisation.diskSize = 1024 * 50; # Use MiB memory.
                  virtualisation.cores = 7; # Number of cores.
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
                  https://github.com/NixOS/nixpkgs/issues/18523#issuecomment-246324977

                  TODO:
                  services.xserver.resolutions = lib.mkOverride 9 { x = 1680; y = 1050; };
                  https://github.com/NixOS/nixpkgs/issues/18523#issuecomment-323389189
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
                    # ping -c3 1.1.1.1
                    # "-nic none"
                  ];
                };

              ## What does not work if it is desabled?
              hardware.enableAllFirmware = true;
              hardware.enableRedistributableFirmware = true;
              # hardware.opengl.driSupport = true;
              hardware.opengl.driSupport32Bit = true;
              hardware.opengl.enable = true;
              hardware.opengl.extraPackages = with pkgs; [ pipewire pulseaudioFull libva-utils ];
              hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ pipewire pulseaudioFull libva-utils ];
              hardware.opengl.package = pkgs.mesa.drivers;
              # hardware.opengl.setLdLibraryPath = true;
              hardware.pulseaudio.package = pkgs.pulseaudioFull;
              hardware.pulseaudio.support32Bit = true;
              hardware.steam-hardware.enable = true;
              programs.steam.enable = true;
              # sound.enable = true;
              # hardware.nvidia = {
              #   # Modesetting is required.
              #   modesetting.enable = true;
              #
              #   # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
              #   # Enable this if you have graphical corruption issues or application crashes after waking
              #   # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
              #   # of just the bare essentials.
              #   powerManagement.enable = false;
              #
              #   # Fine-grained power management. Turns off GPU when not in use.
              #   # Experimental and only works on modern Nvidia GPUs (Turing or newer).
              #   powerManagement.finegrained = false;
              #
              #   # Use the NVidia open source kernel module (not to be confused with the
              #   # independent third-party "nouveau" open source driver).
              #   # Support is limited to the Turing and later architectures. Full list of
              #   # supported GPUs is at:
              #   # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
              #   # Only available from driver 515.43.04+
              #   # Currently alpha-quality/buggy, so false is currently the recommended setting.
              #   open = false;
              #
              #   # Enable the Nvidia settings menu,
              #   # accessible via `nvidia-settings`.
              #   nvidiaSettings = true;
              #
              #   # Optionally, you may need to select the appropriate driver version for your specific GPU.
              #   package = config.boot.kernelPackages.nvidiaPackages.stable;
              # };
              # boot.initrd.kernelModules = [ "nvidia" ];
              # boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
              ##

              # https://nixos.wiki/wiki/PipeWire#nabling_PipeWire
              security.rtkit.enable = true;
              services.pipewire.enable = true;
              services.pipewire.alsa.enable = true;
              services.pipewire.alsa.support32Bit = true;
              services.pipewire.pulse.enable = true;

              users.users.root = {
                password = "root";
                # initialPassword = "root";
                openssh.authorizedKeys.keyFiles = [
                  "${ pkgs.writeText "nixuser-keys.pub" "${toString nixuserKeys}" }"
                  "${ pkgs.writeText "pedro-keys.pub" "${toString pedroKeys}" }"
                ];
              };

              # https://nixos.wiki/wiki/NixOS:nixos-rebuild_build-vm
              users.extraGroups.nixgroup.gid = 999;

              # nix eval --impure --json .#nixosConfigurations.vm.config.security.sudo.package.override.__functionArgs
              security.sudo.wheelNeedsPassword = true; # TODO: hardening
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
                  "vboxsf"
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

                  codeblocksFull
                  # gitkraken
                  jetbrains.pycharm-community
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
                  vscode
                  # xorg.xclock
                  # yt-dlp
                  # gpt4all

                  rustc
                  cargo
                  gcc
                  cmake
                  libclang

                  awscli
                  btop
                  coreutils
                  direnv
                  file

                  firefox
                  chromium
                  librsvg
                  # google-chrome
                  inferno
                  inkscape
                  microsoft-edge

                  python3
                  python3Packages.pip
                  poetry
#                  auditwheel
#                  binutils.out
#                  glibc.bin
#                  git
#                  patchelf
#                  poetry
#                  python3Full
#                  python3Packages.wheel
#                  python3Packages.wheel-filename
#                  python3Packages.wheel-inspect
#                  twine
#                  pax-utils

#                  python3Packages.cffi

                  # nixosTests.kubernetes.dns-single-node.driverInteractive
                  /*
                  export QEMU_NET_OPTS="hostfwd=tcp::6379-:6379" \
                  && nix run nixpkgs#nixosTests.redis.redis.driverInteractive

                  machine.shell_interact()

                  redis-cli ping
                  */
                  nixosTests.redis.redis.driverInteractive

                  git
                  gnumake
                  kubernetes-helm
                  docker-compose
                  nix-info
                  openssh
                  openssl
                  # foo-bar
                  waydroid
                  starship
                  tilix
                  virt-manager
                  which
                  jq
                  unzip
                  ollama
                  # sudo
                  graphviz

                  # pkgsStatic.python3Minimal
                  # pkgsStatic.python311
                  # pkgsMusl.python3Minimal
                  # pkgsMusl.python311

                  #(texlive.combine {texlive.scheme-full})
                  (texlive.combine { inherit (texlive) scheme-full; })
                  # (texlive.combine { inherit (texlive) scheme-basic; })
                  # python311Packages.pytorch-bin
                  # (python3.withPackages (pyPkgs: with pyPkgs; [
                  #   numpy
                  #   matplotlib
                  #   torch-bin
                  #   numba
                  # ]))
                  # (blender.override {
                  #   cudaSupport = true;
                  # })
                  #  (python3.withPackages (pyPkgs: with pyPkgs; [
                  #    ipython
                  #    matplotlib
                  #    nbconvert
                  #    # numpy
                  #    pypdf
                  #
                  #    imageio
                  #    scikitimage
                  #    opencv4
                  #    numpy
                  #  ]))

                  nixpkgs-review

                  okular
                  linuxPackages_latest.perf
                  perf-tools
                  nodejs

                  yarn
                  bun
                  nixd
                  tree

                  # (texlive.combine {
                  #   inherit (pkgs.texlive)
                  #     fontspec
                  #     palatino
                  #     latexmk
                  #     nicematrix
                  #     pgf
                  #     scheme-full
                  #     ;
                  # })

                  (
                    writeScriptBin "prepare-vagrant-vms" ''
                      #! ${pkgs.runtimeShell} -e
                      # set -x

                      for i in {0..100};do
                        echo "The iteration number is: $i. Time: $(date +'%d/%m/%Y %H:%M:%S:%3N')";
                        if (vagrant box list | grep -q hennersz/nixos-23.05-flakes); then
                          break
                        fi
                      done;

                      # for i in {0..100};do
                      #   echo "The iteration number is: $i. Time: $(date +'%d/%m/%Y %H:%M:%S:%3N')";
                      #   if (vagrant box list | grep -q alvistack/ubuntu-24.04); then
                      #     break
                      #   fi
                      # done;

                      for i in {0..100};do
                        echo "The iteration number is: $i. Time: $(date +'%d/%m/%Y %H:%M:%S:%3N')";
                        if (vagrant box list | grep -q generic/alpine319); then
                          break
                        fi
                      done;

                      # $(vagrant global-status | grep -q alpine) || cd /home/nixuser/vagrant-examples/libvirt/alpine && vagrant up
                      # $(vagrant global-status | grep -q ubuntu) || cd /home/nixuser/vagrant-examples/libvirt/ubuntu && vagrant up
                    ''
                  )

                ]
                  # ++
                  # (with rocmPackages; [
                  # clr
                  # clr.icd
                  # hipblas
                  # hipcub
                  # hipfft
                  # hipify
                  # hipsolver
                  # hipsparse
                  # miopen
                  # miopengemm
                  # rccl
                  # rocblas
                  # rocfft
                  # rocm-comgr
                  # rocm-core
                  # rocm-device-libs
                  # rocm-runtime
                  # rocm-thunk
                  # rocminfo
                  # rocprim
                  # rocrand
                  # rocsolver
                  # rocsparse
                  # rocthrust
                  # roctracer
                  # ])
                ;
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
                  k = "kubectl";
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

              systemd.user.services.populate-history = {
                script = ''
                  echo "Started"

                  DESTINATION=/home/nixuser/.zsh_history

                  # TODO: Maybe there is an better way to do this "populate history"
                  echo "cd /home/nixuser/vagrant-examples" >> "$DESTINATION"
                  echo "vagrant ssh" >> "$DESTINATION"
                  echo "vagrant destroy --force; vagrant destroy --force && vagrant up && vagrant ssh" >> "$DESTINATION"
                  echo "cd /home/nixuser/vagrant-examples/libvirt/ubuntu && vagrant up && vagrant ssh && sleep 10 && vagrant ssh" >> "$DESTINATION"
                  echo "vagrant global-status" >> "$DESTINATION"
                  echo "vagrant box list" >> "$DESTINATION"
                  echo "journalctl --user --unit copy-vagrant-examples-vagrant-up.service -b -f" >> "$DESTINATION"
                  echo "prepare-vagrant-vms && cd /home/nixuser/vagrant-examples/libvirt/ubuntu && vagrant up && vagrant ssh" >> "$DESTINATION"
                  echo "prepare-vagrant-vms && cd /home/nixuser/vagrant-examples/libvirt/alpine && vagrant up && vagrant ssh" >> "$DESTINATION"
                  echo "prepare-vagrant-vms && cd /home/nixuser/vagrant-examples/libvirt/nixos && vagrant up && vagrant ssh" >> "$DESTINATION"
                  echo 'ls -alh "$ISOS_DIRETORY"' >> "$DESTINATION"

                  echo "journalctl --unit docker-custom-bootstrap-2.service -b -f" >> "$DESTINATION"
                  echo "journalctl --user --unit podman-custom-bootstrap-1.service -b -f" >> "$DESTINATION"
                  echo "docker images" >> "$DESTINATION"
                  echo "podman images" >> "$DESTINATION"

                  echo "xhost + || nix run nixpkgs#xorg.xhost -- +" >> "$DESTINATION"

                  echo "docker run --device=/dev/dri:/dev/dri -it --privileged -v /var/run/systemd/journal/socket:/var/run/systemd/journal/socket --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket:ro chromium:120.0.6099.129" >> "$DESTINATION"
                  echo 'podman run --env="DISPLAY=''\${DISPLAY:-:0.0}" --interactive=true --mount=type=tmpfs,destination=/var --privileged=false --rm=true --tty=true --user=1234 --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro localhost/static-xorg-xclock:latest' >> "$DESTINATION"

                  echo '
                  docker run --interactive=true --mount=type=tmpfs,destination=/var --privileged=false --rm=true --tty=true --user=1234 --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro firefox:121.0
                  ' >> "$DESTINATION"

                  echo '
                  xhost + && docker run --interactive=true --mount=type=tmpfs,destination=/var --rm=true --tty=true -u 0 --volume=/tmp/.X11-unix:/tmp/.X11-unix:ro --volume=/etc/localtime:/etc/localtime:ro static-xorg-xclock:latest
                  ' >> "$DESTINATION"

                  echo '
                  nix build --cores 3 --impure --print-build-logs --print-out-paths github:NixOS/nixpkgs/nixpkgs-unstable#pkgsStatic.hello
                  docker run --interactive=true --rm=true --tty=true static-zsh
                  docker run --interactive=true --rm=true --tty=true static-busybox
                  docker run --interactive=true --rm=true --tty=true static-nix-cacert \\
                  run nixpkgs#hello
                  ' >> "$DESTINATION"

                  echo "journalctl --unit docker-custom-bootstrap-1.service -b -f" >> "$DESTINATION"

                  echo 'rsync --progress $ISOS_DIRETORY/alpine-standard-3.19.1-x86_64.iso . && chmod -v 0644 alpine-standard-3.19.1-x86_64.iso' >> "$DESTINATION"
                  echo 'rsync --progress $ISOS_DIRETORY/ubuntu-22.04.3-desktop-amd64.iso . && chmod -v 0644 ubuntu-22.04.3-desktop-amd64.iso' >> "$DESTINATION"

                  echo "Ended"
                '';
                wantedBy = [ "default.target" ];
              };

              # journalctl --user --unit copy-vagrant-examples-vagrant-up.service -b -f
              systemd.user.services.copy-vagrant-examples-vagrant-up = {
                path = with pkgs; [
                  curl
                  file
                  gnutar
                  gzip
                  procps
                  vagrant
                  xz
                ];

                script = ''
                  #! ${pkgs.runtimeShell} -e
                    set -x
                    BASE_DIR=/home/nixuser/vagrant-examples/libvirt
                    mkdir -pv "$BASE_DIR"/{alpine,archlinux,ubuntu,nixos}

                    cd "$BASE_DIR"

                    cp -v "${vagrantfileAlpine}" alpine/Vagrantfile
                    # cp -v "${vagrantfileArchlinux}" archlinux/Vagrantfile
                    cp -v "${vagrantfileUbuntu}" ubuntu/Vagrantfile
                    cp -v "${vagrantfileNixos}" nixos/Vagrantfile

                    PROVIDER=libvirt

                    vagrant \
                        box \
                        add \
                        generic/alpine319 \
                        "${alpine319}" \
                        --force \
                        --provider \
                        $PROVIDER

                    vagrant \
                        box \
                        add \
                        hennersz/nixos-23.05-flakes \
                        "${nixos2305}" \
                        --force \
                        --provider \
                        $PROVIDER
                '';
                wantedBy = [ "default.target" ];
              };

              /*
                    vagrant \
                        box \
                        add \
                        alvistack/ubuntu-24.04 \
                        "${ubuntu2404}" \
                        --force \
                        --provider \
                        $PROVIDER

                    vagrant \
                        box \
                        add \
                        generic/alpine319 \
                        "${alpine319}" \
                        --force \
                        --provider \
                        $PROVIDER
              */

              # journalctl --user --unit virtualbox-copy-vagrant-examples-vagrant-up.service -b -f
              #              systemd.user.services.virtualbox-copy-vagrant-examples-vagrant-up = {
              #                path = with pkgs; [
              #                  curl
              #                  file
              #                  gnutar
              #                  gzip
              #                  procps
              #                  vagrant
              #                  xz
              #                ];
              #
              #                script = ''
              #                  #! ${pkgs.runtimeShell} -e
              #                    set -x
              #                    BASE_DIR=/home/nixuser/vagrant-examples/virtualbox
              #                    mkdir -pv "$BASE_DIR"/{alpine,archlinux,ubuntu}
              #
              #                    cd "$BASE_DIR"
              #
              #                    cp -v "${vagrantfileUbuntuVirtualbox}" ubuntu/Vagrantfile
              #
              #                    PROVIDER=virtualbox
              #
              #                    vagrant \
              #                        box \
              #                        add \
              #                        generic/ubuntu2204 \
              #                        "${ubuntu2204Virtualbox}" \
              #                        --force \
              #                        --provider \
              #                        $PROVIDER
              #
              #                '';
              #                wantedBy = [ "default.target" ];
              #              };

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

              systemd.user.services.creates-home-isos-symlink = {
                script = ''
                  ln -fsv $ISOS_DIRETORY "$HOME"/isos
                '';
                wantedBy = [ "xfce4-notifyd.service" ];
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

              # perf record -F99 -p $(pgrep -n node) -g -- sleep 3
              #
              boot.kernel.sysctl."kernel.perf_event_paranoid" = -1;
              boot.kernel.sysctl."kernel.kptr_restrict" = lib.mkForce 0;
              # so perf can find kernel modules
              systemd.tmpfiles.rules = [
                "L /lib - - - - /run/current/system/lib"
              ];

              # https://nixos.wiki/wiki/Libvirt
              # https://discourse.nixos.org/t/set-up-vagrant-with-libvirt-qemu-kvm-on-nixos/14653
              boot.extraModprobeConfig = "options kvm_intel nested=1";

              # https://www.reddit.com/r/NixOS/comments/wcxved/i_gave_an_adhoc_lightning_talk_at_mch2022/
              # Matthew Croughan - Use flake.nix, not Dockerfile - MCH2022
              # file $(readlink -f $(which hello))
              # nixos-option boot.binfmt.emulatedSystems
              # https://github.com/ryan4yin/nixos-and-flakes-book/blob/main/docs/development/cross-platform-compilation.md#custom-build-toolchain
              # https://github.com/ryan4yin/nixos-and-flakes-book/blob/fb2fe1224a4277374cde01404237acc5fecf895a/docs/development/cross-platform-compilation.md#linux-binfmt_misc
               boot.binfmt.emulatedSystems = [
                 "aarch64-linux"
                 "armv7l-linux"
                 "i686-linux"
                 "mips64el-linux"
                 "powerpc64le-linux"
                 "riscv64-linux"
                 "s390x-linux"
               ];

                  boot.binfmt.registrations = {
                    aarch64-linux = {
                      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-aarch64";
                      fixBinary = true;
                    };

                    armv7l-linux = {
                      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-arm";
                      fixBinary = true;
                    };

                    i686-linux = {
                      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-i386";
                      fixBinary = true;
                    };

                    mips64el-linux = {
                      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-mips64el";
                      fixBinary = true;
                    };

                    powerpc64le-linux = {
                      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-ppc64le";
                      fixBinary = true;
                    };

                    riscv64-linux = {
                      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-riscv64";
                      fixBinary = true;
                    };

                    s390x-linux = {
                      interpreter = "${pkgs.pkgsStatic.qemu-user}/bin/qemu-s390x";
                      fixBinary = true;
                    };
                  };

              services.qemuGuest.enable = true;

              # X configuration
              services.xserver.enable = true;
              # services.xserver.videoDrivers = ["nvidia"];
              services.xserver.xkb.layout = "br";

              services.displayManager.autoLogin.enable = true;
              services.displayManager.autoLogin.user = "nixuser";

              # displayManager.job.logToJournal
              # journalctl -t xsession -b -f
              # journalctl -u display-manager.service -b
              # https://askubuntu.com/a/1434433
              services.xserver.displayManager.sessionCommands = ''
                exo-open \
                  --launch TerminalEmulator \
                  --zoom=-3 \
                  --geometry 154x40

                for i in {1..100}; do
                  xdotool getactivewindow
                  $? && break
                  sleep 0.1
                done

                # Race condition. Why?
                # sleep 3
                xdotool type ls \
                && xdotool key Return
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

                  ln \
                    -sfv \
                    "${pkgs.codeblocksFull}"/share/applications/codeblocks.desktop \
                    /home/nixuser/Desktop/codeblocks.desktop

                  ln \
                    -sfv \
                    "${pkgs.virtualbox}"/libexec/virtualbox/virtualbox.desktop \
                    /home/nixuser/Desktop/vboxclient.desktop

                  ln \
                    -sfv \
                    "${pkgs.virt-manager}"/share/applications/virt-manager.desktop \
                    /home/nixuser/Desktop/virt-manager.desktop

                  ln \
                    -sfv \
                    $(readlink -f "${pkgs.jetbrains.pycharm-community}"/share/applications)/pycharm-community.desktop \
                    /home/nixuser/Desktop/pycharm-community.desktop

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

              # nixpkgs.config.allowUnfree = true;

              boot.readOnlyNixStore = true;

              nix = {
                extraOptions = "experimental-features = nix-command flakes";
                # package = pkgs.nixVersions.nix_2_18;
                # package = pkgs.nixVersions.latest;
                registry.nixpkgs.flake = nixpkgs; # https://bou.ke/blog/nix-tips/
                /*
                  echo $NIX_PATH | cut -d'=' -f2

                  nix-info -m | grep store | cut -d'`' -f2

                  nix eval nixpkgs#path
                  nix eval nixpkgs#pkgs.path
                  nix eval --raw nixpkgs#pkgs.path
                  nix eval --impure --expr '<nixpkgs>'

                  nix eval --impure --raw --expr 'builtins.findFile builtins.nixPath "nixpkgs"'
                  nix eval --impure --raw --expr '(import (builtins.getFlake "nixpkgs") {}).path'

                  nix-instantiate --eval --attr 'path' '<nixpkgs>'
                  nix-instantiate --eval --attr 'pkgs.path' '<nixpkgs>'
                  nix-instantiate --eval --expr 'builtins.findFile builtins.nixPath "nixpkgs"'

                  nix eval --impure --raw --expr '(builtins.getFlake "nixpkgs").outPath'
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



              # services.nginx.enable = true;
              # services.nginx.virtualHosts."fooo" = {
              #   locations."/" = {
              #     root = "${pkgs.glowing-bear}";
              #   };
              # };


              #              services.nginx.enable = true;
              #              services.nginx.virtualHosts."myxpto123host.org" = {
              #                addSSL = true;
              #                enableACME = true;
              #                # root = "/var/www/myxpto123host.org";
              #                root = "${pkgs.glowing-bear}";
              #                extraConfig = ''
              #                  return 301 http://acme.test$request_uri;
              #                '';
              #              };
              #              security.acme = {
              #                acceptTerms = true;
              #                defaults.email = "foo@bar.com";
              #              };
              #
              #              networking.extraHosts = ''
              #                127.0.0.1 acme.test
              #              '';
              #
              #              # networking.extraHosts = ''
              #              #   127.0.0.1 myxpto123host.org
              #              # '';
              #
              #              networking.firewall.allowedTCPPorts = [ 80 443 ];
              #              security.pki.certificateFiles = [
              #                (import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert
              #              ];



              security.acme.acceptTerms = true;
              security.acme.defaults.email = "admin+acme@example.com";
              services.nginx.enable = true;
              services.nginx.virtualHosts.redirector = {
                addSSL = true;
                enableACME = true;
                serverName = "acme.test";
                locations."/".return = "301 https://acme.test$request_uri";
              };
              #              services.nginx = {
              #                enable = true;
              #                virtualHosts = {
              #                  "acme.test" = {
              #                    forceSSL = true;
              #                    enableACME = true;
              #                    # All serverAliases will be added as extra domain names on the certificate.
              #                    # serverAliases = [ "bar.example.com" ];
              #                    locations."/" = {
              #                      root = "${pkgs.glowing-bear}";
              #                    };
              #
              #                    locations."/.well-known/acme-challenge" = {
              #                      root = "/var/lib/acme/.challenges";
              #                    };
              #                    locations."/" = {
              #                      return = "301 https://$host$request_uri";
              #                    };
              #
              #                  };
              #                };
              #              };

              security.pki.certificateFiles = [
                (import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert
              ];

              networking.extraHosts = ''
                127.0.0.1 acme.test
              '';
              networking.firewall.allowedTCPPorts = [ 80 443 ];

              #                            services.postfix = {
              #                              enableSubmission = true;
              #                              enableSubmissions = true;
              #                              submissionsOptions = {
              #                                smtpd_sasl_auth_enable = "yes";
              #                                smtpd_client_restrictions = "permit";
              #                              };
              #                            };

              #                environment.variables.NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
              #                environment.variables.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
              #                environment.variables.XPTO = "${(import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert}";


              #              security.acme.acceptTerms = true;
              #              security.acme.email = "web+acme@company.org";
              #              # /var/lib/acme/.challenges must be writable by the ACME user
              #              # and readable by the Nginx user. The easiest way to achieve
              #              # this is to add the Nginx user to the ACME group.
              #              users.users.nginx.extraGroups = [ "acme" ];
              #
              #              services.nginx = {
              #                enable = true;
              #                virtualHosts."acme.test" = {
              #                  # root = "/www/webroot/website";
              #                  locations."/" = {
              #                    root = "${pkgs.runCommand "testdir" {} ''
              #                        mkdir "$out"
              #                        echo '<h2>hello world</h2>' > "$out/index.html"
              #                        echo '<h3>574e9081-0cf3-435c-afd9-f0d2c16e409a</h3>' >> "$out/index.html"
              #                      ''
              #                    }";
              #                    # extraConfig = ''
              #                    #   proxy_pass http://localhost;
              #                    # '';
              #
              #                    # return = "301 https://$host$request_uri";
              #                  };
              #
              #                  # locations."/.well-known/acme-challenge" = {
              #                  #   root = "/var/lib/acme/.challenges";
              #                  # };
              #
              #                  listen = [
              #                    { addr = "[::]"; port = 80; ssl = false; }
              #                    { addr = "0.0.0.0"; port = 80; ssl = false; }
              #                    { addr = "[::]"; port = 443; ssl = true; }
              #                    { addr = "0.0.0.0"; port = 443; ssl = true; }
              #                  ];
              #
              #                  # addSSL = true;
              #                  forceSSL = true;
              #                  enableACME = true;
              #                };
              #              };
              #              security.pki.certificateFiles = [
              #                (import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert
              #              ];
              #
              #              networking.extraHosts = ''
              #                127.0.0.1 ${(import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").domain}
              #              '';
              #              networking.firewall.allowedTCPPorts = [ 80 443 ];




              #              users.users.nginx.extraGroups = [ "acme" ];
              #              services.nginx = {
              #                enable = true;
              #                virtualHosts."acme.test" = {
              #                  enableACME = true;
              #                  forceSSL = true;
              #
              #                  listen = [
              #                    { addr = "0.0.0.0"; port = 80; }
              #                    { addr = "0.0.0.0"; port = 443; ssl = true; }
              #                  ];
              #
              #                  locations."/.well-known/acme-challenge" = {
              #                    root = "/var/lib/acme/.challenges";
              #                  };
              #
              #                  locations."/" = {
              #                    root = "${pkgs.runCommand "testdir" {} ''
              #                        mkdir "$out"
              #                        echo '<h2>hello world</h2>' > "$out/index.html"
              #                        echo '<h3>574e9081-0cf3-435c-afd9-f0d2c16e409a</h3>' >> "$out/index.html"
              #                      ''
              #                    }";
              #                  };
              #                };
              #              };
              #              security.acme = {
              #                acceptTerms = true;
              #                defaults.email = "acme@0xcat.dev";
              #              };



              #              security.acme.certs."acme.test" = {
              #                webroot = "/var/lib/acme/.challenges";
              #                email = "acme@0xcat.dev";
              #                group = "nginx";
              #              };




              #              services.nginx.enable = true;
              #              services.nginx.virtualHosts."acme.test" = {
              #                forceSSL = true;
              #                # enableACME = true;
              #                sslCertificate = (import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert;
              #                sslCertificateKey = (import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.key;
              #                locations."/" = {
              #                  root = "${pkgs.glowing-bear}";
              #                  extraConfig = ''
              #                    return 301 https://acme.test$request_uri;
              #                  '';
              #                };
              #              };
              #              security.acme = {
              #                acceptTerms = true;
              #                defaults.email = "foo@bar.com";
              #
              #                certs."acme.test" = {
              #                  webroot = "/var/lib/acme/challenges";
              #                  email = "myemail@foo-bar.net";
              #                  group = "nginx";
              #                  # extraDomainNames = [ "www.foo-bar.net" ];
              #                };
              #              };
              #              security.acme.server = "https://127.0.0.1";
              #              security.acme.preliminarySelfsigned = true;

              #              networking.extraHosts = ''
              #                127.0.0.1 ${(import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").domain}
              #              '';
              #
              #              security.pki.certificateFiles = [
              #                (import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert
              #              ];

              # /var/lib/acme/.challenges must be writable by the ACME user
              # and readable by the Nginx user. The easiest way to achieve
              # this is to add the Nginx user to the ACME group.
              #              users.users.nginx.extraGroups = [ "acme" ];
              #
              #              services.nginx = {
              #                enable = true;
              #                logError = "stderr info";
              #                recommendedGzipSettings = true;
              #                recommendedOptimisation = true;
              #                recommendedProxySettings = true;
              #                recommendedTlsSettings = true;
              #                virtualHosts."bar" = {
              #                  default = true;
              #                  enableACME = true;
              #                  # sslCertificate = "${(import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert}";
              #                  # sslCertificateKey = "${(import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert.key}";
              #                  forceSSL = true;
              #                  listen = [
              #                    { addr = "0.0.0.0"; port = 80; ssl = false; }
              #                    { addr = "0.0.0.0"; port = 443; ssl = true; }
              #                    { addr = "[::]"; port = 443; ssl = true; }
              #                  ];
              #                  root = "${pkgs.runCommand "testdir" {} ''
              #                      mkdir "$out"
              #                      echo '<h2>hello world</h2>' > "$out/index.html"
              #                      echo '<h3>ac77cd9c-2d8f-4823-8d36-830fd16c97a5</h3>' >> "$out/index.html"
              #                    ''
              #                  }";
              #                };
              #              };
              #              security.acme = {
              #                acceptTerms = true;
              #                defaults.email = "my-email+acme@gmail.com";
              #              };
              #
              #              networking.firewall.allowedTCPPorts = [ 80 443 ];


              #              services.nginx = {
              #                enable = true;
              #                virtualHosts."blogxxyy.example.com" = {
              #                  enableACME = true;
              #                  forceSSL = true;
              #                  root = "/var/www/blog";
              #                };
              #              };
              #              # nix eval --impure '.#nixosConfigurations.vm.config.networking.firewall.allowedTCPPorts'
              #              networking.firewall.allowedTCPPorts = [ 80 443 ];
              #              security.acme.acceptTerms = true;
              #              security.acme.defaults.email = "foo-bar@gmail.com";
              #              # Optional: You can configure the email address used with Let's Encrypt.
              #              # This way you get renewal reminders (automated by NixOS) as well as expiration emails.
              #              security.acme.certs = {
              #                "blogxxyy.example.com".email = "youremail@address.com";
              #              };


              #              services.nginx = {
              #                enable = true;
              #                virtualHosts."www.foo-bar.net" = {
              #                  listen = [{ addr = "0.0.0.0"; port = 80; } { addr = "0.0.0.0"; port = 443; }];
              #
              #                  locations."/.well-known/acme-challenge" = {
              #                    root = "/var/lib/acme/challenges-foo-bar-net";
              #                    extraConfig = ''
              #                      auth_basic off;
              #                    '';
              #                  };
              #
              #                  locations."/" = {
              #                    extraConfig = ''
              #                      return 301 https://foo-bar.net$request_uri;
              #                    '';
              #                  };
              #                };
              #              };
              #
              #              security.acme = {
              #                defaults.email = "myemail@ersocon.net";
              #                acceptTerms = true;
              #
              #                certs."foo-bar.net" = {
              #                  webroot = "/var/lib/acme/acme-challenge";
              #                  email = "myemail@foo-bar.net";
              #                  group = "nginx";
              #                  extraDomainNames = [ "www.foo-bar.net" ];
              #                };
              #              };


              #              services.postfix = {
              #                enableSubmission = true;
              #                enableSubmissions = true;
              #                submissionsOptions = {
              #                  smtpd_sasl_auth_enable = "yes";
              #                  smtpd_client_restrictions = "permit";
              #                };
              #              };
              #
              #              networking.extraHosts = ''
              #                127.0.0.1 ${(import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").domain}
              #              '';
              #
              #              security.pki.certificateFiles = [
              #                (import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix").ca.cert
              #              ];
              #              services.discourse =
              #                let
              #                  certs = import "${pkgs.path}/nixos/tests/common/acme/server/snakeoil-certs.nix";
              #                  clientDomain = "client.fake.domain";
              #                  discourseDomain = certs.domain;
              #                  adminPassword = "eYAX85qmMJ5GZIHLaXGDAoszD7HSZp5d";
              #                  secretKeyBase = "381f4ac6d8f5e49d804dae72aa9c046431d2f34c656a705c41cd52fed9b4f6f76f51549f0b55db3b8b0dded7a00d6a381ebe9a4367d2d44f5e743af6628b4d42";
              #                  admin = {
              #                    email = "alice@${clientDomain}";
              #                    username = "alice";
              #                    fullName = "Alice Admin";
              #                    passwordFile = "${pkgs.writeText "admin-pass" adminPassword}";
              #                  };
              #                in
              #                {
              #                  enable = true;
              #                  inherit admin;
              #                  hostname = discourseDomain;
              #                  sslCertificate = "${certs.${discourseDomain}.cert}";
              #                  sslCertificateKey = "${certs.${discourseDomain}.key}";
              #                  secretKeyBaseFile = "${pkgs.writeText "secret-key-base" secretKeyBase}";
              #                  enableACME = false;
              #                  mail.outgoing.serverAddress = clientDomain;
              #                  mail.incoming.enable = true;
              #                  siteSettings = {
              #                    posting = {
              #                      min_post_length = 5;
              #                      min_first_post_length = 5;
              #                      min_personal_message_post_length = 5;
              #                    };
              #                  };
              #                  unicornTimeout = 900;
              #                };
              #
              #              services.postgresql.package = pkgs.postgresql_13;
              #              security.acme.acceptTerms = true;
              #              security.acme.defaults.email = "foo-bar@gmail.com";

              environment.systemPackages = with pkgs; [
                bashInteractive
                # hello
                # pkgsCross.aarch64-multiplatform.pkgsStatic.hello
                # pkgsCross.aarch64-multiplatform.hello
                # pkgsCross.riscv64.pkgsStatic.hello
                openssh
                virt-manager
                nix-serve # nix store ping --store http://localhost:5000
                # gnome3.dconf-editor
                # gnome2.dconf-editor

                # pkgsCross.aarch64-multiplatform.docker
                # (import nixpkgs {
                #   overlays = [ self.overlays.default ];
                #   system = "aarch64-linux";
                # }).docker

                vagrant
                direnv
                nix-direnv
                fzf
                neovim
                nixos-option
                oh-my-zsh
                sudo
                pandoc
                xclip
                xdotool
                xorg.xhost
                zsh
                zsh-autosuggestions
                zsh-completions
              ];

              environment.variables.ISOS_DIRETORY = "${pkgs.isos}/isos";

              # time.timeZone = "America/Recife";

              system.stateVersion = "22.11";
            })
          #

          { nixpkgs.overlays = [ self.overlays.default ]; }
          { nixpkgs.config.allowUnfree = true; }
        ];
        specialArgs = { inherit nixpkgs allAttrs; };
      };
    };
}
