# Kubeadm을 사용한 Kubernetes 클러스터 구축 가이드

`kubeadm`은 Kubernetes 클러스터를 쉽고 빠르게 부트스트랩(초기 설정 및 구성)하기 위해 Kubernetes 프로젝트에서 공식적으로 제공하는 명령줄 도구입니다. 이 도구는 사용자가 최소한의 노력으로 Kubernetes의 컨트롤 플레인과 워커 노드를 설정할 수 있도록 지원하며, 쿠버네티스 모범 사례를 따르도록 설계되었습니다.

이 가이드는 `kubeadm`을 사용하여 Kubernetes 클러스터를 생성하고 관리하는 기본적인 단계와 주요 개념들을 안내합니다.

## 1. `kubeadm`이란 무엇인가?

*   **`kubeadm`의 정의:** `kubeadm`은 쿠버네티스 클러스터를 부트스트랩(초기 설정 및 구성)하기 위한 공식 도구입니다. 쿠버네티스 클러스터의 컨트롤 플레인 노드를 초기화하고, 워커 노드를 클러스터에 안전하게 참여시키는 데 필요한 작업을 자동화합니다.
*   **주요 역할:**
    *   `kubeadm init`: 컨트롤 플레인 노드를 초기화하고, API 서버, 컨트롤러 매니저, 스케줄러, etcd 등 핵심 구성 요소를 설치 및 설정합니다. 또한, 클러스터 참여에 필요한 토큰과 `kubeconfig` 파일을 생성합니다.
    *   `kubeadm join`: 워커 노드를 기존 클러스터에 참여시킵니다. `kubeadm init` 시 생성된 토큰과 클러스터 정보를 사용하여 컨트롤 플레인에 안전하게 연결합니다.
*   **`kubeadm`의 목표:** 사용자가 최소한의 구성으로 Kubernetes 클러스터를 쉽게 생성할 수 있도록 지원하는 것입니다. `kubeadm`은 프로덕션 환경에서도 사용될 수 있지만, 특정 운영 환경의 요구사항(예: 고가용성, 고급 보안 설정, 특정 클라우드 통합)에 따라 추가적인 수동 설정이나 다른 도구와의 연동이 필요할 수 있습니다. `kubeadm`은 쿠버네티스 클러스터의 라이프사이클 관리 전반을 다루기보다는 부트스트랩에 중점을 둡니다.
*   **장점:**
    *   **공식 지원:** Kubernetes 프로젝트에서 직접 개발하고 지원하므로, 최신 Kubernetes 버전과의 호환성 및 안정성이 높습니다.
    *   **단순성:** 비교적 간단한 명령어로 클러스터의 기본 구성을 빠르게 완료할 수 있습니다.
    *   **커스터마이징:** `kubeadm config` 명령이나 설정 파일을 통해 클러스터의 다양한 매개변수(예: API 서버 옵션, 네트워크 CIDR, 사용할 Kubernetes 버전 등)를 커스터마이징할 수 있습니다.
    *   **업그레이드 지원:** `kubeadm upgrade` 명령을 통해 클러스터 버전을 비교적 쉽게 업그레이드할 수 있도록 지원합니다.
*   **일반적인 사용 사례:**
    *   학습 및 테스트 목적의 Kubernetes 클러스터 구축.
    *   온프레미스(사내 데이터센터) 환경에 Kubernetes 클러스터 구축.
    *   쿠버네티스 기본 구성 요소의 설치 및 초기 구성을 자동화.
    *   다른 고급 클러스터 배포 도구(예: KubeSpray, Kubesphere)의 기반으로 사용되기도 합니다.

## 2. `kubeadm`의 대상 및 비대상 (Scope)

`kubeadm`은 클러스터 부트스트랩에 필요한 많은 작업을 수행하지만, 모든 것을 처리하지는 않습니다. 그 범위를 이해하는 것이 중요합니다.

*   **`kubeadm`이 처리하는 범위:**
    *   컨트롤 플레인 노드의 핵심 구성 요소 설치 및 설정: API 서버(kube-apiserver), 컨트롤러 매니저(kube-controller-manager), 스케줄러(kube-scheduler), etcd (단일 노드 클러스터의 경우 컨트롤 플레인 노드에 설치, HA 구성 시 외부 etcd도 가능).
    *   워커 노드의 `kubelet` 및 `kube-proxy` 설정 및 실행.
    *   클러스터 내부 통신을 위한 TLS 인증서 생성 및 관리.
    *   클러스터 관리를 위한 `kubeconfig` 파일 생성 (예: `/etc/kubernetes/admin.conf`).
    *   필수 애드온(add-on) 설치: CoreDNS (클러스터 DNS 서비스), Kube Proxy (네트워크 프록시).
    *   클러스터 조인 토큰 생성 및 관리.
    *   클러스터 업그레이드 지원 (컨트롤 플레인 및 `kubelet` 업그레이드).

*   **`kubeadm`이 처리하지 않는 범위** (사용자가 직접 처리하거나 다른 도구를 사용해야 하는 부분):
    *   **인프라 프로비저닝:** `kubeadm`은 물리 서버, 가상 머신, 클라우드 인스턴스 등의 기본 인프라를 준비하지 않습니다. 사용자는 Kubernetes를 실행할 호스트 환경을 미리 갖추어야 합니다.
    *   **운영체제 설정 및 필수 패키지 설치 (일부 제외):** 컨테이너 런타임, `kubeadm`, `kubelet`, `kubectl` 자체의 설치는 `kubeadm`이 아닌 운영체제의 패키지 매니저를 통해 이루어져야 합니다. 스왑 비활성화, 방화벽 포트 개방 등도 사전 작업입니다.
    *   **네트워크 구성 (CNI 플러그인 설치 제외):** 서버 간 네트워크 연결성 확보, IP 주소 할당, 기본 방화벽 규칙 설정 등은 사용자의 책임입니다. `kubeadm init` 완료 후, Pod 네트워크를 위한 CNI(Container Network Interface) 플러그인 설치는 사용자가 직접 수행해야 합니다.
    *   **클라우드 공급자 통합:** 특정 클라우드 환경(AWS, Azure, GCP 등)과의 깊은 통합 기능(예: 클라우드 로드 밸런서 자동 생성, 클라우드 스토리지 자동 프로비저닝)은 `kubeadm`만으로는 완벽하게 지원되지 않으며, 해당 클라우드 공급자의 CCM(Cloud Controller Manager)을 별도로 설치하고 구성해야 할 수 있습니다.
    *   **영구 스토리지(Persistent Storage) 프로비저닝:** `kubeadm`은 스토리지를 직접 프로비저닝하지 않습니다. 사용자는 필요에 따라 스토리지 클래스(StorageClass) 및 영구 볼륨(PersistentVolume)을 구성해야 합니다.
    *   **고급 운영 도구:** 로깅(logging), 모니터링(monitoring), 알림(alerting) 시스템 등의 운영 도구는 `kubeadm`의 설치 범위에 포함되지 않으며, Prometheus, Grafana, EFK/ELK 스택 등 별도의 솔루션을 구축해야 합니다.
    *   **보안 강화:** `kubeadm`은 기본적인 보안 설정을 제공하지만, 운영 환경의 엄격한 보안 요구사항을 충족하기 위해서는 네트워크 정책(NetworkPolicy), PodSecurityPolicy(또는 후속 기능), 감사 로깅(audit logging) 등 추가적인 보안 강화 조치가 필요합니다.
    *   **애플리케이션 배포 및 관리:** `kubeadm`은 클러스터 자체의 설정에 집중하며, 애플리케이션의 배포나 관리는 `kubectl`, Helm 등의 도구를 통해 이루어집니다.

## 3. `kubeadm` 클러스터의 기본 아키텍처

`kubeadm`으로 생성된 클러스터는 표준 Kubernetes 아키텍처를 따릅니다. 주요 구성 요소는 다음과 같습니다.

*   **컨트롤 플레인 노드 (Control Plane Node / Master Node):**
    *   클러스터의 "뇌" 역할을 하며, 클러스터 전체를 관리하고 제어하는 핵심 구성 요소들을 실행합니다.
        *   **API 서버 (kube-apiserver):** Kubernetes API의 프론트엔드입니다. 모든 관리 명령 및 통신은 API 서버를 통해 이루어집니다.
        *   **etcd:** 모든 클러스터 데이터(상태, 설정 등)를 저장하는 일관성 있고 고가용성을 제공하는 키-값 저장소입니다. (단일 컨트롤 플레인 구성 시 API 서버와 함께 실행되거나, 외부 클러스터로 구성 가능)
        *   **스케줄러 (kube-scheduler):** 새로 생성된 파드(Pod)를 어떤 노드에 할당할지 결정합니다. 리소스 요구사항, 정책, 노드 상태 등을 고려합니다.
        *   **컨트롤러 매니저 (kube-controller-manager):** 다양한 컨트롤러(예: 노드 컨트롤러, 복제 컨트롤러, 엔드포인트 컨트롤러)를 실행하여 클러스터 상태를 원하는 상태로 유지합니다.
    *   클러스터 상태 관리, 워크로드 스케줄링, API 요청 처리 등을 담당합니다.
    *   고가용성(HA)을 위해 여러 컨트롤 플레인 노드를 구성할 수 있습니다. 이 가이드에서는 주로 단일 컨트롤 플레인 노드 설정을 다루지만, `kubeadm`은 HA 구성도 지원합니다.

*   **워커 노드 (Worker Node):**
    *   실제 사용자 애플리케이션 컨테이너들이 파드(Pod) 형태로 배포되고 실행되는 노드입니다.
    *   주요 구성 요소:
        *   **`kubelet`:** 각 노드에서 실행되는 에이전트입니다. 컨트롤 플레인의 API 서버와 통신하며, 해당 노드에서 파드가 정상적으로 실행되도록 관리합니다. 컨테이너 런타임에게 컨테이너 생명주기 관리를 지시합니다.
        *   **`kube-proxy`:** 각 노드에서 실행되는 네트워크 프록시입니다. Kubernetes 서비스(Service) 개념을 구현하여 파드들 간의 네트워크 통신 및 외부로의 서비스 노출을 가능하게 합니다. IPtables 규칙 등을 관리합니다.
        *   **컨테이너 런타임 (Container Runtime):** 컨테이너를 실제로 실행하는 소프트웨어입니다. Docker, containerd, CRI-O 등이 있으며, Kubernetes는 CRI(Container Runtime Interface)를 통해 이들과 상호작용합니다.

## 4. 사전 준비 사항

클러스터 설정을 시작하기 전에 다음 사항들을 준비하고 확인해야 합니다. (모든 명령어는 필요시 `sudo`를 사용하여 실행합니다.)

### 4.1. 호환되는 OS (Compatible OS)
`kubeadm`은 다양한 Linux 배포판을 지원합니다. 주요 지원 대상은 다음과 같습니다:
*   **Debian 기반 배포판:**
    *   Ubuntu 20.04 (LTS), Ubuntu 22.04 (LTS) 이상
    *   Debian 10 (Buster), Debian 11 (Bullseye) 이상
*   **RHEL (Red Hat Enterprise Linux) 기반 배포판:**
    *   CentOS Stream 8, CentOS Stream 9
    *   RHEL 7.x, RHEL 8.x, RHEL 9.x
    *   Rocky Linux, AlmaLinux 등의 RHEL 클론 배포판
*   **기타:**
    *   SLES (SUSE Linux Enterprise Server) 15 이상
*   **참고:** `kubeadm` 및 Kubernetes 버전별로 공식적으로 지원하는 OS 버전이 달라질 수 있습니다. 항상 설치하려는 Kubernetes 버전의 공식 릴리스 노트 및 `kubeadm` 문서를 참조하여 OS 호환성을 확인하는 것이 중요합니다.

### 4.2. 하드웨어 요구 사항 (Hardware Requirements)
최소 요구 사항이며, 프로덕션 환경에서는 더 높은 사양을 권장합니다.
*   **컨트롤 플레인 노드 (Control Plane Node):**
    *   **CPU:** 최소 2 코어 이상
    *   **메모리(RAM):** 최소 2 GB RAM 이상 (안정적인 운영 및 대규모 클러스터의 경우 4GB 이상 강력 권장)
*   **워커 노드 (Worker Node):**
    *   **CPU:** 최소 1 코어 이상 (프로덕션 또는 리소스 집약적 워크로드의 경우 2 코어 이상 권장)
    *   **메모리(RAM):** 최소 2 GB RAM 이상 (실행될 애플리케이션 파드의 메모리 요구 사항에 따라 충분한 용량 확보 필요)
*   **디스크 공간:**
    *   컨트롤 플레인 노드: `/var/lib/etcd` (etcd 데이터 저장) 및 `/var/lib/kubelet` (kubelet 작업 공간, 이미지 저장 등)을 위해 최소 10-20GB의 여유 공간을 권장합니다. 로그 및 이미지 크기에 따라 더 많은 공간이 필요할 수 있습니다.
    *   워커 노드: `/var/lib/kubelet` 및 컨테이너 이미지 저장을 위해 충분한 디스크 공간이 필요합니다 (최소 10-20GB 권장).
*   **네트워크 인터페이스:**
    *   모든 노드는 서로 통신할 수 있는 네트워크 인터페이스가 필요합니다 (일반적으로 내부망).
    *   클러스터 구성 요소 및 이미지 다운로드를 위해 인터넷 연결이 가능해야 합니다 (또는 오프라인 환경을 위한 별도 준비 필요).

### 4.3. 필수 소프트웨어 및 설정 (Required Software and Settings)

*   **고유 식별자 확인:** 각 노드는 다음 값들이 고유해야 합니다.
    *   **호스트 이름 (Hostname):** `hostname` 명령으로 확인. 각 노드마다 달라야 합니다.
    *   **MAC 주소:** 네트워크 인터페이스의 MAC 주소. `ip link` 또는 `ifconfig` 명령으로 확인.
    *   **`product_uuid`:** 시스템의 고유 ID. `sudo cat /sys/class/dmi/id/product_uuid` 명령으로 확인할 수 있습니다. 가상 머신의 경우 복제 시 이 값이 동일할 수 있으므로, 필요시 VM 설정에서 수정해야 합니다.
*   **Swap 비활성화:** Kubernetes의 `kubelet`은 스왑(Swap) 메모리를 지원하지 않습니다. 따라서 모든 노드에서 스왑을 비활성화해야 합니다.
    *   임시 비활성화 (재부팅 시 다시 활성화될 수 있음):
        ```bash
        sudo swapoff -a
        ```
    *   영구 비활성화: `/etc/fstab` 파일에서 스왑 관련 라인을 찾아 주석 처리(#)하거나 삭제합니다.
        ```bash
        # 예시: /etc/fstab 파일 수정 (주의해서 실행)
        # sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
        ```
*   **방화벽 설정 (Port Configuration):** 클러스터 구성 요소들이 서로 통신할 수 있도록 특정 포트들이 방화벽에서 열려 있어야 합니다.
    *   **컨트롤 플레인 노드에서 열어야 할 주요 포트:**
        *   `kube-apiserver`: 6443/TCP (모든 노드 및 외부 접근)
        *   `etcd` 서버: 2379-2380/TCP (컨트롤 플레인 노드 간 통신)
        *   `kube-scheduler`: 10259/TCP (로컬호스트 전용, 이전 버전에서는 10251)
        *   `kube-controller-manager`: 10257/TCP (로컬호스트 전용, 이전 버전에서는 10252)
    *   **워커 노드에서 열어야 할 주요 포트:**
        *   `kubelet` API: 10250/TCP (컨트롤 플레인에서 접근)
        *   `NodePort` 서비스: 30000-32767/TCP (기본값, 외부에서 접근)
    *   CNI 플러그인에 따라 추가 포트(예: Calico의 경우 179/TCP - BGP, Flannel의 경우 8472/UDP - VXLAN)가 필요할 수 있습니다.
    *   **참고:** 필요한 포트의 전체 목록은 [Kubernetes 공식 문서 - Ports and Protocols](https://kubernetes.io/docs/reference/networking/ports-and-protocols/)를 참조하십시오.
    *   `firewalld`, `ufw`, `iptables` 등 시스템의 방화벽 설정을 확인하고 필요한 포트를 개방합니다. (예: `sudo firewall-cmd --permanent --add-port=6443/tcp && sudo firewall-cmd --reload`)
*   **커널 모듈 및 `sysctl` 네트워크 설정:** 컨테이너화된 환경에서 네트워킹이 올바르게 작동하도록 특정 커널 모듈을 로드하고 `sysctl` 파라미터를 설정해야 합니다.
    *   `overlay` 및 `br_netfilter` 모듈 로드:
        ```bash
        cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
        overlay
        br_netfilter
        EOF
        sudo modprobe overlay
        sudo modprobe br_netfilter
        # 확인: lsmod | grep -e overlay -e br_netfilter
        ```
    *   IP 포워딩 및 브리지 네트워크 설정 (`iptables`가 브리지된 트래픽을 볼 수 있도록):
        ```bash
        cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                 = 1
        EOF
        # 변경사항 즉시 적용
        sudo sysctl --system
        ```
        이 설정은 재부팅 후에도 유지됩니다.

### 4.4. 컨테이너 런타임 설치 (Container Runtime Installation)
Kubernetes는 파드 내의 컨테이너를 실행하기 위해 CRI(Container Runtime Interface)를 준수하는 컨테이너 런타임이 필요합니다. Kubernetes 1.24 버전부터 `dockershim`이 Kubernetes 프로젝트에서 제거되었으므로, CRI 호환 런타임을 직접 설치하고 구성해야 합니다.

*   **`containerd` (권장):**
    *   `containerd`는 CNCF 졸업 프로젝트이며, 경량성과 안정성으로 인해 널리 사용되는 컨테이너 런타임입니다.
    *   **설치:** OS 배포판의 공식 패키지 매니저를 사용하거나, [containerd 공식 GitHub 릴리스](https://github.com/containerd/containerd/releases) 페이지에서 직접 바이너리를 다운로드하여 설치할 수 있습니다.
        ```bash
        # (Debian/Ubuntu 예시)
        # sudo apt-get update
        # sudo apt-get install -y containerd
        ```
    *   **구성:** 설치 후, `containerd`의 기본 설정을 생성하고 중요한 옵션을 수정합니다.
        ```bash
        sudo mkdir -p /etc/containerd
        sudo containerd config default | sudo tee /etc/containerd/config.toml
        ```
        `config.toml` 파일에서 `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]` 섹션의 `SystemdCgroup` 값을 `true`로 변경합니다. 이는 `kubelet`과 `containerd`가 동일한 cgroup 드라이버를 사용하도록 보장하여 시스템 안정성을 높입니다.
        ```bash
        sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        ```
    *   필요시 HTTP 프록시 설정을 `/etc/systemd/system/containerd.service.d/http-proxy.conf` 와 같은 파일에 추가합니다.
    *   `containerd` 서비스를 재시작하고 시스템 부팅 시 자동으로 시작되도록 활성화합니다.
        ```bash
        sudo systemctl restart containerd
        sudo systemctl enable containerd
        ```
*   **Docker Engine (with `cri-dockerd`):**
    *   Docker Engine을 컨테이너 런타임으로 계속 사용하려면, CRI 호환성을 제공하는 어댑터인 `cri-dockerd`를 별도로 설치해야 합니다.
    *   먼저 Docker Engine을 설치합니다. (OS별 공식 Docker 설치 문서 참조)
    *   그 다음, [cri-dockerd GitHub 릴리스](https://github.com/Mirantis/cri-dockerd/releases)에서 `cri-dockerd` 바이너리를 다운로드하고, systemd 서비스로 등록하여 실행합니다.
    *   `kubeadm init` 또는 `kubeadm join` 실행 시 `--cri-socket unix:///var/run/cri-dockerd.sock` (또는 `cri-dockerd`가 사용하는 소켓 경로) 옵션을 명시해야 합니다.
*   **기타 CRI 호환 런타임:** CRI-O 등 다른 CRI 호환 런타임도 사용할 수 있습니다. 각 런타임의 공식 설치 및 구성 가이드를 따르십시오.

### 4.5. `kubelet`, `kubeadm`, `kubectl` 설치
이 세 가지 도구는 모든 노드(컨트롤 플레인 및 워커 노드)에 설치되어야 합니다.
*   `kubelet`: 각 노드에서 실행되며 파드 및 컨테이너 생명주기를 관리하는 에이전트입니다.
*   `kubeadm`: 클러스터 부트스트랩을 위한 명령줄 도구입니다.
*   `kubectl`: Kubernetes 클러스터와 상호작용하기 위한 명령줄 인터페이스입니다.

설치 방법은 OS 배포판에 따라 다릅니다. Kubernetes는 공식적으로 APT (Debian/Ubuntu) 및 YUM (CentOS/RHEL) 리포지토리를 제공합니다.

*   **Debian/Ubuntu 예시 (예: Kubernetes v1.28):**
    ```bash
    sudo apt-get update
    # HTTPS를 통한 리포지토리 사용 및 CA 인증서, curl 설치
    sudo apt-get install -y apt-transport-https ca-certificates curl gpg

    # Kubernetes 패키지 리포지토리의 공개 서명 키 다운로드
    # (2023년 12월 이후 pkgs.k8s.io가 공식 리포지토리임)
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # Kubernetes APT 리포지토리 추가
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    # 패키지 버전 고정 (자동 업그레이드 방지)
    sudo apt-mark hold kubelet kubeadm kubectl
    ```
*   **CentOS/RHEL/Rocky Linux 예시 (예: Kubernetes v1.28):**
    ```bash
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
    [kubernetes]
    name=Kubernetes
    baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
    enabled=1
    gpgcheck=1
    gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
    # kubelet, kubeadm, kubectl은 특정 버전으로 설치 후 exclude 하는 것이 일반적
    # exclude=kubelet kubeadm kubectl
    EOF

    # SELinux permissive 모드로 설정 (선택 사항, 권장되지는 않지만 문제 발생 시 임시 조치)
    # sudo setenforce 0
    # sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    sudo systemctl enable --now kubelet # kubelet 서비스 시작 및 활성화
    ```
*   **버전 관리:**
    *   설치하려는 특정 Kubernetes 버전에 맞춰 `v1.28`과 같은 버전 문자열을 해당 버전으로 변경해야 합니다.
    *   `apt-mark hold` (Debian/Ubuntu) 또는 `yum versionlock` (CentOS/RHEL) 또는 `exclude` 지시문 (YUM 리포지토리 설정)을 사용하여 설치된 Kubernetes 패키지(`kubelet`, `kubeadm`, `kubectl`)의 버전이 예기치 않게 자동 업그레이드되지 않도록 고정하는 것이 매우 중요합니다. 이는 클러스터 안정성을 유지하는 데 도움이 됩니다.

이러한 사전 준비 사항들을 꼼꼼히 확인하고 완료하면 `kubeadm`을 사용하여 클러스터를 성공적으로 구축할 준비가 됩니다.

## 5. 컨테이너 런타임 설치 (예: containerd)

(이전 가이드 내용과 중복되므로, 섹션 4.4로 통합되었습니다. 해당 내용을 참조하십시오.)

## 6. kubeadm, kubelet, kubectl 설치

(이전 가이드 내용과 중복되므로, 섹션 4.5로 통합되었습니다. 해당 내용을 참조하십시오.)

## 7. 컨트롤 플레인 노드 초기화

`kubeadm init` 명령어는 Kubernetes 클러스터의 첫 번째 컨트롤 플레인 노드를 초기화하고 설정하는 데 사용됩니다. **이 명령어는 컨트롤 플레인으로 지정된 노드에서만 실행해야 합니다.**

`kubeadm init`이 수행하는 주요 작업은 다음과 같습니다:
*   **사전 검사 (Preflight Checks):** 노드가 Kubernetes를 실행하기에 적합한지 다양한 검사를 수행합니다 (예: OS 호환성, 필수 포트 사용 가능 여부, cgroup 설정 등).
*   **인증서 및 키 생성:** 클러스터 내부 통신에 필요한 TLS 인증서와 키를 생성합니다 (`/etc/kubernetes/pki` 디렉토리에 저장됨).
*   **Kubeconfig 파일 생성:** 컨트롤 플레인 및 관리자가 클러스터와 상호작용하는 데 필요한 `kubeconfig` 파일들(예: `admin.conf`, `kubelet.conf`, `controller-manager.conf`, `scheduler.conf`)을 생성합니다.
*   **컨트롤 플레인 컴포넌트 배포:** API 서버, 스케줄러, 컨트롤러 매니저를 스태틱 파드(static pod) 형태로 `/etc/kubernetes/manifests` 디렉토리에 매니페스트를 생성하여 `kubelet`이 이를 실행하도록 합니다. `etcd`도 기본적으로 스태틱 파드로 실행됩니다 (외부 etcd 사용 시 제외).
*   **클러스터 애드온 설치:** CoreDNS (DNS 서비스)와 `kube-proxy` (네트워크 프록시) 애드온을 설치합니다.
*   **조인 토큰 생성:** 새로운 노드(워커 또는 다른 컨트롤 플레인)가 클러스터에 참여할 때 사용할 부트스트랩 토큰을 생성합니다.

### 7.1. 주요 `kubeadm init` 옵션

`kubeadm init` 명령어는 다양한 옵션을 통해 클러스터 설정을 세밀하게 조정할 수 있습니다. 주요 옵션은 다음과 같습니다:

*   `--apiserver-advertise-address=<ip-address>`:
    *   API 서버가 클러스터의 다른 멤버(워커 노드, 다른 컨트롤 플레인 노드)에게 알릴 IP 주소입니다.
    *   일반적으로 컨트롤 플레인 노드의 기본 네트워크 인터페이스에 할당된 IP 주소를 사용합니다.
    *   이 옵션을 설정하지 않으면, `kubeadm`은 기본 게이트웨이가 설정된 네트워크 인터페이스의 주소를 자동으로 선택하려고 시도합니다. 여러 네트워크 인터페이스가 있는 경우 명시적으로 지정하는 것이 좋습니다.
*   `--pod-network-cidr=<ipv4-cidr>`:
    *   클러스터 내 파드(Pod)들에게 할당될 IP 주소 범위(CIDR 블록)를 지정합니다. 예: `10.244.0.0/16` (Flannel 기본값), `192.168.0.0/16` (Calico 기본값).
    *   이 옵션은 선택한 CNI(Container Network Interface) 플러그인의 요구사항과 일치해야 합니다. CNI 플러그인은 이 CIDR을 사용하여 파드에 IP를 할당하고 파드 간 통신을 설정합니다.
    *   이 값을 지정하면 `kubeadm`은 컨트롤 플레인 컴포넌트(예: `kube-controller-manager`)가 해당 CIDR을 인식하도록 설정하고, `kube-proxy`도 이 네트워크 범위를 올바르게 처리하도록 구성합니다.
*   `--control-plane-endpoint=<dns-or-ip:port>`:
    *   고가용성(HA) 클러스터를 구성할 때 모든 컨트롤 플레인 노드에 대한 안정적인 단일 진입점(엔드포인트)을 지정합니다. 이는 로드 밸런서의 주소와 포트, 또는 공유 가상 IP(VIP) 주소와 포트일 수 있습니다.
    *   단일 컨트롤 플레인 클러스터에서는 이 옵션이 필수는 아니지만, 향후 HA로 확장할 계획이 있다면 미리 설정해 둘 수 있습니다.
    *   이 옵션을 설정하지 않으면, 단일 컨트롤 플레인 클러스터에서는 `--apiserver-advertise-address`로 지정된 IP와 API 서버의 기본 포트(6443)가 엔드포인트로 사용됩니다.
*   `--cri-socket=<path>`:
    *   컨테이너 런타임 인터페이스(CRI) 소켓 파일의 경로를 지정합니다.
    *   `containerd`의 기본 소켓 경로는 `unix:///var/run/containerd/containerd.sock` 입니다.
    *   Docker Engine과 `cri-dockerd`를 함께 사용하는 경우, 소켓 경로는 일반적으로 `unix:///var/run/cri-dockerd.sock` 입니다.
    *   `kubeadm`은 몇 가지 일반적인 경로에서 CRI 소켓을 자동으로 감지하려고 시도하지만, 시스템에 여러 컨테이너 런타임이 설치되어 있거나 비표준 경로를 사용하는 경우 이 옵션을 사용하여 명시적으로 지정해야 합니다.
*   `--upload-certs`:
    *   컨트롤 플레인의 인증서들을 Kubernetes 시크릿(`kubeadm-certs`)에 암호화하여 업로드합니다. 이 기능은 주로 고가용성(HA) 클러스터에서 다른 컨트롤 플레인 노드를 클러스터에 안전하게 조인시키거나, 재해 복구 시 컨트롤 플레인을 재생성할 때 유용합니다.
    *   이 옵션을 사용하면 `--certificate-key`로 지정된 암호화 키가 필요하며, `kubeadm init` 실행 시 해당 키가 출력됩니다. 이 키는 매우 민감하므로 안전하게 보관해야 합니다.
*   `--ignore-preflight-errors=<error1,error2,...>`:
    *   `kubeadm init` 실행 전에 수행되는 일련의 사전 검사(preflight checks)에서 특정 오류들을 무시하도록 설정합니다. 예를 들어, `Swap` (스왑 메모리 사용), `SystemVerification` (커널 버전 등 시스템 요구사항) 등의 오류를 무시할 수 있습니다.
    *   **경고:** 이 옵션은 해당 오류의 원인과 잠재적 영향을 정확히 알고 있으며, 이를 무시해도 클러스터의 안정성 및 기능에 문제가 없다고 확신하는 경우에만 매우 주의해서 사용해야 합니다. 일반적으로 권장되지 않습니다.
*   `--config=<path-to-config-file.yaml>`:
    *   명령줄 플래그 대신 YAML 형식의 설정 파일을 사용하여 `kubeadm init`의 모든 구성을 지정할 수 있습니다.
    *   이 방식은 더 많고 세분화된 설정 옵션을 제어할 수 있게 해주며, 클러스터 구성을 버전 관리 시스템(예: Git)에서 관리하기 용이하게 합니다.
    *   `kubeadm config print init-defaults > kubeadm-config.yaml` 명령을 사용하여 기본 설정 파일 템플릿을 생성한 후, 필요에 맞게 수정하여 사용할 수 있습니다.
    *   YAML 설정 파일 내에서는 `InitConfiguration`, `ClusterConfiguration`, `KubeletConfiguration`, `KubeProxyConfiguration` 등 다양한 종류(Kind)의 설정을 통해 위에서 언급된 명령줄 옵션들을 포함한 거의 모든 `kubeadm` 관련 설정을 지정할 수 있습니다.

### 7.2. `kubeadm init` 실행 예시

(모든 명령어는 루트 권한(`sudo`)으로 실행해야 합니다.)

*   **가장 일반적인 사용 예시 (컨트롤 플레인 노드의 IP와 Pod 네트워크 CIDR 지정):**
    ```bash
    sudo kubeadm init --apiserver-advertise-address=192.168.1.10 --pod-network-cidr=10.244.0.0/16
    ```
    *   `192.168.1.10`은 컨트롤 플레인 노드의 IP 주소로 변경해야 합니다.
    *   `10.244.0.0/16`은 Flannel CNI 플러그인을 사용할 경우의 예시이며, 다른 CNI (예: Calico의 경우 `192.168.0.0/16`)를 사용한다면 해당 CNI의 권장 CIDR로 변경해야 합니다.

*   **`cri-dockerd` 사용 시 CRI 소켓 경로 지정 예시:**
    ```bash
    sudo kubeadm init --apiserver-advertise-address=192.168.1.10 --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/cri-dockerd.sock
    ```

*   **YAML 설정 파일 사용 예시:**
    1.  먼저, 기본 설정 파일 템플릿을 생성합니다:
        ```bash
        kubeadm config print init-defaults > kubeadm-config.yaml
        ```
    2.  생성된 `kubeadm-config.yaml` 파일을 편집하여 필요한 설정들을 수정합니다. 예를 들어:
        *   `localAPIEndpoint.advertiseAddress`: 컨트롤 플레인 노드의 IP 주소 설정
        *   `networking.podSubnet`: 파드 네트워크 CIDR 설정
        *   `criSocket`: 컨테이너 런타임 소켓 경로 (필요시)
        *   `nodeRegistration.kubeletExtraArgs`: `kubelet`에 추가 인자 전달
        ```yaml
        # kubeadm-config.yaml 예시 일부
        apiVersion: kubeadm.k8s.io/v1beta3
        kind: InitConfiguration
        localAPIEndpoint:
          advertiseAddress: 192.168.1.10 # 실제 IP로 변경
          bindPort: 6443
        nodeRegistration:
          criSocket: unix:///var/run/containerd/containerd.sock # 사용 중인 CRI 소켓 경로
          # ... 기타 kubelet 설정
        ---
        apiVersion: kubeadm.k8s.io/v1beta3
        kind: ClusterConfiguration
        kubernetesVersion: v1.28.0 # 원하는 쿠버네티스 버전
        networking:
          podSubnet: 10.244.0.0/16 # CNI에 맞는 CIDR로 변경
          serviceSubnet: 10.96.0.0/12
        # ... 기타 클러스터 설정
        ```
    3.  수정된 설정 파일을 사용하여 `kubeadm init`을 실행합니다:
        ```bash
        sudo kubeadm init --config kubeadm-config.yaml
        ```

### 7.3. 초기화 성공 후 작업

`kubeadm init` 명령이 성공적으로 완료되면, 화면에 몇 가지 중요한 지침과 정보가 출력됩니다. 이 지침을 주의 깊게 따르는 것이 매우 중요합니다.

*   **`kubectl` 사용 설정:**
    *   클러스터를 관리하기 위해 `kubectl` 명령어를 사용하려면 `kubeconfig` 파일이 필요합니다. `kubeadm init`은 컨트롤 플레인 노드의 `/etc/kubernetes/admin.conf` 경로에 관리자용 `kubeconfig` 파일을 생성합니다.
    *   일반 사용자 계정으로 `kubectl`을 사용하려면, 다음 명령을 실행하여 `kubeconfig` 파일을 사용자의 홈 디렉토리로 복사하고 적절한 권한을 설정해야 합니다:
        ```bash
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        ```
    *   또는, 루트 사용자인 경우 환경 변수를 설정하여 직접 사용할 수도 있습니다 (권장되지는 않음):
        ```bash
        export KUBECONFIG=/etc/kubernetes/admin.conf
        ```
*   **클러스터 조인(Join) 명령어 저장:**
    *   출력 메시지에는 워커 노드나 다른 컨트롤 플레인 노드를 현재 클러스터에 추가하는 데 사용될 `kubeadm join` 명령어가 포함되어 있습니다. 이 명령어는 토큰과 CA 인증서 해시 값을 포함하고 있으며, 다음과 유사한 형태입니다:
        ```
        kubeadm join <control-plane-host>:<control-plane-port> --token <token> \
            --discovery-token-ca-cert-hash sha256:<hash>
        ```
    *   이 명령어는 매우 중요하므로, 안전한 곳에 정확히 복사하여 보관해야 합니다.
    *   `kubeadm init`으로 생성된 기본 부트스트랩 토큰은 보안상의 이유로 **24시간 동안만 유효**합니다. 만약 토큰이 만료되거나 분실한 경우, 새로운 토큰을 생성해야 합니다 (자세한 내용은 "워커 노드 추가" 섹션 참조).
*   **Pod 네트워크 애드온(CNI) 설치:**
    *   `kubeadm init`은 Kubernetes 클러스터의 핵심 구성 요소만을 설치하며, 파드 간 통신을 가능하게 하는 네트워크 솔루션(CNI 플러그인)은 설치하지 않습니다.
    *   따라서, `kubeadm init` 완료 후 **반드시 CNI 플러그인을 클러스터에 설치해야 합니다.** CNI 플러그인이 설치되기 전까지는 CoreDNS와 같은 일부 시스템 파드들이 `Pending` 상태로 남아있게 되며, 파드 간 통신이 제대로 이루어지지 않습니다.
    *   CNI 플러그인 설치는 다음 섹션에서 자세히 다룹니다.

이 단계까지 성공적으로 완료하면 Kubernetes 컨트롤 플레인이 준비된 상태이며, 다음 단계는 CNI 플러그인을 설치하고 워커 노드를 클러스터에 참여시키는 것입니다.

## 8. Pod 네트워크 애드온(CNI 플러그인) 설치

### 8.1. CNI 플러그인 설치의 필요성
Kubernetes 클러스터에서 파드(Pod)들이 서로 통신하고, 외부에서 서비스에 접근하기 위해서는 파드 네트워크가 올바르게 구성되어야 합니다. CNI(Container Network Interface) 플러그인은 이러한 파드 네트워크를 구현하는 역할을 담당합니다.

`kubeadm`은 특정 CNI 플러그인을 기본으로 설치하지 않습니다. 이는 사용자에게 다양한 CNI 솔루션 중에서 환경 및 요구사항에 맞는 것을 선택할 유연성을 제공하기 위함입니다. 따라서 `kubeadm init`으로 컨트롤 플레인 초기화 후, **사용자는 반드시 CNI 플러그인을 직접 선택하고 설치해야 합니다.**

CNI 플러그인이 설치되지 않으면 다음과 같은 문제가 발생합니다:
*   파드들은 IP 주소를 할당받지 못하거나, 할당받더라도 다른 파드와 통신할 수 없습니다.
*   CoreDNS와 같은 클러스터의 핵심 DNS 서비스 파드들이 정상적으로 실행되지 못하고 `Pending` 상태에 머무르게 됩니다. 이는 클러스터 내 서비스 디스커버리가 작동하지 않음을 의미합니다.
*   `kubectl get nodes` 명령 실행 시, 노드들이 CNI가 준비되지 않았다는 이유로 `NotReady` 상태로 표시될 수 있습니다. CNI 플러그인이 성공적으로 설치되고 각 노드에서 관련 컴포넌트(보통 DaemonSet으로 배포됨)가 실행되면 노드 상태가 `Ready`로 변경됩니다.

### 8.2. CNI 플러그인 선택 시 고려사항 (간략히)
다양한 CNI 플러그인이 존재하며, 각각의 특징과 기능이 다릅니다. 대표적인 CNI 플러그인으로는 Calico, Flannel, Weave Net, Cilium 등이 있습니다. 선택 시 고려할 수 있는 몇 가지 요소는 다음과 같습니다:
*   **네트워크 정책(Network Policy) 지원 여부:** Calico, Cilium, Weave Net 등은 네트워크 정책을 지원하여 파드 간 트래픽을 세밀하게 제어할 수 있습니다. Flannel은 기본적으로 네트워크 정책을 지원하지 않지만, Canal과 같이 Calico와 함께 사용하여 이를 보완할 수 있습니다.
*   **네트워킹 모델:** 오버레이 네트워크(VXLAN 등) 방식, 네이티브 라우팅(BGP 등) 방식 등 구현 방식에 따라 성능 및 복잡성이 다를 수 있습니다.
*   **성능 요구사항:** 고성능 네트워크 처리가 필요한 경우, 커널 수준의 네트워킹(eBPF 활용 등 - 예: Cilium)을 제공하는 CNI를 고려할 수 있습니다.
*   **설치 및 운영의 용이성:** 일부 CNI는 설치가 매우 간단하지만, 다른 CNI는 더 많은 구성 옵션과 전문 지식을 요구할 수 있습니다.
*   **부가 기능:** 암호화, 고급 관찰 가능성(observability) 도구 통합 등 CNI 플러그인별로 제공하는 부가 기능이 다릅니다.

**가장 중요한 점은, 선택한 CNI 플러그인의 공식 문서에서 요구하는 `--pod-network-cidr` 값을 `kubeadm init` 명령어 실행 시 정확하게 사용했는지 확인하는 것입니다.** 이 값이 일치하지 않으면 CNI 플러그인이 올바르게 작동하지 않거나 IP 주소 충돌이 발생할 수 있습니다.

### 8.3. 일반적인 CNI 플러그인 설치 방법
대부분의 CNI 플러그인은 컨트롤 플레인 노드에서 `kubectl apply -f <manifest_url_or_file>` 명령을 사용하여 YAML 매니페스트 파일을 클러스터에 적용하는 방식으로 설치됩니다. 이 매니페스트에는 CNI 데몬셋(DaemonSet), RBAC 설정, ConfigMap 등 필요한 모든 Kubernetes 리소스가 포함되어 있습니다.

일반 사용자로 `kubectl`을 사용하도록 설정했다면 (즉, `$HOME/.kube/config` 파일을 사용), 해당 사용자로 명령을 실행합니다. 루트로만 `kubectl`을 사용할 수 있다면 `sudo`를 사용해야 할 수 있습니다.

### 8.4. 대표적인 CNI 플러그인 설치 예시

아래는 몇 가지 대표적인 CNI 플러그인의 설치 예시입니다. **주의: 여기에 제시된 URL과 버전은 예시이며, 실제 설치 시에는 반드시 각 CNI 플러그인의 공식 문서에서 최신 안정 버전의 매니페스트 URL과 설치 지침을 확인해야 합니다.**

*   **Calico:**
    *   **소개:** Calico는 고성능 네트워킹과 강력한 네트워크 정책 기능을 제공하는 CNI 플러그인입니다. BGP를 사용하여 네이티브 라우팅을 지원하거나, VXLAN 또는 IPIP 오버레이 네트워크를 사용할 수 있습니다.
    *   **설치 명령어 (예시):**
        ```bash
        # 컨트롤 플레인 노드에서 실행
        # Calico 공식 문서에서 최신 버전에 맞는 명령어를 확인하세요.
        # 예시 (버전 및 URL은 변경될 수 있습니다):
        kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
        ```
    *   **참고:** `kubeadm init` 시 `--pod-network-cidr`를 Calico의 기본값(일반적으로 `192.168.0.0/16`) 또는 Calico 매니페스트에서 지정한 값과 일치하도록 설정했어야 합니다.

*   **Flannel:**
    *   **소개:** Flannel은 간단하고 설치가 쉬운 오버레이 네트워크를 제공하는 CNI 플러그인입니다. VXLAN을 기본 백엔드로 사용합니다.
    *   **설치 명령어 (예시):**
        ```bash
        # 컨트롤 플레인 노드에서 실행
        # Flannel 공식 문서/GitHub에서 최신 버전에 맞는 명령어를 확인하세요.
        # 예시 (버전 및 URL은 변경될 수 있습니다):
        kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
        ```
    *   **참고:** `kubeadm init` 시 `--pod-network-cidr`를 Flannel의 기본값(일반적으로 `10.244.0.0/16`)으로 설정했어야 합니다.

*   **Weave Net (선택적 예시):**
    *   **소개:** Weave Net은 설치가 용이하며, 추가 설정 없이 네트워크 정책 및 암호화를 기본적으로 지원하는 CNI 플러그인입니다.
    *   **설치 명령어 (예시):**
        ```bash
        # 컨트롤 플레인 노드에서 실행
        # Weave Net 공식 문서에서 최신 버전에 맞는 명령어를 확인하세요.
        # 예시 (Kubernetes 버전에 맞는 매니페스트를 동적으로 가져옴):
        # kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
        ```
    *   **참고:** Weave Net은 일반적으로 별도의 `--pod-network-cidr` 설정을 `kubeadm init` 시 요구하지 않을 수 있지만, 공식 문서를 확인하는 것이 좋습니다.

**주의사항:** 각 CNI 플러그인은 자체적인 구성 옵션, 사전 요구사항 (예: 특정 커널 모듈, 방화벽 규칙) 또는 권장 `sysctl` 설정이 있을 수 있습니다. 따라서, 어떤 CNI 플러그인을 선택하든 **반드시 해당 플러그인의 공식 설치 문서 및 구성 가이드를 주의 깊게 참조해야 합니다.** 위에 제시된 명령어와 URL은 설명 및 예시 목적이며, 실제 운영 환경에서는 항상 최신 안정 버전의 매니페스트와 지침을 따라야 합니다.

### 8.5. CNI 설치 후 확인 사항
CNI 플러그인 매니페스트를 적용한 후, 관련 컴포넌트들이 클러스터에 배포되고 실행되기까지 약간의 시간이 소요될 수 있습니다. 다음 명령들을 컨트롤 플레인 노드에서 실행하여 설치 상태를 확인할 수 있습니다:

*   **CNI 관련 파드 상태 확인:**
    ```bash
    kubectl get pods -n kube-system
    ```
    출력에서 선택한 CNI 플러그인 관련 파드들(예: `calico-node-xxxxx`, `calico-kube-controllers-xxxxx`, `kube-flannel-ds-xxxxx` 등)이 `Running` 상태인지 확인합니다. 모든 노드에 CNI 에이전트(보통 DaemonSet으로 배포됨)가 성공적으로 실행되어야 합니다.

*   **CoreDNS 파드 상태 확인:**
    CNI가 정상적으로 작동하면, 이전에 `Pending` 상태였던 CoreDNS 파드들이 `Running` 상태로 변경되어야 합니다.
    ```bash
    kubectl get pods -n kube-system -l k8s-app=kube-dns
    ```

*   **노드 상태 확인:**
    모든 노드가 `Ready` 상태로 변경되었는지 확인합니다.
    ```bash
    kubectl get nodes
    ```
    이전에 CNI가 없어 `NotReady`였던 노드들이 CNI 설치 후 `Ready` 상태가 되어야 합니다.

*   **(선택 사항) 파드 간 통신 테스트:**
    간단한 테스트용 파드를 여러 개 배포하여 서로 다른 노드에 스케줄링되도록 한 후, 파드 내부에서 다른 파드의 IP로 `ping` 또는 `curl`과 같은 명령을 실행하여 네트워크 통신이 정상적으로 이루어지는지 확인할 수 있습니다.

CNI 플러그인이 성공적으로 설치되고 모든 노드와 핵심 서비스(CoreDNS 등)가 정상 작동하면, Kubernetes 클러스터는 기본적인 네트워크 기능을 갖추게 됩니다.

## 9. 워커 노드 추가

### 9.1. 워커 노드 추가 개요
워커 노드는 실제 애플리케이션 파드가 실행되는 클러스터의 일꾼입니다. 컨트롤 플레인 노드에서 `kubeadm init` 명령이 성공적으로 완료되면, 워커 노드를 클러스터에 참여시킬 수 있는 `kubeadm join` 명령어가 출력됩니다.

**중요:** 워커 노드로 추가하려는 모든 머신은 컨트롤 플레인 노드와 마찬가지로 "4. 사전 준비 사항" 섹션에 명시된 요구 사항들(호환 OS, 하드웨어, 필수 소프트웨어 및 설정, 컨테이너 런타임 설치, `kubelet`/`kubeadm`/`kubectl` 설치, 스왑 비활성화, 네트워크 설정 등)을 동일하게 충족해야 합니다. 특히, 컨테이너 런타임이 올바르게 설치 및 실행 중이어야 하며, `kubelet`이 설치되어 있어야 합니다.

### 9.2. `kubeadm join` 명령어 사용법

`kubeadm join` 명령어는 워커 노드를 기존 Kubernetes 클러스터에 참여시키는 역할을 합니다. 이 명령어는 워커 노드가 될 머신에서 루트 권한(`sudo`)으로 실행해야 합니다.

*   **명령어 형식:**
    컨트롤 플레인 노드에서 `kubeadm init` 실행 후 출력된 명령어는 다음과 같은 형식을 가집니다.
    ```
    kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
    ```
*   **파라미터 설명:**
    *   `<control-plane-host>:<control-plane-port>`: 컨트롤 플레인 노드의 API 서버 주소와 포트입니다. 이 값은 `kubeadm init` 실행 시 사용된 `--control-plane-endpoint` 또는 `--apiserver-advertise-address` 옵션 값과 API 서버 포트(기본값 6443)로 구성됩니다.
    *   `--token <token>`: 부트스트랩 토큰(bootstrap token)입니다. 워커 노드가 클러스터에 참여할 때 인증을 위해 사용됩니다. 이 토큰은 민감한 정보이므로 안전하게 관리해야 합니다.
    *   `--discovery-token-ca-cert-hash sha256:<hash>`: 컨트롤 플레인 노드의 CA(Certificate Authority) 인증서 공개 키에 대한 SHA256 해시 값입니다. 워커 노드는 이 해시 값을 사용하여 컨트롤 플레인 노드를 신뢰하고 안전하게 통신할 수 있습니다. "Token-based discovery with CA pinning" 방식에 사용됩니다.

*   **실행 예시:**
    ```bash
    sudo kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    ```
    (위 값들은 예시이므로 실제 출력된 값으로 대체해야 합니다.)

*   **`--cri-socket` 옵션 (필요시):**
    워커 노드에 설치된 컨테이너 런타임의 CRI 소켓 경로가 기본값(`unix:///var/run/containerd/containerd.sock` 또는 `unix:///run/containerd/containerd.sock` 등)과 다르거나, Docker Engine과 `cri-dockerd`를 사용하는 경우에는 `kubeadm init` 때와 마찬가지로 `--cri-socket` 옵션을 `kubeadm join` 명령어에 명시적으로 추가해야 합니다.
    ```bash
    sudo kubeadm join 192.168.1.10:6443 --token <token> \
        --discovery-token-ca-cert-hash sha256:<hash> \
        --cri-socket unix:///var/run/cri-dockerd.sock
    ```

### 9.3. 조인 토큰(Bootstrap Token) 관리

`kubeadm join`에 사용되는 부트스트랩 토큰은 보안을 위해 유효 기간이 있습니다.

*   **토큰의 유효 기간:** `kubeadm init`으로 생성된 기본 부트스트랩 토큰은 **24시간** 동안 유효합니다.
*   **새로운 조인 토큰 생성:**
    *   기존 토큰이 만료되었거나, 분실했거나, 또는 추가적인 워커 노드를 나중에 참여시키고 싶을 경우, 컨트롤 플레인 노드에서 새로운 토큰을 생성할 수 있습니다.
        ```bash
        # 컨트롤 플레인 노드에서 실행
        kubeadm token create
        ```
        이 명령어는 새로운 토큰 문자열만 출력합니다. `kubeadm join`을 위해서는 `--discovery-token-ca-cert-hash` 값도 필요합니다.
*   **CA 인증서 해시 값 가져오기:**
    *   컨트롤 플레인 노드에서 다음 명령어를 사용하여 CA 인증서의 공개 키 해시 값을 조회할 수 있습니다:
        ```bash
        openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
            openssl dgst -sha256 -hex | sed 's/^.* //'
        ```
*   **새로운 `kubeadm join` 명령어 전체 생성 (권장):**
    *   새로운 토큰과 CA 인증서 해시 값을 수동으로 조합하는 것보다, 다음 명령어를 컨트롤 플레인 노드에서 실행하면 완전한 `kubeadm join` 명령어를 바로 생성하여 출력해 주므로 매우 편리합니다.
        ```bash
        # 컨트롤 플레인 노드에서 실행
        sudo kubeadm token create --print-join-command
        ```
*   **기존 토큰 목록 확인 및 삭제:**
    *   현재 클러스터에 설정된 유효한 토큰 목록을 확인하려면 컨트롤 플레인 노드에서 다음 명령을 실행합니다:
        ```bash
        # 컨트롤 플레인 노드에서 실행
        sudo kubeadm token list
        ```
    *   더 이상 사용하지 않거나 보안상 문제가 될 수 있는 토큰은 삭제하는 것이 좋습니다. 토큰 ID를 사용하여 특정 토큰을 삭제할 수 있습니다:
        ```bash
        # 컨트롤 플레인 노드에서 실행 (예: 토큰 ID가 abcdef 인 경우)
        sudo kubeadm token delete abcdef
        ```

### 9.4. 워커 노드 추가 확인
워커 노드에서 `kubeadm join` 명령이 성공적으로 실행되면, 해당 노드는 클러스터에 등록되고 `kubelet`이 필요한 작업을 수행하기 시작합니다.

컨트롤 플레인 노드에서 `kubectl get nodes` 명령을 실행하여 새로 추가된 워커 노드가 클러스터에 정상적으로 참여했고 `Ready` 상태인지 확인할 수 있습니다.
```bash
# 컨트롤 플레인 노드에서 실행
kubectl get nodes -o wide
```
출력 결과에서 새로 추가된 노드가 목록에 나타나고, 잠시 후 `STATUS`가 `Ready`로 변경되어야 합니다. 만약 노드가 `NotReady` 상태로 오랫동안 머무른다면, 해당 워커 노드의 네트워크 설정(CNI 관련), `kubelet` 로그 (`sudo journalctl -u kubelet -f`), 또는 컨테이너 런타임 로그를 확인하여 문제를 해결해야 할 수 있습니다.

## 10. 클러스터 상태 확인

컨트롤 플레인 노드에서 `kubectl`을 사용하여 클러스터 상태를 확인합니다.

```bash
# 노드 목록 및 상태 확인
kubectl get nodes

# 시스템 파드 상태 확인
kubectl get pods -A
```

모든 노드가 `Ready` 상태이고, 시스템 파드들이 정상적으로 실행 중이면 클러스터 설정이 완료된 것입니다.

## 11. (선택 사항) kubectl 자동 완성 설정

편의를 위해 kubectl 자동 완성을 설정할 수 있습니다.

```bash
# bash 쉘의 경우
echo 'source <(kubectl completion bash)' >>~/.bashrc
source ~/.bashrc

# zsh 쉘의 경우
echo 'source <(kubectl completion zsh)' >>~/.zshrc
source ~/.zshrc
```

## 12. 클러스터 업그레이드

### 12.1. 업그레이드 개요 및 중요성
Kubernetes는 새로운 기능 추가, 버그 수정, 보안 취약점 해결을 위해 주기적으로 새 버전이 릴리스됩니다. 따라서 운영 중인 클러스터를 최신 상태로 유지하고 안정적으로 운영하기 위해서는 주기적인 업그레이드가 필수적입니다. `kubeadm`은 클러스터 업그레이드 과정을 지원하는 도구를 제공합니다.

**매우 중요: 업그레이드 전 주의사항**
*   **백업(Backup):** 업그레이드 과정에서 예기치 않은 문제가 발생할 수 있으므로, **반드시 업그레이드 전에 etcd 데이터를 포함한 클러스터의 중요 데이터를 백업해야 합니다.** `etcd`는 모든 클러스터 상태를 저장하므로 가장 중요합니다.
    *   `etcd` 스냅샷 생성 방법: 만약 `etcd`가 컨트롤 플레인 노드의 스태틱 파드로 실행 중이라면 (기본값), 다음 명령을 사용하여 스냅샷을 생성할 수 있습니다 (etcdctl v3 사용 기준):
        ```bash
        # ETCDCTL_API=3 etcdctl --endpoints=https://[127.0.0.1]:2379 \
        # --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        # --cert=/etc/kubernetes/pki/etcd/server.crt \
        # --key=/etc/kubernetes/pki/etcd/server.key \
        # snapshot save snapshotdb.db
        ```
        자세한 백업 및 복원 절차는 [Kubernetes 공식 etcd 백업 문서](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)를 참조하십시오.
*   **릴리스 노트 확인:** 업그레이드하려는 Kubernetes 버전의 공식 릴리스 노트와 변경 사항(Changelog)을 반드시 숙지해야 합니다. 특히, 중요한 변경 사항(breaking changes), 사용 중단(deprecated)되는 API, 또는 업그레이드 전후로 필요한 특정 작업들이 명시되어 있을 수 있습니다.
*   **버전 스큐 정책 (Version Skew Policy):** Kubernetes는 컴포넌트 간 버전 차이를 제한하는 정책을 가지고 있습니다. 일반적으로 컨트롤 플레인 컴포넌트(API 서버, 컨트롤러 매니저, 스케줄러)는 한 번에 하나의 마이너 버전만 업그레이드하는 것이 권장됩니다. 예를 들어, 1.26에서 1.28로 직접 업그레이드하는 대신, 1.26 -> 1.27 -> 1.28 순서로 순차적인 업그레이드를 수행해야 합니다. `kubelet`은 API 서버보다 높은 버전일 수 없으며, 최대 두 단계 낮은 마이너 버전까지 호환될 수 있습니다 (예: API 서버가 1.28이면, kubelet은 1.28, 1.27, 1.26 가능). 자세한 내용은 [Kubernetes 공식 버전 스큐 정책 문서](https://kubernetes.io/releases/version-skew-policy/)를 참조하십시오.

### 12.2. 업그레이드 절차 (컨트롤 플레인 노드부터 시작)

클러스터 업그레이드는 항상 컨트롤 플레인 노드부터 시작해야 합니다.

#### 12.2.1. 1단계: 업그레이드할 버전 결정
*   **현재 클러스터 버전 확인:**
    ```bash
    kubectl version --short
    kubeadm version
    ```
*   **업그레이드 가능한 `kubeadm` 버전 확인:**
    *   Debian/Ubuntu:
        ```bash
        sudo apt update
        sudo apt-cache madison kubeadm
        ```
    *   CentOS/RHEL:
        ```bash
        sudo yum list kubeadm --showduplicates | sort -r
        ```
*   대상 버전의 Kubernetes 릴리스 노트를 꼼꼼히 읽고 주요 변경 사항 및 주의 사항을 확인합니다.

#### 12.2.2. 2단계: 첫 번째 컨트롤 플레인 노드 업그레이드
*   **업그레이드 계획 확인:**
    `kubeadm upgrade plan` 명령은 현재 클러스터 상태를 분석하고 업그레이드할 수 있는 컴포넌트와 대상 버전을 보여줍니다. 이 명령은 실제 업그레이드를 수행하지 않으므로 안전하게 실행할 수 있습니다.
    ```bash
    # 컨트롤 플레인 노드에서 실행
    sudo kubeadm upgrade plan
    ```
*   **대상 버전으로 `kubeadm` 패키지 업그레이드:**
    업그레이드하려는 Kubernetes 버전에 맞는 `kubeadm` 패키지를 설치합니다.
    ```bash
    # Debian/Ubuntu 예시 (예: v1.28.5-00 버전으로 업그레이드)
    # 실제 패키지 버전은 'apt-cache madison kubeadm' 결과에 따라 정확히 명시해야 합니다.
    sudo apt-mark unhold kubeadm && \
    sudo apt-get update && sudo apt-get install -y kubeadm=1.28.5-00 && \
    sudo apt-mark hold kubeadm

    # CentOS/RHEL 예시 (예: v1.28.5 버전으로 업그레이드)
    # sudo yum install -y kubeadm-1.28.5-0 --disableexcludes=kubernetes
    ```
    (위 `1.28.5-00` 또는 `1.28.5-0` 부분은 실제 사용 가능한 패키지 버전으로 대체해야 합니다.)
*   **컨트롤 플레인 컴포넌트 업그레이드 적용:**
    `kubeadm upgrade apply` 명령을 사용하여 실제로 컨트롤 플레인 컴포넌트(API 서버, 스케줄러, 컨트롤러 매니저, etcd 등)를 업그레이드합니다.
    ```bash
    # 컨트롤 플레인 노드에서 실행 (예: v1.28.5로 업그레이드)
    sudo kubeadm upgrade apply v1.28.5
    ```
    (위 `v1.28.5`는 업그레이드하려는 정확한 Kubernetes 버전으로 지정합니다.)
*   **노드 드레인 (Node Drain) (선택 사항이지만 권장):**
    `kubelet`을 업그레이드하기 전에 해당 노드에서 실행 중인 워크로드를 다른 노드로 안전하게 이동시켜 서비스 중단을 최소화합니다. 단일 컨트롤 플레인 노드이고 다른 워커 노드가 없다면 이 단계를 건너뛸 수 있지만, 일반적으로 권장됩니다.
    ```bash
    # 컨트롤 플레인 노드에서 실행 (다른 터미널 또는 kubectl이 설정된 머신에서)
    kubectl drain <control-plane-node-name> --ignore-daemonsets
    ```
*   **`kubelet` 및 `kubectl` 패키지 업그레이드:**
    컨트롤 플레인 컴포넌트와 동일한 버전으로 `kubelet`과 `kubectl`을 업그레이드합니다.
    ```bash
    # Debian/Ubuntu 예시
    sudo apt-mark unhold kubelet kubectl && \
    sudo apt-get update && sudo apt-get install -y kubelet=1.28.5-00 kubectl=1.28.5-00 && \
    sudo apt-mark hold kubelet kubectl

    # CentOS/RHEL 예시
    # sudo yum install -y kubelet-1.28.5-0 kubectl-1.28.5-0 --disableexcludes=kubernetes
    ```
*   **`kubelet` 서비스 재시작:**
    새로운 버전의 `kubelet` 설정을 적용하기 위해 서비스를 재시작합니다.
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    ```
*   **노드 언코든 (Uncordon) (드레인 했을 경우):**
    노드 드레인을 수행했다면, 업그레이드가 완료된 후 다시 스케줄링이 가능하도록 언코든 상태로 변경합니다.
    ```bash
    # 컨트롤 플레인 노드에서 실행
    kubectl uncordon <control-plane-node-name>
    ```
*   **업그레이드 후 상태 확인:**
    클러스터 및 노드 상태를 확인하여 업그레이드가 성공적으로 이루어졌는지 확인합니다.
    ```bash
    kubectl get nodes
    kubectl cluster-info
    # kube-system 네임스페이스의 파드 상태 확인
    kubectl get pods -n kube-system
    ```

#### 12.2.3. 3단계: 나머지 컨트롤 플레인 노드 업그레이드 (HA 클러스터의 경우)
고가용성(HA) 클러스터로 여러 컨트롤 플레인 노드를 운영 중인 경우, 첫 번째 컨트롤 플레인 노드 업그레이드 후 나머지 컨트롤 플레인 노드들도 순차적으로 업그레이드해야 합니다. **한 번에 하나씩 진행하는 것이 안전합니다.**

각 추가 컨트롤 플레인 노드에서 다음 절차를 따릅니다:
1.  **`kubeadm` 패키지를 대상 버전으로 업그레이드합니다.** (위의 첫 번째 컨트롤 플레인 노드와 동일한 방식)
2.  **`kubeadm upgrade node` 명령을 실행합니다.** 이 명령은 해당 컨트롤 플레인 노드의 로컬 Kubernetes 설정을 업그레이드합니다. (`kubeadm upgrade apply`는 첫 번째 노드에서만 사용합니다.)
    ```bash
    # 추가 컨트롤 플레인 노드에서 실행
    sudo kubeadm upgrade node
    ```
3.  **(선택 사항이지만 권장) 노드를 드레인합니다.**
    ```bash
    kubectl drain <other-control-plane-node-name> --ignore-daemonsets
    ```
4.  **`kubelet` 및 `kubectl` 패키지를 대상 버전으로 업그레이드합니다.** (첫 번째 컨트롤 플레인 노드와 동일한 방식)
5.  **`kubelet` 서비스를 재시작합니다.**
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    ```
6.  **(드레인 했을 경우) 노드를 언코든합니다.**
    ```bash
    kubectl uncordon <other-control-plane-node-name>
    ```

모든 컨트롤 플레인 노드가 성공적으로 업그레이드될 때까지 이 과정을 반복합니다.

### 12.3. 워커 노드 업그레이드

모든 컨트롤 플레인 노드가 성공적으로 업그레이드된 후, 워커 노드들을 업그레이드할 수 있습니다. **워커 노드도 한 번에 하나씩 또는 소규모 그룹으로 순차적으로 업그레이드하는 것이 안전합니다.**

각 워커 노드에서 다음 절차를 따릅니다:

1.  **`kubeadm` 패키지를 대상 버전으로 업그레이드합니다.** (컨트롤 플레인 노드와 동일한 방식)
    ```bash
    # Debian/Ubuntu 예시 (예: v1.28.5-00 버전으로 업그레이드)
    sudo apt-mark unhold kubeadm && \
    sudo apt-get update && sudo apt-get install -y kubeadm=1.28.5-00 && \
    sudo apt-mark hold kubeadm
    ```
2.  **워커 노드 설정 업그레이드:**
    `kubeadm upgrade node` 명령을 실행하여 워커 노드의 로컬 `kubelet` 설정을 업그레이드합니다.
    ```bash
    # 각 워커 노드에서 실행
    sudo kubeadm upgrade node
    ```
3.  **노드 드레인 (Node Drain):**
    컨트롤 플레인 노드에서 업그레이드할 워커 노드를 드레인하여 실행 중인 파드들을 안전하게 다른 노드로 이동시킵니다.
    ```bash
    # 컨트롤 플레인 노드에서 실행
    kubectl drain <worker-node-name> --ignore-daemonsets
    ```
4.  **`kubelet` 및 `kubectl` 패키지 업그레이드:**
    컨트롤 플레인 노드와 동일한 방식으로 `kubelet`과 `kubectl` 패키지를 대상 버전으로 업그레이드합니다.
    ```bash
    # Debian/Ubuntu 예시
    sudo apt-mark unhold kubelet kubectl && \
    sudo apt-get update && sudo apt-get install -y kubelet=1.28.5-00 kubectl=1.28.5-00 && \
    sudo apt-mark hold kubelet kubectl
    ```
5.  **`kubelet` 서비스 재시작:**
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    ```
6.  **노드 언코든 (Uncordon):**
    컨트롤 플레인 노드에서 업그레이드가 완료된 워커 노드를 다시 스케줄링 가능하도록 언코든합니다.
    ```bash
    # 컨트롤 플레인 노드에서 실행
    kubectl uncordon <worker-node-name>
    ```
모든 워커 노드에 대해 이 과정을 반복합니다.

### 12.4. 업그레이드 후 확인 사항

모든 노드의 업그레이드가 완료된 후 다음 사항들을 확인합니다:
*   클러스터 전체 컴포넌트 상태 확인:
    ```bash
    kubectl get nodes -o wide
    kubectl get pods -A
    kubectl cluster-info
    ```
    모든 노드가 `Ready` 상태이고, 모든 시스템 파드(특히 `kube-system` 네임스페이스)가 정상적으로 실행 중인지 확인합니다.
*   애플리케이션 정상 동작 확인: 클러스터에 배포된 사용자 애플리케이션들이 정상적으로 작동하는지 테스트합니다.
*   클러스터 기능 확인: CNI 플러그인, CoreDNS, 스토리지 등 주요 클러스터 기능들이 새 버전과 호환되며 올바르게 작동하는지 확인합니다.

### 12.5. 롤백 (간략히)
업그레이드 중 심각한 문제가 발생하여 이전 상태로 돌아가야 할 경우, 롤백 절차는 복잡할 수 있습니다. `kubeadm`은 직접적인 다운그레이드 명령을 제공하지 않습니다.
*   **가장 안전한 롤백 방법은 사전에 수행한 `etcd` 스냅샷을 복원하는 것입니다.** 이는 클러스터 상태를 백업 시점으로 되돌립니다.
*   각 노드의 컴포넌트(kubelet 등)를 이전 버전으로 수동 다운그레이드하는 것은 매우 복잡하며 권장되지 않습니다.
*   따라서 업그레이드 전 철저한 백업과 테스트 환경에서의 사전 검증이 매우 중요합니다.

클러스터 업그레이드는 신중하게 계획하고 실행해야 하는 중요한 작업입니다. 항상 공식 Kubernetes 문서를 참조하고, 운영 환경에 적용하기 전에 테스트 환경에서 충분히 검증하십시오.

## 13. 클러스터 관리 및 유지보수 관련 `kubeadm` 명령어

`kubeadm`은 클러스터 초기 생성 및 참여 외에도 몇 가지 관리 및 유지보수 작업을 위한 하위 명령어들을 제공합니다. 이 명령어들은 주로 컨트롤 플레인 노드에서 실행됩니다.

### 13.1. `kubeadm config`
이 명령어 그룹은 클러스터 설정과 관련된 작업을 수행합니다.

*   **`kubeadm config images list`**:
    *   현재 `kubeadm` 버전 및 클러스터 구성에 필요한 컨테이너 이미지 목록을 보여줍니다. 업그레이드 전이나 에어갭(air-gapped) 환경에서 필요한 이미지를 미리 확인하고 준비하는 데 유용합니다.
    *   ```bash
        sudo kubeadm config images list
        ```
*   **`kubeadm config images pull`**:
    *   `kubeadm config images list`로 확인된 이미지들을 컨테이너 런타임으로 미리 가져옵니다(pull). 네트워크가 불안정하거나 에어갭 환경에서 클러스터를 설치/업그레이드하기 전에 실행하면 유용합니다.
    *   ```bash
        # CRI 소켓 경로가 기본값이 아닌 경우 명시해야 할 수 있습니다.
        sudo kubeadm config images pull --cri-socket unix:///var/run/containerd/containerd.sock
        ```
*   **`kubeadm config print init-defaults`**:
    *   `kubeadm init` 명령에 사용될 수 있는 기본 설정값들을 YAML 형식으로 출력합니다. 이 내용을 파일로 저장하여 (`kubeadm-config.yaml` 등) 클러스터 초기화 시 `--config` 옵션으로 사용할 수 있습니다. (이전 "컨트롤 플레인 노드 초기화" 섹션에서도 언급됨)
    *   ```bash
        kubeadm config print init-defaults > init-config.yaml
        ```
*   **`kubeadm config print join-defaults`**:
    *   `kubeadm join` 명령에 사용될 수 있는 기본 설정값들을 YAML 형식으로 출력합니다. 이를 통해 노드 참여 시 세부 설정을 파일 기반으로 관리할 수 있습니다.
    *   ```bash
        kubeadm config print join-defaults > join-config.yaml
        ```
*   **`kubeadm config migrate`**:
    *   이전 버전의 `kubeadm` 설정 파일을 새로운 버전의 설정 파일 형식으로 마이그레이션(변환)합니다. Kubernetes 버전 업그레이드 시 오래된 설정 파일을 사용해야 할 때 유용할 수 있습니다.
    *   **주의:** 변환된 설정을 사용하기 전에 반드시 내용을 검토하고, 공식 Kubernetes 및 `kubeadm` 문서를 참조하여 변경 사항을 확인해야 합니다.
    *   ```bash
        sudo kubeadm config migrate --old-config old-config.yaml --new-config new-config.yaml
        ```
*   **`kubeadm config view`**:
    *   현재 실행 중인 클러스터의 `kubeadm` 설정을 보여줍니다. 이 정보는 컨트롤 플레인 노드의 `kube-system` 네임스페이스에 있는 `kubeadm-config`라는 이름의 ConfigMap에서 가져옵니다.
    *   ```bash
        # 컨트롤 플레인 노드에서 실행 (kubectl 설정 필요)
        kubeadm config view
        ```

### 13.2. `kubeadm token`
이 명령어 그룹은 클러스터 참여를 위한 부트스트랩 토큰을 관리합니다. (이전 "워커 노드 추가" 섹션에서 일부 내용을 다루었으나, 명령어 중심으로 종합 정리합니다.)

*   **`kubeadm token list`**:
    *   현재 클러스터에 설정된 모든 부트스트랩 토큰의 목록, 남은 유효 시간(TTL), 사용 목적(usages), 설명 등을 보여줍니다.
    *   ```bash
        # 컨트롤 플레인 노드에서 실행
        sudo kubeadm token list
        ```
*   **`kubeadm token create`**:
    *   새로운 부트스트랩 토큰을 생성합니다. 기본 유효 기간은 24시간입니다.
    *   ```bash
        # 컨트롤 플레인 노드에서 실행
        sudo kubeadm token create
        ```
*   **`kubeadm token create --print-join-command`**:
    *   새로운 부트스트랩 토큰을 생성하고, 해당 토큰과 클러스터의 CA 인증서 해시 값을 포함한 완전한 `kubeadm join` 명령어를 출력합니다. 워커 노드를 클러스터에 추가할 때 매우 유용한 명령어입니다.
    *   ```bash
        # 컨트롤 플레인 노드에서 실행
        sudo kubeadm token create --print-join-command
        ```
*   **`kubeadm token delete <token_value_or_id>`**:
    *   지정된 토큰 값 또는 토큰 ID에 해당하는 부트스트랩 토큰을 클러스터에서 삭제합니다. 더 이상 사용되지 않거나 보안상 유출이 의심되는 토큰은 즉시 삭제하는 것이 좋습니다.
    *   ```bash
        # 컨트롤 플레인 노드에서 실행 (예: 토큰 ID가 'abcdef'인 경우)
        sudo kubeadm token delete abcdef
        ```
*   **`kubeadm token generate`**:
    *   임의의 안전한 토큰 문자열을 로컬에서 생성하여 화면에 출력합니다. 이 명령어 자체는 생성된 토큰을 클러스터의 부트스트랩 토큰 목록에 추가하지는 않습니다. `kubeadm token create`와 함께 사용되거나, 다른 시스템에서 토큰을 미리 생성할 때 활용될 수 있습니다.
    *   ```bash
        kubeadm token generate
        ```

### 13.3. `kubeadm certs`
이 명령어 그룹은 Kubernetes 클러스터의 PKI 인증서 관리에 사용됩니다. 주로 컨트롤 플레인 노드에서 실행됩니다.

*   **`kubeadm certs check-expiration`**:
    *   `kubeadm`이 관리하는 클러스터 인증서들(예: API 서버, 컨트롤러 매니저, 스케줄러, etcd 서버/클라이언트, kubelet 클라이언트 인증서 등)의 만료일을 확인하여 목록으로 보여줍니다. CA 인증서의 만료일도 함께 표시됩니다.
    *   ```bash
        sudo kubeadm certs check-expiration
        ```
*   **`kubeadm certs renew all` (또는 특정 인증서 이름)**:
    *   만료가 임박했거나 이미 만료된 `kubeadm` 관리 인증서들을 수동으로 갱신합니다. `all`을 사용하면 모든 대상 인증서를 갱신 시도하며, 특정 인증서 이름(예: `apiserver`, `kubelet-admin`)을 지정하여 개별적으로 갱신할 수도 있습니다.
    *   Kubernetes v1.17부터 `kubeadm upgrade apply` 및 `kubeadm upgrade node` 실행 시 컨트롤 플레인 및 kubelet 인증서가 자동으로 갱신됩니다. 하지만 그 외의 상황이나 특정 버전에서는 수동 갱신이 필요할 수 있습니다.
    *   **중요:** 이 명령어는 일반적으로 루트 CA(Certificate Authority) 인증서는 갱신하지 않습니다. CA 인증서가 만료되면 클러스터 전체에 심각한 문제가 발생하며, 복구 절차가 복잡해집니다. 따라서 CA 인증서의 만료일은 주기적으로 확인하고, 만료 전에 적절한 절차(예: 수동 CA 교체 또는 클러스터 재설치)를 계획해야 합니다.
    *   ```bash
        # 모든 kubeadm 관리 인증서 갱신 시도
        sudo kubeadm certs renew all

        # API 서버 인증서만 갱신 시도
        # sudo kubeadm certs renew apiserver
        ```
*   **`kubeadm certs certificate-key`**:
    *   `kubeadm init --upload-certs` 명령 실행 시 사용된 인증서 암호화 키를 다시 생성(출력)합니다. 이 키는 다른 컨트롤 플레인 노드를 HA 클러스터에 추가하거나, 기존 컨트롤 플레인 노드의 인증서를 외부에서 복사/관리할 때 필요할 수 있습니다.
    *   ```bash
        sudo kubeadm certs certificate-key
        ```

### 13.4. `kubeadm kubeconfig`
이 명령어는 추가적인 `kubeconfig` 파일을 생성하는 데 사용됩니다.

*   **`kubeadm kubeconfig user --client-name <user> --org <group>`**:
    *   지정된 사용자 이름과 그룹(선택 사항)에 대한 클라이언트 인증서와 키를 생성하고, 이를 사용하여 해당 사용자를 위한 `kubeconfig` 파일을 생성합니다.
    *   이 명령어는 인증 정보와 클러스터 접속 정보가 포함된 `kubeconfig` 파일만 생성하며, 실제 해당 사용자에 대한 Kubernetes 내의 역할 기반 접근 제어(RBAC) 설정(Role, ClusterRole, RoleBinding, ClusterRoleBinding 등)은 별도로 수행해야 합니다.
    *   ```bash
        # 예시: 'johndoe' 사용자를 'developers' 그룹으로 하여 kubeconfig 파일 생성
        # 실제 RBAC 설정은 kubectl을 사용하여 별도로 적용해야 합니다.
        # sudo kubeadm kubeconfig user --client-name johndoe --org developers > johndoe.kubeconfig
        ```

### 13.5. `kubeadm reset`
이 명령어는 `kubeadm init` 또는 `kubeadm join`으로 해당 노드에 적용된 모든 변경 사항을 되돌립니다.

*   **경고: 이 명령어는 해당 노드를 Kubernetes 클러스터에서 효과적으로 제거하며, 해당 노드에 저장된 워크로드 데이터(Pod 볼륨 등)나 클러스터 상태 정보(컨트롤 플레인 노드의 경우 etcd 데이터)가 유실될 수 있습니다. 프로덕션 환경에서는 이 명령어를 실행하기 전에 모든 중요한 데이터를 백업하고, 명령어의 영향을 완전히 이해한 상태에서 매우 신중하게 사용해야 합니다.**
*   컨트롤 플레인 노드 또는 워커 노드에서 실행하여 해당 노드를 클러스터에서 분리하고 관련 파일들(인증서, kubeconfig 파일, 매니페스트 등)을 정리합니다.
*   **`etcd` 데이터:** 컨트롤 플레인 노드에서 `kubeadm reset`을 실행해도, 기본적으로 `/var/lib/etcd` 디렉토리의 `etcd` 데이터는 자동으로 삭제되지 않습니다. 클러스터를 완전히 새로 시작하려면 이 디렉토리를 수동으로 삭제해야 할 수 있습니다. (주의: HA 클러스터의 경우 다른 `etcd` 멤버에 영향이 없는지 확인 필요)
*   **주요 옵션:**
    *   `--force`: 사전 검사 오류나 확인 프롬프트를 무시하고 강제로 리셋을 진행합니다.
    *   `--cri-socket <path>`: 사용할 컨테이너 런타임의 CRI 소켓 경로를 지정합니다. (예: `unix:///var/run/cri-dockerd.sock`)
    *   `--ignore-preflight-errors`: 리셋 전 사전 검사에서 특정 오류를 무시합니다.
*   **실행 예시:**
    ```bash
    # 현재 노드를 클러스터에서 제거하고 관련 파일 정리
    sudo kubeadm reset
    ```
*   **추가 정리 작업:** `kubeadm reset` 후에도 CNI 플러그인에 의해 생성된 네트워크 인터페이스(예: `cni0`, `flannel.1`)나 `iptables` 규칙 등이 시스템에 남아있을 수 있습니다. 필요에 따라 이러한 네트워크 설정들을 수동으로 정리해야 할 수 있습니다.
    ```bash
    # 예시: iptables 규칙 초기화 (주의해서 실행)
    # sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
    # sudo ipvsadm --clear
    ```
*   리셋된 노드는 다시 `kubeadm join`을 사용하여 클러스터에 참여시키거나, 새로운 클러스터의 일부로 사용할 수 있습니다.

이러한 `kubeadm` 명령어들은 클러스터의 생명주기 관리, 특히 설정 확인, 인증서 관리, 토큰 관리, 노드 초기화 등의 작업에 유용하게 사용될 수 있습니다. 각 명령어 사용 시에는 공식 문서를 참조하여 정확한 옵션과 영향을 파악하는 것이 중요합니다.

## 14. 추가 고려 사항

*   **보안:** API 서버 접근 제어, 네트워크 정책, etcd 암호화 등 보안 설정을 강화해야 합니다.
*   **고가용성 (HA):** 프로덕션 환경에서는 여러 컨트롤 플레인 노드를 사용하여 고가용성 클러스터를 구성해야 합니다. `kubeadm`은 HA 클러스터 설정도 지원합니다.
*   **스토리지:** PersistentVolume, StorageClass 등을 설정하여 애플리케이션이 영구 스토리지를 사용할 수 있도록 해야 합니다.
*   **모니터링 및 로깅:** Prometheus, Grafana, ELK/EFK 스택 등을 사용하여 클러스터 및 애플리케이션 모니터링/로깅 시스템을 구축합니다.
*   **백업 및 복원:** etcd 데이터베이스의 정기적인 백업 및 복원 절차를 마련해야 합니다.

이 가이드는 `kubeadm`을 사용한 기본적인 클러스터 설정 방법을 다룹니다. 실제 운영 환경에서는 더 많은 설정과 고려 사항이 필요하며, 항상 공식 Kubernetes 문서를 참조하는 것이 좋습니다.

[end of kubeadm_guide.md]
