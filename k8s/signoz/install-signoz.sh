#!/bin/bash

# SigNoz 설치 스크립트

echo "SigNoz 설치 시작..."

# 네임스페이스 생성
kubectl apply -f namespace.yaml

# SigNoz Helm 레포지토리 추가
helm repo add signoz https://charts.signoz.io
helm repo update

# SigNoz 설치
helm install signoz signoz/signoz \
  --namespace observability \
  --values signoz-values.yaml \
  --create-namespace

echo "SigNoz 설치 완료!"
echo "포트 포워딩으로 접속: kubectl port-forward -n observability svc/signoz-frontend 3301:3301"