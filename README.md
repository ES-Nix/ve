# ve
Virtualization and Emulation with nix


## Executing


Remote:
```bash
nix run --impure --refresh github:ES-Nix/ve#vm
```


```bash
du -hs nixos.qcow2 \
&& rm -frv nixos.qcow2

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


