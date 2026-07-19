
# My custom Void Linux Packages Repository

my personal repository for custom Void Linux packages with automated builds via GitHub Actions.

- Updated ROCM to 7.14.0
- Updated vscode-bin to 1.129.1
- Updated zen-browser to 1.21.8b

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
2. **Install packages:**

   ```bash
   sudo xbps-install -S your-package-name
   ```
   
