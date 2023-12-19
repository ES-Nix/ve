# ve
Virtualization and Emulation with nix


## Why?

When dealing with "custom": init systems, cross compilation, custom kernels, 
Virtualization and Emulation, usually under the hood there is QEMU.

> To cross-compile for different systems I wrote goon, 
> which uses QEMU to start a VM. It’s a little bit unpolished, 
> but it works.
> https://www.arp242.net/static-go.html


Nix seems to be "the best" build system to assembly each peace that 
is need to build some specific combination of things.

## Executing


Remote:
```bash
nix run --impure --refresh github:ES-Nix/ve#vm
```


```bash
du -hs nixos.qcow2 \
&& rm -fv nixos.qcow2

df -h / \
&& nix run --impure --refresh --verbose github:ES-Nix/ve#vm
```


Local:
```bash
du -hs nixos.qcow2 \
&& rm -fv nixos.qcow2

df -h / \
&& nix run --impure --refresh --verbose .#vm
```




```bash
while ! false; do clear && echo $(date +'%d/%m/%Y %H:%M:%S:%3N') && ps -u "$(echo nixbld{1..32})"; sleep 0.5; done
```


Be carefull, the `--option keep-outputs false` seems to remove lots of stuff:
```bash
nix \
store \
gc \
--verbose \
--option keep-build-log false \
--option keep-derivations false \
--option keep-env-derivations false \
&& nix-collect-garbage --delete-old --verbose \
&& nix store optimise --verbose
```



### k8s?


List:
- [Set up Kubernetes 1.24 on Ubuntu 22.04 with Vagrant | VirtualBox | Libvirt](https://www.youtube.com/watch?v=2aJSAzLW6fg)
- https://github.com/justmeandopensource/kubernetes/blob/master/vagrant-provisioning/Vagrantfile
- https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544
- [NixCon2023 Nix and Kubernetes: Deployments Done Right](https://www.youtube.com/watch?v=SEA1Qm8K4gY)
- [NixOS Kubernetes Cluster](https://www.youtube.com/watch?v=rTovNSGH_qo)


### nix 


```bash
cat > Containerfile << 'EOF'
FROM docker.io/library/alpine:3.18.3 as alpine-with-ca-certificates-tzdata
# FROM docker.io/library/python:3.9.18-alpine3.18 as alpine-with-ca-certificates-tzdata

# https://stackoverflow.com/a/69918107
# https://serverfault.com/a/1133538
# https://wiki.alpinelinux.org/wiki/Setting_the_timezone
# https://bobcares.com/blog/change-time-in-docker-container/
# https://github.com/containers/podman/issues/9450#issuecomment-783597549
# https://www.redhat.com/sysadmin/tick-tock-container-time
ENV TZ=America/Recife

RUN apk update \
 && apk \
          add \
          --no-cache \
          ca-certificates \
          tzdata \
          shadow \
 && mkdir -pv /home/nixuser \
 && addgroup nixgroup --gid 4455 \
 && adduser \
     -g '"An unprivileged user with an group"' \
     -D \
     -h /home/nixuser \
     -G nixgroup \
     -u 3322 \
     nixuser \
 && echo \
 && echo 'Start kvm stuff...' \
 && getent group kvm || groupadd kvm \
 && usermod --append --groups kvm nixuser \
 && echo 'End kvm stuff!' \
 && echo 'Start tzdata stuff' \
 && (test -d /etc || mkdir -pv /etc) \
 && cp -v /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && apk del tzdata shadow \
 && echo 'End tzdata stuff!' 

# sudo sh -c 'mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv '"$(id -nu)":"$(id -gn)"' /nix'
RUN mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv nixuser:nixgroup /nix

USER nixuser
WORKDIR /home/nixuser
ENV USER="nixuser"

RUN CURL_OR_WGET_OR_ERROR=$($(curl -V &> /dev/null) && echo 'curl -L' && exit 0 || $(wget -q &> /dev/null; test $? -eq 1) && echo 'wget -O-' && exit 0 || echo no-curl-or-wget) \
 && $CURL_OR_WGET_OR_ERROR https://hydra.nixos.org/build/237228729/download/2/nix > nix \
 && chmod -v +x nix \
 && echo \
 && ./nix \
         --extra-experimental-features nix-command \
         --extra-experimental-features flakes \
         --extra-experimental-features auto-allocate-uids \
         registry \
         pin \
         nixpkgs github:NixOS/nixpkgs/98e7aaa5cfad782b8effe134bff3717280ec41ca
RUN ./nix \
         --extra-experimental-features nix-command \
         --extra-experimental-features flakes \
         --extra-experimental-features auto-allocate-uids \
         build \
         --impure \
         --print-out-paths \
         --print-build-logs \
         github:ES-Nix/ve/c1bf94254753320cba498b4095c25b30733b358b#vm \
 && echo
EOF

podman \
build \
--cap-add=SYS_ADMIN \
--tag alpine-with-ca-certificates-tzdata \
--target alpine-with-ca-certificates-tzdata \
. \
&& podman kill conteiner-unprivileged-alpine-with-ca-certificates-tzdata &> /dev/null || true \
&& podman rm --force conteiner-unprivileged-alpine-with-ca-certificates-tzdata || true \
&& podman \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--hostname=container-nix \
--interactive=true \
--name=conteiner-unprivileged-alpine-with-ca-certificates-tzdata \
--privileged=true \
--tty=true \
--rm=true \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh -c '. ~/.profile && nix flake metadata nixpkgs'

xhost + || nix run nixpkgs#xorg.xhost -- +
podman \
run \
--annotation=run.oci.keep_original_groups=1 \
--device=/dev/kvm:rw \
--env="DISPLAY=${DISPLAY:-:0}" \
--hostname=container-nix \
--interactive=true \
--name=conteiner-unprivileged-alpine-with-ca-certificates-tzdata \
--privileged=true \
--tty=true \
--rm=true \
--volume=/tmp/.X11-unix:/tmp/.X11-unix:ro \
localhost/alpine-with-ca-certificates-tzdata:latest \
sh \
-c \
'
. ~/.profile \
&& nix run nixpkgs#xorg.xclock
'

```



```bash
./nix \
--option keep-build-log true \
--option keep-derivations true \
--option keep-env-derivations true \
--option keep-failed true \
--option keep-going true \
--option keep-outputs true \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
store \
gc \
--verbose
```



```bash
./nix \
--extra-experimental-features nix-command \
--extra-experimental-features flakes \
--extra-experimental-features auto-allocate-uids \
run \
nixpkgs#xorg.xclock 
```



```bash
./nix \
--extra-experimental-features auto-allocate-uids \
--extra-experimental-features flakes \
--extra-experimental-features nix-command \
run \
--impure \
--refresh \
github:ES-Nix/ve/c1bf94254753320cba498b4095c25b30733b358b#vm 
```


### OpenGL


https://github.com/NixOS/nixpkgs/issues/9415
https://nixos.wiki/wiki/Nixpkgs_with_OpenGL_on_non-NixOS
https://lobste.rs/s/7h20zl/nix_opengl_ubuntu_integration_nightmare

Test it!
https://github.com/NixOS/nixpkgs/issues/168431

```bash
nix run nixpkgs#blender
```


```bash
nix run nixpkgs#godot
```

```bash
nix run nixpkgs#openarena
```

```bash
nix run --impure github:guibou/nixGL nix run nixpkgs#openarena
```


```bash
nix run --impure github:guibou/nixGL nix run nixpkgs#godot
```


```bash
nix run --impure github:guibou/nixGL nix run nixpkgs#obs-studio
```
https://github.com/NixOS/nixpkgs/issues/231561#issuecomment-1546638257




### SOPS-Nix


[NixOS Secrets Management | SOPS-NIX](https://www.youtube.com/watch?v=G5f6GC7SnhU)

