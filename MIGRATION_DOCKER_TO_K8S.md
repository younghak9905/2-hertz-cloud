# Docker에서 Kubernetes로 마이그레이션

이 문서는 애플리케이션을 Docker 기반 배포에서 Kubernetes 기반 배포로 마이그레이션하는 데 관련된 단계를 설명합니다.

## 1. 소개

Docker 기반 배포에서 Kubernetes로 마이그레이션하면 다음과 같은 몇 가지 중요한 이점을 얻을 수 있습니다.

*   **확장성 및 고가용성:** Kubernetes는 컨테이너화된 애플리케이션 오케스트레이션에 뛰어나며, 수요에 따른 자동 확장 기능을 제공하고 컨테이너 재시작 관리 및 여러 노드에 워크로드 분산을 통해 고가용성을 보장합니다.
*   **리소스 활용도 향상:** Kubernetes는 리소스 할당을 최적화하여 애플리케이션이 필요한 리소스를 확보하는 동시에 기본 인프라의 활용도를 극대화합니다.
*   **선언적 구성 및 자가 치유:** Kubernetes는 선언적 접근 방식을 사용하여 애플리케이션의 원하는 상태를 정의합니다. 시스템을 지속적으로 모니터링하고 해당 상태를 유지하기 위해 자동으로 수정 조치를 수행합니다(예: 실패한 컨테이너 재시작).
*   **서비스 검색 및 로드 밸런싱:** Kubernetes는 서비스 검색 및 로드 밸런싱을 위한 내장 메커니즘을 제공하여 마이크로서비스 간의 통신을 단순화합니다.
*   **롤링 업데이트 및 롤백:** Kubernetes는 롤링 업데이트 전략을 통해 원활한 애플리케이션 업데이트를 지원하고 문제 발생 시 손쉬운 롤백을 위한 메커니즘을 제공합니다.
*   **이식성 및 공급업체 중립성:** Kubernetes는 주요 클라우드 공급업체에서 지원하는 오픈 소스 플랫폼이며 온프레미스에서 실행할 수 있어 유연성을 제공하고 공급업체 종속을 방지합니다.
*   **생태계 및 커뮤니티:** Kubernetes는 방대하고 활발한 커뮤니티를 보유하고 있으며 풍부한 도구, 확장 기능 및 지원 생태계를 제공합니다.

## 2. 전제 조건

마이그레이션 프로세스를 시작하기 전에 다음 전제 조건이 충족되었는지 확인하십시오.

*   **기존 Docker 설정:** 애플리케이션은 이미 Docker를 사용하여 컨테이너화되어 있어야 하며, 각 서비스에 대한 Dockerfile이 있고 로컬 개발 및 오케스트레이션을 위해 가급적 Docker Compose를 사용하고 있어야 합니다.
*   **Kubernetes 클러스터 액세스:** 실행 중인 Kubernetes 클러스터에 액세스해야 합니다. 다음 중 하나일 수 있습니다.
    *   **로컬 클러스터:** 개발 및 테스트용 (예: Minikube, Kind, Docker Desktop Kubernetes).
    *   **클라우드 관리형 클러스터:** 클라우드 공급업체에서 제공 (예: Google Kubernetes Engine - GKE, Amazon Elastic Kubernetes Service - EKS, Azure Kubernetes Service - AKS).
    *   **자체 관리형 클러스터:** 직접 설정하고 관리하는 클러스터.
*   **`kubectl` 설치 및 구성:** Kubernetes 명령줄 도구인 `kubectl`이 설치되어 있고 선택한 Kubernetes 클러스터와 통신하도록 구성되어 있어야 합니다. `kubectl version` 및 `kubectl cluster-info`를 실행하여 이를 확인할 수 있습니다.
*   **Docker 이미지:** 애플리케이션의 Docker 이미지가 빌드되어 Kubernetes 클러스터에서 액세스할 수 있는지 확인합니다(예: Docker Hub, Google Container Registry - GCR, Amazon Elastic Container Registry - ECR 또는 Azure Container Registry - ACR과 같은 컨테이너 레지스트리에 푸시됨).
*   **핵심 Kubernetes 개념 이해:** Pod, Deployment, Service, ConfigMap, Secret 및 Namespace와 같은 기본적인 Kubernetes 객체에 대해 숙지하십시오.

## 3. 마이그레이션 단계

이 섹션에서는 Docker화된 애플리케이션을 Kubernetes로 마이그레이션하는 단계별 프로세스를 자세히 설명합니다.

### 3.1. Kubernetes 클러스터 설정

Kubernetes 클러스터가 없는 경우 설정해야 합니다. 다음은 몇 가지 일반적인 옵션입니다.

*   **Minikube:**
    *   로컬 개발에 이상적입니다.
    *   로컬 머신의 VM 내부에 단일 노드 Kubernetes 클러스터를 생성합니다.
    *   설치: 공식 Minikube 설치 가이드를 따릅니다.
    *   클러스터 시작: `minikube start`
*   **Kind (Kubernetes in Docker):**
    *   로컬 개발을 위한 또 다른 훌륭한 옵션입니다.
    *   Kubernetes 클러스터 노드를 Docker 컨테이너로 실행합니다.
    *   설치: 공식 Kind 설치 가이드를 따릅니다.
    *   클러스터 생성: `kind create cluster`
*   **클라우드 공급자 서비스:**
    *   **GKE (Google Kubernetes Engine):** Google Cloud의 관리형 Kubernetes 서비스입니다.
    *   **EKS (Amazon Elastic Kubernetes Service):** AWS의 관리형 Kubernetes 서비스입니다.
    *   **AKS (Azure Kubernetes Service):** Microsoft Azure의 관리형 Kubernetes 서비스입니다.
    *   이러한 서비스는 클러스터 생성 및 관리를 단순화합니다. 각 클라우드 공급자의 설명서에 따라 클러스터를 생성하고 구성하십시오. `kubectl`이 새로 생성된 클라우드 클러스터를 가리키도록 구성되었는지 확인하십시오.

### 3.2. Docker Compose를 Kubernetes 매니페스트로 변환

Kubernetes는 YAML 매니페스트 파일을 사용하여 애플리케이션 배포를 정의합니다. Docker Compose를 사용하는 경우 `docker-compose.yml` 파일을 Kubernetes 매니페스트로 변환할 수 있습니다.

*   **Kompose 사용:**
    *   Kompose는 Docker Compose 파일을 Kubernetes 객체로 변환하는 작업을 자동화하는 도구입니다.
    *   설치: 공식 Kompose 설치 가이드를 따릅니다.
    *   변환: `kompose convert -f docker-compose.yml -o <output_directory>`
    *   생성된 매니페스트를 검토하고 구체화합니다. Kompose는 좋은 시작점을 제공하지만 프로덕션 환경에서 사용하려면 출력을 사용자 지정해야 할 가능성이 높습니다(예: 프로브 추가, 리소스 요청/제한, 더 정교한 배포 전략).
*   **Kubernetes 매니페스트 수동 생성:**
    *   더 많은 제어가 필요하거나 복잡한 설정의 경우 Kubernetes 매니페스트를 수동으로 생성하는 것을 선호할 수 있습니다. 주요 매니페스트 유형은 다음과 같습니다.
        *   **Deployment:** Docker 이미지, 복제본 수, 업데이트 전략 및 파드 템플릿을 포함하여 상태 비저장 애플리케이션을 실행하는 방법을 정의합니다.
        *   **Service:** 애플리케이션을 네트워크에 노출합니다(클러스터 내부 또는 외부). 일반적인 유형은 `ClusterIP`, `NodePort` 및 `LoadBalancer`입니다.
        *   **ConfigMap:** 애플리케이션 구성 데이터를 키-값 쌍으로 관리합니다.
        *   **Secret:** API 키, 암호 및 인증서와 같은 중요한 데이터를 관리합니다.
        *   **PersistentVolume (PV) 및 PersistentVolumeClaim (PVC):** 영구 스토리지가 필요한 상태 저장 애플리케이션용입니다.
        *   **Ingress:** 일반적으로 HTTP인 클러스터의 서비스에 대한 외부 액세스를 관리합니다.

    **예제: 간단한 웹 애플리케이션 배포 (deployment.yaml)**
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-web-app
      labels:
        app: my-web-app
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: my-web-app
      template:
        metadata:
          labels:
            app: my-web-app
        spec:
          containers:
          - name: my-web-container
            image: your-docker-registry/my-web-app:latest # 이미지로 교체하십시오.
            ports:
            - containerPort: 80
    ```

    **예제: 웹 애플리케이션을 노출하는 서비스 (service.yaml)**
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: my-web-app-service
    spec:
      selector:
        app: my-web-app
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
      type: LoadBalancer # 또는 필요에 따라 NodePort/ClusterIP
    ```

### 3.3. Kubernetes에 애플리케이션 배포

Kubernetes 매니페스트 파일이 있으면 `kubectl`을 사용하여 애플리케이션을 배포할 수 있습니다.

*   **매니페스트 적용:**
    *   YAML 매니페스트 파일이 포함된 디렉터리로 이동합니다.
    *   명령 실행: `kubectl apply -f <filename.yaml>` 또는 `kubectl apply -f <directory_name>/`
    *   예제: `kubectl apply -f deployment.yaml` 및 `kubectl apply -f service.yaml`
*   **배포 확인:**
    *   배포 상태 확인: `kubectl get deployments`
    *   파드 상태 확인: `kubectl get pods` (파드가 생성되고 실행 중인 것을 볼 수 있어야 함)
    *   서비스 상태 확인: `kubectl get services` (`LoadBalancer` 유형을 사용하는 경우 외부 IP 참고)

### 3.4. Kubernetes에서 애플리케이션 관리

`kubectl`은 실행 중인 애플리케이션을 관리하고 상호 작용하기 위한 다양한 명령을 제공합니다.

*   **로그 보기:**
    *   `kubectl logs <pod_name>`
    *   `kubectl logs -f <pod_name>` (실시간으로 로그 추적)
    *   `kubectl logs -l app=my-web-app` (특정 레이블이 있는 모든 파드의 로그 보기)
*   **컨테이너에서 명령 실행:**
    *   `kubectl exec -it <pod_name> -- /bin/bash` (컨테이너 내부 셸 얻기)
*   **배포 확장:**
    *   `kubectl scale deployment <deployment_name> --replicas=<new_replica_count>`
    *   예제: `kubectl scale deployment my-web-app --replicas=5`
*   **롤아웃 업데이트:**
    *   `deployment.yaml` 파일에서 Docker 이미지 버전을 업데이트합니다.
    *   업데이트된 매니페스트 적용: `kubectl apply -f deployment.yaml`
    *   롤아웃 상태 모니터링: `kubectl rollout status deployment/<deployment_name>`
    *   롤아웃 기록 보기: `kubectl rollout history deployment/<deployment_name>`
*   **롤백 업데이트:**
    *   `kubectl rollout undo deployment/<deployment_name>`
    *   `kubectl rollout undo deployment/<deployment_name> --to-revision=<revision_number>`
*   **리소스 설명:**
    *   `kubectl describe pod <pod_name>`
    *   `kubectl describe deployment <deployment_name>`
    *   `kubectl describe service <service_name>`
    *   이 명령은 문제 해결에 유용한 이벤트를 포함하여 리소스에 대한 자세한 정보를 제공합니다.

### 3.5. 테스트 및 검증

Kubernetes에서 실행 중인 애플리케이션을 철저히 테스트합니다.

*   외부 IP 주소 또는 서비스 DNS 이름을 통해 애플리케이션에 액세스합니다.
*   모든 기능이 예상대로 작동하는지 확인하기 위해 기능 테스트를 수행합니다.
*   확장성 및 리소스 활용도를 확인하기 위해 성능 및 부하 테스트를 수행합니다.
*   파드를 삭제하고 Kubernetes가 파드를 다시 시작하고 서비스 가용성을 유지하는지 관찰하여 장애 조치 테스트를 수행합니다.

### 3.6. 전환

Kubernetes 배포가 안정적이고 성능이 우수하다고 확신하면 전환을 계획합니다.

*   **DNS 업데이트:** DNS 레코드를 업데이트하여 Kubernetes 서비스의 외부 IP 주소 또는 로드 밸런서를 가리키도록 합니다.
*   **면밀한 모니터링:** 전환 후 Kubernetes에서 애플리케이션의 성능과 로그를 모니터링합니다.
*   **단계적 롤아웃 (선택 사항):** 중요한 애플리케이션의 경우 Kubernetes가 지원할 수 있는 카나리 릴리스 또는 블루/그린 배포와 같은 기술을 사용하여 단계적 롤아웃을 고려합니다.

## 4. 일반적인 문제 해결

발생할 수 있는 몇 가지 일반적인 문제와 해결 방법은 다음과 같습니다.

*   **ImagePullBackOff / ErrImagePull:**
    *   **원인:** Kubernetes가 Docker 이미지를 가져올 수 없습니다.
    *   **문제 해결:**
        *   배포 매니페스트에서 이미지 이름과 태그가 올바른지 확인합니다.
        *   이미지가 지정된 레지스트리에 있고 공개되어 있거나 Kubernetes가 개인 레지스트리에 액세스하는 데 필요한 자격 증명(ImagePullSecrets)을 가지고 있는지 확인합니다.
        *   Kubernetes 노드에서 레지스트리로의 네트워크 연결을 확인합니다.
        *   `kubectl describe pod <pod_name>`은 자세한 오류 메시지를 표시합니다.
*   **CrashLoopBackOff:**
    *   **원인:** 애플리케이션 컨테이너가 시작된 후 반복적으로 충돌합니다.
    *   **문제 해결:**
        *   컨테이너 로그 확인: `kubectl logs <pod_name>`
        *   애플리케이션 오류, 잘못된 구성 또는 리소스 문제(예: 메모리 부족)를 찾습니다.
        *   환경 변수 및 ConfigMap을 확인합니다.
        *   준비성 및 활성 프로브가 올바르게 구성되었는지 확인합니다(사용된 경우).
*   **서비스에 액세스할 수 없음:**
    *   **원인:** Kubernetes 서비스가 애플리케이션을 올바르게 노출하지 않습니다.
    *   **문제 해결:**
        *   서비스 선택기가 파드의 레이블과 일치하는지 확인합니다: `kubectl describe service <service_name>` 및 `kubectl get pods --show-labels`.
        *   서비스 유형(`ClusterIP`, `NodePort`, `LoadBalancer`)을 확인하고 액세스 요구 사항에 적합한지 확인합니다.
        *   `LoadBalancer`를 사용하는 경우 클라우드 공급자가 외부 IP를 프로비저닝했는지 확인합니다.
        *   네트워크 정책이 트래픽을 차단하지 않는지 확인합니다.
        *   서비스 매니페스트의 `targetPort`가 배포 매니페스트의 `containerPort`와 일치하는지 확인합니다.
*   **Pending Pods (보류 중인 파드):**
    *   **원인:** 파드를 노드에 예약할 수 없습니다.
    *   **문제 해결:**
        *   `kubectl describe pod <pod_name>`은 이유를 표시합니다(예: CPU/메모리 부족, 노드 테인트/톨러레이션).
        *   노드 리소스 확인: `kubectl top nodes`.
        *   클러스터에 충분한 용량이 있는지 확인합니다.

## 5. Kubernetes에서 애플리케이션 실행을 위한 모범 사례

*   **준비성(Readiness) 및 활성(Liveness) 프로브:**
    *   **활성 프로브:** 컨테이너가 실행 중인지 여부를 나타냅니다. 활성 프로브가 실패하면 Kubernetes는 컨테이너를 다시 시작합니다.
    *   **준비성 프로브:** 컨테이너가 트래픽을 처리할 준비가 되었는지 여부를 나타냅니다. 준비성 프로브가 실패하면 Kubernetes는 통과할 때까지 파드에 트래픽을 보내지 않습니다.
    *   애플리케이션 복원력을 향상시키기 위해 배포 매니페스트에서 이를 정의합니다.
*   **리소스 요청 및 제한:**
    *   **요청:** Kubernetes가 컨테이너에 보장하는 CPU 및 메모리 양입니다.
    *   **제한:** 컨테이너가 소비할 수 있는 최대 CPU 및 메모리 양입니다.
    *   공정한 리소스 할당을 보장하고 리소스 부족 또는 과다 사용을 방지하기 위해 적절한 요청 및 제한을 설정합니다.
*   **로깅:**
    *   애플리케이션이 `stdout` 및 `stderr`에 로그를 기록하는지 확인합니다. Kubernetes는 이러한 로그를 수집합니다.
    *   더 쉬운 로그 집계 및 분석을 위해 중앙 집중식 로깅 솔루션(예: EFK 스택 - Elasticsearch, Fluentd, Kibana 또는 Loki) 구현을 고려합니다.
*   **모니터링:**
    *   애플리케이션 및 Kubernetes 클러스터에 대한 모니터링을 구현합니다.
    *   Prometheus 및 Grafana와 같은 도구는 메트릭 수집 및 시각화에 일반적으로 사용됩니다.
    *   CPU/메모리 사용량, 오류율, 대기 시간 및 파드 상태와 같은 주요 메트릭을 모니터링합니다.
*   **네임스페이스:**
    *   클러스터 내에서 리소스를 구성하는 데 네임스페이스를 사용합니다(예: 환경별, 팀별, 애플리케이션별).
*   **RBAC (역할 기반 액세스 제어):**
    *   RBAC를 구성하여 Kubernetes API 리소스에 대한 액세스를 제어하여 보안 및 최소 권한을 보장합니다.
*   **시크릿 관리:**
    *   중요한 데이터에는 Kubernetes 시크릿을 사용합니다.
    *   향상된 보안을 위해 HashiCorp Vault와 같은 외부 시크릿 관리 솔루션과의 통합을 고려합니다.
*   **구성 관리:**
    *   ConfigMap을 사용하여 컨테이너 이미지 외부에서 애플리케이션 구성을 관리합니다.
*   **Helm:**
    *   Kubernetes 패키지 관리자인 Helm을 사용하여 애플리케이션을 템플릿화, 관리 및 배포하는 것을 고려합니다. Helm 차트는 복잡한 배포를 단순화합니다.

## 6. 롤백 계획

철저한 테스트에도 불구하고 문제가 발생할 수 있습니다. 롤백 계획을 마련하십시오.

*   **Kubernetes 배포 롤백:**
    *   `kubectl rollout undo deployment/<deployment_name>`을 사용하여 이전 안정 버전으로 되돌립니다.
*   **DNS 변경 사항 되돌리기:** DNS를 통해 이미 트래픽을 전환한 경우 DNS 변경 사항을 되돌려 이전 Docker 기반 배포를 다시 가리키도록 합니다.
*   **근본 원인 파악:** 마이그레이션을 다시 시도하기 전에 문제의 원인을 철저히 조사합니다.
*   **이전 인프라 계속 실행:** 마이그레이션 직후 이전 Docker 기반 환경을 해체하지 마십시오. Kubernetes 배포에 완전히 확신할 때까지 대체 수단으로 계속 실행하십시오.

## 7. 마이그레이션 후 작업

성공적인 마이그레이션 후:

*   **포괄적인 모니터링 및 로깅 설정:** 모니터링 및 로깅 도구가 Kubernetes 환경에 대해 완전히 구성되어 있고 필요한 통찰력을 제공하는지 확인합니다.
*   **CI/CD 파이프라인 업데이트:** CI/CD 파이프라인을 업데이트하여 Docker 이미지를 빌드하고 레지스트리에 푸시하며 Kubernetes에서 애플리케이션을 배포/업데이트합니다(예: `kubectl apply` 또는 Helm 사용).
*   **문서 업데이트:** 모든 관련 애플리케이션 및 운영 문서를 업데이트하여 새로운 Kubernetes 기반 배포를 반영합니다.
*   **팀 교육:** 팀이 Kubernetes 개념과 애플리케이션 관리를 위한 `kubectl` 명령에 익숙한지 확인합니다.
*   **이전 인프라 해체:** 확신이 서면 이전 Docker 기반 인프라의 해체를 계획하고 실행합니다.

## 8. 결론

Docker에서 Kubernetes로 마이그레이션하는 것은 확장성, 복원력 및 운영 효율성 측면에서 상당한 이점을 가져올 수 있는 중요한 단계입니다. 프로세스에 신중한 계획과 실행이 필요하지만 Kubernetes와 같은 강력한 오케스트레이션 플랫폼에서 애플리케이션을 실행하는 장기적인 이점은 종종 노력할 가치가 있습니다. 이 문서는 포괄적인 가이드를 제공하지만 특정 애플리케이션 및 조직의 요구 사항에 맞게 단계와 모범 사례를 조정해야 함을 기억하십시오.
