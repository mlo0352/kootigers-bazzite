# Build notes

- Completed: `2026-08-14T18:37:57-04:00` (America/New_York)
- Universal Blue image-template commit: `3430fb692292cc1aec6c134913816bfc42094c81`
- PiercingXX/arch-mini-mod commit: `12062ee4b5f0691eeafde64f056380ed94e97098`
- Final successful build/configuration commit: `39bc59aeffa70476638f79b9c8cbe2458ca7f119`
- Successful OCI workflow run ID: `31844477182`
- Successful ISO workflow run ID: `31845898153`
- GHCR image: `ghcr.io/mlo0352/kootigers-bazzite:latest`
- Verified GHCR manifest digest: `sha256:7621032f1f2abc11a54ed232dc5415ec5506e90e5a969e5390dc87e4fa477ba5`
- Final ISO: `kootigers-bazzite-amd64.iso`
- ISO size: `5966096384` bytes (`5.556360` GiB)
- ISO SHA-256: `6d5fcb5c10a7946d0e9b78f6ba15d0f043a5637fcb5abd609ed3465abc487762`

## Important deviations from the upstream template

- The project uses the template's normal digest-pinned Bazzite KDE stable base,
  but removes the example `tmux` package and `podman.socket` enablement.
- The ISO-only workflow directly selects `disk_config/iso-kde.toml`, resolving
  the upstream workflow's stale `disk_config/iso.toml` reference. It builds
  only an amd64 Anaconda ISO and uploads it to GitHub Actions; ARM, QCOW2, and
  S3 output are not configured.
- Current bootc-image-builder requires an explicit root filesystem for this
  Bazzite image, so the workflow passes `rootfs: btrfs`.
- Bazzite's Terra repository files refer to GPG keys through container-local
  `file://` paths. Those URLs are rewritten in the target image to the matching
  official `https://repos.fyralabs.com/<repo>/key.asc` endpoints so the
  external ISO dependency solver can retain GPG verification.
- `iio-sensor-proxy` was already present in the current Bazzite base. The build
  verifies it and retains a Fedora-repository fallback, but does not enable its
  D-Bus-activated service manually.

## Installer and physical-hardware status

The successful legacy Anaconda ISO is built from installer RPMs and embeds the
custom Bazzite OCI payload. The target image's immutable `/usr` files are not
the Anaconda live runtime, so touchscreen input is not promised during the
installation itself; a USB mouse or keyboard should be available.

CI verified the touchscreen files, enabled service, sensor package, and current
Bazzite kernel modules. The final ISO was independently hashed on Windows and
its ISO9660 contents were listed successfully, including BIOS/UEFI boot files,
kernel/initrd, `images/install.img`, and the embedded OCI layout. The following
still require the physical KooTigers machine:

- Goodix GDIX1002 enumeration and touch response after first installed boot.
- Correct touchscreen coordinate mapping on the built-in LCD.
- Whether the hardware exposes a supported IIO orientation sensor.
- The effects of the parent Intel LPSS/I2C PCI unbind/rebind on this firmware.
