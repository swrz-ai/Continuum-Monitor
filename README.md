<p align="center">
  <a href="https://github.com/swrz-ai/Continuum-Monitor">
    <img src="https://img.shields.io/github/stars/swrz-ai/Continuum-Monitor?style=social" alt="Star on GitHub">
  </a>
</p>

# 📊 Continuum Monitor

**Enterprise‑grade infrastructure monitoring with real‑time WebSocket, native Modbus IoT, and AI anomaly detection.**

[![GitHub stars](https://img.shields.io/github/stars/swrz-ai/Continuum-Monitor?style=flat-square)](https://github.com/swrz-ai/Continuum-Monitor/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/swrz-ai/Continuum-Monitor?style=flat-square)](https://github.com/swrz-ai/Continuum-Monitor/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Go Report Card](https://goreportcard.com/badge/github.com/swrz-ai/Continuum-Monitor?style=flat-square)](https://goreportcard.com/report/github.com/swrz-ai/Continuum-Monitor)

---

> **If you find Continuum Monitor useful, please consider starring the repo ⭐ – it helps others discover the project!**

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
| **🔁 Async Modbus (RabbitMQ)** | Non‑blocking Modbus reads – instantly return `202 Accepted` while processing in the background |
| **🔐 MFA (TOTP)** | Multi‑factor authentication with Google Authenticator, Authy, Microsoft Authenticator |
| **📱 PWA Mobile App** | Installable on Android and iOS – monitor from anywhere |
| **📊 Audit Logging** | Full audit trail of dashboard accesses, MFA events, and API key usage |
| **🏢 Multi‑Tenant** | Isolated views for multiple clients from one dashboard |
| **🔒 Enterprise Security** | TLS 1.3, MFA, RBAC, rate limiting, and Crowdsec |

---

## 🏗️ Architecture

```text
Internet → Cloudflare (DDoS) → Nginx (TLS 1.3) → Go App (WebSocket) → RabbitMQ (Async) → Crowdsec (IDS)
                                    ↓
                    ┌───────────────┼───────────────┐
                    ↓               ↓               ↓
              Port 18508      Port 18509      Port 18506
              Dashboard       Maintenance     WebSocket
              (Go + Modbus)   (Terms/Health)  (Real-time)
