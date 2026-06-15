# silverblue-nix

Personal BlueBuild image for Fedora Silverblue.

## Scope

This image is intentionally just:

- Fedora 44 `ghcr.io/ublue-os/silverblue-main` base
- persistent `/nix` bind mount backed by `/var/nix`

No extra RPMs are installed, no base RPMs are removed, and no Flatpaks/GNOME extensions are preinstalled. Install optional apps/extensions later with Flatpak, Extension Manager, or `rpm-ostree install`; if something becomes a permanent host requirement, it can be moved into `recipes/recipe.yml` later.

User tools and shell/editor/terminal configuration are managed from the separate dotfiles Home Manager flake.

## Validate/build

```bash
bluebuild validate recipes/recipe.yml
bluebuild build recipes/recipe.yml
```

## Registry/rebase

The image can be hosted on any OCI registry that `rpm-ostree` can pull from: GHCR, a private Gitea container registry, etc. A public GitHub account is not required.

First-time bootstrap is two rebases. The host's default `containers-policy.json` is `insecureAcceptAnything`, which refuses `ostree-image-signed:` on principle. The image we build carries a stricter `policy.json` (via BlueBuild's `signing` module) that knows about this specific image — so we install it via the unverified form first, then switch to signed after the policy lands.

```bash
# Bootstrap: pull the image (carries its own policy + pubkey)
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/OWNER/silverblue-nix:latest
sudo systemctl reboot

# After reboot, switch to signed
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

After reboot, check:

```bash
ls -ld /nix /var/nix
mount | grep ' /nix '
systemctl status nix-directory.service nix.mount
```

Then install Nix with the Determinate installer and apply Home Manager.

## Signed image

BlueBuild can sign pushed images with cosign when a private signing key is available in CI. Keep only `cosign.pub` in git; keep the private key in CI secrets.
