# 🔍 Continuum Monitor

[![Go version](https://img.shields.io/github/go-mod/go-version/yourusername/continuum-monitor)](https://golang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/yourusername/continuum-monitor)](https://github.com/yourusername/continuum-monitor/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/yourusername/continuum-monitor)](https://github.com/yourusername/continuum-monitor/network)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

> **Stop chasing alerts. Start preventing incidents.**  
> Enterprise‑grade, cloud‑native monitoring for OT, IT, and everything in between.

---

## 🧠 Why We Built This

We’ve seen too many manufacturing and industrial teams juggling five different dashboards – one for Modbus, one for cloud logs, one for security alerts, and none of them talking to each other.

Alerts are missed. Anomalies go unnoticed until something breaks.

We built **Continuum Monitor** to bring **OT, IT, and security monitoring into a single pane of glass** – without the $50k SCADA license or vendor lock‑in.

It’s open‑source, runs as a single Go binary, and connects to:
- Modbus TCP/RTU and MQTT telemetry
- AI anomaly detection
- SLA tracking & incident grouping
- Slack/Discord alerts (webhooks)
- Role‑based access control

---

## 🚀 What Makes This Different

| Feature | What It Does | Why It Matters |
|---------|--------------|----------------|
| **AI Anomaly Detection** | Predicts failure probability for every device (PLC, sensors, etc.) | Catch problems before they become outages |
| **Modbus TCP/RTU** | Native read with retry & backoff | No extra gateways – talk directly to your PLCs |
| **SLA & Tenant Management** | Track uptime, latency, error rate per project | Prove your reliability to clients |
| **Incident Grouping** | Smart grouping of related alerts | Reduce noise, focus on root cause |
| **IP Whitelisting (Cloudflare‑aware)** | Restrict access by real IP, even behind Cloudflare | Secure your dashboard without blocking legitimate users |
| **Horizontal Scaling** | Stateless design – run as many replicas as you need | Grow from a single server to a fleet |
| **Export Reports (CSV/HTML)** | Compliance‑ready reports | Pass audits without manual work |
| **PowerShell & Python Scripts** | Extend with custom logic (MQTT, event logs, etc.) | Integrate with your existing automation |

---

## ⚡️ 5‑Minute Quick Start

### Option A: Self‑Host (Open Source)

```bash
# Clone the repo
git clone https://github.com/yourusername/continuum-monitor.git
cd continuum-monitor

# Build the binary (Go 1.19+)
go build -o continuum-go main.go

# Set your environment (optional – runs in degraded mode without DB)
export PORT=18517
export DB_URL=postgres://user:pass@localhost/db   # optional
export REDIS_URL=redis://localhost:6379           # optional
export RABBITMQ_URL=amqp://guest:guest@localhost  # optional

# Start the server
./continuum-go
```

Your dashboard is live at `http://localhost:18517`.

### Option B: Cloud‑Hosted (Fully Managed)

[👉 **Start your free 7‑day trial**](https://continuum.monitor/signup) – no credit card required, deploy in 60 seconds.

---

## 📊 Dashboard Preview

<img width="802" height="1080" alt="Continuum Monitor Dashboard – Overview" src="https://github.com/user-attachments/assets/746a7626-5bc0-4205-b632-79b44e6a4661" />

---

## 🧪 We Read Every Message

**Stuck? Have an idea?**  
👉 [**Fill out our 30‑second feedback form**](https://forms.gle/your‑link) – we respond within 24 hours.

---

## ⭐ If This Saves You Time…

- **Star this repo** – it helps others find it.
- **Share it** with a colleague who’s fighting the same OT/IT battles.
- **Join our [Slack](https://join.slack.com/t/your‑workspace/shared_invite/...)** – we discuss monitoring, share war stories, and help each other debug.

---

## 🤝 Contributing

We welcome issues, PRs, and ideas.  
Check out [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT – use it freely, just keep the copyright notice.

---

**Made with ❤️ by the Continuum team.**  
[Website](https://continuum.monitor) · [Docs](https://docs.continuum.monitor) · [Blog](https://blog.continuum.monitor)
