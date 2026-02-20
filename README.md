# 🎮 Tic-Tac-Toe — DevSecOps CI/CD Pipeline

A complete end-to-end DevSecOps CI/CD pipeline for a React + TypeScript web application, featuring automated security scanning at every stage of the software delivery lifecycle.

[![DevSecOps Pipeline](https://github.com/rasikh111/tictactoe-devsecops/actions/workflows/devsecops-pipeline.yml/badge.svg)](https://github.com/rasikh111/tictactoe-devsecops/actions/workflows/devsecops-pipeline.yml)

---

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tech Stack](#tech-stack)
- [Security Tools](#security-tools)
- [Pipeline Stages](#pipeline-stages)
- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [GitHub Secrets Configuration](#github-secrets-configuration)
- [AWS EC2 Setup](#aws-ec2-setup)
- [SonarQube Setup](#sonarqube-setup)
- [Slack Webhook Setup](#slack-webhook-setup)
- [Running the Pipeline](#running-the-pipeline)
- [Deployment](#deployment)
- [Artifacts & Reports](#artifacts--reports)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKSTATION                               │
│                                                                             │
│   git push / pull request  ──────────────────────────────────────────────► │
└───────────────────────────────────────────────────────────┬─────────────────┘
                                                            │
                                                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GITHUB ACTIONS (CI/CD)                             │
│                                                                             │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                │
│  │  Job 1   │   │  Job 2   │   │  Job 3   │   │  Job 4   │                │
│  │ Secrets  │──►│  Deps    │   │  SAST    │──►│  Unit    │                │
│  │ Scan     │   │  Audit   │   │ ESLint + │   │  Tests   │                │
│  │ GitLeaks │   │ npm audit│   │ SonarQube│   │  Vitest  │                │
│  └──────────┘   │ OWASP DC │   └──────────┘   └────┬─────┘                │
│       │         └──────────┘         │              │                      │
│       │               │              │              │                      │
│       └───────────────┴──────────────┘              │                      │
│                                                      ▼                      │
│                                              ┌──────────────┐              │
│                                              │    Job 5     │              │
│                                              │ Docker Build │              │
│                                              │ + Trivy Scan │              │
│                                              └──────┬───────┘              │
│                                                     │                      │
│                                                     ▼                      │
│                                              ┌──────────────┐              │
│                                              │    Job 6     │              │
│                                              │  Deploy to   │              │
│                                              │   AWS EC2    │              │
│                                              └──────┬───────┘              │
│                                                     │                      │
│                                                     ▼                      │
│                                              ┌──────────────┐              │
│                                              │    Job 7     │              │
│                                              │  OWASP ZAP   │              │
│                                              │  DAST Scan   │              │
│                                              └──────┬───────┘              │
│                                                     │                      │
│                                                     ▼                      │
│                                              ┌──────────────┐              │
│                                              │    Job 8     │              │
│                                              │    Slack     │              │
│                                              │ Notification │              │
│                                              └──────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   DOCKER HUB    │  │    AWS EC2      │  │   SONARQUBE     │
│                 │  │                 │  │                 │
│ rasikh111/      │  │ nginx:alpine    │  │ Self-hosted     │
│ tictactoe-app  │  │ container       │  │ Port 9000       │
│ :latest        │  │ Port 80         │  │                 │
│ :<git-sha>     │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  SLACK ALERTS   │
                    │                 │
                    │ #devsecops-     │
                    │  alerts         │
                    │ Pass/Fail msgs  │
                    └─────────────────┘
```

### Docker Multi-Stage Build

```
┌──────────────────────────────────┐     ┌──────────────────────────────────┐
│         STAGE 1: BUILD           │     │        STAGE 2: RUNTIME          │
│                                  │     │                                  │
│  Base: node:20-alpine            │     │  Base: nginx:alpine              │
│                                  │     │                                  │
│  npm ci                          │     │  COPY --from=builder             │
│  npm run build                   │────►│    /app/dist → /usr/share/       │
│                                  │     │    nginx/html                    │
│  Output: /app/dist               │     │                                  │
│  (static HTML/CSS/JS only)       │     │  No Node.js  ✓                  │
│                                  │     │  No dev deps ✓                  │
│                                  │     │  No source   ✓                  │
└──────────────────────────────────┘     └──────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | React + TypeScript | 18.x |
| Build Tool | Vite | 6.x |
| Styling | Tailwind CSS | 3.x |
| Testing | Vitest + jsdom | 3.x |
| Container | Docker (nginx:alpine) | Latest |
| CI/CD | GitHub Actions | — |
| Cloud | AWS EC2 t2.micro | Amazon Linux 2 |
| Code Analysis | SonarQube Community | v26.2 |
| Registry | Docker Hub | — |

---

## Security Tools

| Tool | Type | Purpose |
|------|------|---------|
| **GitLeaks** | SAST · Secrets | Scans Git history for leaked credentials and API keys |
| **npm audit** | SCA | Checks production packages for known CVEs |
| **OWASP Dependency-Check** | SCA | Maps all deps to NIST NVD using CVSS scoring |
| **ESLint** | SAST · Code | Detects security anti-patterns in TypeScript/React |
| **SonarQube Community** | SAST · Quality Gate | Security hotspots, code smells, quality enforcement |
| **Trivy** | Container SAST | Scans Docker image layers for OS and library CVEs |
| **OWASP ZAP** | DAST | Black-box scan of live app for OWASP Top 10 |

---

## Pipeline Stages

```
Push to main
     │
     ▼
┌─────────────────────────────────────────────┐
│ Stage 1 — Secrets Detection                 │
│ Tool: GitLeaks                              │
│ Scans entire Git history for secrets        │
│ FAIL → Pipeline stops immediately           │
└──────────────────────┬──────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────┐     ┌──────────────────────┐
│ Stage 2          │     │ Stage 3               │
│ Dependency Audit │     │ SAST Scan             │
│ npm audit        │     │ ESLint + SonarQube    │
│ OWASP DC         │     │ Quality Gate check    │
└────────┬─────────┘     └──────────┬────────────┘
         └──────────┬───────────────┘
                    ▼
          ┌──────────────────┐
          │ Stage 4          │
          │ Unit Tests       │
          │ Vitest + Coverage│
          └────────┬─────────┘
                   ▼
          ┌──────────────────┐
          │ Stage 5          │
          │ Docker Build     │
          │ Trivy Image Scan │
          │ Push to Hub      │
          └────────┬─────────┘
                   ▼
          ┌──────────────────┐
          │ Stage 6          │
          │ Deploy to EC2    │
          │ SSH + Docker run │
          └────────┬─────────┘
                   ▼
          ┌──────────────────┐
          │ Stage 7          │
          │ OWASP ZAP DAST   │
          │ Live app scan    │
          └────────┬─────────┘
                   ▼
          ┌──────────────────┐
          │ Stage 8          │
          │ Slack Notify     │
          │ Always runs      │
          └──────────────────┘
```

---

## Prerequisites

Make sure you have the following installed locally:

- [Node.js](https://nodejs.org/) v20+
- [npm](https://www.npmjs.com/) v9+
- [Docker](https://www.docker.com/)
- [Git](https://git-scm.com/)
- AWS account with EC2 access
- Docker Hub account
- SonarQube instance (or use the EC2 setup below)
- Slack workspace with webhook access

---

## Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/rasikh111/tictactoe-devsecops.git
cd tictactoe-devsecops
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Run Locally

```bash
npm run dev
# App available at http://localhost:5173
```

### 4. Run Tests

```bash
npx vitest run --coverage
```

### 5. Build for Production

```bash
npm run build
# Output in /dist
```

### 6. Run with Docker Locally

```bash
docker build -t tictactoe-app .
docker run -d -p 80:80 --name tictactoe tictactoe-app
# App available at http://localhost
```

---

## GitHub Secrets Configuration

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** and add the following secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKER_USERNAME` | Your Docker Hub username | `-` |
| `DOCKER_TOKEN` | Docker Hub access token (not password) | `-` |
| `EC2_HOST` | EC2 public IP address | `-` |
| `EC2_USER` | EC2 login user | `ec2-user` |
| `EC2_SSH_KEY` | Full contents of your `.pem` private key | `-` |
| `SONAR_TOKEN` | SonarQube Global Analysis Token | `-` |
| `SONAR_HOST_URL` | SonarQube server URL | `http://yourpubip:9000` |
| `SLACK_WEBHOOK_URL` | Slack incoming webhook URL | `https://hooks.slack.com/services/...` |

### How to get Docker Hub Token

1. Log in to [hub.docker.com](https://hub.docker.com)
2. **Account Settings** → **Security** → **New Access Token**
3. Name: `github-actions` → **Generate**
4. Copy the token and save as `DOCKER_TOKEN` secret

### How to get EC2 SSH Key

```bash
# The full content of your .pem file including headers
cat your-key.pem
# Copy everything including:
# -
# ...
# -
```

---

## AWS EC2 Setup

### 1. Launch EC2 Instance

- **AMI:** Ubuntu 24
- **Instance type:** t2.micro (free tier)
- **Key pair:** Create or use existing `.pem` key

### 2. Configure Security Group Inbound Rules

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | Your IP only | SSH access |
| HTTP | 80 | 0.0.0.0/0 | Web app access |
| Custom TCP | 9000 | 0.0.0.0/0 | SonarQube UI |

### 3. Install Docker on EC2

SSH into your instance and run:

```bash
# Connect to EC2
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Install Docker
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Verify
docker --version
```

> **Note:** Log out and back in after adding user to docker group.

---

## SonarQube Setup

### 1. Install SonarQube on EC2

```bash
# Install Java (required by SonarQube)
sudo yum install java-17-amazon-corretto -y

# Run SonarQube via Docker
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  sonarqube:community

# Verify running
docker ps | grep sonarqube
```

### 2. Initial SonarQube Configuration

1. Open `http://YOUR_EC2_IP:9000` in browser
2. Login with default credentials: `admin` / `admin`
3. Change the password when prompted
4. Go to **Projects** → **Create Project** → **Manually**
5. Set Project Key: `DevSecOps-Scaning` *(note: one 'n')*
6. Set Display Name: `DevSecOps Scaning`
7. Click **Set Up**

### 3. Generate SonarQube Token

1. Top-right → profile icon → **My Account**
2. **Security** tab
3. Under **Generate Tokens**:
   - Name: `github-token`
   - Type: **Global Analysis Token**
   - Expiry: **No expiration**
4. Click **Generate** → copy the token
5. Save as `SONAR_TOKEN` in GitHub Secrets

### 4. Verify sonar-project.properties

Ensure this file in your repo root matches exactly:

```properties
sonar.projectKey=DevSecOps-Scaning
sonar.projectName=DevSecOps Scaning
sonar.projectVersion=1.0
sonar.sources=src
sonar.tests=src/__tests__
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.exclusions=node_modules/**,dist/**,coverage/**
sonar.sourceEncoding=UTF-8
```

---

## Slack Webhook Setup

### 1. Create a Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App** → **From scratch**
3. Name: `DevSecOps Pipeline` → select your workspace

### 2. Enable Incoming Webhooks

1. In your app settings → **Incoming Webhooks** → toggle **On**
2. Click **Add New Webhook to Workspace**
3. Select the channel (e.g. `#devsecops-alerts`)
4. Click **Allow**
5. Copy the webhook URL (`https://hooks.slack.com/services/...`)
6. Save as `SLACK_WEBHOOK_URL` in GitHub Secrets

---

## Running the Pipeline

### Automatic Trigger

The pipeline runs automatically on:

```yaml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
```

Simply push any commit to `main`:

```bash
git add .
git commit -m "your commit message"
git push origin main
```

### Manual Trigger

GitHub → **Actions** tab → **DevSecOps Pipeline** → **Run workflow**

### Monitor the Pipeline

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Click the latest workflow run
4. Watch each job in real time

Expected total runtime: **~6-7 minutes**

---

## Deployment

The deployment happens automatically in Stage 6 after all security scans pass.

### What happens during deployment

```bash
# Pipeline runs these commands on your EC2 via SSH:

# 1. Pull latest image from Docker Hub
docker pull rasikh111/tictactoe-app:latest

# 2. Stop and remove old container
docker stop tictactoe 2>/dev/null || true
docker rm   tictactoe 2>/dev/null || true

# 3. Start new container
docker run -d \
  --name tictactoe \
  --restart unless-stopped \
  -p 80:80 \
  rasikh111/tictactoe-app:latest

# 4. Verify it's running
docker ps | grep tictactoe

# 5. Clean up old images
docker image prune -f
```

### Access the Live App

After successful deployment, open in your browser:

```
http://YOUR_EC2_IP
```

### Check Container Status on EC2

```bash
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Check running container
docker ps

# View container logs
docker logs tictactoe

# Restart container manually
docker restart tictactoe
```

---

## Artifacts & Reports

After each pipeline run, 6 security artifacts are available under **Actions** → your run → **Artifacts**:

| Artifact | Tool | Contents |
|----------|------|----------|
| `owasp-dependency-report` | OWASP DC | HTML report of all CVEs found in dependencies |
| `eslint-report` | ESLint | JSON report of all linting security violations |
| `coverage-report` | Vitest | HTML coverage report showing tested code % |
| `trivy-container-report` | Trivy | SARIF report of Docker image vulnerabilities |
| `zap-dast-report` | OWASP ZAP | HTML + JSON report of live app security findings |

---

## File Structure

```
tictactoe-devsecops/
├── .github/
│   └── workflows/
│       └── devsecops-pipeline.yml   # Main CI/CD pipeline
├── .zap/
│   └── rules.tsv                    # ZAP false positive suppressions
├── src/
│   ├── components/                  # React components
│   ├── utils/
│   │   └── gameLogic.ts             # Game logic (tested)
│   ├── __tests__/                   # Unit tests
│   ├── App.tsx
│   └── main.tsx
├── .owasp-suppressions.xml          # OWASP DC suppression rules
├── Dockerfile                       # Multi-stage Docker build
├── nginx.conf                       # nginx with security headers
├── sonar-project.properties         # SonarQube configuration
├── vite.config.ts                   # Vite + Vitest config
├── package.json
└── README.md
```

---

## Troubleshooting

### npm ci fails — package-lock.json out of sync

```bash
# Run locally to regenerate lock file
npm install
git add package.json package-lock.json
git commit -m "fix: regenerate package-lock.json"
git push origin main
```

### SonarQube — HTTP 401 Unauthorized

- Generate a new **Global Analysis Token** (not Project token) in SonarQube
- Update `SONAR_TOKEN` secret in GitHub
- Verify `SONAR_HOST_URL` has no trailing slash: `http://IP:9000`
- Confirm EC2 Security Group allows port `9000`

### SonarQube — Project not found

- Check the project key in SonarQube UI exactly: `DevSecOps-Scaning` (one `n`)
- Must match exactly in `sonar-project.properties`

### EC2 SSH connection failed

- Verify `EC2_SSH_KEY` secret contains the full `.pem` content including `-----BEGIN` and `-----END` lines
- Verify `EC2_USER` is `ec2-user` for Amazon Linux or `ubuntu` for Ubuntu
- Confirm port `22` is open in EC2 Security Group for GitHub Actions IPs

### Docker push denied

- Verify `DOCKER_USERNAME` is your Docker Hub username (not email)
- Regenerate `DOCKER_TOKEN` — use Access Token, not your password
- Confirm the Docker Hub repository exists or auto-create is enabled

### OWASP ZAP — Permission denied

The pipeline already includes the fix:
```yaml
- name: Fix ZAP workspace permissions
  run: chmod -R 777 ${{ github.workspace }}
```
If still failing, ensure you are using the latest pipeline YAML.

### OWASP DC — Suppression file parse error

Use `<vulnerabilityName>` tag for GHSA IDs, not `<cve>` tag:
```xml
<!-- CORRECT for GitHub Advisory IDs -->
<vulnerabilityName>GHSA-3ppc-4f35-3m26</vulnerabilityName>

<!-- CORRECT for CVE IDs only -->
<cve>CVE-2023-12345</cve>
```

---

## Security Gates Summary

The pipeline blocks deployment if any of these are triggered:

| Gate | Condition | Tool |
|------|-----------|------|
| Secrets found in code | Any secret pattern matched | GitLeaks |
| Critical CVE in production deps | CVSS >= critical | npm audit |
| Critical CVE in any dep | CVSS >= 10.0 | OWASP DC |
| Quality Gate failed | SonarQube thresholds not met | SonarQube |
| Unit test failure | Any test fails | Vitest |
| Critical/High CVE in image | Unfixed CRITICAL or HIGH | Trivy |

---

## Contributing

1. Fork the repository

---

*Built with GitHub Actions · Docker · AWS EC2 · All tools free and open-source*
