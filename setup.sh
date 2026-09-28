#!/bin/bash
# ============================================================
# setup.sh - Safe modern Android development toolchain setup
# ============================================================
# Does not modify apt repositories, remove/downgrade tools,
# replace binaries, or generate APK payloads/backdoors.

set -u

if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

PACKAGES=(adb aapt aapt2 zipalign apksigner default-jdk)
TOOLS=(adb aapt aapt2 d8 zipalign apksigner apktool baksmali smali)

run_version() {
    local title="$1"; shift
    echo "----- $title -----"
    "$@" 2>&1 | head -n 3 || true
    echo
}

echo
echo "============================================================"
echo "       MODERN ANDROID DEVELOPMENT TOOLCHAIN SETUP"
echo "============================================================"
echo

echo "[1/4] Updating package metadata..."
if ! $SUDO apt-get update; then
    echo "[!] apt-get update returned an error; repository configuration was not changed."
fi

echo
echo "[2/4] Installing available standard Android packages..."
for package in "${PACKAGES[@]}"; do
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'; then
        echo "[✔] $package already installed"
    elif apt-cache show "$package" >/dev/null 2>&1; then
        echo "[*] Installing $package..."
        $SUDO apt-get install -y "$package" || echo "[!] Could not install $package"
    else
        echo "[i] $package is not available in the configured repositories"
    fi
done

echo
echo "[3/4] Checking commands..."
FOUND=0
MISSING=0
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '[✔] %-12s %s\n' "$tool" "$(command -v "$tool")"
        FOUND=$((FOUND+1))
    else
        printf '[✘] %-12s NOT FOUND\n' "$tool"
        MISSING=$((MISSING+1))
    fi
done

echo
echo "[4/4] Version information..."
command -v java >/dev/null 2>&1 && run_version "Java" java -version
command -v adb >/dev/null 2>&1 && run_version "ADB" adb version
command -v aapt >/dev/null 2>&1 && run_version "AAPT" aapt version
command -v aapt2 >/dev/null 2>&1 && run_version "AAPT2" aapt2 version
command -v d8 >/dev/null 2>&1 && run_version "D8" d8 --version
command -v zipalign >/dev/null 2>&1 && run_version "Zipalign" zipalign -h
command -v apksigner >/dev/null 2>&1 && run_version "Apksigner" apksigner version
command -v apktool >/dev/null 2>&1 && run_version "Apktool" apktool --version
command -v baksmali >/dev/null 2>&1 && run_version "Baksmali" baksmali --version
command -v smali >/dev/null 2>&1 && run_version "Smali" smali --version

echo "----- Legacy DX -----"
if command -v dx >/dev/null 2>&1; then
    echo "[i] dx found at $(command -v dx)"
    dx --version 2>&1 | head -n 2 || true
    echo "[i] D8 is the modern replacement for DX."
else
    echo "[i] dx not found; no installation is attempted because DX is obsolete."
fi

echo
echo "----- Android SDK environment -----"
[ -n "${ANDROID_HOME:-}" ] && echo "[✔] ANDROID_HOME=$ANDROID_HOME" || echo "[i] ANDROID_HOME is not set"
[ -n "${ANDROID_SDK_ROOT:-}" ] && echo "[✔] ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" || echo "[i] ANDROID_SDK_ROOT is not set"

echo
echo "============================================================"
echo "Available commands : $FOUND"
echo "Missing commands   : $MISSING"
echo "============================================================"
echo
echo "No existing Android tool was deliberately removed, purged, downgraded, or replaced."
echo
echo "Setup complete."
exit 0
