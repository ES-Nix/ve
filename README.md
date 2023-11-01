# ve
Virtualization and Emulation with nix


## Executing


Remote:
```bash
nix run github:ES-Nix/ve#vm
```


Local:
```bash
export QEMU_NET_OPTS="hostfwd=tcp::10022-:2200" && nix run .#vm
```
