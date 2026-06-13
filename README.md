# Void Linux Custom Packages Repository

A personal repository for custom Void Linux package templates with automated builds via GitHub Actions.

Packages included are: 

- hip-runtime-amd
- hipcc
- rocm-llvm
- rocm-cmake
- rocm-comgr
- rocm-device-libs
- rocm-opencl
- rocminfo
- rocr-runtime
- vscode-bin
- zen-browser

## 📦 What's This?

This repository hosts custom package templates for Void Linux, including ROCm packages and other custom builds. Packages are automatically built via GitHub Actions and published as releases, making it easy to install on multiple machines.

## 🚀 Quick Start

### On a New Machine

1. **Add this repository as a package source:**

   ```bash
   sudo nano /etc/xbps.d/voidrepo.conf
   ```
   
   Add this line to the file and save:
   
   ```
   repository=https://github.com/markupstart/voidrepo/releases/download/latest
   ```
   
   Then sync the repository index:
   
   ```bash
   sudo xbps-install -S
   ```

2. **Trust the repository signing key:**

   ```bash
   sudo mkdir -p /var/db/xbps/keys
   sudo wget -O /var/db/xbps/keys/voidrepo.plist \
     https://raw.githubusercontent.com/markupstart/voidrepo/main/keys/voidrepo-signing.pub
   ```

3. **Install packages:**

   ```bash
   sudo xbps-install -S your-package-name
   ```
   
