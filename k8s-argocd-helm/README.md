k8s-argocd-helm/
├── Chart.yaml
├── values.yaml
├── apps/
│   ├── backend/
│   ├── frontend/
│   ├── mysql/
│   ├── kafka/
│   ├── redis/
│   └── signoz/
├── infrastructure/
│   ├── alb/
│   ├── network/
│   └── secrets/
├── argocd/
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── charts/
│   └── templates/
└── aws-iam/                    # 정적 IAM 정책 파일들
    ├── alb_controller_iam_policy.json
    └── ssm-parameter-policy.json


#### 전체 스택 배포
helm upgrade --install hertz-tuning ./k8s-argocd-helm \
  --namespace hertz-tuning-dev \
  --create-namespace \
  --set global.accountId=$AWS_ACCOUNT_ID \
  --set image.repository=$ECR_REPOSITORY_URL \
  --set ingress.certificateArn=$ACM_CERTIFICATE_ARN \
  --set externalSecrets.secretStore.path=$SSM_PARAMETER_STORE_PATH


#### 파드 상태 확인
kubectl get pods -n hertz-tuning-dev

#### HPA 상태 확인
kubectl get hpa -n hertz-tuning-dev

#### 서비스 확인
kubectl get svc -n hertz-tuning-dev

#### Ingress 확인
kubectl get ingress -n hertz-tuning-dev

#### SigNoz 확인
kubectl get pods -n observability
