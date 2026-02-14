# 🚀 singbox-install

One-line installer for:

- VLESS + Reality
- Hysteria2
- IPv4 + IPv6 support
- Auto firewall configuration
- BBR enabled
- Ubuntu / Debian supported

Designed for fast VPS deployment (DigitalOcean, Vultr, etc.)

---

## ✅ Quick Install (One Line)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tienhsiangkao/singbox-install/main/install.sh)
```

---

## 🖥 Supported Systems

- Ubuntu 20.04+
- Ubuntu 22.04+
- Ubuntu 24.04
- Debian 11/12

Must run as **root**.

---

## 📦 What This Script Does

- Installs latest sing-box
- Enables BBR
- Configures:
  - VLESS + Reality (TCP 8443)
  - Hysteria2 (UDP 2102)
- Enables IPv6 if available
- Opens firewall ports automatically
- Creates systemd service
- Prints client configuration info

---

## 🔐 Default Ports

| Protocol     | Port  |
|--------------|-------|
| VLESS        | 8443  |
| Hysteria2    | 2102  |

---

## 📋 After Installation

Check service status:

```bash
systemctl status sing-box
```

View logs:

```bash
journalctl -u sing-box -f
```

Check listening ports:

```bash
ss -lntup | grep -E '8443|2102'
```

---

## 🌍 IPv6

If your VPS supports IPv6, script auto-detects it.

Check:

```bash
ip -6 addr
```

---

## 🔄 Reinstall

Just run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tienhsiangkao/singbox-install/main/install.sh)
```

It will overwrite old configuration.

---

## 🗑 Uninstall

```bash
systemctl stop sing-box
systemctl disable sing-box
rm -rf /etc/sing-box
rm -f /usr/local/bin/sing-box
rm -f /etc/systemd/system/sing-box.service
systemctl daemon-reload
```

---

## ⚠️ Security Note

Always verify scripts before running in production:

```bash
curl -fsSL https://raw.githubusercontent.com/tienhsiangkao/singbox-install/main/install.sh
```

---

## 📄 License

MIT License
