#!/bin/bash
set -euo pipefail

echo "▶ SigNoz 설치 시작…"

# 1) namespace 생성 (이미 있으면 무시)
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# 2) Helm 레포 업데이트
helm repo add signoz https://charts.signoz.io || helm repo update
helm repo update

# 3) SigNoz 코어 컴포넌트 설치
helm install signoz signoz/signoz \
  --namespace observability \
  --create-namespace \
  -f signoz-values.yaml \
  --wait --timeout 10m

# 4) k8s-infra (Host & Kubelet Metrics) 설치
helm install signoz-infra signoz/k8s-infra \
  --namespace observability \
  -f override-values.yaml \
  --wait --timeout 5m

echo "✅ SigNoz 설치 완료!"
echo "포트포워딩: kubectl port-forward -n observability svc/signoz 3301:8080"