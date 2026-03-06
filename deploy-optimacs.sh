#!/bin/bash
set -e

NAMESPACE="optimacs"
CHART_PATH="./charts/optimacs"

# Create namespace
echo "Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create TLS secret first
echo "Creating TLS secret..."
kubectl create secret generic ac-server-tls \
  --namespace $NAMESPACE \
  --from-literal=server.crt="$(openssl req -x509 -newkey rsa:4096 -keyout /dev/null -out /dev/stdout -days 365 -nodes -subj '/CN=optimacs' 2>/dev/null)" \
  --from-literal=server.key="$(openssl genrsa 4096 2>/dev/null)" \
  --from-literal=rootCA.crt="$(openssl req -x509 -newkey rsa:4096 -keyout /dev/null -out /dev/stdout -days 365 -nodes -subj '/CN=OptimACS CA' 2>/dev/null)" \
  --from-literal=rootCA.key="$(openssl genrsa 4096 2>/dev/null)" \
  --dry-run=client -o yaml | kubectl apply -f -

# Generate UI secret key
UI_SECRET_KEY=$(openssl rand -hex 32)

# Deploy with corrected settings
echo "Deploying OptimACS..."
helm upgrade --install optimacs $CHART_PATH \
  --namespace $NAMESPACE \
  --set image.repository=gitea.optimcloud.com/optim-enterprises-bv/ac-server \
  --set ui.image.repository=gitea.optimcloud.com/optim-enterprises-bv/optimacs-ui \
  --set image.tag=latest \
  --set ui.image.tag=latest \
  --set db.password=optimacs123 \
  --set mysql.auth.rootPassword=root12345 \
  --set mysql.image.tag=8.4.1-debian-12-r3 \
  --set ui.secretKey=$UI_SECRET_KEY \
  --set mysql.enabled=true \
  --set mysql.architecture=standalone \
  --set redis.enabled=false \
  --set stepca.enabled=false \
  --set emqx.enabled=true \
  --set vector.enabled=false \
  --set databunker.enabled=false \
  --set autoscaling.enabled=false \
  --set networkPolicy.enabled=false \
  --set podSecurityContext.fsGroup=1000 \
  --set podSecurityContext.runAsUser=1000 \
  --set podSecurityContext.runAsGroup=1000 \
  --set securityContext.readOnlyRootFilesystem=false \
  --set securityContext.runAsUser=1000 \
  --set securityContext.runAsGroup=1000 \
  --set securityContext.allowPrivilegeEscalation=false \
  --set securityContext.capabilities.drop[0]=ALL \
  --wait --timeout 10m

echo "Deployment complete!"
echo ""
echo "Check status with: kubectl get pods -n $NAMESPACE"
