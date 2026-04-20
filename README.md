# Continuum Monitor
## Cross-Platform Infrastructure Monitoring | v5.0

![Version](https://img.shields.io/badge/version-5.0-green)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue)
![License](https://img.shields.io/badge/license-MIT-orange)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-lightgrey)
![Discord](https://img.shields.io/badge/discord-join-7289da)
[![Website](https://img.shields.io/badge/Website-Continuum_Monitor-blue?logo=githubpages)](https://swrz-ai.github.io/Continuum-Monitor/)

**Monitor anything, anywhere. Deploys in minutes. Up to 95% lower cost than traditional enterprise solutions.**

⚡ **PowerShell-native** | 🐧 **Cross-Platform** | 📊 **Interactive Graphs** | 💬 **Slack & Discord** | 🤖 **AI-Ready**

---

## 🤖 AI-Ready Infrastructure Monitoring

Continuum Monitor is built differently:

| Feature | Benefit |
|---------|---------|
| **Infrastructure-based pricing** | Monitor unlimited nodes, no per-seat costs |
| **System of Record** | Immutable audit logs and 365-day retention for compliance and AI training |
| **API-first ready** | Easy integration with AI agents and automation workflows |
| **Self-hosted** | Your monitoring data stays on your infrastructure |
| **95% lower cost** | Compare: traditional infrastructure solutions vs Continuum ($99/month unlimited hosts) |

> *"Continuum Monitor monitors the infrastructure that powers your business."*

---

## ✨ Features

### 📊 Monitoring Capabilities
| Category | Features |
|----------|----------|
| **Operating Systems** | Windows, Linux, macOS |
| **Ports & Services** | SSH (22), MySQL (3306), PostgreSQL (5432), RDP (3389), any TCP port |
| **Web Services** | HTTP/HTTPS endpoints, APIs, websites |
| **Security** | SSL certificate expiry tracking |

### 📈 Analytics & Visualization
| Category | Features |
|----------|----------|
| **Uptime Tracking** | Per-node percentage with color coding (Green/Yellow/Red) |
| **Response Time** | Ping latency in milliseconds with speed indicators |
| **Interactive Graphs** | Chart.js with zoom, pan, and double-click reset |
| **Data Retention** | 365-day automatic archiving with auto-delete |

## 🔒 Security Features

| Feature | Description | Status |
|---------|-------------|--------|
| **IP Whitelisting** | Restrict access to specific IP addresses/ranges | ✅ Optional |
| **HTTPS Support** | SSL/TLS encryption for secure dashboard access | ✅ Optional |
| **Rate Limiting** | 60 requests/minute per IP to prevent abuse | ✅ Active |
| **Audit Logging** | Complete access logs with timestamps and IPs | ✅ Active |
| **SHA-256 Hashing** | API keys encrypted, never stored in plain text | ✅ Active |
| **Security Headers** | CSP, X-Frame-Options, XSS protection | ✅ Active |
| **Multi-tenant Isolation** | Separate API keys and data per client | ✅ Active |

### For Production Deployment

```yaml
Recommended Security Setup:
  ├── Enable IP whitelisting for client office IPs
  ├── Use Cloudflare Tunnel or Let's Encrypt for HTTPS
  ├── Deploy behind firewall or cloud VPC
  ├── Regular audit log reviews
  └── Rotate API keys every 30 days (configurable)

### 🖱️ Interactive Graph Controls
| Action | Result |
|--------|--------|
| 🖱️ **Mouse wheel** | Zoom in/out on time range |
| 👆 **Click and drag** | Pan left/right across timeline |
| 🔁 **Double-click** | Reset to full 12-hour view |
| 🔍 **Hover** | See exact values at any point |

### 🔔 Alerts & Notifications
| Channel | Support |
|---------|---------|
| **Console** | Real-time status changes |
| **Slack** | Webhook integration |
| **Discord** | Webhook integration |
| **Email** | Coming in v5.1 |

### 🔒 Security & Compliance
| Feature | Implementation |
|---------|----------------|
| **API Keys** | SHA-256 hashing |
| **Rate Limiting** | 60 requests per minute per IP |
| **Audit Trail** | Complete access logs |
| **Data Privacy** | Self-hosted, no external data collection |

---

## 🚀 Quick Start

### System Requirements
- Windows 10/11 or Windows Server 2016+ (Linux/macOS via PowerShell Core)
- PowerShell 5.1+ (built into Windows)
- Administrator access (recommended for port monitoring)
- **No additional dependencies** - Everything included

### One-Line Installation

```powershell
# Download and run
powershell -ExecutionPolicy Bypass -File Continuum_Monitor_v5.0.ps1

# Access dashboard (replace locahost with your server's IP for remote access)
http://localhost:18503/dashboard?tenant=Demo&key=demo-123
