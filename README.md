# OptimACS Helm Charts

Helm chart repository for [OptimACS](https://github.com/optim-enterprises-bv/APConfig) — an open-source access-point management platform built on the Broadband Forum **TR-369 / USP** standard.

## Add the repository

```sh
helm repo add optimacs https://optim-enterprises-bv.github.io/helm-charts
helm repo update
```

## Charts

| Chart | Version | Description |
|-------|---------|-------------|
| `optimacs/optimacs` | 0.4.0 | Full OptimACS stack — ac-server (USP Controller), optimacs-ui, EMQX, MySQL, Redis, step-ca |

## Install

```sh
helm install optimacs optimacs/optimacs \
  --namespace optimacs --create-namespace \
  --set db.password=<app-db-password> \
  --set mysql.auth.rootPassword=<mysql-root-password> \
  --set ui.secretKey=$(openssl rand -hex 32) \
  --set ui.ingress.enabled=true \
  --set ui.ingress.hostname=optimacs.example.com
```

See the [full documentation](https://github.com/optim-enterprises-bv/APConfig#15-kubernetes-deployment) for all configuration options, step-ca PKI setup, and upgrade instructions.

## Source

Chart source lives in [`charts/optimacs/`](charts/optimacs/).
Packaged releases and `index.yaml` are served from this branch via GitHub Pages.
