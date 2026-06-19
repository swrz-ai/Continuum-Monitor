# 📊 Continuum Monitor

**Enterprise‑grade infrastructure monitoring with real‑time WebSocket, native Modbus IoT, and AI anomaly detection.**

[![GitHub stars](https://img.shields.io/github/stars/swrz-ai/Continuum-Monitor?style=social)](https://github.com/swrz-ai/Continuum-Monitor/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/swrz-ai/Continuum-Monitor?style=social)](https://github.com/swrz-ai/Continuum-Monitor/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Go Report Card](https://goreportcard.com/badge/github.com/swrz-ai/Continuum-Monitor)](https://goreportcard.com/report/github.com/swrz-ai/Continuum-Monitor)

---

## 🚀 Live Demo

Try Continuum Monitor now – no signup required.

👉 **[Launch Enterprise Demo](https://continuum-monitor.com/demo-enterprise)**

Or sign up for a free tenant:
👉 **[Sign up free](https://continuum-monitor.com/signup)**

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **⚡ Real‑time WebSocket** | Live updates every 3 seconds – 60% less latency than HTTP polling |
| **🏭 Native Modbus IoT** | Monitor PLCs, sensors, flow meters, and SCADA systems out of the box |
| **🛡️ Crowdsec IDS/IPS** | Real‑time SSH brute‑force & web attack detection – 19,000+ malicious IPs blocked |
| **🔐 MFA (TOTP)** | Multi‑factor authentication with Google Authenticator, Authy, Microsoft Authenticator |
| **📱 PWA Mobile App** | Installable on Android and iOS – monitor from anywhere |
| **📊 Audit Logging** | Full audit trail of dashboard accesses, MFA events, and API key usage |
| **🏢 Multi‑Tenant** | Isolated views for multiple clients from one dashboard |
| **🔒 Enterprise Security** | TLS 1.3, MFA, RBAC, rate limiting, IP whitelisting, and Crowdsec |

---

1. Architecture Diagram Formatting – The alignment is slightly off. Here's a cleaner version:

Internet → Cloudflare (DDoS) → Nginx (TLS 1.3) → Go App (WebSocket) → Crowdsec (IDS)
                                    ↓
                    ┌───────────────┼───────────────┐
                    ↓               ↓               ↓
              Port 18508      Port 18509      Port 18506
              Dashboard       Maintenance     WebSocket
              (Go + Modbus)   (Terms/Health)  (Real-time)
              
2. Quick Start –
   
git clone https://github.com/swrz-ai/Continuum-Monitor.git 
cd Continuum-Monitor go build -o continuum-go main.go./continuum-go
Then open http://localhost:18508/static/index.html in your browser.

