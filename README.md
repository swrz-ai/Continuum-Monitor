## 📋 Commercial Use Policy

> **⚠️ IMPORTANT – READ BEFORE COMMERCIAL USE**

Continuum Monitor is **MIT licensed** for individual, internal business, and open source use.

### ✅ Allowed Without Payment

| Use Case | Allowed? | Conditions |
|----------|----------|------------|
| Personal projects | ✅ Yes | None |
| Internal company monitoring (self-hosted) | ✅ Yes | None |
| Open source integrations | ✅ Yes | Must retain copyright |
| Education & research | ✅ Yes | None |
| Non-profit organizations | ✅ Yes | None |

### ⚠️ Requires Commercial License

| Use Case | License Required | Fee |
|----------|------------------|-----|
| Reselling to multiple clients (MSPs, consultants) | ✅ Yes | $999/year |
| White-label / rebranded distribution | ✅ Yes | $4,999/year |
| Embedding in commercial product | ✅ Yes | Contact sales |
| Offering as SaaS without source disclosure | ✅ Yes | Contact sales |

### 📞 Commercial Licensing

- **Email:** hello@continuum-monitor.com
- **Subject:** Commercial License Request
- **Response:** Within 24 hours

### 🤝 Revenue Sharing Option

Small consultancies and system integrators may qualify for **revenue sharing** instead of upfront license fees:

- Contribute 10% of Continuum-related revenue
- Receive priority support and white-label rights
- **Contact:** hello@continuum-monitor.com (Subject: Partnership Inquiry)

---

## 🚀 Features

### ⚡ Real-time WebSocket
- **3-second update intervals** – 60% less latency than HTTP polling
- **Concurrent monitoring** – 500+ nodes simultaneously

### 🏭 Industrial IoT (Modbus TCP)
- **Native Modbus support** – PLCs, sensors, flow meters, SCADA
- **Register reading** – Real-time industrial data

### 🔒 Enterprise Security
- **TLS 1.3 + AES-256-GCM** – Bank-grade encryption
- **Multi-tenant isolation** – Separate API keys per client
- **IP whitelisting** – Restrict dashboard access
- **Rate limiting** – 10 requests/second
- **Audit logging** – Complete access tracking

### 📊 Monitoring Capabilities
- **Cross-platform** – Linux, Windows, macOS
- **HTTP/HTTPS endpoints** – Websites, APIs
- **ICMP ping** – Network devices
- **Port checks** – SSH, MySQL, PostgreSQL, any TCP port
- **SSL certificate expiry** – Color-coded warnings

### 🛡️ Resilience
- **Systemd auto-restart** – 5-second recovery
- **Daily backups** – 7-day retention
- **Log rotation** – Automatic disk space management

### 🎨 User Customization
- **Save preferences** – Theme, widgets, refresh rate
- **Persistent settings** – Survive app restarts

---

## 🏗️ Architecture

Continuum Monitor uses a **microservices-inspired architecture** with isolated components for maximum stability and security.
┌─────────────────────────────────────────────────────────────┐
│ Cloudflare CDN + DDoS │
│ (DDoS protection, CDN caching) │
├─────────────────────────────────────────────────────────────┤
│ Nginx (SSL/TLS 1.3) │
│ (Reverse proxy, rate limiting) │
├───────────────┬───────────────┬─────────────────────────────┤
│ Port 18508 │ Port 18509 │ Port 18506 │
│ 🖥️ Go App │ 📄 Maintenance│ 🔌 WebSocket │
│ Dashboard │ Terms/Health │ Real-time Data │
│ (Production)│ Privacy/Ping │ (3s intervals) │
└───────────────┴───────────────┴─────────────────────────────┘

