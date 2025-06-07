# GCP Terraform 아키텍처 개요

---
**Note for AI Agents:** 이 문서는 GCP (Google Cloud Platform) 환경을 Terraform으로 구성하는 코드베이스를 이해하는 데 도움을 주기 위해 작성되었습니다. 각 섹션에서는 주요 인프라 구성 요소, 환경별 설정, 사용된 모듈 및 핵심 아키텍처 원칙에 대해 설명합니다. 코드베이스 탐색 시 이 문서를 참조점으로 활용하여 리소스 간의 관계 및 전체 구조를 파악하는 데 도움을 받으십시오.
---

이 문서는 `terraform/gcp/` 디렉토리 내의 Terraform 코드를 통해 구축된 Google Cloud Platform (GCP) 아키텍처에 대한 개요를 제공합니다. 이 아키텍처는 개발, 프로덕션 환경을 지원하며, 모듈화된 접근 방식을 사용하여 리소스를 관리합니다.

주요 구성 요소는 다음과 같습니다:

*   **Shared 환경**: 모든 환경에서 공유되는 핵심 네트워크, 보안 및 서비스 리소스를 포함합니다.
*   **Develop 환경**: 개발 및 테스트를 위한 애플리케이션 배포 환경입니다.
*   **Prod 환경**: 실제 운영을 위한 애플리케이션 배포 환경으로, 확장성, 복원력 및 블루/그린 배포 전략을 지원합니다.
*   **Terraform 모듈**: 네트워크, 컴퓨팅, 로드 밸런서 등 재사용 가능한 인프라 구성 요소를 정의합니다.

이어지는 섹션에서는 각 환경과 모듈에 대해 더 자세히 설명합니다.

## 디렉토리 구조

```
terraform/gcp/
├── README.md
├── environments/
│   ├── develop/
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── scripts/
│   │   │   ├── backend-install.sh.tpl
│   │   │   ├── db-install.sh.tpl
│   │   │   ├── frontend-install.sh.tpl
│   │   │   └── vm-install.sh.tpl
│   │   └── variable.tf
│   ├── prod/
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── scripts/
│   │   │   ├── backend-install.sh.tpl
│   │   │   ├── db-install.sh.tpl
│   │   │   ├── frontend-install.sh.tpl
│   │   │   └── vm-install.sh.tpl
│   │   └── variable.tf
│   └── shared/
│       ├── main.tf
│       ├── output.tf
│       ├── scripts/
│       │   ├── install-openvpn.sh.tpl
│       │   └── vm-install.sh.tpl
│       └── variables.tf
└── modules/
    ├── compute/
    │   ├── main.tf
    │   ├── output.tf
    │   ├── scripts/
    │   │   └── base-init.sh.tpl
    │   └── variables.tf
    ├── external-https-lb/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── firewall/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── health-check/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── internal-http-lb/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── mig-asg/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    ├── network/
    │   ├── main.tf
    │   ├── output.tf
    │   └── variables.tf
    └── target-group/
        ├── main.tf
        ├── output.tf
        └── variables.tf
```

## Shared 환경

Shared 환경은 모든 GCP 환경 (Develop, Prod 등)에서 공유되는 핵심 인프라 리소스를 중앙에서 관리합니다. 이를 통해 일관성을 유지하고 리소스 중복을 방지합니다.

주요 리소스는 다음과 같습니다:

*   **네트워킹 (Shared VPC):**
    *   `modules/network` 모듈을 사용하여 중앙 집중식 Virtual Private Cloud (VPC) 네트워크 (`google_compute_network`)를 생성합니다.
    *   Public, Private, NAT 서브넷을 정의하여 다양한 종류의 리소스를 격리하고 관리합니다. Public 서브넷은 인터넷 연결 리소스, Private 서브넷은 내부 리소스, NAT 서브넷은 외부 인터넷으로의 아웃바운드 통신이 필요한 내부 리소스에 사용됩니다.
*   **보안:**
    *   **OpenVPN 서버 (`google_compute_instance.openvpn`):** `modules/compute` 모듈을 활용하여 개발자 및 관리자가 GCP 환경에 안전하게 접근할 수 있도록 OpenVPN 서버 (`google_compute_instance.openvpn`)를 구축합니다.
    *   **공통 방화벽 규칙 (`google_compute_firewall.shared_firewalls`):** `modules/firewall` 모듈을 사용하여 SSH, HTTP, HTTPS 등 기본적인 인바운드 트래픽과 내부 트래픽을 허용하는 공통 방화벽 규칙 (`google_compute_firewall.shared_firewalls`)을 정의합니다. VPN 접근을 위한 규칙도 포함됩니다.
*   **공유 서비스:**
    *   **헬스 체크 (`module.hc_backend`, `module.hc_frontend`):** `modules/health-check` 모듈을 사용하여 백엔드 (`module.hc_backend`) 및 프론트엔드 (`module.hc_frontend`) 서비스의 상태를 확인하기 위한 HTTP 기반 헬스 체크를 정의합니다. 이는 로드 밸런서 및 인스턴스 그룹에서 사용됩니다.
    *   **영구 디스크 (`google_compute_disk`):** MySQL 데이터베이스 인스턴스를 위한 영구 SSD 디스크를 프로비저닝합니다 (개발용 `mysql_data`, 프로덕션용 `mysql_data_prod`). 이를 통해 데이터베이스의 데이터가 VM 인스턴스의 생명주기와 분리되어 안전하게 보존됩니다.
    *   **전역 고정 IP 주소 (`google_compute_global_address`):** 개발 및 프로덕션 환경의 외부 HTTPS 로드 밸런서에서 사용할 고정 외부 IP 주소를 예약합니다.
## Develop 환경

Develop 환경은 애플리케이션 개발 및 테스트를 주목적으로 하며, 프로덕션 환경과 유사한 구성을 가지지만 일반적으로 더 작은 규모로 운영됩니다. Shared 환경의 네트워크 및 기타 공유 리소스를 활용합니다.

주요 리소스는 다음과 같습니다:

*   **컴퓨팅:**
    *   **백엔드 VM (`google_compute_instance.backend_vm`):** 백엔드 애플리케이션을 실행하는 단일 Compute Engine VM 인스턴스입니다.
    *   **프론트엔드 VM (`google_compute_instance.frontend_vm`):** 프론트엔드 애플리케이션을 실행하는 단일 Compute Engine VM 인스턴스입니다.
    *   두 VM 모두 시작 스크립트(`metadata_startup_script`)를 통해 Docker 컨테이너 형태로 애플리케이션을 배포합니다. AWS ECR에서 이미지를 가져오는 설정이 포함될 수 있습니다.
*   **인스턴스 그룹:**
    *   **Unmanaged Instance Groups (`google_compute_instance_group`):** 백엔드 및 프론트엔드 VM을 각각 그룹화하여 로드 밸런서의 대상으로 지정합니다. Develop 환경에서는 오토스케일링이 적용되지 않는 Unmanaged Instance Group을 사용합니다.
*   **로드 밸런싱:**
    *   **외부 HTTPS 로드 밸런서 (`module.external_lb`):** `modules/external-https-lb` 모듈을 사용하여 외부 인터넷 트래픽을 수신합니다. 이 로드 밸런서는 `modules/target-group` 모듈을 통해 정의된 백엔드 서비스(프론트엔드 및 백엔드 VM 그룹 대상)로 트래픽을 라우팅합니다. URL 경로 기반 라우팅 규칙(예: `/api/*`는 백엔드로, 그 외는 프론트엔드로)을 사용합니다. Shared 환경에서 예약된 고정 IP를 사용합니다.
*   **데이터베이스:**
    *   **MySQL 인스턴스 (`google_compute_instance.mysql_vm`):** Shared 환경에서 생성된 영구 디스크를 사용하는 MySQL 데이터베이스 서버 VM입니다.
*   **네트워킹 및 보안:**
    *   Shared VPC의 서브넷을 사용하며 (`terraform_remote_state.shared`를 통해 참조), 환경별 특정 방화벽 규칙(예: 프론트엔드에서 백엔드 접근 허용)을 추가로 정의합니다.
    *   Cloud NAT (`google_compute_router_nat`)를 통해 외부 인터넷으로의 아웃바운드 통신을 지원합니다.
## Prod 환경

Prod 환경은 실제 사용자에게 서비스를 제공하는 운영 환경입니다. Develop 환경과 유사한 기본 구조를 가지지만, 고가용성, 확장성, 그리고 안정적인 배포를 위해 다음과 같은 주요 차이점과 기능을 포함합니다. Shared 환경의 리소스를 적극 활용합니다.

주요 리소스는 다음과 같습니다:

*   **컴퓨팅 (Blue/Green 배포 지원):**
    *   **백엔드 MIGs (`module.backend_internal_asg_blue`, `module.backend_internal_asg_green`):** `modules/mig-asg` 모듈을 사용하여 백엔드 애플리케이션을 위한 두 개의 Managed Instance Groups (MIGs) (`module.backend_internal_asg_blue`, `module.backend_internal_asg_green`)를 운영하여 블루/그린 배포를 지원합니다. 각 MIG는 오토스케일링이 설정되어 트래픽에 따라 인스턴스 수가 자동으로 조절됩니다.
    *   **프론트엔드 MIGs (`module.frontend_asg_blue`, `module.frontend_asg_green`):** `modules/mig-asg` 모듈을 사용하여 프론트엔드 애플리케이션을 위한 두 개의 MIGs (`module.frontend_asg_blue`, `module.frontend_asg_green`)를 운영하여 블루/그린 배포를 지원합니다. 마찬가지로 오토스케일링이 적용됩니다.
    *   각 MIG는 시작 스크립트를 통해 Docker 컨테이너 애플리케이션을 배포하며, `variables.tf` 또는 `terraform.tfvars`를 통해 블루/그린 버전에 해당하는 Docker 이미지 태그를 지정합니다.
*   **로드 밸런싱 (Blue/Green 트래픽 제어):**
    *   **내부 HTTP 로드 밸런서 (`module.internal_lb`):** `modules/internal-http-lb` 모듈을 사용하여 백엔드 서비스(Blue/Green MIGs)로 트래픽을 분산하는 내부 로드 밸런서 (`module.internal_lb`)입니다. 외부 로드 밸런서의 백엔드 타겟 그룹으로 사용될 수 있습니다.
    *   **외부 HTTPS 로드 밸런서 (`module.external_lb`):** `modules/external-https-lb` 모듈을 사용하는 외부 HTTPS 로드 밸런서 (`module.external_lb`)가 인터넷 트래픽의 진입점입니다. URL 경로 기반 라우팅을 수행하며, `modules/target-group` 모듈을 통해 정의된 프론트엔드 (`module.frontend_tg`) 및 백엔드 (`module.backend_tg`) 타겟 그룹으로 트래픽을 전달합니다.
        *   백엔드 및 프론트엔드 타겟 그룹(`module.backend_tg`, `module.frontend_tg`)은 블루/그린 MIGs에 대한 트래픽 가중치를 설정하여 점진적인 배포 또는 롤백을 가능하게 합니다. (`terraform.tfvars`의 `traffic_weight_blue`, `traffic_weight_green` 변수 사용)
*   **데이터베이스:**
    *   **MySQL 인스턴스 (`google_compute_instance.mysql_vm`):** Shared 환경에서 생성된 프로덕션용 영구 디스크를 사용하는 MySQL 데이터베이스 서버 VM입니다. Develop 환경의 MySQL 인스턴스와는 별도의 디스크와 VM을 사용합니다.
*   **네트워킹 및 보안:**
    *   Shared VPC 및 서브넷을 사용하며, 내부 로드 밸런서의 헬스 체크 및 프록시 접근을 위한 특정 방화벽 규칙을 포함합니다.
    *   Cloud NAT를 통해 외부 인터넷으로의 아웃바운드 통신을 지원합니다.
## Terraform 모듈

이 아키텍처는 재사용성과 관리 용이성을 높이기 위해 여러 Terraform 모듈을 활용합니다. 각 모듈은 특정 GCP 리소스 또는 기능 그룹을 캡슐화합니다.

주요 모듈은 다음과 같습니다:

*   **`modules/network`**: VPC 네트워크 및 서브넷 생성을 담당합니다. Shared 환경에서 VPC를 구축하는 데 사용됩니다.
*   **`modules/compute`**: 단일 Compute Engine VM 인스턴스 생성을 위한 기본 모듈입니다. Shared 환경의 OpenVPN 서버 생성에 사용됩니다.
*   **`modules/external-https-lb`**: 외부 사용자 트래픽을 위한 전역 HTTPS 로드 밸런서를 설정합니다. URL 맵, SSL 인증서, 포워딩 규칙 등을 포함합니다. Develop 및 Prod 환경에서 사용됩니다.
*   **`modules/internal-http-lb`**: 내부 트래픽 관리를 위한 지역 HTTP 로드 밸런서를 설정합니다. Prod 환경의 백엔드 서비스에 사용됩니다.
*   **`modules/mig-asg`**: 오토스케일링 기능이 있는 Managed Instance Group (MIG)을 생성합니다. 인스턴스 템플릿, 리전 인스턴스 그룹 관리자, 오토스케일러를 포함합니다. Prod 환경의 프론트엔드 및 백엔드 서비스에 사용되어 블루/그린 배포 및 확장성을 지원합니다.
*   **`modules/target-group`**: 로드 밸런서의 백엔드 서비스(`google_compute_backend_service`)를 정의합니다. MIG 또는 Unmanaged Instance Group을 백엔드로 연결하고 헬스 체크 및 로드 밸런싱 설정을 구성합니다. Develop 및 Prod 환경에서 사용됩니다.
*   **`modules/health-check`**: HTTP(S) 기반의 헬스 체크를 정의합니다. 로드 밸런서 및 MIG에서 인스턴스의 상태를 모니터링하는 데 사용됩니다.
*   **`modules/firewall`**: 방화벽 규칙 생성을 위한 모듈입니다. Shared 환경에서 공통 방화벽 규칙을 정의하는 데 사용됩니다.
## 주요 아키텍처 특징

이 GCP Terraform 아키텍처는 다음과 같은 주요 특징을 가지고 있습니다:

*   **모듈성 (Modularity):** Terraform 모듈을 사용하여 GCP 리소스를 논리적 단위로 구성함으로써 코드의 재사용성을 높이고 관리를 용이하게 합니다. 각 모듈은 특정 기능(예: 네트워크, 로드 밸런서, 인스턴스 그룹)을 담당합니다.
*   **환경 분리 (Environment Separation):** `Shared`, `Develop`, `Prod` 환경을 명확히 분리하여 각 환경의 목적에 맞는 인프라를 구성하고 관리합니다. 이를 통해 개발, 테스트, 운영 환경 간의 독립성을 보장하고 안정적인 서비스 운영을 지원합니다.
*   **확장성 및 복원력 (Scalability & Resilience - Production):** 프로덕션 환경에서는 Managed Instance Groups (MIGs)와 오토스케일링을 사용하여 트래픽 변화에 따라 자동으로 인스턴스 수를 조절하고, 여러 가용 영역에 인스턴스를 분산하여 서비스의 확장성과 내결함성을 확보합니다.
*   **블루/그린 배포 (Blue/Green Deployments - Production):** 프로덕션 환경의 프론트엔드 및 백엔드 서비스는 두 개의 독립적인 인스턴스 그룹(Blue/Green)을 운영하고, 로드 밸런서의 트래픽 가중치 조정을 통해 신규 버전으로의 무중단 또는 점진적 배포 및 필요시 빠른 롤백을 지원합니다.
*   **중앙 집중식 공유 리소스 (Centralized Shared Resources):** Shared VPC, OpenVPN, 공통 헬스 체크 및 영구 디스크와 같은 핵심 리소스를 `Shared` 환경에서 중앙 집중적으로 관리하여 모든 환경에서 일관된 방식으로 공유하고 활용할 수 있도록 합니다. 이는 보안 강화 및 운영 효율성 증대에 기여합니다.
*   **코드형 인프라 (Infrastructure as Code - IaC):** Terraform을 사용하여 인프라를 코드로 정의함으로써 버전 관리, 변경 추적, 반복 가능한 배포 및 자동화를 가능하게 합니다.
