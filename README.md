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
&& nix run --impure --refresh github:ES-Nix/ve#vm
```


Local:
```bash
export QEMU_NET_OPTS="hostfwd=tcp::10022-:2200" && nix run .#vm
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
- https://www.youtube.com/watch?v=2aJSAzLW6fg
- https://github.com/justmeandopensource/kubernetes/blob/master/vagrant-provisioning/Vagrantfile
- https://gist.github.com/danielepolencic/ef4ddb763fd9a18bf2f1eaaa2e337544


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
# RUN mkdir -pv /nix/var/nix && chmod -v 0777 /nix && chown -Rv nixuser:nixgroup /nix

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
         nixpkgs github:NixOS/nixpkgs/98e7aaa5cfad782b8effe134bff3717280ec41ca \
 && ./nix \
         --extra-experimental-features nix-command \
         --extra-experimental-features flakes \
         --extra-experimental-features auto-allocate-uids \
         profile \
         install \
         nixpkgs#pkgsStatic.nix \
 && rm -v ./nix \
 && mkdir -pv "$HOME"/.config/nix \
 && grep 'experimental-features' "$HOME"/.config/nix/nix.conf -q || (echo 'experimental-features = nix-command flakes' >> "$HOME"/.config/nix/nix.conf) \
 && grep 'nix-profile' "$HOME"/.profile -q || (echo 'export PATH="$HOME"/.nix-profile/bin:"$HOME"/.local/bin:"$PATH"' >> "$HOME"/.profile) \
 && . "$HOME"/.profile \
 && nix flake --version \
 && nix flake metadata nixpkgs

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
sh -c '. ~/.profile && nix run nixpkgs#xorg.xclock'

```
