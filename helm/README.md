.
├── charts/                         # (Optional) 헬름 차트 종속성 디렉토리
│   └── myapp/                      # 만약 umbrella chart가 있다면 서브 차트 위치
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── templates/
│       └── .helmignore
│
├── helm/                           # 실제 관리하는 차트들은 이 아래에 둡니다
│   └── nextjs-fe/                  # Next.js FE용 Helm 차트
│       ├── Chart.yaml              # 차트 메타데이터
│       ├── values.yaml             # 기본 값
│       ├── values-dev.yaml         # dev 환경 오버라이드
│       ├── values-prod.yaml        # prod 환경 오버라이드
│       ├── .helmignore             # 패키징 시 제외할 파일
│       ├── templates/              
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── ingress.yaml
│       │   ├── _helpers.tpl        # 공통 템플릿 함수
│       │   └── NOTES.txt           # 설치/업그레이드 후 안내 메시지
│       └── charts/                 # 서브차트(예: 공통 라이브러리) 디렉토리
│
├── apps/                           # GitOps용 App 선언 폴더 (ArgoCD 등)
│   ├── nextjs-fe-app.yaml          # ArgoCD Application CRD 예시
│   └── springboot-be-app.yaml
│
├── scripts/                        # 배포·검증 스크립트
│   ├── deploy-nextjs.sh
│   └── test-ingress.sh
│
├── .github/                        # GitHub Actions 등 CI 설정
│   └── workflows/
│       └── helm-lint.yml
│



# 개발환경 배포 예시
helm upgrade --install nextjs-fe helm/nextjs-fe \
  -f helm/nextjs-fe/values.yaml \
  -f helm/nextjs-fe/values-dev.yaml \
  --set imagePullSecret=ecr-regcred

# 운영환경 배포 예시
helm upgrade --install nextjs-fe helm/nextjs-fe \
  -f helm/nextjs-fe/values.yaml \
  -f helm/nextjs-fe/values-prod.yaml \
  --set imagePullSecret=ecr-regcred


  # 개발 환경
helm upgrade --install springboot-be helm/springboot-be \
  -f helm/springboot-be/values.yaml \
  -f helm/springboot-be/values-dev.yaml \
  --namespace hertz-tuning-dev \
  --create-namespace \
  --set imagePullSecret=ecr-regcred