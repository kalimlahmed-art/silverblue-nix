#!/usr/bin/env bash
# Runs during the BlueBuild image build.
# Create /nix in the ostree commit; runtime writes go to the bind-mounted
# persistent store root prepared by nix-directory.service.
set -euxo pipefail

install -d -m 0755 -o root -g root /nix
