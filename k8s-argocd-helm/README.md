k8s-argocd-helm/
├── apps/
│   ├── backend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── frontend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── signoz/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── infrastructure/
│   ├── alb/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   ├── network/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── secrets/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── argocd/
└── aws-iam/



#### Infrastructure
helm upgrade --install alb ./k8s-argocd-helm/infrastructure/alb -n hertz-tuning-dev
helm upgrade --install network ./k8s-argocd-helm/infrastructure/network -n hertz-tuning-dev
helm upgrade --install secrets ./k8s-argocd-helm/infrastructure/secrets -n hertz-tuning-dev

#### DB
helm upgrade --install mysql ./k8s-argocd-helm/apps/mysql -n hertz-tuning-dev
helm upgrade --install redis ./k8s-argocd-helm/apps/redis -n hertz-tuning-dev
helm upgrade --install kafka ./k8s-argocd-helm/apps/kafka -n hertz-tuning-dev

#### Applications
helm upgrade --install backend ./k8s-argocd-helm/apps/backend -n hertz-tuning-dev
helm upgrade --install frontend ./k8s-argocd-helm/apps/frontend -n hertz-tuning-dev

#### Monitoring
helm upgrade --install signoz ./k8s-argocd-helm/apps/signoz -n observability

#### Ubrella 전체 스택 배포
# 의존성 관리와 순서를 자동으로 처리
helm dependency update ./k8s-argocd-helm
helm upgrade --install hertz-tuning ./k8s-argocd-helm \
  --namespace hertz-tuning-dev \
  --create-namespace



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


