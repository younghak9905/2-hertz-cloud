🍀 [프로젝트 Wiki 바로가기](https://github.com/100-hours-a-week/2-hertz-wiki/wiki)

# 2-team-hertz-cloud

# 📄 Managed Kubernetes 도입 배경 및 설계 설명서

## 1. 도입 배경 및 목적

### 1.1 우리 서비스 특성과 Managed Kubernetes 전환 필요성

현재 우리 서비스는 **뉴스 배포 시점에 트래픽이 급증**하고, 이후에는 **채팅 중심으로 안정화**되는 패턴을 보입니다.
이에 따라 **오토스케일링을 통한 탄력적인 자원 운영**이 필수적입니다. 
또한, kubeadm 기반 수동 구축 환경에서는 **주기적인 업그레이드, 패치, 인증서 갱신** 등을 직접 관리해야 하며, 이는 운영 리스크를 초래할 수 있습니다.

이러한 한계를 극복하기 위해, 우리는 **Managed Kubernetes(EKS)** 기반 환경으로의 전환을 추진합니다.


- **오토스케일링 부재**: 급격한 트래픽 증가 시 노드를 자동으로 확장하는 기능이 기본 제공되지 않습니다.
- **운영 자동화 부족**: 업그레이드, 패치, 인증서 갱신 등을 직접 관리해야 해 운영 리스크가 존재합니다.
- **모니터링/관측성 한계**: 클러스터 전반 모니터링, 알림 체계 구성에 추가적인 관리 비용이 발생합니다.

### 1.2 기존 kubeadm 운영 환경의 한계

#### 1.2.1 오토스케일링 부재

- kubeadm 환경에서는 트래픽 급증 시 노드를 자동으로 확장할 수 없음
- 수동으로 노드를 추가해야 하며, 확장 대응이 늦어질 수 있어 서비스 안정성에 영향을 미침
- 트래픽이 적은 시간대에도 고사양 인스턴스를 고정으로 운영
- 트래픽 변동이 잦은 우리 서비스 특성상, 탄력적 자원 운영이 필요하지만 어려움
#### 1.2.2 운영 자동화 부족

- 마스터 노드의 업그레이드, 패치, 인증서 갱신을 모두 수작업으로 처리해야 됨
- 보안 업데이트, 버전 업그레이드 등 지속적인 유지보수 작업 필요
- 운영자의 실수 가능성이 존재하며, 클러스터 안정성 확보를 위해 지속적인 관리 부담이 따름
- 노드 장애 시 수동 복구 절차 필요

### 1.3 Managed Kubernetes 도입 기대효과
#### 1.3.1 오토스케일링 자동화

- 트래픽 급증 시 **Cluster Autoscaler** 기능을 통해 워커 노드가 자동으로 확장/축소
- 뉴스 배포 시점, 채팅 급증 상황에서도 수동 개입 없이 탄력적인 대응이 가능
#### 1.3.2 클러스터 운영 자동화

- Kubernetes 버전 업그레이드, 패치, 인증서 갱신 등을 AWS가 관리
- 운영팀이 직접 수작업으로 관리할 필요가 없어 **운영 리스크**가 대폭 감소
#### 1.3.3 장애 복구 속도 향상

- 노드 장애 발생 시, **Auto Healing** 기능을 통해 자동으로 새 인스턴스가 생성 및 연결
- 인프라 수준에서의 복구 시간 단축
#### 1.3.4 비용 및 인프라 최적화

- 트래픽 패턴에 맞춘 유연한 워커노드 운영으로 장기적으로 비용 절감 기대
- 추후 사용량 기반 과금 및 노드 최적화(스팟 인스턴스, EC2 Savings Plan 등) 적용이 쉬워짐
#### 1.3.5 보안 강화 및 관리 용이성

- IAM, VPC, 보안 그룹 등 AWS 인프라 보안 체계와 Kubernetes 리소스 접근 제어가 통합 관리됩니다.
- 인증/인가 관리(예: IRSA, OIDC 통합)도 용이해져, 서비스 안정성이 향상됩니다.

### 1.4 배포 전략 비교

| **항목** | **kubeadm** | **EKS** |
| --- | --- | --- |
| 컨트롤 플레인 관리 | 직접 (수동) | AWS 관리 (자동) |
| Rolling Update | Deployment/StatefulSet rollingUpdate 수동 튜닝 | 동일, 하지만 안정성 강화됨 |
| 장애 대응 | 마스터/etcd 다운 직접 복구 | 컨트롤 플레인은 AWS가 복구 |
| Pod 헬스체크 기반 자동화 | 제한적 | ALB/TargetGroup 헬스체크와 통합 가능 |

## 2. EKS 선택 이유 및 결론

EKS는 AWS에서 제공하는 Managed Kubernetes 서비스로, 기존 **kubeadm** 환경에서 사용하던 **Helm**, **ArgoCD** 기반 CI/CD 체계를 그대로 활용할 수 있습니다.
    ➔ 추가 마이그레이션 비용 없이, 기존 표준 Kubernetes 생태계를 **자연스럽게 확장**할 수 있습니다.
    
특히 **Tuning 서비스**는 뉴스 알림 시점에 **Burst성 트래픽**이 몰리는 구조를 가지는데, EKS는 **노드 오토스케일링과 자원 자동 확장**을 기본 제공하여, 이러한 **급격한 부하 변화에 민첩하게 대응**할 수 있습니다.
    
결과적으로, EKS는 **운영 안정성**, **비용 최적화**, **확장성 확보**라는 세 가지 관점 모두에서 우리 서비스에 최적화된 선택입니다.
따라서 우리는 **Managed Kubernetes** 서비스인 **EKS** 환경으로의 전환을 추진합니다.
<br>

# 📄 Kubernetes 리소스 명세서
## 1. Kubernetes 아키텍처 다이어그램
![카카오테크 - Tuning 아키텍처-EKS (1)](https://github.com/user-attachments/assets/03eb6b58-225e-4e1d-b504-0f2a0444a8c4)
