# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 5.x     | ✅ Yes    |
| < 5.0   | ❌ No     |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability, please:

1. **Do NOT** open a public issue.
2. Email us at **security@continuum-monitor.com**.
3. Include a detailed description of the issue.
4. Allow us 48 hours to respond.

We will acknowledge your report and work on a fix. Once resolved, we will credit you (if you wish) in the release notes.

## Security Best Practices

- Keep your API keys secure. Never commit them to the repository.
- Use IP whitelisting for production deployments.
- Enable MFA for all user accounts.
- Regularly rotate API keys.
- Monitor audit logs for suspicious activity.

## Security Features

- TLS 1.3 encryption
- MFA (TOTP)
- Crowdsec IDS/IPS
- API key rotation
- Audit logging
- Rate limiting
- IP whitelisting
