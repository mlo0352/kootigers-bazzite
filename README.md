# KooTigers Bazzite

This repository builds a normal x86_64 Bazzite KDE stable image with an
immutable, boot-time hardware workaround for the KooTigers built-in Goodix
touchscreen. It is intended for the Intel N150 KooTigers touchscreen mini PC
(Intel graphics, 12 GB RAM, 1 TB SSD, Wi-Fi 6, Bluetooth 5.2, HDMI, USB-C, and
dual gigabit Ethernet). It is not an NVIDIA or Bazzite-Deck image.

The published image is:

```text
ghcr.io/mlo0352/kootigers-bazzite:latest
```

## Touchscreen integration

The affected ACPI/I2C device appears as:

```text
/sys/bus/i2c/devices/i2c-GDIX1002:00
```

At boot, `kootigers-touchscreen.service` waits for that device, requests
runtime power `on`, reloads the Goodix/I2C/HID modules, finds the parent PCI
function, and unbinds/rebinds its Intel LPSS/I2C driver when one is available.
The service logs what it finds and deliberately returns without blocking boot
when the touchscreen is absent.

The implementation is adapted from the working community workaround in
[`PiercingXX/arch-mini-mod`](https://github.com/PiercingXX/arch-mini-mod) at
commit `12062ee4b5f0691eeafde64f056380ed94e97098`. Credit and the upstream MIT
license are preserved in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Current Bazzite already includes `iio-sensor-proxy`; the image build verifies
it is present and installs it from Fedora only if a future base image removes
it. The package is D-Bus activated, so this project does not try to enable a
static service. No desktop-session rotation hacks are added.

## Reproducible upstream base

This project was imported from `ublue-os/image-template` commit:

```text
3430fb692292cc1aec6c134913816bfc42094c81
```

The `Containerfile` retains that template revision's digest-pinned normal
`ghcr.io/ublue-os/bazzite:stable` base. The only image changes are the
KooTigers service, its diagnostic utility, sensor-package verification, and
build-time checks for `goodix_ts`, `i2c_hid`, `i2c_hid_acpi`, and
`hid_multitouch` in the installed Bazzite kernel module trees.

## Automated builds

`.github/workflows/build.yml` builds, rechunks, pushes, and signs the OCI image
on pushes to `main`, on manual dispatch, and on its upstream-derived schedule.
The workflow publishes `latest` plus dated/commit aliases to GHCR.

`.github/workflows/build-iso.yml` is a manual, amd64-only workflow. It uses the
current Universal Blue `bootc-image-builder` action and the KDE Anaconda
configuration in `disk_config/iso-kde.toml`; it does not build ARM or QCOW2.
The kickstart switches the installed deployment to the exact custom GHCR image
above. A successful run uploads the ISO and `SHA256SUMS.txt` as a GitHub Actions
artifact without requiring S3.

## Installation

Download the completed ISO artifact, verify its SHA-256, and flash it with the
trusted imaging tool of your choice. Boot the KooTigers from that media, use
the graphical Anaconda installer, select the internal target SSD carefully,
and complete the installation. Remove the installation media before booting
the installed system.

The legacy Anaconda ISO runtime is assembled from Fedora installer RPMs, not
from the target image's immutable `/usr` tree. The supported template mechanism
therefore does not make this project's service run inside the installer live
environment. Touch is not promised during installation; use a USB mouse or
keyboard. The installed custom image contains and enables the fix, so it runs
automatically on the first installed-system boot and after future updates.

## Verify on the physical KooTigers

After the first installed-system boot, run:

```bash
systemctl status kootigers-touchscreen.service
journalctl -u kootigers-touchscreen.service -b
sudo kootigers-touchscreen-diagnose
```

Useful focused checks are:

```bash
readlink -f /sys/bus/i2c/devices/i2c-GDIX1002:00
lsmod | grep -E 'goodix_ts|i2c_hid|hid_multitouch'
sudo libinput list-devices | grep -A12 -i -E 'Goodix|GDIX|Touchscreen'
monitor-sensor
```

If touch still fails, send the complete output of
`sudo kootigers-touchscreen-diagnose`, the current boot's service journal, and
`sudo journalctl -b -k` together with the exact KooTigers model/firmware
version. CI can prove that the files, service enablement, packages, and kernel
modules are in the image, but it cannot prove physical touch input or rotation.

## Updates, rollback, and recovery

Bazzite/bootc stages image updates transactionally. Inspect deployments with:

```bash
bootc status
```

If a new deployment causes a problem, select the previous deployment from the
bootloader menu or use Bazzite's documented rollback flow. The touchscreen fix
lives in this custom image, so remain on `ghcr.io/mlo0352/kootigers-bazzite`
when updating or rebasing; switching to stock Bazzite removes this project's
service from the next deployment.

## Limitations

- The Goodix behavior is hardware- and firmware-specific and still requires a
  real KooTigers installation test.
- Touch is not expected in the Anaconda installer runtime.
- Automatic rotation depends on the machine exposing a supported IIO sensor;
  installing `iio-sensor-proxy` cannot create absent or unsupported hardware.
- The PCI reset can briefly reset other devices on the same controller during
  boot, matching the community workaround's behavior.
