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



