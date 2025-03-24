# TUIC for ASUS Merlin (Entware) - Easy Install & Uninstall Scripts

This repository contains two simple shell scripts for installing and uninstalling the `sing-box` TUIC v5 server on ASUS routers running Merlin firmware with Entware.

## 📜 Scripts

### `tuic4as.sh`

A fully automated installation script for setting up a TUIC v5 server using `sing-box` via Entware.

#### ✅ Features:

- Installs `sing-box-go` using `opkg` 
- Generates ECC private key and a self-signed TLS certificate
- Randomly generates UUID and password
- Prompts user for port number and preferred IP strategy (IPv4/IPv6)
- Creates a config file compatible with TUIC v5
- Registers the service for auto-start via `/jffs/scripts/services-start`
- Starts the service immediately
- Outputs a TUIC proxy URL compatible with clients like Nekobox

#### 📦 Requirements:

- ASUS router with Merlin firmware
- Entware installed
- OpenSSL available

#### ▶ Usage:

```bash
chmod +x tuic4as.sh
./tuic4as.sh
```

### `untuic.sh`

A cleanup script to fully uninstall the `sing-box` TUIC server and related files.

#### 🔥 What it removes:

- Stops any running `sing-box` instance
- Deletes config files and certificates
- Removes the init script and startup link
- Cleans up `/jffs/scripts/services-start`
- Removes `sing-box-go` via `opkg`

#### ▶ Usage:

```bash
chmod +x untuic.sh
./untuic.sh
```

## 💡 Notes

- The generated TUIC link uses `192.168.50.1` as the server address, which is the default LAN IP for ASUS Merlin routers. Adjust manually if needed.
- TLS certificates are self-signed and stored locally at `/opt/etc/sing-box/cert/`.
- Both scripts are designed for maximum compatibility with Koolshare-based Merlin firmware environments.

## 📄 License

MIT License

