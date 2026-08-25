# Security Policy

Nawa-Recruit takes the security of candidate evaluation data and administrative operations with the utmost seriousness. We are committed to maintaining a robust, enterprise-grade security posture.

## Supported Versions

Currently, only the latest release of the `main` branch is actively supported with security updates. 

| Version | Supported          |
| ------- | ------------------ |
| Main    | :white_check_mark: |
| < 1.0   | :x:                |

## Core Security Architecture

By design, Nawa-Recruit enforces strict security principles:
- **Zero Public Access:** Registration is closed. User provisioning is strictly managed by administrators.
- **Row Level Security (RLS):** All data access is governed by PostgreSQL-level RLS policies, ensuring evaluators can only interact with their explicitly authorized segments of data.
- **Stateless Authentication:** Session management relies on cryptographically signed JWTs provided by Supabase Auth.

## Reporting a Vulnerability

If you discover a security vulnerability within Nawa-Recruit, please **do not** open a public issue. We ask that you report it privately to ensure the integrity of the platform while we investigate and deploy a patch.

Please report all security vulnerabilities via email to:
**[ferdi@nawasena.site](mailto:ferdi@nawasena.site)**

### What to include in your report:
- A description of the vulnerability and its potential impact.
- Detailed steps to reproduce the issue.
- Any relevant logs, code snippets, or environment details.

### Response Timeline
- We will acknowledge receipt of your vulnerability report within **48 hours**.
- We aim to provide a resolution or mitigation plan within **7 days** of triage.

Thank you for helping us keep Nawa-Recruit secure.
