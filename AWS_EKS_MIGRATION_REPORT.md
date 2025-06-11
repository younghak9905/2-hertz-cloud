# AWS EKS 마이그레이션 및 애플리케이션 배포 보고서

## 1. 도입

### 1.1. 보고서의 목적 및 범위

본 보고서는 기존 온프레미스 또는 자체 관리형 Kubernetes 환경에서 운영 중인 애플리케이션 및 인프라를 Amazon Web Services (AWS)의 관리형 Kubernetes 서비스인 Amazon Elastic Kubernetes Service (EKS)로 성공적으로 마이그레이션하고, 지정된 애플리케이션 스택을 EKS 환경에 최적화하여 배포 및 운영하기 위한 전략과 절차를 기술하는 것을 목적으로 한다.

**보고서의 범위는 다음을 포함한다:**

*   기존 `kubeadm` 기반 Kubernetes 환경의 현황 분석 (간략).
*   Amazon EKS로의 전환 시 얻을 수 있는 주요 이점 분석.
*   EKS 클러스터 아키텍처 설계 및 구축 방안.
*   대상 애플리케이션 스택(FE, BE, Ingress, Kafka, Websocket, DB)의 EKS 환경 배포 전략 및 Helm 차트 구성안.
*   모니터링, CI/CD 등 인프라 및 운영 도구의 EKS 통합 방안.
*   실제 마이그레이션 수행을 위한 단계별 절차 및 주요 고려 사항.
*   EKS 환경에서의 보안 강화 방안.

본 보고서는 실제 마이그레이션 프로젝트 수행을 위한 가이드라인을 제공하며, 기술적 결정과 실행 계획 수립에 필요한 정보를 포함한다.

### 1.2. 기존 `kubeadm` 환경 개요

현재 운영 중인 시스템은 `kubeadm`을 사용하여 자체적으로 구축 및 관리되는 Kubernetes 클러스터 환경에 배포되어 있다. 이 환경은 초기 Kubernetes 도입 및 학습, 그리고 특정 워크로드 운영에는 적합했으나, 클러스터의 라이프사이클 관리(설치, 업그레이드, 패치), 컨트롤 플레인 및 etcd의 고가용성 확보, 최신 보안 업데이트 적용, 그리고 AWS의 다양한 서비스와의 유연한 통합 측면에서 운영 부담이 증가하고 있는 상황이다.

주요 특징은 다음과 같다:
*   **클러스터 구성**: `kubeadm`을 통한 수동 또는 반자동 구성.
*   **인프라 관리**: 물리 서버 또는 가상 머신에 대한 직접적인 관리 필요.
*   **확장성**: 수동 또는 별도의 자동화 스크립트를 통한 노드 확장.
*   **통합**: AWS 서비스(IAM, 로드밸런서, 스토리지 등)와의 통합이 제한적이거나 복잡함.

이러한 환경은 Kubernetes 자체의 운영 및 관리에 상당한 시간과 노력이 요구되어, 핵심 비즈니스 애플리케이션 개발 및 개선에 집중하기 어려운 도전 과제를 안고 있다.

### 1.3. Amazon EKS로의 전환 이점

Amazon EKS는 AWS에서 완전 관리형 Kubernetes 컨트롤 플레인을 제공하는 서비스로, 기존 `kubeadm` 환경 대비 다음과 같은 명확한 이점을 제공하여 마이그레이션의 당위성을 높인다.

*   **운영 부담 감소**:
    *   AWS가 Kubernetes 컨트롤 플레인(API 서버, etcd 등)의 설치, 확장, 고가용성, 백업 및 업그레이드를 자동으로 관리하므로, 인프라 관리 부담이 크게 줄어든다.
    *   `etcd`의 안정성 및 성능 관리에 대한 걱정 해소.
*   **고가용성 및 안정성 향상**:
    *   EKS는 기본적으로 여러 가용 영역(AZ)에 걸쳐 컨트롤 플레인을 분산시켜 고가용성을 보장한다.
    *   AWS의 견고한 인프라 위에서 실행되어 안정적인 서비스 운영이 가능하다.
*   **AWS 서비스와의 긴밀한 통합**:
    *   IAM (Identity and Access Management): 세분화된 접근 제어를 위한 IAM 역할 및 사용자 통합 (IRSA - IAM Roles for Service Accounts).
    *   ELB (Elastic Load Balancing): Application Load Balancer (ALB) 및 Network Load Balancer (NLB)와의 손쉬운 통합으로 트래픽 분산 및 SSL/TLS 관리 용이.
    *   ECR (Elastic Container Registry): 안전하고 확장 가능한 프라이빗 Docker 컨테이너 레지스트리.
    *   VPC (Virtual Private Cloud): 격리된 가상 네트워크 환경 제공.
    *   EBS (Elastic Block Store), EFS (Elastic File System), FSx: 다양한 영구 스토리지 옵션 제공.
    *   CloudWatch, CloudTrail: 로깅 및 모니터링 통합.
    *   AWS Secrets Manager, Parameter Store: 민감 정보 및 설정 관리 용이.
*   **보안 및 규정 준수**:
    *   AWS의 보안 모범 사례 및 다양한 규정 준수 프로그램(PCI DSS, ISO, SOC 등) 활용 가능.
    *   최신 Kubernetes 버전에 대한 보안 패치가 신속하게 적용됨.
*   **확장성 및 유연성**:
    *   관리형 노드 그룹(Managed Node Groups) 및 Fargate를 통한 유연한 워커 노드 관리 및 자동 확장.
    *   다양한 EC2 인스턴스 유형 선택 가능.
*   **커뮤니티 및 생태계**:
    *   순수 Kubernetes(Upstream Kubernetes) 환경을 제공하여 CNCF 생태계의 다양한 도구 및 솔루션과의 호환성이 높다.

이러한 이점들을 통해, EKS로의 전환은 인프라 관리의 복잡성을 줄이고, 개발팀이 애플리케이션 개발 및 혁신에 더 집중할 수 있도록 지원하며, 전반적인 서비스의 안정성과 확장성을 크게 향상시킬 수 있을 것으로 기대된다.

## 2. Amazon EKS 클러스터 설계 및 구축 전략

성공적인 EKS 마이그레이션 및 운영을 위해서는 초기 클러스터 설계가 매우 중요하다. 본 섹션에서는 EKS 클러스터의 핵심 구성 요소들에 대한 설계 전략을 기술한다.

### 2.1. AWS 네트워킹 구성 (VPC, 서브넷, 보안 그룹)

EKS 클러스터는 AWS의 Virtual Private Cloud (VPC) 내에 구축되므로, VPC 및 관련 네트워킹 요소들의 설계가 선행되어야 한다.

*   **VPC (Virtual Private Cloud)**:
    *   **리전 선택**: 애플리케이션 사용자의 지리적 위치, 지연 시간 요구사항, AWS 서비스 가용성 등을 고려하여 최적의 AWS 리전을 선택한다.
    *   **CIDR 블록**: EKS 클러스터, 노드, 파드, 서비스 IP 등을 충분히 수용할 수 있는 VPC CIDR 블록을 계획한다. (예: `/16` 또는 `/20`) 너무 작게 설정하면 향후 IP 부족 문제가 발생할 수 있다.
    *   **고가용성 설계**: 최소 2개 이상의 가용 영역(Availability Zone, AZ)을 사용하도록 VPC를 설계하여 EKS 컨트롤 플레인 및 워커 노드의 고가용성을 확보한다.

*   **서브넷 (Subnets)**:
    *   **퍼블릭 서브넷 및 프라이빗 서브넷**:
        *   **퍼블릭 서브넷**: 인터넷 게이트웨이(IGW)와 직접 연결되어 외부 인터넷 접근이 가능한 서브넷. 주로 Bastion Host, NAT 게이트웨이, 외부용 Application Load Balancer (ALB) 등이 위치한다.
        *   **프라이빗 서브넷**: 외부에서 직접 접근할 수 없으며, NAT 게이트웨이를 통해 아웃바운드 인터넷 통신만 허용되는 서브넷. EKS 워커 노드는 보안을 위해 프라이빗 서브넷에 배치하는 것이 일반적이다.
    *   **가용 영역(AZ) 분산**: 각 서브넷은 특정 AZ에 속하며, 고가용성을 위해 여러 AZ에 걸쳐 서브넷을 분산 배치한다. (예: 각 AZ마다 퍼블릭 서브넷 1개, 프라이빗 서브넷 1개 이상).
    *   **IP 주소 충분성**: 각 서브넷의 CIDR 블록은 예상되는 노드 및 파드 수, 그리고 AWS 서비스(예: 로드밸런서)에서 사용하는 IP 수를 고려하여 충분한 크기로 할당한다. EKS는 파드 네트워킹을 위해 VPC CNI를 사용하므로, 노드당 할당 가능한 파드 수와 IP 주소 관리가 중요하다.

*   **라우팅 테이블 (Route Tables)**:
    *   퍼블릭 서브넷은 IGW를 향하는 기본 경로를, 프라이빗 서브넷은 NAT 게이트웨이를 향하는 기본 경로를 갖도록 설정한다.

*   **NAT 게이트웨이 (NAT Gateway)**:
    *   프라이빗 서브넷의 워커 노드가 외부 인터넷(예: ECR에서 이미지 다운로드, 외부 API 호출 등)에 접근할 수 있도록 퍼블릭 서브넷에 NAT 게이트웨이를 배치한다. 고가용성을 위해 각 AZ에 NAT 게이트웨이를 배치하거나, 리전 단위의 NAT 게이트웨이를 고려할 수 있다.

*   **보안 그룹 (Security Groups)**:
    *   **EKS 클러스터 보안 그룹**: EKS 컨트롤 플레인과 워커 노드 간의 통신을 허용하도록 자동으로 생성되거나 사용자가 지정할 수 있다. 필요한 포트(예: 443, 10250)에 대한 규칙을 포함한다.
    *   **노드 보안 그룹**: 워커 노드에 적용되며, 컨트롤 플레인과의 통신, 파드 간 통신, 로드밸런서로부터의 트래픽 등을 허용하도록 설정한다. 최소 권한 원칙에 따라 필요한 포트만 개방한다.
    *   **애플리케이션별 보안 그룹**: 필요에 따라 애플리케이션 로드밸런서나 데이터베이스 등에 별도의 보안 그룹을 적용하여 접근 제어를 강화한다.

*   **네트워크 ACL (Network Access Control Lists)**:
    *   서브넷 수준의 방화벽 역할을 하며, 보안 그룹과 함께 다층 방어(defense-in-depth) 전략을 구현한다. 상태 비저장(stateless)이므로 인바운드 및 아웃바운드 규칙을 모두 명시적으로 정의해야 한다.

### 2.2. EKS 컨트롤 플레인 설정

EKS 컨트롤 플레인은 AWS에서 완전 관리형으로 제공되지만, 몇 가지 주요 설정을 사용자가 지정할 수 있다.

*   **Kubernetes 버전**:
    *   애플리케이션 호환성, 필요한 기능, CNCF의 지원 주기 등을 고려하여 EKS에서 지원하는 Kubernetes 버전 중 적절한 버전을 선택한다. 최신 안정 버전을 사용하는 것이 일반적이지만, 충분한 테스트가 필요하다.
*   **API 서버 엔드포인트 접근**:
    *   **퍼블릭 접근**: 인터넷을 통해 API 서버에 접근 가능. IP 주소 기반으로 접근을 제한할 수 있다.
    *   **프라이빗 접근**: VPC 내부에서만 API 서버에 접근 가능. 보안성이 높지만, VPC 외부에서의 `kubectl` 접근 등을 위해 추가 설정(예: Bastion Host, VPN, AWS Direct Connect)이 필요할 수 있다.
    *   **퍼블릭 및 프라이빗 접근 혼용**: 가장 유연한 옵션.
*   **클러스터 로깅**:
    *   API 서버 로그, 감사(Audit) 로그, 인증자(Authenticator) 로그, 컨트롤러 매니저(Controller Manager) 로그, 스케줄러(Scheduler) 로그 등을 Amazon CloudWatch Logs로 전송하도록 설정할 수 있다. 문제 해결 및 보안 감사에 매우 유용하다.

### 2.3. EKS 노드 그룹 구성 (관리형 노드 그룹/Fargate)

워커 노드는 애플리케이션 파드가 실행되는 EC2 인스턴스 또는 AWS Fargate로 구성된다.

*   **관리형 노드 그룹 (Managed Node Groups)**:
    *   AWS가 EC2 인스턴스의 프로비저닝, 업그레이드, 패치 등을 자동화하여 관리 부담을 줄여준다.
    *   **인스턴스 타입 선택**: 애플리케이션의 CPU, 메모리, 네트워크, 스토리지 요구사항에 맞춰 다양한 EC2 인스턴스 타입(예: m5, c5, r5, t3 등)을 선택한다. 비용 효율성도 고려한다.
    *   **AMI (Amazon Machine Image)**: EKS 최적화 AMI (Amazon Linux 2, Bottlerocket, Windows Server 등)를 사용한다. 커스텀 AMI도 사용 가능하지만 관리가 복잡해질 수 있다.
    *   **디스크 크기**: EBS 볼륨의 크기를 애플리케이션 데이터, Docker 이미지, 로그 등을 충분히 저장할 수 있도록 설정한다.
    *   **Auto Scaling 그룹 설정**:
        *   최소(Min), 최대(Max), 희망(Desired) 노드 수를 설정하여 워크로드 변화에 따른 자동 확장을 지원한다.
        *   Cluster Autoscaler와 연동하여 파드 수요에 따라 노드 수를 동적으로 조절할 수 있다.
    *   **노드 레이블 및 테인트**: 특정 워크로드를 특정 노드 그룹에 배치하거나, 특정 노드에서 워크로드가 실행되지 않도록 설정할 수 있다.
    *   **업데이트 전략**: 노드 그룹 업데이트 시 롤링 업데이트 또는 블루/그린 배포 방식 등을 설정할 수 있다.

*   **AWS Fargate**:
    *   서버리스 컨테이너 실행 환경으로, EC2 인스턴스를 직접 관리할 필요가 없다.
    *   파드별로 리소스를 할당하고 비용을 지불한다.
    *   장점: 인프라 관리 부담 최소화, 보안 강화(파드 격리).
    *   단점: Stateful 워크로드 지원 제한, 데몬셋(DaemonSet) 지원 안 함, 특정 EC2 기능(예: GPU) 사용 불가, 비용 모델이 다름.
    *   특정 워크로드(예: 배치 작업, 상태 비저장 웹 애플리케이션)에 적합할 수 있다. Fargate 프로파일을 사용하여 어떤 파드가 Fargate에서 실행될지 지정한다.

*   **자체 관리형 노드 (Self-Managed Nodes)**: (일반적으로 권장되지 않음)
    *   사용자가 EC2 인스턴스를 직접 생성하고 EKS 클러스터에 연결하는 방식. 유연성은 높지만, AMI 관리, 업그레이드, 패치 등을 모두 직접 수행해야 하므로 운영 부담이 매우 크다.

### 2.4. IAM 역할 및 정책 설계 (클러스터 역할, 노드 역할, IRSA)

AWS 리소스에 대한 안전한 접근 제어를 위해 IAM(Identity and Access Management) 역할 및 정책을 신중하게 설계해야 한다.

*   **EKS 클러스터 IAM 역할**:
    *   EKS 서비스가 사용자를 대신하여 AWS 리소스(예: EC2, ELB)를 관리하는 데 필요한 권한을 부여하는 역할. EKS 클러스터 생성 시 필요하다.
    *   `AmazonEKSClusterPolicy` 관리형 정책을 주로 사용한다.
*   **노드 인스턴스 IAM 역할**:
    *   EKS 워커 노드(EC2 인스턴스)가 EKS 컨트롤 플레인과 통신하고, ECR에서 이미지를 가져오거나 CloudWatch에 로그를 전송하는 등 AWS API를 호출하는 데 필요한 권한을 부여하는 역할.
    *   `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy` 등의 관리형 정책을 주로 사용한다.
*   **IRSA (IAM Roles for Service Accounts)**:
    *   Kubernetes 서비스 어카운트에 IAM 역할을 직접 연결하여, 파드 내의 애플리케이션이 AWS 리소스에 안전하게 접근할 수 있도록 하는 기능.
    *   예를 들어, S3 버킷에 접근해야 하는 파드는 해당 권한을 가진 IAM 역할을 서비스 어카운트에 연결하여 사용한다.
    *   노드 인스턴스 역할에 광범위한 권한을 부여하는 대신, 각 애플리케이션에 필요한 최소한의 권한만 부여할 수 있어 보안성이 향상된다.
    *   OpenID Connect (OIDC) 자격 증명 공급자를 EKS 클러스터에 생성해야 한다.

### 2.5. 클러스터 생성 방법 요약 (`eksctl`, AWS Console 등)

EKS 클러스터를 생성하는 주요 방법은 다음과 같다.

*   **`eksctl`**:
    *   AWS와 Weaveworks가 공동으로 개발한 EKS 공식 CLI 도구.
    *   YAML 설정 파일을 통해 클러스터 및 노드 그룹 생성을 자동화할 수 있어 매우 편리하다.
    *   VPC, 서브넷, IAM 역할 등 필요한 리소스를 자동으로 생성하거나 기존 리소스를 사용할 수 있다.
    *   예시: `eksctl create cluster --name my-cluster --region ap-northeast-2 --nodegroup-name standard-workers --node-type m5.large --nodes 3 --nodes-min 1 --nodes-max 4 --managed`
*   **AWS Management Console**:
    *   웹 기반 UI를 통해 단계별로 EKS 클러스터 및 관련 리소스를 생성할 수 있다.
    *   시각적으로 설정을 확인할 수 있어 처음 사용자에게 유용할 수 있지만, 반복적인 작업이나 자동화에는 부적합하다.
*   **AWS CloudFormation / Terraform**:
    *   IaC (Infrastructure as Code) 도구를 사용하여 EKS 클러스터 및 모든 관련 AWS 리소스를 코드로 정의하고 관리할 수 있다.
    *   반복 가능하고 일관된 환경 구성에 매우 유용하며, 버전 관리 및 변경 추적이 용이하다.
    *   복잡한 환경이나 대규모 배포에 권장된다.

클러스터 생성 시, 선택한 CNI 플러그인(예: AWS VPC CNI가 기본), CoreDNS, `kube-proxy` 애드온이 자동으로 설치 및 관리된다.

## 3. 애플리케이션 스택별 EKS 배포 전략
### 3.1. 프론트엔드 (Next.js)

Next.js 기반의 프론트엔드 애플리케이션을 EKS에 배포하기 위한 전략은 다음과 같다.

#### 3.1.1. ECR 이미지 관리

*   **Dockerfile 최적화**: Next.js 애플리케이션의 Docker 이미지를 효율적으로 빌드하기 위해 멀티 스테이지 빌드(multi-stage build)를 사용한다. 첫 번째 스테이지에서는 의존성 설치 및 `next build`를 수행하고, 두 번째 스테이지에서는 빌드된 결과물(` .next` 폴더, `public` 폴더, `package.json`, `next.config.js` 등)만을 경량화된 Node.js 런타임 이미지(예: `node:18-alpine`)에 복사하여 최종 이미지 크기를 최소화한다.
*   **이미지 버전 관리**: Git 태그나 커밋 해시를 사용하여 Docker 이미지 태그를 관리하고, ECR에 푸시한다. 이를 통해 배포 롤백 및 버전 추적이 용이해진다.
*   **ECR 리포지토리**: Next.js 애플리케이션을 위한 별도의 ECR 프라이빗 리포지토리를 생성하여 이미지를 안전하게 저장 및 관리한다. IAM 권한 설정을 통해 EKS 노드가 ECR에서 이미지를 풀(pull)할 수 있도록 한다. (노드 인스턴스 역할에 `AmazonEC2ContainerRegistryReadOnly` 정책 연결).

#### 3.1.2. Kubernetes 리소스 정의 (Deployment, Service)

*   **Deployment**:
    *   Next.js 애플리케이션 파드를 관리한다.
    *   `replicas`: 초기 복제본 수 및 HPA(Horizontal Pod Autoscaler) 설정을 통해 트래픽에 따른 자동 확장을 고려한다.
    *   `image`: ECR에 푸시된 애플리케이션 이미지를 사용한다.
    *   `containerPort`: Next.js 애플리케이션이 실행되는 포트(기본값: 3000)를 지정한다.
    *   `env`: 필요한 환경 변수(예: `NEXT_PUBLIC_API_URL`, `NODE_ENV=production` 등)는 `ConfigMap` 또는 `Secret`을 통해 주입한다.
    *   `readinessProbe` 및 `livenessProbe`: Next.js 애플리케이션의 상태를 확인할 수 있는 헬스 체크 엔드포인트(예: 간단한 API 라우트 `/api/healthz`)를 설정한다.
    *   `resources`: CPU 및 메모리 요청(requests)과 제한(limits)을 설정하여 리소스 사용을 최적화한다.
*   **Service**:
    *   Next.js 파드에 대한 내부 접근을 위해 `ClusterIP` 타입의 서비스를 생성한다.
    *   외부 트래픽은 Ingress를 통해 이 서비스로 라우팅된다.
    *   `selector`는 Deployment의 파드 레이블과 일치시킨다.
    *   `port`는 80 또는 애플리케이션이 사용하는 포트(예: 3000)로 설정하고, `targetPort`는 컨테이너 포트를 가리킨다.

#### 3.1.3. Helm 차트 구성안

Next.js 애플리케이션 배포를 위해 다음과 같은 구조의 Helm 차트를 구성한다.

*   **`Chart.yaml`**: 차트 정보 (이름: `nextjs-app`, 버전, 설명 등).
*   **`values.yaml`**: 사용자 정의 가능한 설정 값 정의.
    ```yaml
    # values.yaml (nextjs-app)
    replicaCount: 2
    image:
      repository: "<aws_account_id>.dkr.ecr.<region>.amazonaws.com/my-nextjs-app"
      tag: "latest" # CI/CD 파이프라인에서 동적으로 설정 권장
      pullPolicy: IfNotPresent
    service:
      type: ClusterIP
      port: 80 # 서비스가 노출할 포트
      targetPort: 3000 # Next.js 컨테이너 포트
    ingress: # Ingress 설정은 Umbrella 차트나 별도 Ingress 차트에서 관리될 수 있음
      enabled: true
      host: "app.example.com"
      path: "/"
      annotations: {} # Ingress 컨트롤러에 따른 추가 어노테이션
    config:
      apiUrl: "http://api.example.com/api" # 백엔드 API 주소
      nodeEnv: "production"
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPUUtilizationPercentage: 75
    # readinessProbePath: "/api/healthz"
    # livenessProbePath: "/api/healthz"
    ```
*   **`templates/deployment.yaml`**: Deployment 리소스 템플릿. `values.yaml`의 값을 참조하여 이미지, 복제본 수, 환경 변수, 프로브, 리소스 등을 설정.
*   **`templates/service.yaml`**: Service 리소스 템플릿. `values.yaml`의 값을 참조하여 서비스 타입, 포트 등을 설정.
*   **`templates/hpa.yaml`**: HorizontalPodAutoscaler 리소스 템플릿 (선택 사항).
*   **`templates/configmap.yaml`**: 환경 변수 등을 위한 ConfigMap 리소스 템플릿 (선택 사항).
*   **`templates/_helpers.tpl`**: 공통 레이블, 이름 등을 위한 헬퍼 템플릿.

### 3.2. Ingress (AWS Load Balancer Controller / Nginx)

EKS 클러스터 외부에서 내부 서비스로 HTTP/HTTPS 트래픽을 라우팅하기 위해 Ingress를 구성한다. AWS 환경에서는 AWS Load Balancer Controller를 사용하는 것이 권장된다.

#### 3.2.1. AWS Load Balancer Controller 설치 및 구성

*   **역할**: Kubernetes Ingress 리소스를 모니터링하고, 이에 따라 Application Load Balancer (ALB) 또는 Network Load Balancer (NLB)를 자동으로 프로비저닝 및 설정한다.
*   **설치 방법**:
    1.  **IAM OIDC 공급자 생성**: EKS 클러스터에 OIDC 공급자를 생성하여 IRSA(IAM Roles for Service Accounts)를 활성화한다. (`eksctl utils associate-iam-oidc-provider --cluster <cluster_name> --approve`)
    2.  **AWS Load Balancer Controller IAM 정책 생성**: 필요한 권한(ALB/NLB 생성, 수정, 삭제 등)을 가진 IAM 정책을 생성한다. (AWS 공식 문서 제공 JSON 활용).
    3.  **IAM 역할 생성 및 서비스 어카운트 연결 (IRSA)**: AWS Load Balancer Controller 파드가 사용할 Kubernetes 서비스 어카운트(`aws-load-balancer-controller`)를 생성하고, 위에서 만든 IAM 역할을 이 서비스 어카운트에 연결한다.
    4.  **Helm 차트를 이용한 컨트롤러 배포**: EKS 공식 Helm 차트 저장소를 사용하여 `aws-load-balancer-controller`를 배포한다. 이때, 위에서 생성한 서비스 어카운트 이름을 `values.yaml` 또는 `--set` 옵션으로 지정한다.
        ```bash
        helm repo add eks https://aws.github.io/eks-charts
        helm repo update eks
        helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
          -n kube-system \
          --set clusterName=<cluster_name> \
          --set serviceAccount.create=false \
          --set serviceAccount.name=aws-load-balancer-controller
        ```
*   **ALB vs NLB 선택**:
    *   **ALB (Application Load Balancer)**: HTTP/HTTPS (L7) 로드 밸런싱에 적합. 경로 기반 라우팅, 호스트 기반 라우팅, SSL/TLS 종료, WAF 통합 등 다양한 기능 제공. Next.js, Spring Boot 등 웹 애플리케이션에 주로 사용.
    *   **NLB (Network Load Balancer)**: TCP/UDP/TLS (L4) 로드 밸런싱에 적합. 고성능, 낮은 지연 시간, 고정 IP 제공. 웹소켓, Kafka 등 TCP 기반 트래픽이나 성능이 매우 중요한 서비스에 사용.

#### 3.2.2. Ingress 리소스 정의 및 라우팅 규칙

*   `apiVersion: networking.k8s.io/v1`
*   `kind: Ingress`
*   **`ingressClassName: alb`**: AWS Load Balancer Controller를 사용하도록 지정.
*   **Annotations**: ALB/NLB의 특정 동작을 제어하기 위해 다양한 어노테이션을 사용한다.
    *   `alb.ingress.kubernetes.io/scheme: internet-facing` (외부용) 또는 `internal` (내부용).
    *   `alb.ingress.kubernetes.io/target-type: ip` (Fargate 또는 VPC CNI 사용 시 권장) 또는 `instance`.
    *   `alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'`
    *   `alb.ingress.kubernetes.io/certificate-arn: <acm_certificate_arn>` (HTTPS용 ACM 인증서 ARN).
    *   `alb.ingress.kubernetes.io/ssl-redirect: '443'` (HTTP를 HTTPS로 리디렉션).
    *   `alb.ingress.kubernetes.io/group.name: <group-name>` (여러 Ingress 리소스를 단일 ALB로 그룹화).
    *   기타: 헬스 체크 설정, 타임아웃, WAF 연동, 인증(Cognito, OIDC) 등.
*   **Rules**:
    *   `host`: 도메인 이름 (예: `app.example.com`).
    *   `http.paths`:
        *   `path`: URL 경로 (예: `/`, `/api`).
        *   `pathType`: `Prefix`, `Exact`, `ImplementationSpecific`.
        *   `backend.service.name`: 라우팅 대상 Kubernetes 서비스 이름.
        *   `backend.service.port.number`: 대상 서비스 포트.

#### 3.2.3. SSL/TLS 인증서 관리

*   **AWS Certificate Manager (ACM)**: AWS에서 제공하는 무료 SSL/TLS 인증서 발급 및 관리 서비스.
*   ACM에서 인증서를 발급받고, 해당 ARN(Amazon Resource Name)을 Ingress 리소스의 `alb.ingress.kubernetes.io/certificate-arn` 어노테이션에 지정하여 ALB에 적용한다.
*   여러 호스트 또는 와일드카드 인증서 사용 가능.

**Nginx Ingress Controller (대안)**:
만약 기존 환경에서 Nginx Ingress Controller를 사용하고 있었고, 특정 Nginx 기능(예: 고급 rewrite 규칙, 특정 모듈)이 반드시 필요하거나 ALB의 비용 모델이 부담스러운 경우, EKS에서도 Nginx Ingress Controller를 직접 설치하여 사용할 수 있다. 이 경우 NLB를 통해 Nginx Ingress Controller 서비스로 트래픽을 전달받는 구성을 고려할 수 있다. 하지만 AWS 환경에서는 일반적으로 AWS Load Balancer Controller 사용이 관리 및 통합 측면에서 더 유리하다.

### 3.3. 백엔드 (Spring Boot)

Spring Boot 기반의 백엔드 애플리케이션을 EKS에 배포하기 위한 전략은 다음과 같다.

#### 3.3.1. ECR 이미지 관리

*   **Dockerfile 최적화**:
    *   Spring Boot 애플리케이션의 경우, JRE만 포함된 경량 베이스 이미지(예: `amazoncorretto:17-alpine-jre`)를 사용하고, 빌드된 JAR 파일을 복사하는 형태로 Dockerfile을 작성한다.
    *   멀티 스테이지 빌드를 활용하여, 첫 번째 스테이지에서 Maven 또는 Gradle을 사용하여 애플리케이션을 빌드하고 테스트하며, 두 번째 스테이지에서 생성된 JAR 파일만을 JRE 베이스 이미지에 추가하여 최종 이미지 크기를 최적화한다.
    *   Spring Boot Actuator를 포함하여 헬스 체크 및 메트릭 수집이 용이하도록 한다.
*   **이미지 버전 관리**: Git 태그나 커밋 해시를 사용하여 Docker 이미지 태그를 관리하고, ECR에 푸시한다.
*   **ECR 리포지토리**: 백엔드 애플리케이션을 위한 별도의 ECR 프라이빗 리포지토리를 생성하고, IAM 권한을 통해 EKS 노드가 이미지를 풀(pull)할 수 있도록 설정한다.

#### 3.3.2. Kubernetes 리소스 정의 (Deployment, Service, HPA)

*   **Deployment**:
    *   Spring Boot 애플리케이션 파드를 관리한다.
    *   `replicas`: 초기 복제본 수 및 HPA 설정을 통해 자동 확장을 구성한다.
    *   `image`: ECR에 푸시된 애플리케이션 이미지를 사용한다.
    *   `containerPort`: Spring Boot 애플리케이션이 실행되는 포트(예: 8080)를 지정한다.
    *   `env`: 데이터베이스 접속 정보, 외부 서비스 API 키, Spring Profiles (`SPRING_PROFILES_ACTIVE=eks` 등) 등의 환경 변수는 `ConfigMap` 및 `Secret` (특히 AWS Secrets Manager 또는 Parameter Store 연동)을 통해 안전하게 주입한다.
    *   `readinessProbe` 및 `livenessProbe`: Spring Boot Actuator의 `/actuator/health/readiness` 및 `/actuator/health/liveness` 엔드포인트를 사용하여 애플리케이션 상태를 정교하게 확인한다. 초기 지연 시간(initialDelaySeconds) 및 주기(periodSeconds)를 적절히 설정한다.
    *   `resources`: JVM 기반 애플리케이션의 특성을 고려하여 CPU 및 메모리 요청(requests)과 제한(limits)을 신중하게 설정한다. 특히 메모리 설정 시 JVM 힙 사이즈(`-Xms`, `-Xmx`)와 컨테이너 메모리 제한 간의 관계를 고려한다. (예: `JAVA_TOOL_OPTIONS` 환경 변수 사용).
*   **Service**:
    *   일반적으로 백엔드 서비스는 클러스터 내부에서만 접근 가능하도록 `ClusterIP` 타입의 서비스를 생성한다.
    *   프론트엔드 또는 다른 내부 서비스로부터의 요청을 받는다.
    *   `selector`는 Deployment의 파드 레이블과 일치시킨다.
    *   `port`는 서비스가 노출할 포트(예: 8080), `targetPort`는 컨테이너 포트를 가리킨다.
*   **HorizontalPodAutoscaler (HPA)**:
    *   CPU 사용률, 메모리 사용률 또는 커스텀 메트릭(예: 초당 요청 수 - RPS)에 기반하여 Deployment의 파드 수를 자동으로 확장하거나 축소한다.
    *   `minReplicas`, `maxReplicas` 및 목표 사용률을 `values.yaml`을 통해 설정 가능하도록 한다.

#### 3.3.3. 설정 및 Secret 관리 (ConfigMap, AWS Secrets Manager/Parameter Store 연동)

*   **ConfigMap**:
    *   애플리케이션의 비민감성 설정 정보(예: `application.properties` 또는 `application.yml`의 일부, 활성 프로파일, 외부 서비스 URL 등)를 관리한다.
    *   파일 형태로 마운트하거나 환경 변수로 주입할 수 있다.
*   **AWS Secrets Manager 또는 AWS Systems Manager Parameter Store**:
    *   데이터베이스 자격 증명, API 키, TLS 인증서 등 민감한 정보는 AWS의 관리형 시크릿 저장소에 안전하게 보관한다.
    *   **AWS Secrets & Configuration Provider (ASCP)** 또는 **Secrets Store CSI Driver**와 같은 도구를 사용하여 EKS 파드에서 이러한 시크릿을 안전하게 참조하고 환경 변수나 파일로 주입한다.
        *   **Secrets Store CSI Driver**: Kubernetes Secret으로 동기화하거나 파드에 직접 파일로 마운트하는 기능을 제공한다. IRSA를 통해 파드별로 세분화된 접근 권한을 부여할 수 있다.
    *   이러한 접근 방식은 Kubernetes `Secret` 오브젝트에 직접 민감 정보를 저장하는 것보다 보안성이 높고 중앙 관리가 용이하다.

#### 3.3.4. Helm 차트 구성안

Spring Boot 백엔드 애플리케이션 배포를 위한 Helm 차트 구성은 다음과 같다.

*   **`Chart.yaml`**: 차트 정보 (이름: `springboot-app`, 버전 등).
*   **`values.yaml`**: 사용자 정의 가능한 설정 값.
    ```yaml
    # values.yaml (springboot-app)
    replicaCount: 2
    image:
      repository: "<aws_account_id>.dkr.ecr.<region>.amazonaws.com/my-springboot-app"
      tag: "latest"
      pullPolicy: IfNotPresent
    service:
      type: ClusterIP
      port: 8080
      targetPort: 8080 # Spring Boot Actuator 포트와 다를 경우 actuator 별도 포트 설정 고려

    # Spring Profiles, 일반 설정 등
    config:
      activeProfiles: "eks,production"
      # 예: application.properties 또는 application.yml 내용을 여기에 직접 넣거나,
      # 별도의 ConfigMap 파일로 관리하고 해당 ConfigMap 이름을 지정할 수 있음.
      # server.port: 8080

    # 데이터베이스 연결 정보, API 키 등 (Secrets Store CSI Driver 사용 예시)
    # secretsStoreCsiDriver:
    #   enabled: true
    #   serviceAccountName: "my-springboot-sa" # IRSA 설정된 서비스 어카운트
    #   secretProviderClass: "my-springboot-aws-secrets" # SecretProviderClass 리소스 이름
      # mountPath: "/mnt/secrets-store" # 파드 내 마운트 경로
      # envVars: # 환경 변수로 주입할 시크릿 키 목록
      #   SPRING_DATASOURCE_USERNAME: "dbUsernameSecret" # SecretProviderClass에 정의된 객체 이름
      #   SPRING_DATASOURCE_PASSWORD: "dbPasswordSecret"

    # AWS Secrets Manager 직접 참조를 위한 환경 변수 (애플리케이션에서 AWS SDK 사용 시)
    # secretsManager:
    #   dbCredentialsSecretName: "prod/mydb/credentials"
    #   apiKeySecretName: "prod/api/myapikey"

    resources:
      requests:
        cpu: "500m"
        memory: "1Gi" # JVM 메모리 설정을 고려
      limits:
        cpu: "1"
        memory: "2Gi"

    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70
      # targetMemoryUtilizationPercentage: 75 # 메모리 기반 스케일링은 신중히 사용

    # Actuator 경로 및 포트 설정
    # management:
    #   port: 8081 # Actuator 포트를 분리하는 경우
    #   endpoints:
    #     web:
    #       base-path: /actuator
    readinessProbe:
      path: "/actuator/health/readiness"
      # port: 8081 # management.port 사용 시
      initialDelaySeconds: 60
      periodSeconds: 10
    livenessProbe:
      path: "/actuator/health/liveness"
      # port: 8081
      initialDelaySeconds: 90
      periodSeconds: 15
    ```
*   **`templates/deployment.yaml`**: Deployment 템플릿. `values.yaml` 참조하여 구성. Secrets Store CSI Driver 사용 시 관련 볼륨 및 볼륨 마운트 설정 포함.
*   **`templates/service.yaml`**: Service 템플릿.
*   **`templates/hpa.yaml`**: HPA 템플릿.
*   **`templates/configmap.yaml`**: (선택 사항) 일반 설정을 위한 ConfigMap.
*   **`templates/secretproviderclass.yaml`**: (선택 사항, Secrets Store CSI Driver 사용 시) AWS Secrets Manager 또는 Parameter Store에서 시크릿을 가져오기 위한 `SecretProviderClass` 리소스 정의.
*   **`templates/_helpers.tpl`**: 공통 헬퍼 템플릿.

이러한 구성을 통해 Spring Boot 애플리케이션을 EKS 환경에 안정적이고 확장 가능하며 안전하게 배포할 수 있다.

### 3.4. 메시지 큐 (Kafka)

안정적이고 확장 가능한 메시지 큐 시스템인 Kafka를 EKS 환경에 배포하고 운영하기 위한 전략은 다음과 같다. AWS 환경에서는 Amazon MSK(Managed Streaming for Apache Kafka)를 우선적으로 고려하고, 필요시 EKS에 직접 Kafka 클러스터를 구축하는 방안도 검토한다.

#### 3.4.1. Amazon MSK 활용 방안 또는 자체 배포 방안

*   **Amazon MSK (Managed Streaming for Apache Kafka)**:
    *   **장점**:
        *   **완전 관리형 서비스**: AWS가 Kafka 클러스터의 프로비저닝, 설정, 확장, 패치, 고가용성(Multi-AZ) 및 Zookeeper 관리를 자동화한다. 운영 부담이 크게 감소한다.
        *   **AWS 통합**: CloudWatch(모니터링), IAM(인증/인가), VPC(네트워크 격리), S3(데이터 스트리밍) 등 다른 AWS 서비스와 긴밀하게 통합된다.
        *   **보안**: 암호화(전송 중/저장 시), VPC 보안 그룹, IAM 접근 제어 등을 통해 보안을 강화할 수 있다.
        *   **확장성 및 안정성**: AWS 인프라 기반으로 높은 처리량과 안정성을 제공하며, 필요에 따라 쉽게 확장 가능하다.
    *   **단점**:
        *   **비용**: 자체 구축 대비 초기 비용 또는 특정 워크로드에서 더 높을 수 있다. (총 소유 비용(TCO) 분석 필요).
        *   **제한된 커스터마이징**: 특정 Kafka 버전이나 고급 구성 옵션에 대한 제어가 자체 구축보다 제한적일 수 있다.
    *   **권장 사항**: 대부분의 경우, 운영 효율성, 안정성, AWS 통합의 이점을 고려할 때 **Amazon MSK 사용을 강력히 권장한다.** 애플리케이션에서는 MSK 클러스터의 부트스트랩 브로커(bootstrap brokers) 주소를 설정하여 연결한다.

*   **EKS에 Kafka 자체 배포 (Self-Managed Kafka on EKS)**:
    *   **장점**:
        *   **완전한 제어**: Kafka 버전, 구성, 토폴로지 등에 대한 완전한 제어권을 가진다.
        *   **비용 최적화 가능성**: 특정 워크로드 및 인스턴스 타입 선택에 따라 비용을 최적화할 수 있다. (단, 운영 비용 포함 시 TCO는 다를 수 있음).
    *   **단점**:
        *   **운영 복잡성 증가**: Kafka 클러스터(브로커, Zookeeper)의 설치, 구성, 모니터링, 업그레이드, 백업, 장애 조치 등을 모두 직접 관리해야 한다. 이는 상당한 전문 지식과 운영 노력을 필요로 한다.
        *   **고가용성 및 안정성 확보 책임**: Multi-AZ 배포, 데이터 복제, Zookeeper 클러스터 안정성 등을 직접 설계하고 구현해야 한다.
    *   **권장 상황**: 매우 특수한 Kafka 구성이 필요하거나, MSK에서 제공하지 않는 기능을 반드시 사용해야 하는 경우, 또는 기존에 Kubernetes에서 Kafka를 운영한 경험과 전문 인력이 충분한 경우에 한해 고려할 수 있다.

#### 3.4.2. Kubernetes 리소스 정의 (StatefulSet, PV/PVC - 자체 배포 시)

EKS에 Kafka를 자체 배포할 경우, 일반적으로 Strimzi 또는 Bitnami/Banzai Cloud에서 제공하는 Kubernetes Operator 또는 Helm 차트를 사용하는 것이 권장된다. 직접 모든 리소스를 정의하는 것은 매우 복잡하다.

만약 직접 구성한다면 주요 리소스는 다음과 같다:

*   **Zookeeper**: (Kafka가 의존하는 경우. KRaft 모드는 Zookeeper 불필요)
    *   `StatefulSet`으로 배포하여 안정적인 ID와 스토리지를 제공한다.
    *   `PersistentVolumeClaim` (PVC) 템플릿을 사용하여 각 Zookeeper 파드에 영구 스토리지를 할당한다. (EBS 사용).
    *   `Service` (Headless Service 및 클라이언트용 ClusterIP Service).
*   **Kafka 브로커**:
    *   `StatefulSet`으로 배포한다. 각 브로커는 고유 ID, 안정적인 네트워크 이름, 전용 스토리지를 가진다.
    *   `volumeClaimTemplates`를 사용하여 각 브로커의 데이터(로그 세그먼트) 저장을 위한 PVC를 동적으로 생성한다. (EBS 사용, I/O 성능 고려).
    *   `ConfigMap`을 사용하여 Kafka 브로커 설정(`server.properties`)을 관리한다 (리스너, 복제 계수, 로그 보존 정책 등).
    *   `Service`:
        *   **Headless Service**: 각 브로커 파드에 대한 안정적인 DNS 이름을 제공 (`<pod-name>.<headless-service-name>`). 브로커 간 통신 및 클라이언트의 특정 파티션 접근에 사용.
        *   **Bootstrap Service (ClusterIP 또는 LoadBalancer)**: 클라이언트가 Kafka 클러스터에 처음 연결하기 위한 단일 진입점(bootstrap server)을 제공. 외부 접근이 필요하면 NLB 타입의 LoadBalancer 서비스를 고려할 수 있으나, 리스너 설정 및 보안에 매우 주의해야 한다.
    *   **리스너(Listeners) 및 광고된 리스너(Advertised Listeners)**: Kubernetes 환경(특히 EKS)에서 가장 복잡한 설정 중 하나. 파드 내부 IP, 서비스 DNS, 외부 접근 주소 등을 올바르게 설정해야 클라이언트 및 브로커 간 통신이 가능하다. AWS VPC CNI의 네트워킹 특성을 이해해야 한다.

#### 3.4.3. Helm 차트 구성안

*   **Amazon MSK 사용 시**:
    *   애플리케이션 Helm 차트의 `values.yaml`에 MSK 클러스터의 부트스트랩 서버 주소 및 관련 보안 설정을 구성한다. 별도의 Kafka 클러스터 배포용 Helm 차트는 필요 없다.
    *   애플리케이션의 `ConfigMap`이나 `Secret`을 통해 부트스트랩 서버 정보를 주입한다.
    ```yaml
    # values.yaml (애플리케이션 차트 내)
    kafka:
      bootstrapServers: "b-1.my-msk-cluster.xxxxxx.c3.kafka.ap-northeast-2.amazonaws.com:9092,b-2.my-msk-cluster.xxxxxx.c3.kafka.ap-northeast-2.amazonaws.com:9092"
      # securityProtocol: "SASL_SSL" # MSK IAM 인증 등 사용 시
      # saslMechanism: "AWS_MSK_IAM"
      # topicName: "my-topic"
    ```

*   **EKS에 Kafka 자체 배포 시 (예: Bitnami Kafka Helm 차트 활용)**:
    *   Bitnami Kafka Helm 차트와 같이 검증된 외부 차트를 사용하는 것을 강력히 권장한다.
    *   주요 `values.yaml` 설정 항목 (Bitnami 차트 기준 예시):
        ```yaml
        # values.yaml (Bitnami Kafka 차트)
        replicaCount: 3 # 브로커 수
        zookeeper:
          enabled: true # 자체 Zookeeper 배포 또는 외부 Zookeeper 사용 여부
          replicaCount: 3
        # persistence:
        #   enabled: true
        #   storageClass: "gp2" # 또는 gp3 등 EBS 스토리지 클래스
        #   size: "50Gi" # 브로커당 디스크 크기
        # externalAccess: # 외부 접근 설정 (주의 필요)
        #   enabled: false
        #   service:
        #     type: LoadBalancer
        #     ports:
        #       external: 9094
        # listeners: # 내부/외부 리스너 설정
        #   client: PLAINTEXT://:9092
        #   internal: PLAINTEXT://:9093
        # advertisedListeners:
        #   client: PLAINTEXT://{{ .Values.externalAccess.service.loadBalancerIPs }}:{{ .Values.externalAccess.service.ports.external }} # 예시, 실제로는 LB DNS 사용
        #   internal: PLAINTEXT://{{ .Release.Name }}-kafka-{{ .Pod.Ordinal }}.{{ .Release.Name }}-kafka-headless.{{ .Release.Namespace }}.svc.cluster.local:9093

        # 리소스 요청/제한, JVM 옵션 등 상세 설정 가능
        ```
    *   차트 문서를 참고하여 EKS 환경 및 VPC CNI에 맞게 리스너, 광고된 리스너, 스토리지 클래스, 서비스 타입 등을 신중하게 설정해야 한다.

**결론적으로, 특별한 요구사항이 없는 한 Amazon MSK를 사용하는 것이 운영 효율성과 안정성 측면에서 EKS 환경의 Kafka 배포에 가장 적합한 전략이다.** 자체 배포는 상당한 Kubernetes 및 Kafka 운영 전문성을 필요로 한다.

### 3.5. 웹소켓 (Socket.io)

실시간 양방향 통신을 위한 Socket.io (일반적으로 Node.js 기반) 애플리케이션을 EKS에 배포하고 안정적으로 운영하기 위한 전략은 다음과 같다.

#### 3.5.1. ECR 이미지 관리

*   **Dockerfile 최적화**:
    *   Next.js 와 유사하게 멀티 스테이지 빌드를 사용하여 최종 이미지 크기를 최소화한다. (Node.js 런타임 이미지 사용).
    *   애플리케이션 코드, `package.json`, 필요한 정적 파일 등을 포함한다.
*   **이미지 버전 관리**: Git 태그나 커밋 해시를 사용하여 Docker 이미지 태그를 관리하고, ECR에 푸시한다.
*   **ECR 리포지토리**: Socket.io 애플리케이션을 위한 별도의 ECR 프라이빗 리포지토리를 사용한다.

#### 3.5.2. Kubernetes 리소스 정의 (Deployment, Service)

*   **Deployment**:
    *   Socket.io 애플리케이션 파드를 관리한다.
    *   `replicas`: 초기 복제본 수 및 HPA 설정을 고려한다. 여러 인스턴스 운영 시 **상태 공유**가 필수적이므로 후술할 "로드 밸런싱 및 세션 관리" 부분을 반드시 참고한다.
    *   `image`: ECR의 애플리케이션 이미지를 사용한다.
    *   `containerPort`: Socket.io 서버가 사용하는 포트(예: 3001, 8080 등)를 지정한다.
    *   `env`: 필요한 환경 변수(예: Redis 주소, CORS 설정 등)는 `ConfigMap`이나 `Secret`을 통해 주입한다.
    *   `readinessProbe` 및 `livenessProbe`: 간단한 HTTP 헬스 체크 엔드포인트(예: `/healthz`)를 애플리케이션에 구현하여 사용한다. 웹소켓 연결 자체를 프로브하기는 어려우므로, HTTP 기반의 간단한 상태 확인용 API를 노출하는 것이 일반적이다.
    *   `resources`: CPU 및 메모리 요청/제한을 설정한다. 동시 접속자 수 및 메시지 트래픽 양을 고려하여 적절히 산정한다.
*   **Service**:
    *   Socket.io 파드에 대한 내부 접근을 위해 `ClusterIP` 타입의 서비스를 생성한다.
    *   외부 트래픽은 NLB 또는 ALB (웹소켓 지원 확인)를 통해 이 서비스로 라우팅된다.
    *   `selector`는 Deployment의 파드 레이블과 일치시킨다.

#### 3.5.3. 로드 밸런싱 및 세션 관리 (NLB/ALB, ElastiCache for Redis)

웹소켓은 클라이언트와 서버 간의 지속적인 연결을 유지해야 하므로 로드 밸런싱 및 세션 관리가 매우 중요하다.

*   **로드 밸런서 선택 (AWS Load Balancer Controller 사용)**:
    *   **NLB (Network Load Balancer)**:
        *   TCP 레벨(L4)에서 작동하므로 웹소켓 트래픽 처리에 이상적이다.
        *   고성능 및 낮은 지연 시간을 제공한다.
        *   **IP 주소 타겟 타입**: EKS에서는 NLB가 파드의 IP 주소로 직접 트래픽을 라우팅하도록 `service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: target_type=ip` 어노테이션을 서비스에 추가한다.
        *   **세션 고정성 (Sticky Sessions)**: NLB 자체는 세션 고정성을 제공하지 않지만, 클라이언트가 특정 파드에 계속 연결될 필요가 없는 경우 (Socket.io Redis 어댑터 사용 시) 문제가 되지 않는다. 만약 특정 파드에 연결이 유지되어야 하고 Redis 어댑터를 사용하지 않는다면, NLB만으로는 부족하며 애플리케이션 레벨 또는 다른 프록시에서의 처리가 필요할 수 있다. (일반적으로는 Redis 어댑터 사용 권장).
    *   **ALB (Application Load Balancer)**:
        *   HTTP/HTTPS (L7) 로드 밸런서로, 웹소켓 프로토콜(ws://, wss://)을 지원한다.
        *   경로 기반 라우팅, SSL/TLS 종료 등의 추가 기능을 제공한다.
        *   **세션 고정성 (Sticky Sessions)**: ALB는 대상 그룹(Target Group) 레벨에서 쿠키 기반의 세션 고정성을 지원한다. (`Target group -> Attributes -> Stickiness`). 하지만 Socket.io의 경우, 여러 인스턴스 간의 메시지 브로드캐스팅 등을 위해 Redis 어댑터 사용이 더 일반적이고 권장된다.
        *   타임아웃 설정을 웹소켓의 긴 연결 시간에 맞게 조정해야 할 수 있다. (`alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=3600` 등).

*   **Socket.io 어댑터 (예: `socket.io-redis`)**:
    *   **필수 사항**: Socket.io 서버를 여러 인스턴스(파드)로 확장할 경우, 모든 클라이언트가 어떤 인스턴스에 연결되어 있든 실시간으로 메시지를 주고받을 수 있도록 **반드시** 어댑터를 사용해야 한다.
    *   `socket.io-redis` 어댑터는 Redis를 중앙 메시지 버스로 사용하여 여러 Socket.io 인스턴스 간의 이벤트와 메시지를 동기화한다.
    *   **Amazon ElastiCache for Redis**: AWS 환경에서는 관리형 Redis 서비스인 ElastiCache를 사용하는 것이 운영 부담을 줄이고 안정성을 높이는 데 유리하다.
        *   클러스터 모드 활성화/비활성화 여부, 인스턴스 타입, 보안 그룹 등을 적절히 설정한다.
        *   Socket.io 애플리케이션에서는 ElastiCache Redis 엔드포인트로 접속하도록 설정한다.

#### 3.5.4. Helm 차트 구성안

Socket.io 애플리케이션 배포를 위한 Helm 차트 구성은 다음과 같다.

*   **`Chart.yaml`**: 차트 정보 (이름: `socketio-app`, 버전 등).
*   **`values.yaml`**: 사용자 정의 가능한 설정 값.
    ```yaml
    # values.yaml (socketio-app)
    replicaCount: 2 # Redis 어댑터 사용을 전제로 함
    image:
      repository: "<aws_account_id>.dkr.ecr.<region>.amazonaws.com/my-socketio-app"
      tag: "latest"
      pullPolicy: IfNotPresent

    service:
      type: ClusterIP # NLB/ALB에서 이 서비스로 트래픽 전달
      port: 80
      targetPort: 3001 # Socket.io 컨테이너 포트
      # NLB 사용 시 서비스 어노테이션 예시 (AWS Load Balancer Controller v2.4.1 이상)
      # annotations:
      #   service.beta.kubernetes.io/aws-load-balancer-type: "external"
      #   service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
      #   service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
      #   # service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "traffic-port" # 또는 특정 헬스체크 포트
      #   # service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: TCP # 또는 HTTP/HTTPS
      #   # service.beta.kubernetes.io/aws-load-balancer-healthcheck-path: /healthz # HTTP/HTTPS 헬스체크 시

    # Ingress (ALB 사용 시)
    # ingress:
    #   enabled: true
    #   className: "alb"
    #   host: "ws.example.com"
    #   path: "/" # 또는 /socket.io 등
    #   annotations:
    #     alb.ingress.kubernetes.io/scheme: internet-facing
    #     alb.ingress.kubernetes.io/target-type: ip
    #     alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
    #     alb.ingress.kubernetes.io/certificate-arn: "<acm_certificate_arn>"
    #     alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
    #     alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=3600 # 웹소켓 타임아웃 증가
          # ALB 스티키 세션 사용 시 (Redis 어댑터 사용 시 불필요하거나 오히려 방해될 수 있음)
          # alb.ingress.kubernetes.io/target-group-attributes: stickiness.enabled=true,stickiness.lb_cookie.duration_seconds=86400

    config:
      redisHost: "my-elasticache-redis.xxxxxx.ng.0001.apne2.cache.amazonaws.com" # ElastiCache Redis 엔드포인트
      redisPort: "6379"
      corsOrigin: "https://app.example.com"

    resources:
      requests:
        cpu: "200m"
        memory: "256Mi"
      limits:
        cpu: "1"
        memory: "512Mi"

    autoscaling:
      enabled: true
      minReplicas: 2
      maxReplicas: 5
      targetCPUUtilizationPercentage: 70
      # 커스텀 메트릭 (예: 활성 연결 수) 기반 HPA도 고려 가능 (복잡도 증가)

    # readinessProbePath: "/healthz"
    # livenessProbePath: "/healthz"
    ```
*   **`templates/deployment.yaml`**: Deployment 템플릿.
*   **`templates/service.yaml`**: Service 템플릿. NLB 사용 시 필요한 어노테이션 포함.
*   **`templates/ingress.yaml`**: (ALB 사용 시) Ingress 리소스 템플릿.
*   **`templates/hpa.yaml`**: HPA 템플릿.
*   **`templates/configmap.yaml`**: (선택 사항) Redis 접속 정보 등 ConfigMap.
*   **`templates/_helpers.tpl`**: 공통 헬퍼 템플릿.

**로드밸런서 선택 최종 권장 사항**:
일반적으로 웹소켓 트래픽에는 **NLB (IP 타겟 타입)** 를 사용하는 것이 성능 및 안정성 면에서 더 유리할 수 있다. ALB를 사용해야 하는 경우(예: 복잡한 경로 기반 라우팅, WAF 통합 등이 동일 로드밸런서에서 필요한 경우)에는 웹소켓 지원 및 타임아웃 설정을 반드시 확인해야 한다. 어떤 경우든, Socket.io 서버를 여러 대 운영한다면 **Redis 어댑터와 Amazon ElastiCache for Redis 사용은 강력히 권장**된다.

### 3.6. 데이터베이스 (MySQL)

애플리케이션의 핵심 데이터를 저장하는 MySQL 데이터베이스를 EKS 환경에 배포하고 운영하기 위한 전략은 안정성, 가용성, 백업, 보안을 최우선으로 고려해야 한다. AWS 환경에서는 Amazon RDS for MySQL을 사용하는 것이 일반적인 모범 사례이며, 특정 요구사항이 있을 경우 EKS에 직접 MySQL 클러스터를 구축하는 방안도 고려할 수 있다.

#### 3.6.1. Amazon RDS 활용 방안 또는 자체 배포 방안

*   **Amazon RDS for MySQL**:
    *   **장점**:
        *   **완전 관리형 서비스**: AWS가 데이터베이스 서버의 프로비저닝, OS 패치, 마이너 버전 업그레이드, 백업, 시점 복구(Point-in-Time Recovery), 고가용성(Multi-AZ), 읽기 전용 복제본(Read Replicas) 설정을 자동화한다. 운영 부담이 획기적으로 감소한다.
        *   **고가용성 및 내구성**: Multi-AZ 배포를 통해 자동 장애 조치를 지원하며, 데이터는 자동으로 여러 AZ에 복제될 수 있다.
        *   **보안**: IAM 데이터베이스 인증, 저장 데이터 암호화(KMS 사용), 전송 중 암호화(SSL/TLS), VPC 보안 그룹 및 NACL을 통한 네트워크 격리 등 강력한 보안 기능을 제공한다.
        *   **성능 및 확장성**: 다양한 DB 인스턴스 유형과 스토리지 옵션(범용 SSD, 프로비저닝된 IOPS SSD)을 제공하며, 필요에 따라 쉽게 스케일업/스케일아웃(읽기 전용 복제본)이 가능하다.
        *   **모니터링 및 로깅**: CloudWatch를 통해 상세한 성능 메트릭 및 로그를 제공하며, Performance Insights를 통해 쿼리 성능 분석이 가능하다.
    *   **단점**:
        *   **비용**: 자체 구축 대비 특정 상황에서 비용이 더 높을 수 있다 (TCO 분석 필요).
        *   **제한된 제어권**: OS 레벨 접근이나 특정 고급 MySQL 파라미터 수정 등에 제한이 있을 수 있다.
    *   **권장 사항**: 안정성, 가용성, 운영 효율성, 보안 등을 종합적으로 고려할 때, **대부분의 경우 Amazon RDS for MySQL 사용을 강력히 권장한다.** 애플리케이션에서는 RDS 인스턴스의 엔드포인트 주소, 사용자 이름, 비밀번호(AWS Secrets Manager 통해 관리)를 설정하여 연결한다.

*   **EKS에 MySQL 자체 배포 (Self-Managed MySQL on EKS)**:
    *   **장점**:
        *   **완전한 제어**: MySQL 버전, 모든 구성 파라미터, 스토리지 엔진, 복제 토폴로지 등에 대한 완전한 제어권을 가진다.
        *   **비용 최적화 가능성**: 특정 EC2 인스턴스 및 EBS 볼륨 조합을 통해 비용을 최적화할 수 있다 (운영 비용 제외).
    *   **단점**:
        *   **극도로 높은 운영 복잡성**: 데이터베이스 설치, 구성, 백업 및 복원, 고가용성(예: Primary/Replica, InnoDB Cluster), 패치, 업그레이드, 모니터링, 보안 등을 모두 직접 책임지고 관리해야 한다. 이는 매우 높은 수준의 전문 지식과 지속적인 운영 노력을 요구한다.
        *   **데이터 유실 위험**: 잘못된 구성이나 관리 실수로 인해 데이터 유실 위험이 존재한다.
        *   **성능 튜닝의 어려움**: Kubernetes 환경에서의 스토리지 I/O, 네트워크 성능 등을 고려한 정교한 튜닝이 필요하다.
    *   **권장 상황**: 매우 특수한 MySQL 구성(예: 특정 스토리지 엔진, 비표준 복제 방식)이 반드시 필요하거나, RDS에서 제공하지 않는 기능을 사용해야 하며, 동시에 Kubernetes 및 MySQL 운영에 매우 높은 전문성을 가진 전담팀이 있는 경우에만 극히 제한적으로 고려할 수 있다. 일반적으로는 권장되지 않는다.

#### 3.6.2. Kubernetes 리소스 정의 (StatefulSet, PV/PVC - 자체 배포 시)

EKS에 MySQL을 자체 배포할 경우, 데이터의 영속성과 안정적인 네트워크 식별을 위해 `StatefulSet`을 사용한다. Bitnami 또는 Percona에서 제공하는 검증된 Helm 차트를 사용하는 것이 좋다.

*   **StatefulSet**:
    *   각 MySQL 파드(마스터, 슬레이브)에 고유하고 안정적인 이름(예: `mysql-0`, `mysql-1`)과 네트워크 ID를 제공한다.
    *   `serviceName`을 통해 헤드리스 서비스를 지정하여 파드 간 DNS 확인이 가능하도록 한다.
    *   `volumeClaimTemplates`: 각 파드에 대한 `PersistentVolumeClaim`(PVC)을 동적으로 생성하여 전용 EBS 볼륨을 할당한다. 데이터는 `/var/lib/mysql` 경로에 저장된다.
    *   `ConfigMap`: MySQL 설정 파일(`my.cnf`) 내용을 관리한다. (예: `character_set_server`, `max_connections`, `innodb_buffer_pool_size` 등).
    *   `Secret`: MySQL 루트 비밀번호, 복제용 사용자 비밀번호 등을 안전하게 저장하고 환경 변수나 파일로 주입한다.
    *   Liveness/Readiness 프로브: `mysqladmin ping` 또는 간단한 SQL 쿼리 실행을 통해 상태를 확인한다.
*   **Service**:
    *   **마스터 서비스 (ClusterIP)**: 쓰기 작업을 위한 마스터 파드를 가리키는 서비스. 애플리케이션은 이 서비스를 통해 DB에 연결한다.
    *   **복제본 서비스 (ClusterIP, Headless)**: 읽기 작업을 분산하기 위한 복제본 파드들을 가리키는 서비스 (선택 사항).
*   **초기화 로직 (Init Containers)**:
    *   데이터베이스 스키마 생성, 복제 설정, 사용자 생성 등의 초기화 작업을 위해 Init Container를 사용할 수 있다.

#### 3.6.3. 데이터 백업 및 복원 전략

*   **Amazon RDS 사용 시**:
    *   자동 백업(일일 스냅샷) 및 수동 스냅샷 기능을 활용한다.
    *   특정 시점으로 복구(PITR)가 가능하다.
    *   다른 리전으로 스냅샷 복사하여 DR(재해 복구) 구성이 가능하다.
*   **EKS에 자체 배포 시**:
    *   **EBS 스냅샷**: `PersistentVolume`으로 사용되는 EBS 볼륨에 대해 정기적인 스냅샷을 생성한다. (AWS Backup 서비스 또는 자체 스크립트 사용).
    *   **논리적 백업 (`mysqldump`, Percona XtraBackup)**:
        *   `mysqldump`를 사용하여 특정 데이터베이스 또는 전체 서버의 논리적 백업을 생성하여 S3 등에 저장한다. `CronJob`으로 자동화.
        *   Percona XtraBackup은 Hot Backup을 지원하여 서비스 중단 없이 백업이 가능하다.
    *   **복원 절차**: 명확하고 테스트된 복원 절차를 반드시 문서화하고 정기적으로 검증해야 한다.

#### 3.6.4. Helm 차트 구성안

*   **Amazon RDS 사용 시**:
    *   애플리케이션 Helm 차트의 `values.yaml`에 RDS 엔드포인트, DB 이름 등을 설정하고, 비밀번호는 AWS Secrets Manager를 통해 주입받도록 구성한다.
    ```yaml
    # values.yaml (애플리케이션 차트 내)
    database:
      host: "my-rds-instance.xxxxxx.ap-northeast-2.rds.amazonaws.com"
      port: "3306"
      name: "mydatabase"
      usernameSecretName: "rds-user-credentials" # Secrets Store CSI Driver 통해 주입될 Secret 객체 이름
      # usernameKey: "username" # Secret 객체 내 사용자 이름 키
      # passwordKey: "password" # Secret 객체 내 비밀번호 키
    ```
    *   `SecretProviderClass` 리소스를 Helm 차트에 포함하거나 별도로 관리하여 AWS Secrets Manager의 RDS 비밀번호를 Kubernetes Secret으로 동기화하고, 이를 애플리케이션 파드에 마운트하거나 환경 변수로 주입한다.

*   **EKS에 MySQL 자체 배포 시 (예: Bitnami MySQL Helm 차트 활용)**:
    *   Bitnami MySQL Helm 차트는 마스터-슬레이브 복제 구성, PVC 관리, Secret 생성, `my.cnf` 커스터마이징 등을 지원한다.
    *   주요 `values.yaml` 설정 항목 (Bitnami 차트 기준 예시):
        ```yaml
        # values.yaml (Bitnami MySQL 차트)
        # global:
        #   storageClass: "gp2" # 또는 gp3

        # auth:
        #   rootPassword: "verysecretrootpassword" # 프로덕션에서는 외부 주입 또는 자동 생성 권장
        #   database: "mydatabase"
        #   username: "myuser"
        #   password: "verysecretuserpassword"
          # replicationUser: "repl_user"
          # replicationPassword: "verysecretreplpassword"

        # primary:
        #   persistence:
        #     enabled: true
        #     size: "20Gi"
        #   resources: # 요청/제한 설정
        #     requests:
        #       memory: "1Gi"
        #       cpu: "500m"

        # secondary: # 읽기 전용 복제본 설정
        #   replicaCount: 1
        #   persistence:
        #     enabled: true
        #     size: "20Gi"

        # # my 요청/제한 설정
        # # configuration: |-
        # #   [mysqld]
        # #   max_connections=200
        # #   innodb_buffer_pool_size=512M

        # # 백업 설정 (차트에서 지원하는 경우)
        # # backup:
        # #   enabled: true
        # #   schedule: "0 2 * * *" # 매일 새벽 2시
        # #   storage:
        # #     # S3 또는 PVC 설정
        ```
    *   차트 문서를 면밀히 검토하여 EKS 환경에 맞게 스토리지, 네트워크, 복제, 백업 설정을 구성해야 한다.

**결론적으로, 데이터베이스는 애플리케이션의 가장 중요한 상태 저장소이므로, 운영의 안정성과 데이터 보호를 최우선으로 고려해야 한다. 대부분의 EKS 환경에서는 Amazon RDS for MySQL을 사용하는 것이 이러한 요구사항을 충족하는 가장 효과적인 방법이다.**

## 4. 인프라 및 운영 도구 구성

안정적이고 효율적인 EKS 클러스터 및 애플리케이션 운영을 위해서는 적절한 인프라 지원 및 운영 자동화 도구 구성이 필수적이다. 본 섹션에서는 모니터링, CI/CD, 그리고 중앙화된 Helm 차트 관리에 대한 구성 방안을 기술한다.

### 4.1. 모니터링 (Prometheus + Grafana)

EKS 클러스터 및 애플리케이션의 상태, 성능, 리소스 사용률 등을 지속적으로 모니터링하여 문제를 사전에 감지하고 신속하게 대응할 수 있도록 시스템을 구축한다.

#### 4.1.1. Amazon Managed Service for Prometheus (AMP) 및 Grafana (AMG) 활용

*   **Amazon Managed Service for Prometheus (AMP)**:
    *   Prometheus와 호환되는 완전 관리형 모니터링 서비스. Prometheus 서버의 설치, 관리, 확장, 고가용성 확보에 대한 부담을 AWS가 담당한다.
    *   EKS 클러스터의 메트릭(컨트롤 플레인, 노드, 파드, 컨테이너 등) 및 애플리케이션 커스텀 메트릭을 수집하여 저장하고 쿼리할 수 있다.
    *   데이터 수집 에이전트(예: AWS Distro for OpenTelemetry(ADOT) Collector, Prometheus Server)를 EKS 클러스터에 배포하여 AMP로 메트릭을 전송한다.
    *   IAM을 통한 접근 제어, VPC 엔드포인트를 통한 프라이빗 접근이 가능하다.
*   **Amazon Managed Grafana (AMG)**:
    *   Grafana와 호환되는 완전 관리형 시각화 서비스. Grafana 서버의 설치, 관리, 확장을 AWS가 담당한다.
    *   AMP를 데이터 소스로 쉽게 연동하여 EKS 및 애플리케이션 메트릭을 시각화하고 대시보드를 구성할 수 있다.
    *   AWS Single Sign-On (SSO) 또는 SAML 기반 IDP와의 통합을 통해 사용자 인증 및 권한 관리가 용이하다.
*   **장점**: 운영 부담 감소, AWS 환경과의 통합 용이, 확장성 및 안정성 확보.
*   **권장 사항**: EKS 환경에서는 AMP와 AMG를 조합하여 사용하는 것이 모니터링 시스템 구축 및 운영의 효율성을 크게 높일 수 있다.

#### 4.1.2. 또는 자체 배포 방안 (Prometheus Operator)

*   **Prometheus Operator**:
    *   Kubernetes 네이티브 방식으로 Prometheus 및 관련 컴포넌트(Alertmanager, Grafana 등)의 배포와 관리를 자동화하는 오퍼레이터.
    *   `kube-prometheus-stack` Helm 차트 등을 사용하여 쉽게 설치할 수 있다.
    *   EKS 클러스터 내에 직접 Prometheus 서버, Alertmanager, Grafana 등을 배포하고 운영한다.
*   **장점**: 완전한 제어권, 다양한 커스터마이징 가능, 비용 최적화 가능성 (리소스 직접 관리).
*   **단점**: Prometheus 서버, Alertmanager, Grafana의 설치, 설정, 데이터 저장소(PV/PVC), 고가용성, 업그레이드 등을 직접 관리해야 하므로 운영 부담이 크다. 데이터 백업 및 복원 전략도 필요하다.
*   **권장 상황**: AMP/AMG에서 제공하지 않는 매우 특수한 기능이 필요하거나, 기존에 Prometheus Operator 운영 경험이 풍부한 경우 고려할 수 있다.

#### 4.1.3. 주요 메트릭 수집 대상

*   **EKS 컨트롤 플레인 메트릭**: API 서버 지연 시간, 요청률 등 (AMP에서 기본 제공 가능).
*   **노드 메트릭**: CPU, 메모리, 디스크 I/O, 네트워크 사용률 등 (`node-exporter` 사용).
*   **파드 및 컨테이너 메트릭**: CPU, 메모리 사용량, 재시작 횟수 등 (`kube-state-metrics` 및 cAdvisor 통해 수집).
*   **애플리케이션 특정 메트릭**:
    *   **Spring Boot**: Actuator를 통해 JVM 메트릭, HTTP 요청 수/지연 시간 등 노출.
    *   **Next.js/Node.js**: `prom-client`와 같은 라이브러리를 사용하여 커스텀 메트릭 노출.
    *   **Kafka (MSK 또는 자체)**: 브로커 처리량, 지연 시간, 파티션 상태 등.
    *   **MySQL (RDS 또는 자체)**: 연결 수, 쿼리 성능, 복제 상태 등.
*   **AWS 서비스 메트릭**: ALB/NLB 요청 수/지연 시간, RDS CPU/메모리, ElastiCache 사용률 등 CloudWatch 메트릭을 Grafana에서 함께 시각화 (CloudWatch 데이터 소스 연동).

### 4.2. CI/CD (AWS CodePipeline, ECR, ArgoCD)

애플리케이션 변경 사항을 안정적이고 빠르게 EKS 클러스터에 배포하기 위한 CI/CD 파이프라인을 구축한다.

#### 4.2.1. ECR을 활용한 Docker 이미지 관리 파이프라인

*   **소스 코드 관리**: AWS CodeCommit, GitHub, GitLab 등 사용.
*   **빌드 및 테스트**:
    *   AWS CodeBuild 또는 Jenkins, GitLab CI 등을 사용하여 소스 코드 변경 시 자동으로 Docker 이미지를 빌드하고 단위/통합 테스트를 수행한다.
    *   빌드 성공 시, 버전 태그(Git 태그/커밋 해시)를 붙여 Amazon ECR(Elastic Container Registry)에 이미지를 푸시한다. ECR은 안전하고 확장 가능한 프라이빗 컨테이너 이미지 저장소이다.
*   **이미지 스캐닝**: ECR의 이미지 스캐닝 기능을 활성화하여 알려진 보안 취약점을 검사하고, 심각한 취약점 발견 시 배포를 차단하는 로직을 파이프라인에 추가할 수 있다.

#### 4.2.2. ArgoCD를 이용한 GitOps 기반 배포 자동화

*   **GitOps 원칙**: Kubernetes 클러스터의 원하는 상태를 Git 저장소에서 선언적으로 관리하고, 자동화된 도구를 사용하여 실제 클러스터 상태를 Git의 상태와 일치시키는 방식.
*   **ArgoCD**: 대표적인 GitOps 도구.
    *   EKS 클러스터에 ArgoCD를 설치한다 (Helm 차트 사용 가능).
    *   애플리케이션 배포 매니페스트(Kubernetes YAML 또는 Helm 차트)가 저장된 Git 리포지토리를 ArgoCD에 등록한다.
    *   ArgoCD는 주기적으로 Git 리포지토리의 변경 사항을 감지하고, 변경이 발생하면 자동으로 EKS 클러스터에 해당 변경 사항을 동기화(배포)한다.
    *   **장점**: 배포 일관성 및 추적 용이성 향상, 롤백 용이, 개발자 친화적인 배포 프로세스.
    *   Helm 차트를 사용하는 경우, ArgoCD는 Helm 차트와 `values.yaml` 파일을 기반으로 렌더링된 매니페스트를 클러스터에 적용한다. 환경별 `values.yaml` 파일을 별도 브랜치나 디렉토리로 관리하여 다중 환경 배포를 지원할 수 있다.

#### 4.2.3. AWS CodeDeploy 연동 (선택 사항)

*   AWS CodeDeploy는 EKS에 대한 점진적인 배포 전략(예: Canary, Linear, AllAtOnce)을 지원한다.
*   ALB와 통합하여 트래픽 전환을 자동화하고, 배포 중 롤백 기능을 제공한다.
*   ArgoCD와 함께 사용하거나, ArgoCD의 자체적인 동기화 및 롤백 기능을 활용할 수도 있다. CodeDeploy는 AWS 네이티브 배포 오케스트레이션이 필요할 때 유용하다.

### 4.3. 중앙화된 Helm 차트 관리 (Umbrella Chart)

여러 마이크로서비스 및 인프라 구성 요소(예: Prometheus, Grafana, Ingress 컨트롤러 등)를 EKS에 배포할 때, 각 구성 요소를 개별 Helm 차트로 관리하고, 이들을 하나의 상위 차트인 "Umbrella Chart"를 통해 전체 애플리케이션 스택으로 묶어 배포하고 관리하는 전략을 사용한다.

*   **Umbrella Chart 구조**:
    *   최상위 `Chart.yaml` 파일은 애플리케이션 스택 전체를 나타낸다.
    *   `requirements.yaml` 또는 `Chart.yaml`의 `dependencies` 섹션에 각 하위 차트(Next.js, Spring Boot, Kafka, MySQL 등) 및 외부 차트(Prometheus Operator, Nginx Ingress 등)를 의존성으로 정의한다.
    *   최상위 `values.yaml` 파일에서 각 하위 차트의 주요 설정 값들을 오버라이드(override)하여 전체 스택의 설정을 중앙에서 관리한다.
*   **장점**:
    *   **일관된 배포**: 전체 애플리케이션 스택을 단일 명령(`helm install/upgrade`)으로 배포 및 관리할 수 있다.
    *   **환경별 설정 용이**: 최상위 `values.yaml` 파일 또는 별도의 환경별 `values-<env>.yaml` 파일을 사용하여 개발, 스테이징, 프로덕션 환경에 대한 설정을 쉽게 관리할 수 있다.
    *   **의존성 관리**: 애플리케이션 구성 요소 간의 의존성을 명확하게 정의하고 관리할 수 있다.
    *   **버전 관리**: 전체 스택의 버전을 관리하고 롤백하기 용이하다.
*   **Helm 리포지토리**: 개발된 사내 Helm 차트들은 ChartMuseum, Amazon S3, JFrog Artifactory 등과 같은 Helm 리포지토리에 저장하여 버전 관리 및 공유를 용이하게 한다.

이러한 인프라 및 운영 도구 구성은 EKS 환경에서의 애플리케이션 라이프사이클 관리를 자동화하고, 안정성과 효율성을 높이는 데 기여한다.

## 5. `kubeadm`에서 EKS로의 마이그레이션 절차

기존 `kubeadm` 기반 Kubernetes 클러스터에서 Amazon EKS로의 마이그레이션은 신중한 계획과 단계별 실행이 필요하다. 본 섹션에서는 일반적인 마이그레이션 절차와 주요 고려 사항, 그리고 전체적인 구축 및 마이그레이션 순서도 개념을 기술한다.

### 5.1. 마이그레이션 준비 단계 (Preparation Phase)

1.  **EKS 클러스터 환경 준비 (본 보고서 2, 3, 4절 내용 기반)**:
    *   AWS 네트워킹(VPC, 서브넷, 보안 그룹 등) 설계 및 구축 완료.
    *   IAM 역할 및 정책(클러스터, 노드, IRSA) 생성 및 구성 완료.
    *   Amazon EKS 클러스터 생성 (컨트롤 플레인, 관리형 노드 그룹 또는 Fargate 프로파일). (본 보고서 2.5절 참조)
    *   AWS Load Balancer Controller, Cluster Autoscaler 등 필수 애드온 설치 및 구성.
    *   모니터링(AMP/AMG 또는 자체 Prometheus) 및 로깅 시스템 기본 설정 완료.
    *   ECR 리포지토리 생성 및 CI/CD 파이프라인(ArgoCD 등) 기본 연동 준비.
2.  **기존 `kubeadm` 환경 분석 및 문서화**:
    *   배포된 애플리케이션 목록, 구성, 의존성, 데이터 저장소 현황 상세 파악.
    *   네트워크 구성, Ingress 규칙, 보안 설정, RBAC 등 현재 설정 값 문서화.
    *   상태 저장 애플리케이션의 경우 데이터 볼륨, 백업 및 복원 절차 확인.
3.  **애플리케이션 컨테이너화 및 Kubernetes 매니페스트 검토/최적화**:
    *   모든 애플리케이션이 컨테이너화 되어 있고 ECR에 이미지가 푸시되었는지 확인. (본 보고서 3.x.1절 참조)
    *   기존 Kubernetes 매니페스트(YAML) 또는 Helm 차트를 EKS 환경에 맞게 검토하고 필요시 수정.
        *   AWS 서비스 연동 부분 (예: 로드밸런서 어노테이션, IAM 역할 매핑, 스토리지 클래스 등).
        *   리소스 요청 및 제한 값 재검토.
        *   Secret 및 ConfigMap 관리 방안 EKS 환경에 맞게 조정 (AWS Secrets Manager, Parameter Store 사용 등).
4.  **데이터 마이그레이션 전략 수립**:
    *   상태 저장 애플리케이션(특히 데이터베이스, Kafka 등)의 데이터 이전 방안 확정. (본 보고서 3.x.3절 및 3.6.3절 참조)
        *   백업/복원 방식, 실시간 동기화 방식 등 다운타임 최소화 전략 포함.
        *   테스트 환경에서 사전 검증 필수.
5.  **테스트 환경 구축 및 마이그레이션 리허설**:
    *   프로덕션 환경과 유사한 EKS 기반의 테스트/스테이징 환경을 구축.
    *   비교적 덜 중요하거나 단순한 애플리케이션부터 마이그레이션 리허설 수행.
    *   발생 가능한 문제점 식별 및 해결 방안 마련.

### 5.2. 구축 및 마이그레이션 순서도 (개념)

다음은 EKS 환경 구축부터 애플리케이션 배포 및 최종 전환까지의 일반적인 순서도 개념이다. 실제 프로젝트에서는 상황에 따라 순서가 일부 조정될 수 있다.

```mermaid
graph TD
    A[1. AWS 기반 환경 준비] --> B(1.1. VPC, 서브넷, IGW, NAT GW 구성);
    B --> C(1.2. IAM 역할/정책 정의: EKS, Node, IRSA);
    C --> D(1.3. EKS 클러스터 생성: eksctl 또는 콘솔);
    D --> E(1.4. EKS 노드 그룹/Fargate 프로파일 설정);
    E --> F(1.5. 필수 애드온 설치: AWS LBC, Metrics Server, CA 등);

    G[2. 운영 인프라 구축] --> H(2.1. 모니터링 시스템 구축: AMP/AMG 또는 Prometheus);
    H --> I(2.2. 로깅 시스템 구축);
    I --> J(2.3. CI/CD 환경 구성: ECR, ArgoCD 연동 설정);
    J --> K(2.4. Helm 리포지토리 설정);

    L[3. 애플리케이션 배포 (Test/Staging 환경 우선)] --> M(3.1. 데이터베이스 마이그레이션/설정: RDS 또는 자체 배포);
    M --> N(3.2. 메시지 큐 설정: MSK 또는 자체 배포);
    N --> O(3.3. 백엔드(Spring Boot) 배포: Helm + ArgoCD);
    O --> P(3.4. 웹소켓(Socket.io) 배포: Helm + ArgoCD);
    P --> Q(3.5. 프론트엔드(Next.js) 배포: Helm + ArgoCD);
    Q --> R(3.6. Ingress 설정 및 외부 접근 테스트);

    S[4. 프로덕션 마이그레이션 및 전환] --> T(4.1. 프로덕션 데이터 마이그레이션 최종 동기화);
    T --> U(4.2. 프로덕션 애플리케이션 배포 검증);
    U --> V(4.3. DNS 트래픽 전환: 점진적 또는 일괄);
    V --> W(4.4. 기존 kubeadm 환경 모니터링 및 비활성화 준비);

    W --> X[5. 최종 확인 및 안정화];
```
*(Mermaid 문법을 사용한 순서도 예시입니다. Markdown 뷰어에 따라 실제 다이어그램으로 표시될 수 있습니다.)*

**단계별 요약 리스트:**

1.  **AWS 인프라 준비**: VPC, 서브넷, IAM 역할, EKS 클러스터 및 노드 그룹 생성, 기본 애드온 설치.
2.  **운영 환경 구축**: 모니터링, 로깅, CI/CD (ECR, ArgoCD), Helm 리포지토리 설정.
3.  **애플리케이션 및 데이터 이전 (스테이징)**:
    *   데이터베이스 (RDS 또는 자체 DB) 마이그레이션 및 설정.
    *   메시지 큐 (MSK 또는 자체 Kafka) 설정.
    *   각 애플리케이션(BE, Websocket, FE) Helm 차트 기반 배포 (ArgoCD 활용).
    *   Ingress 설정 및 내부/외부 통신 테스트.
4.  **최종 검증 및 문서화**: 스테이징 환경에서 기능, 성능, 안정성 검증. 마이그레이션 절차 및 결과 문서화.
5.  **프로덕션 마이그레이션 실행**:
    *   마이그레이션 기간 및 다운타임 공지 (필요시).
    *   프로덕션 데이터 최종 동기화 및 이전.
    *   프로덕션 EKS 환경에 애플리케이션 배포.
    *   기능 및 성능 최종 검증.
6.  **트래픽 전환**: DNS 설정을 변경하여 트래픽을 새로운 EKS 환경으로 점진적 또는 일괄적으로 전환.
7.  **모니터링 및 안정화**: 전환 후 시스템 상태 집중 모니터링, 문제 발생 시 신속 대응.
8.  **기존 `kubeadm` 환경 자원 정리**: EKS 환경이 완전히 안정화된 후, 기존 `kubeadm` 클러스터 및 관련 리소스 정리.

### 5.3. 애플리케이션 및 데이터 이전 전략 상세

*   **상태 비저장(Stateless) 애플리케이션 (예: Next.js, Spring Boot 일부)**:
    *   ECR에 최신 이미지를 푸시하고, 준비된 Helm 차트를 사용하여 ArgoCD로 EKS에 배포한다.
    *   ConfigMap 및 Secret (AWS Secrets Manager 연동)을 통해 환경별 설정을 주입한다.
    *   트래픽 전환은 DNS 변경 또는 로드밸런서 가중치 조정을 통해 수행한다.
*   **상태 저장(Stateful) 애플리케이션 (예: DB, Kafka)**:
    *   **데이터베이스 (MySQL)**:
        *   **RDS로 마이그레이션 시**: AWS DMS(Database Migration Service)를 사용하거나, `mysqldump`를 이용한 백업/복원, 또는 실시간 복제(Replication) 설정 후 전환 시점에 동기화를 끊는 방식 등을 사용한다. 다운타임 최소화를 위해 복제 방식이 선호된다.
        *   **EKS 내 자체 DB로 마이그레이션 시**: 기존 DB 백업 후 EKS의 PV에 복원. 데이터 정합성 및 복원 시간 철저히 검증.
    *   **메시지 큐 (Kafka)**:
        *   **MSK로 마이그레이션 시**: MirrorMaker 2.0 등을 사용하여 기존 Kafka 클러스터에서 MSK로 토픽과 데이터를 미러링(동기화)한다. 프로듀서와 컨슈머 애플리케이션의 부트스트랩 서버 주소를 MSK로 변경한다.
        *   **EKS 내 자체 Kafka로 마이그레이션 시**: 데이터 디렉토리 이전 또는 MirrorMaker 사용.
    *   **다운타임 최소화**: 실시간 데이터 동기화가 가능한 경우(DB 복제, Kafka MirrorMaker), 최종 전환 시점의 다운타임을 최소화할 수 있다. 애플리케이션 특성에 따라 읽기 전용 모드 전환 후 데이터 동기화, 이후 완전 전환 등의 단계적 접근도 고려한다.

### 5.4. DNS 전환 및 트래픽 관리

*   **Route 53 활용**: AWS Route 53을 사용하여 DNS 레코드를 관리하고 트래픽을 EKS 환경의 ALB/NLB로 향하도록 변경한다.
*   **TTL(Time To Live) 최소화**: DNS 변경 전파 시간을 줄이기 위해, 전환 전에 해당 DNS 레코드의 TTL 값을 짧게(예: 60초) 변경해둔다.
*   **점진적 트래픽 전환**:
    *   Route 53의 가중치 기반 라우팅(Weighted Routing) 또는 지연 시간 기반 라우팅(Latency-based Routing)을 사용하여 일부 사용자 트래픽만 새로운 EKS 환경으로 보내고, 안정성을 확인하며 점차적으로 트래픽 비율을 늘려나간다 (카나리 배포 방식).
    *   ALB의 경우, 대상 그룹 간 가중치 조정을 통해 유사한 방식 구현 가능.
*   **헬스 체크**: 로드밸런서 및 DNS 수준에서 강력한 헬스 체크를 설정하여, 문제 발생 시 자동으로 이전 환경 또는 정상적인 다른 AZ로 트래픽이 라우팅되도록 한다.

### 5.5. 다운타임 최소화 방안

*   **철저한 사전 준비 및 테스트**: 모든 마이그레이션 절차, 스크립트, 설정 변경 사항을 테스트 환경에서 반복적으로 검증한다.
*   **데이터 동기화 기술 활용**: DB 복제, Kafka MirrorMaker 등 실시간 또는 거의 실시간 데이터 동기화 도구를 사용하여 최종 데이터 이전 시간을 최소화한다.
*   **애플리케이션 읽기 전용 모드**: 필요한 경우, 주요 데이터 변경이 발생하는 애플리케이션을 일시적으로 읽기 전용 모드로 전환하여 데이터 정합성을 확보하고 백업/동기화 시간을 확보한다.
*   **Blue/Green 배포 전략**: EKS에 새로운 환경(Green)을 완전히 구축하고 테스트한 후, DNS 전환을 통해 트래픽을 한 번에 Green 환경으로 이전한다. 문제 발생 시 신속하게 이전 환경(Blue)으로 롤백 가능하다.
*   **점진적 롤아웃 및 카나리 배포**: 새로운 기능이나 변경 사항을 소수의 사용자에게만 먼저 노출시켜 안정성을 검증한 후 전체 사용자에게 확대한다. (애플리케이션 레벨 또는 Ingress/Service Mesh 레벨에서 구현).
*   **자동화된 롤백 계획**: 마이그레이션 중 심각한 문제 발생 시, 사전에 정의되고 테스트된 롤백 절차를 신속하게 실행할 수 있도록 준비한다.

### 5.6. 롤백 계획 (Rollback Plan)

마이그레이션 중 예상치 못한 문제가 발생하여 서비스에 심각한 영향을 미칠 경우를 대비하여 명확한 롤백 계획을 수립해야 한다.

1.  **롤백 결정 기준**: 어떤 상황(예: 특정 시간 내 문제 미해결, 핵심 기능 오류율 임계치 초과 등)에서 롤백을 결정할지 사전에 정의한다.
2.  **DNS 롤백**: 가장 빠르고 효과적인 롤백 방법 중 하나는 DNS 레코드를 이전 `kubeadm` 환경의 로드밸런서나 서비스 IP로 다시 변경하는 것이다. (TTL 최소화가 중요).
3.  **데이터베이스 롤백**:
    *   데이터 변경이 이미 새 환경에서 발생했다면, 이전 환경으로 롤백 시 데이터 정합성 문제가 발생할 수 있다.
    *   전환 직전에 생성한 최종 백업을 이전 환경에 복원하거나, 이전 환경으로의 역방향 복제(가능하다면)를 고려한다. 데이터 유실 가능성을 최소화하는 방안을 마련해야 한다.
4.  **애플리케이션 및 설정 롤백**: 이전 버전의 애플리케이션 코드 및 설정을 이전 환경에 재배포하거나 활성화한다.
5.  **롤백 절차 문서화 및 검증**: 롤백 절차를 명확히 문서화하고, 가능하다면 테스트 환경에서 롤백 시나리오를 검증한다.
6.  **커뮤니케이션 계획**: 롤백 결정 시 관련 팀 및 이해관계자에게 신속하게 상황을 전파한다.

성공적인 마이그레이션은 철저한 계획, 충분한 테스트, 그리고 예상치 못한 문제에 대한 신속한 대응 능력에 달려있다.

## 6. 보안 고려 사항

Amazon EKS 클러스터 및 배포된 애플리케이션의 보안을 확보하는 것은 매우 중요하다. AWS의 다양한 보안 서비스와 Kubernetes 자체의 보안 기능을 조합하여 다층 방어(defense-in-depth) 전략을 수립하고 이행해야 한다.

### 6.1. IAM 통합 및 최소 권한 원칙

*   **IAM 역할 및 정책의 정교한 관리**:
    *   **EKS 클러스터 역할**: EKS 서비스가 AWS 리소스를 관리하는 데 필요한 최소한의 권한만 부여한다. (`AmazonEKSClusterPolicy` 사용).
    *   **노드 인스턴스 역할**: 워커 노드가 EKS 컨트롤 플레인과 통신하고, ECR에서 이미지를 가져오며, CloudWatch에 로그를 보내는 등 필요한 최소한의 권한만 부여한다. (`AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy` 등). 노드에 직접적인 AWS API 접근 권한을 광범위하게 부여하지 않도록 주의한다.
    *   **IRSA (IAM Roles for Service Accounts)**: **가장 강력히 권장되는 방식이다.** Kubernetes 서비스 어카운트에 IAM 역할을 직접 매핑하여, 파드(애플리케이션)가 AWS 리소스(S3, DynamoDB, Secrets Manager 등)에 접근 시 필요한 최소한의 권한만 갖도록 한다. 이를 통해 노드 인스턴스 역할의 권한을 최소화하고, 파드별로 세분화된 접근 제어를 구현할 수 있다. (본 보고서 2.4절 참조).
*   **사용자 접근 관리**:
    *   EKS 클러스터에 대한 사용자 접근은 IAM 사용자 및 그룹을 통해 관리하고, `aws-auth` ConfigMap (또는 EKS API의 접근 항목 관리 기능)을 사용하여 Kubernetes RBAC 역할과 매핑한다.
    *   AWS Single Sign-On (SSO) 또는 페더레이션된 자격 증명(SAML, OIDC)을 사용하여 중앙에서 사용자 접근을 관리하는 것을 고려한다.
*   **정기적인 IAM 정책 검토**: 부여된 권한이 여전히 최소 권한 원칙을 준수하는지 정기적으로 검토하고 업데이트한다. AWS IAM Access Analyzer를 활용하여 과도한 권한을 식별할 수 있다.

### 6.2. 네트워크 보안 (보안 그룹, NACL, 네트워크 정책)

*   **VPC 네트워크 격리**:
    *   EKS 클러스터는 전용 VPC 또는 잘 격리된 VPC 환경에 배포한다. (본 보고서 2.1절 참조).
    *   컨트롤 플레인 API 서버 엔드포인트 접근(퍼블릭/프라이빗)을 신중하게 결정하고, 퍼블릭 접근 시에는 IP 주소 기반 필터링을 적용한다.
*   **보안 그룹 (Security Groups)**:
    *   **컨트롤 플레인 보안 그룹**: EKS가 자동으로 생성하며, 워커 노드 및 지정된 네트워크에서의 접근만 허용하도록 엄격하게 관리한다.
    *   **노드 보안 그룹**: 워커 노드에 적용되며, 컨트롤 플레인과의 통신, 파드 간 통신, 로드밸런서로부터의 인바운드 트래픽 등 필요한 최소한의 포트만 허용한다. 애플리케이션 포트 외에는 외부 접근을 기본적으로 차단한다.
    *   **로드밸런서 보안 그룹**: ALB/NLB에 적용되며, 필요한 소스 IP(예: 사용자 네트워크, CDN)에서의 HTTP/HTTPS 트래픽만 허용한다.
*   **네트워크 ACL (Network Access Control Lists)**:
    *   서브넷 수준에서 상태 비저장 트래픽 필터링을 제공하여 보안 그룹을 보완하는 추가 방어 계층으로 활용한다.
*   **Kubernetes 네트워크 정책 (Network Policies)**:
    *   **필수 적용 고려**: 파드 간의 통신을 제어하는 Kubernetes 네이티브 리소스. 기본적으로 클러스터 내 모든 파드는 서로 통신 가능하므로, 네트워크 정책을 사용하여 네임스페이스별, 레이블 셀렉터별로 파드 인그레스(ingress) 및 이그레스(egress) 트래픽을 명시적으로 허용/차단해야 한다.
    *   이를 지원하는 CNI 플러그인(예: Calico, Cilium, Weave Net, AWS VPC CNI의 일부 기능)을 사용해야 한다.
    *   "기본 거부(default-deny)" 정책을 네임스페이스에 적용하고, 필요한 통신만 허용하는 화이트리스트 기반 정책을 정의하는 것이 모범 사례이다.
*   **VPC 엔드포인트 (AWS PrivateLink)**:
    *   ECR, S3, Secrets Manager, CloudWatch 등 AWS 서비스에 대한 접근을 퍼블릭 인터넷을 통하지 않고 VPC 내부 네트워크를 통해 안전하게 수행하도록 VPC 엔드포인트를 사용한다.

### 6.3. Secret 관리 심층 분석

*   **AWS Secrets Manager 또는 AWS Systems Manager Parameter Store (SecureString 타입)**:
    *   데이터베이스 자격 증명, API 키, TLS 인증서 등의 민감 정보를 중앙에서 안전하게 저장하고 관리하는 데 **가장 권장되는 방식이다.**
    *   IAM을 통한 세분화된 접근 제어, 자동 암호화(KMS 사용), 버전 관리, 자동 교체(rotation) 기능을 제공한다.
*   **Secrets Store CSI Driver**:
    *   EKS 파드에서 AWS Secrets Manager 또는 Parameter Store의 시크릿을 안전하게 마운트하거나 Kubernetes Secret으로 동기화하는 표준 방법이다. (본 보고서 3.3.3절 참조).
    *   IRSA와 함께 사용하여 파드별로 필요한 시크릿에만 접근 권한을 부여한다.
*   **Kubernetes Secrets 오브젝트**:
    *   직접 민감 정보를 저장할 경우, 기본적으로 Base64 인코딩만 되므로 암호화되지 않는다.
    *   EKS에서는 KMS를 사용한 봉투 암호화(envelope encryption) 기능을 활성화하여 Kubernetes Secrets 오브젝트를 암호화할 수 있다. 이는 컨트롤 플레인 설정에서 활성화한다.
    *   하지만, 시크릿 내용 자체는 여전히 `etcd`에 저장되므로, `etcd` 접근 보안도 중요하다. (EKS는 `etcd`를 관리하므로 이 부분은 AWS 책임).
*   **애플리케이션 레벨에서의 시크릿 처리**:
    *   환경 변수를 통해 시크릿을 주입할 경우, 해당 파드에 접근 가능한 사용자는 시크릿을 볼 수 있으므로 주의해야 한다. 파일로 마운트하는 방식이 더 안전할 수 있다.
    *   애플리케이션 로그에 시크릿 값이 노출되지 않도록 주의한다.

### 6.4. 컨테이너 이미지 보안 및 ECR 스캐닝

*   **최소 권한 이미지 사용**: 공식적이고 검증된 베이스 이미지를 사용하고, 애플리케이션 실행에 필요한 최소한의 패키지만 포함하여 이미지 크기를 줄이고 공격 표면을 최소화한다. (예: Alpine Linux 기반 이미지, Distroless 이미지).
*   **루트 사용자로 실행 금지**: Dockerfile에서 `USER` 지시어를 사용하여 컨테이너 내부에서 애플리케이션이 루트가 아닌 일반 사용자로 실행되도록 한다. Kubernetes `PodSecurityContext` 및 `ContainerSecurityContext`를 사용하여 `runAsNonRoot: true`를 강제할 수 있다.
*   **ECR 이미지 스캐닝**:
    *   Amazon ECR은 이미지 푸시 시 또는 스케줄에 따라 이미지의 알려진 운영 체제 취약점을 자동으로 스캔하는 기능을 제공한다. (Trivy, Clair 등 오픈소스 스캐너 기반).
    *   스캔 결과를 확인하고, 심각한 취약점이 발견되면 CI/CD 파이프라인에서 배포를 차단하거나 알림을 받도록 구성한다.
*   **이미지 서명 (Image Signing)**:
    *   Docker Content Trust 또는 Notary와 같은 도구를 사용하여 컨테이너 이미지의 무결성과 출처를 보증하는 이미지 서명을 고려할 수 있다. Kubernetes에서는 Admission Controller를 통해 서명되지 않은 이미지의 배포를 차단할 수 있다.
*   **정기적인 이미지 업데이트**: 베이스 이미지 및 애플리케이션 의존성의 보안 패치를 위해 정기적으로 이미지를 재빌드하고 업데이트한다.

### 6.5. EKS 클러스터 보안 모범 사례

*   **최신 Kubernetes 버전 사용**: EKS에서 지원하는 최신 안정 Kubernetes 버전으로 클러스터를 업그레이드하여 최신 보안 패치 및 기능을 활용한다. (본 보고서 업그레이드 섹션 참조).
*   **컨트롤 플레인 로깅 활성화**: API 서버, 감사, 인증자 등의 로그를 CloudWatch Logs로 전송하여 보안 이벤트 모니터링 및 분석에 활용한다. (본 보고서 2.2절 참조).
*   **RBAC (Role-Based Access Control) 적극 활용**:
    *   Kubernetes API에 대한 접근 권한을 사용자, 그룹, 서비스 어카운트별로 세분화하여 부여한다.
    *   최소 권한 원칙에 따라 각 주체에게 필요한 최소한의 역할(Role) 또는 클러스터 역할(ClusterRole)만 바인딩(RoleBinding, ClusterRoleBinding)한다.
    *   `system:masters` 그룹 사용을 최소화하고, 특정 작업을 위한 전용 역할을 생성하여 사용한다.
*   **Pod Security Standards (PSS) 또는 Pod Security Policies (PSP - deprecated)**:
    *   파드가 실행될 수 있는 보안 컨텍스트를 제한하여 잠재적인 보안 위협을 줄인다. (예: 권한 있는 컨테이너 실행 금지, 특정 볼륨 타입 사용 제한 등).
    *   Kubernetes v1.25부터 PSP는 제거되었으며, PSS가 이를 대체한다. 네임스페이스 레벨에서 `privileged`, `baseline`, `restricted` 프로파일을 적용할 수 있다.
    *   OPA Gatekeeper, Kyverno와 같은 Policy-as-Code 도구를 사용하여 더 세분화된 정책 강제도 가능하다.
*   **네트워크 세그멘테이션 및 방화벽**: VPC 서브넷, 보안 그룹, NACL, Kubernetes 네트워크 정책을 조합하여 네트워크를 적절히 분할하고 불필요한 통신을 차단한다.
*   **etcd 보안**: EKS는 컨트롤 플레인의 일부인 `etcd` 데이터베이스를 AWS가 관리하며 암호화한다. 사용자가 직접 `etcd`에 접근할 필요는 없다.
*   **워커 노드 보안 강화**:
    *   EKS 최적화 AMI 사용 및 정기적인 업데이트.
    *   CIS (Center for Internet Security) Kubernetes Benchmark와 같은 보안 가이드라인 준수 고려.
    *   노드에 대한 SSH 접근 최소화 및 필요한 경우 Bastion Host를 통해 접근.
*   **런타임 보안 모니터링**: Falco, Aqua Security, Sysdig Secure 등과 같은 런타임 보안 도구를 사용하여 컨테이너 내부의 의심스러운 활동이나 위협을 탐지하고 대응하는 것을 고려한다.

보안은 지속적인 프로세스이며, 정기적인 감사, 취약점 점검, 최신 보안 동향 학습을 통해 EKS 환경의 보안 태세를 강화해야 한다.

## 7. 결론 및 향후 권장 사항

### 7.1. 마이그레이션 결과 요약 및 기대 효과

본 보고서에서 제시된 전략과 절차에 따라 기존 `kubeadm` 기반 Kubernetes 환경에서 Amazon EKS (Elastic Kubernetes Service)로의 마이그레이션 및 애플리케이션 스택 배포가 성공적으로 완료될 경우, 다음과 같은 주요 결과 및 기대 효과를 예상할 수 있다:

*   **운영 효율성 대폭 향상**:
    *   EKS의 관리형 컨트롤 플레인 및 노드 그룹(선택 시)을 통해 Kubernetes 클러스터 자체의 설치, 업그레이드, 패치, 백업, 고가용성 확보 등 복잡한 운영 업무 부담이 현저히 감소한다.
    *   이를 통해 DevOps 팀은 인프라 관리보다 애플리케이션 개발, 배포 자동화, 서비스 안정화 등 더 가치 있는 활동에 집중할 수 있게 된다.
*   **서비스 안정성 및 가용성 증대**:
    *   AWS의 견고한 인프라와 EKS의 Multi-AZ 컨트롤 플레인 아키텍처를 기반으로 높은 수준의 서비스 안정성과 가용성을 확보할 수 있다.
    *   관리형 노드 그룹 사용 시 노드 장애 감지 및 자동 복구 기능으로 서비스 중단 시간을 최소화할 수 있다.
    *   Amazon RDS, MSK, ElastiCache 등 관리형 데이터 서비스를 활용함으로써 해당 서비스들의 고가용성 및 백업/복원 기능을 쉽게 활용할 수 있다.
*   **보안 태세 강화**:
    *   IAM, VPC, 보안 그룹, NACL, AWS Secrets Manager, ECR 이미지 스캐닝 등 AWS의 포괄적인 보안 서비스를 EKS와 긴밀하게 통합하여 다층적인 보안 체계를 구축할 수 있다.
    *   IRSA를 통한 파드별 세분화된 접근 제어, Kubernetes 네트워크 정책을 통한 파드 간 통신 제어, Pod Security Standards 적용 등으로 클러스터 내부 보안을 강화할 수 있다.
*   **확장성 및 유연성 확보**:
    *   애플리케이션 트래픽 및 워크로드 변화에 따라 EKS 클러스터 오토스케일러(Cluster Autoscaler)와 HPA(Horizontal Pod Autoscaler)를 통해 노드 및 파드 수를 유연하게 자동 확장/축소할 수 있다.
    *   다양한 EC2 인스턴스 유형 및 AWS Fargate와 같은 서버리스 컴퓨팅 옵션을 활용하여 비용과 성능을 최적화할 수 있다.
*   **AWS 생태계와의 완벽한 통합**:
    *   로드밸런서(ALB/NLB), 스토리지(EBS, EFS, S3), 데이터베이스(RDS), 메시징(MSK, SQS), 모니터링(CloudWatch, AMP, AMG), CI/CD(Code* 시리즈, ECR) 등 다양한 AWS 서비스와의 원활한 연동을 통해 클라우드 네이티브 애플리케이션 아키텍처를 효과적으로 구축하고 확장할 수 있다.
*   **표준화된 배포 및 관리**:
    *   Helm 차트 및 GitOps(ArgoCD) 기반의 표준화된 배포 파이프라인을 통해 애플리케이션 배포의 일관성, 반복성, 추적성을 확보하고 배포 오류를 줄일 수 있다.

궁극적으로, Amazon EKS로의 전환은 기술 부채를 줄이고, 최신 클라우드 네이티브 기술을 적극적으로 도입하여 비즈니스 민첩성을 높이며, 장기적인 IT 운영 비용(TCO) 절감에도 기여할 수 있을 것으로 기대된다.

### 7.2. 향후 권장 사항 및 개선 방안

본 마이그레이션 및 EKS 환경 구축 이후에도 지속적인 개선과 최적화를 위한 노력이 필요하다. 다음은 향후 고려할 수 있는 권장 사항 및 개선 방안이다:

*   **FinOps 도입 및 비용 최적화 심화**:
    *   EKS 및 관련 AWS 서비스 비용을 정기적으로 모니터링하고 분석한다 (AWS Cost Explorer, Kubecost 등 활용).
    *   EC2 스팟 인스턴스(Spot Instances)를 워커 노드에 적극 활용하여 비용을 절감하는 방안을 검토하고 적용한다 (단, 상태 비저장 및 내결함성 있는 워크로드에 적합).
    *   Graviton 기반 EC2 인스턴스(ARM 아키텍처) 도입을 검토하여 비용 대비 성능을 향상시킨다.
    *   사용량이 적은 시간에는 개발/스테이징 환경의 리소스를 자동으로 축소하거나 중지시키는 자동화 구현.
    *   EBS 볼륨 타입 및 크기 최적화, S3 스토리지 클래스 최적화 등을 지속적으로 수행한다.
*   **보안 강화 및 자동화 확대**:
    *   정기적인 보안 감사 및 취약점 점검 자동화 (예: ECR 스캐닝 결과 연동, CIS Benchmark 기반 점검 자동화).
    *   보안 정책 위반 사항을 자동으로 감지하고 수정하는 Policy-as-Code 도구(OPA Gatekeeper, Kyverno 등)의 활용 범위를 확대한다.
    *   AWS Security Hub, Amazon GuardDuty, AWS WAF 등 AWS 보안 서비스를 적극 활용하여 위협 탐지 및 대응 능력을 강화한다.
    *   Secret 자동 교체(rotation) 기능을 AWS Secrets Manager에서 적극 활용한다.
*   **DevSecOps 문화 정착 및 파이프라인 고도화**:
    *   CI/CD 파이프라인에 SAST(정적 분석 보안 테스트), DAST(동적 분석 보안 테스트), 컨테이너 이미지 서명 및 검증 단계를 통합하여 개발 초기 단계부터 보안을 강화한다.
    *   IaC(Infrastructure as Code - 예: Terraform, CloudFormation)를 사용하여 EKS 클러스터 및 관련 AWS 리소스 관리를 더욱 자동화하고 일관성을 유지한다.
*   **서비스 메시(Service Mesh) 도입 고려**:
    *   마이크로서비스 아키텍처가 더욱 복잡해지고 서비스 간 통신 제어, 관찰 가능성, 보안 요구사항이 높아질 경우 Istio, Linkerd, AWS App Mesh와 같은 서비스 메시 도입을 검토한다.
    *   트래픽 관리(A/B 테스트, 카나리 배포), mTLS를 통한 서비스 간 암호화, 상세한 트래픽 모니터링 등의 이점을 얻을 수 있다.
*   **Chaos Engineering 도입**:
    *   시스템의 잠재적인 약점을 사전에 발견하고 내결함성을 강화하기 위해, 통제된 환경에서 의도적으로 장애를 주입하는 Chaos Engineering 실습을 도입한다. (예: AWS Fault Injection Simulator 사용).
*   **지속적인 학습 및 커뮤니티 참여**:
    *   Kubernetes 및 AWS EKS 관련 최신 기술 동향, 보안 업데이트, 모범 사례 등을 지속적으로 학습하고 팀 내에 공유한다.
    *   관련 컨퍼런스, 밋업, 오픈소스 커뮤니티에 참여하여 지식을 넓히고 네트워킹을 강화한다.
*   **문서화 및 지식 공유**:
    *   EKS 클러스터 구성, 애플리케이션 배포 절차, 트러블슈팅 가이드 등을 지속적으로 업데이트하고 팀 내에 공유하여 지식 자산화한다.

이러한 지속적인 노력을 통해 EKS 환경을 더욱 안정적이고 효율적이며 안전하게 운영하고, 비즈니스 목표 달성에 기여할 수 있을 것이다.
