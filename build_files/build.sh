#!/usr/bin/bash

set -ouex pipefail

# Copy immutable system content into the image.
cp -avf /ctx/system_files/. /
chmod 0755 /usr/libexec/kootigers-touchscreen
chmod 0755 /usr/bin/kootigers-touchscreen-diagnose

# Current normal Bazzite already contains iio-sensor-proxy. Keep this fallback
# so future base-image changes do not silently remove sensor/rotation support.
if ! rpm -q iio-sensor-proxy; then
    dnf5 install -y iio-sensor-proxy
fi

# bootc-image-builder resolves installer RPMs outside the target container.
# Terra's release RPMs use container-local file:// GPG key paths, even though
# each repository publishes the corresponding key at its HTTPS root. Rewrite
# only those key URLs so external image builders can retain GPG verification.
terra_repo_files=(/etc/yum.repos.d/terra*.repo)
if [[ -e "${terra_repo_files[0]}" ]]; then
    sed -Ei \
        's#^gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-(terra.+)$#gpgkey=https://repos.fyralabs.com/\1/key.asc#' \
        "${terra_repo_files[@]}"
fi
if grep -Rqs '^gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-terra' /etc/yum.repos.d; then
    echo "A Terra repository still has a container-local GPG key URL" >&2
    exit 1
fi

# Validate the installed-image integration before publishing it.
test -x /usr/libexec/kootigers-touchscreen
test -x /usr/bin/kootigers-touchscreen-diagnose
test -f /usr/lib/systemd/system/kootigers-touchscreen.service
rpm -q iio-sensor-proxy

mapfile -t kernel_versions < <(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n')
if (( ${#kernel_versions[@]} == 0 )); then
    echo "No installed kernel module trees were found" >&2
    exit 1
fi

# Verify the real module set shipped by every kernel in this Bazzite image.
for kernel_version in "${kernel_versions[@]}"; do
    for module in goodix_ts i2c_hid i2c_hid_acpi hid_multitouch; do
        modinfo -k "$kernel_version" "$module" >/dev/null
    done
done

systemctl enable kootigers-touchscreen.service
test "$(systemctl is-enabled kootigers-touchscreen.service)" = "enabled"
