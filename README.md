# silverblue-nix

Personal BlueBuild image for Fedora Silverblue.

## Scope

This image provides:

- Fedora 44 `ghcr.io/ublue-os/silverblue-main` base
- a real `/nix` mountpoint in the ostree commit so the Determinate Nix installer can manage Nix cleanly on Silverblue
- RPM repos for RPM Fusion, Tailscale, and Mullvad
- rpm-ostree installed host packages:
  - `tailscale`
  - `mullvad-vpn`
- enabled host service:
  - `tailscaled.service`

The image intentionally does **not** ship `nix-directory.service` or `nix.mount`. Those unit names are owned by the Determinate Nix installer; shipping them in the image causes installer conflicts.

No Flatpaks, GNOME extensions, editor/terminal tools, or regular user CLI packages are preinstalled. Those belong in Flatpak/Home Manager unless they are truly host-level rpm-ostree requirements.

User tools and shell/editor/terminal configuration are managed from the separate dotfiles Home Manager flake.

## Validate/build

```bash
bluebuild validate recipes/recipe.yml
bluebuild build recipes/recipe.yml
```

## Registry/rebase

The image can be hosted on any OCI registry that `rpm-ostree` can pull from: GHCR, a private Gitea container registry, etc. A public GitHub account is not required.

First-time bootstrap is two rebases. The host's default `containers-policy.json` is `insecureAcceptAnything`, which refuses `ostree-image-signed:` on principle. The image we build carries a stricter `policy.json` via BlueBuild's `signing` module, but that policy is only available after the image is installed once.

```bash
# Bootstrap: pull the image so its policy/key files land on disk
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/OWNER/silverblue-nix:latest
sudo systemctl reboot

# After reboot, switch to signed updates
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/OWNER/silverblue-nix:latest
sudo systemctl reboot
```

Subsequent upgrades after the signed origin is set:

```bash
sudo rpm-ostree upgrade
# or enable staged auto-updates
sudo systemctl enable --now rpm-ostreed-automatic.timer
```

For a purely local build/rebase, bypass the registry:

```bash
sudo bluebuild switch recipes/recipe.yml --tempdir /var/tmp
sudo systemctl reboot
```

After reboot, check the image-provided pieces:

```bash
ls -ld /nix
systemctl status tailscaled.service
rpm -q tailscale mullvad-vpn
```

Then install Nix with the Determinate installer. The installer should create and own its own Nix systemd units, including any `nix-directory.service`/`nix.mount` units it needs.

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

After installation, open a new shell and verify:

```bash
exec $SHELL -l
nix --version
findmnt /nix || true
systemctl status nix-daemon.socket
```

Then apply Home Manager.

## Signed image

BlueBuild can sign pushed images with cosign when a private signing key is available in CI. Keep only `cosign.pub` in git; keep the private key in CI secrets.
