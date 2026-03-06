#!/bin/bash
set -e

NAMESPACE="optimacs"
CHART_PATH="./charts/optimacs"

echo "=== Cleaning up any existing deployment ==="
helm uninstall optimacs -n $NAMESPACE 2>/dev/null || true
kubectl delete namespace $NAMESPACE --force 2>/dev/null || true
sleep 5

echo "=== Creating namespace ==="
kubectl create namespace $NAMESPACE

echo "=== Creating TLS secret ==="
# Generate proper TLS certificates
openssl genrsa -out /tmp/ca.key 4096 2>/dev/null
openssl req -x509 -new -nodes -key /tmp/ca.key -sha256 -days 365 -out /tmp/ca.crt -subj "/CN=OptimACS CA" 2>/dev/null
openssl genrsa -out /tmp/server.key 4096 2>/dev/null
openssl req -new -key /tmp/server.key -out /tmp/server.csr -subj "/CN=optimacs" 2>/dev/null
openssl x509 -req -in /tmp/server.csr -CA /tmp/ca.crt -CAkey /tmp/ca.key -CAcreateserial -out /tmp/server.crt -days 365 -sha256 2>/dev/null

kubectl create secret generic ac-server-tls \
  --namespace $NAMESPACE \
  --from-file=server.crt=/tmp/server.crt \
  --from-file=server.key=/tmp/server.key \
  --from-file=rootCA.crt=/tmp/ca.crt \
  --from-file=rootCA.key=/tmp/ca.key

echo "=== Generating UI secret key ==="
UI_SECRET_KEY=$(openssl rand -hex 32)

echo "=== Deploying OptimACS with correct images ==="
helm upgrade --install optimacs $CHART_PATH \
  --namespace $NAMESPACE \
  --set image.repository=gitea.optimcloud.com/optim-enterprises-bv/ac-server \
  --set ui.image.repository=gitea.optimcloud.com/optim-enterprises-bv/optimacs-ui \
  --set image.tag=latest \
  --set ui.image.tag=latest \
  --set db.password=optimacs123 \
  --set mysql.auth.rootPassword=root12345 \
  --set mysql.auth.database=laravel \
  --set mysql.auth.username=acserver \
  --set mysql.auth.password=optimacs123 \
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
  --wait --timeout 10m

echo ""
echo "=== Deployment Complete ==="
echo "Check status: kubectl get pods -n $NAMESPACE"
echo "Port forward UI: kubectl port-forward svc/optimacs-ui 8080:8080 -n $NAMESPACE"
