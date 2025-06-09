# Helm 차트 구성 요소 가이드

이 가이드는 Helm 차트에서 일반적으로 발견되는 파일 및 디렉터리에 대한 개요를 제공합니다. 이러한 구성 요소를 이해하는 것은 Helm 차트를 생성, 관리 및 사용자 정의하는 데 필수적입니다.

## 1. Helm 차트 소개

*   **Helm이란 무엇인가?** Helm은 쿠버네티스(Kubernetes) 패키지 관리자입니다. 애플리케이션을 쉽게 정의, 설치, 업그레이드할 수 있도록 도와줍니다.
*   **Helm 차트란 무엇인가?** Helm 차트는 사전 구성된 쿠버네티스 리소스의 묶음입니다. 차트는 애플리케이션을 실행하는 데 필요한 모든 리소스 정의, 설정 값 및 메타데이터를 포함합니다.
*   **Helm 차트 사용의 이점:**
    *   **재사용성:** 잘 정의된 차트는 여러 환경에서 재사용될 수 있습니다.
    *   **단순성:** 복잡한 애플리케이션도 단일 명령으로 배포할 수 있습니다.
    *   **버전 관리:** 차트 버전을 통해 릴리스를 관리하고 롤백할 수 있습니다.
    *   **공유 가능성:** 차트 저장소(repository)를 통해 차트를 공유하고 사용할 수 있습니다.

## 2. Helm 차트 기본 구조 및 공통 패턴

일반적인 Helm 차트는 다음과 같은 디렉터리 구조를 갖습니다.

```
mychart/
  Chart.yaml          # 차트 메타데이터 파일
  LICENSE             # (선택 사항) 차트에 대한 라이선스 파일
  README.md           # (선택 사항) 사람이 읽을 수 있는 README 파일 (차트 설명, 사용법 등)
  values.yaml         # 차트 기본 설정 값 파일
  charts/             # (선택 사항) 하위 차트(의존성) 디렉터리
  crds/               # (선택 사항) Custom Resource Definitions (CRD) 파일들을 포함하는 디렉터리
  templates/          # 매니페스트 템플릿 디렉터리
  templates/NOTES.txt # (선택 사항) 릴리스 노트 템플릿 파일
  templates/_helpers.tpl # (선택 사항) 템플릿 헬퍼 파일
```

### 2.1. Helm 차트 파일 구조 상세 설명

#### 2.1.1. `Chart.yaml`

*   **목적 및 내용:** 차트에 대한 메타데이터를 정의하는 필수 파일입니다. 차트의 이름, 버전, 설명 등을 포함하여 차트를 식별하고 관리하는 데 필요한 정보를 제공합니다.
*   **주요 필드:**
    *   `apiVersion`: 차트 API 버전 (예: `v2` - Helm 3+에서 사용). 필수 항목입니다.
    *   `name`: 차트의 이름 (예: `my-web-app`). 필수 항목입니다.
    *   `version`: 차트의 버전 (SemVer 2.0.0 형식, 예: `0.1.0`). 필수 항목입니다. 릴리스 관리에 사용됩니다.
    *   `appVersion`: (선택 사항) 차트가 배포하는 애플리케이션의 버전 (예: `1.16.0`). 정보 제공 목적으로 사용됩니다.
    *   `description`: (선택 사항) 차트에 대한 사람이 읽을 수 있는 간략한 설명.
    *   `type`: (선택 사항) 차트의 유형. `application` (기본값) 또는 `library` (다른 차트에서 재사용 가능한 유틸리티나 함수를 제공하며, 자체적으로 배포되지 않음).
    *   `dependencies`: (선택 사항) 이 차트가 의존하는 다른 차트(하위 차트)의 목록. (`charts/` 디렉토리 관련).
    *   `keywords`: (선택 사항) 차트를 설명하고 검색하는 데 사용되는 키워드 목록.
    *   `home`: (선택 사항) 프로젝트 또는 애플리케이션의 홈페이지 URL.
    *   `sources`: (선택 사항) 애플리케이션의 소스 코드 저장소 URL 목록.
    *   `maintainers`: (선택 사항) 차트 유지보수 담당자 정보 (이름, 이메일 등).

#### 2.1.2. `values.yaml`

*   **목적:** 차트의 기본 설정 값을 정의하는 파일입니다. 이 파일에 정의된 값들은 템플릿에 주입되어 Kubernetes 매니페스트를 동적으로 생성하는 데 사용됩니다. 사용자는 `helm install` 또는 `helm upgrade` 시 이 기본값들을 재정의(override)할 수 있습니다.
*   **내용:** YAML 형식으로 키-값 쌍을 정의합니다. 계층적인 구조를 가질 수 있어 복잡한 설정도 체계적으로 관리할 수 있습니다.
*   **예시:**
    ```yaml
    replicaCount: 1
    image:
      repository: nginx # 사용할 Docker 이미지 저장소
      pullPolicy: IfNotPresent # 이미지 가져오기 정책
      tag: "" # 이미지 태그 (비어있으면 Chart.yaml의 appVersion 사용 가능)

    service:
      type: ClusterIP # 서비스 타입 (ClusterIP, NodePort, LoadBalancer 등)
      port: 80 # 서비스가 노출할 포트

    ingress:
      enabled: false # Ingress 생성 여부
      annotations: {} # Ingress에 추가할 어노테이션
      hosts:
        - host: chart-example.local # Ingress 호스트명
          paths:
            - path: / # 라우팅 경로
              pathType: ImplementationSpecific
    ```

#### 2.1.3. `templates/` 디렉토리

*   **역할:** Kubernetes 매니페스트 파일을 생성하는 템플릿 파일들이 위치하는 핵심 디렉토리입니다. Helm은 이 디렉토리의 템플릿 파일들과 `values.yaml` (또는 사용자가 명령줄에서 제공한 값)을 결합(렌더링)하여 최종적으로 Kubernetes 클러스터에 적용될 YAML 매니페스트 파일들을 생성합니다.
*   **Go 템플릿 언어:** Helm 템플릿은 Go 프로그래밍 언어의 템플릿 엔진을 사용합니다. 이를 통해 변수, 함수, 조건문(`if/else`), 반복문(`range`), `with` 블록 등 다양한 프로그래밍 구조를 사용하여 동적이고 유연한 매니페스트 생성이 가능합니다.
*   **일반적인 Kubernetes 객체:** 이 디렉토리에는 일반적으로 Deployment, Service, ConfigMap, Secret, Ingress, PersistentVolumeClaim 등 다양한 Kubernetes 리소스에 대한 템플릿 파일들(확장자는 보통 `.yaml`)이 포함됩니다.

##### `templates/NOTES.txt`

*   **목적:** `helm install` 또는 `helm upgrade` 명령이 성공적으로 완료된 후 사용자에게 터미널에 표시될 유용한 정보나 다음 단계를 안내하는 메시지를 정의하는 일반 텍스트 파일입니다.
*   **내용:** 배포된 애플리케이션에 접근하는 방법, 주요 설정 값, 추가적인 명령어 안내 등을 포함할 수 있습니다.
*   **템플릿 사용:** `NOTES.txt` 파일도 Go 템플릿 언어를 사용하여 동적인 정보를 포함할 수 있습니다. 예를 들어, 서비스의 IP 주소, 릴리스 이름, 사용자가 설정한 값 등을 메시지에 동적으로 삽입할 수 있습니다.
*   **예시:**
    ```
    {{- .Release.Name }} 이(가) 성공적으로 배포되었습니다.

    애플리케이션 접근 방법:

    {{- if eq .Values.service.type "LoadBalancer" }}
    외부 IP 주소가 프로비저닝될 때까지 몇 분 정도 기다리십시오.
      export SERVICE_IP=$(kubectl get svc --namespace {{ .Release.Namespace }} {{ include "mychart.fullname" . }} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      echo "애플리케이션 URL: http://$SERVICE_IP:{{ .Values.service.port }}"
    {{- else if eq .Values.service.type "NodePort" }}
      export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "mychart.fullname" . }})
      export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} -o jsonpath="{.items[0].status.addresses[0].address}")
      echo "애플리케이션 URL: http://$NODE_IP:$NODE_PORT"
    {{- else }}
    다음 명령을 실행하여 포트 포워딩을 설정하십시오:
      kubectl port-forward svc/{{ include "mychart.fullname" . }} {{ .Values.service.port }}:{{ .Values.service.port }}
    그런 다음 브라우저에서 http://127.0.0.1:{{ .Values.service.port }} 로 접속하십시오.
    {{- end }}
    ```

##### `templates/_helpers.tpl`

*   **목적:** 차트 전체에서 공통적으로 사용될 헬퍼(helper) 템플릿이나 명명 규칙, 레이블 블록 등을 정의하는 파일입니다. `.tpl` 확장자는 "template library"를 의미하며, 이 파일 자체는 Kubernetes 매니페스트를 직접 생성하지 않고 다른 템플릿 파일에서 재사용될 수 있는 명명된 템플릿 조각(partials)들을 정의합니다.
*   **이점:** 코드 중복을 줄이고 (DRY - Don't Repeat Yourself 원칙), 차트의 가독성과 유지보수성을 크게 향상시킵니다. 예를 들어, 모든 리소스에 일관된 이름이나 레이블을 적용하는 로직을 이곳에 정의할 수 있습니다.
*   **사용법:** `define` 액션(action)을 사용하여 명명된 템플릿을 정의하고, 다른 템플릿 파일에서는 `include` 액션을 사용하여 해당 명명된 템플릿을 호출하여 그 결과를 삽입합니다.
*   **예시 (fullname 헬퍼):**
    ```go
    {{/*
    mychart.fullname 템플릿을 정의합니다.
    차트 이름이 "mychart"이고 릴리스 이름이 "myrelease"라면,
    "myrelease-mychart"를 반환합니다.
    릴리스 이름이 차트 이름을 포함하면 릴리스 이름만 사용합니다.
    fullnameOverride 값이 있으면 해당 값을 사용합니다.
    결과 문자열은 63자로 제한되고, 마지막에 '-'가 있으면 제거됩니다.
    */}}
    {{- define "mychart.fullname" -}}
    {{- if .Values.fullnameOverride -}}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
    {{- $name := default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
    {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
    {{- end -}}
    {{- end -}}
    ```
    위 헬퍼는 다른 템플릿 파일에서 `{{ include "mychart.fullname" . }}` 와 같이 호출되어 사용될 수 있습니다.

#### 2.1.4. `charts/` 디렉토리 (선택 사항)

*   **목적:** 현재 차트가 의존하는 다른 Helm 차트(하위 차트 또는 서브차트라고도 함)들이 위치하는 디렉토리입니다. 이를 통해 복잡한 애플리케이션을 여러 개의 관리 가능한 작은 차트로 분리하고 조합할 수 있습니다.
*   **의존성 관리:** `Chart.yaml` 파일의 `dependencies` 필드에 하위 차트의 이름, 버전, 저장소 URL 등을 명시합니다. `helm dependency update <차트경로>` 또는 `helm dependency build <차트경로>` 명령을 실행하면, 명시된 의존성에 따라 하위 차트들이 이 `charts/` 디렉토리로 다운로드되거나 복사됩니다.
*   **구성:** 하위 차트의 설정 값들은 현재 차트(부모 차트)의 `values.yaml` 파일에서 해당 하위 차트의 이름(alias)을 키로 사용하여 재정의할 수 있습니다. 예를 들어, `mychart`가 `postgresql`이라는 이름의 하위 차트에 의존한다면, `mychart`의 `values.yaml`에 다음과 같이 `postgresql` 설정을 추가하여 하위 차트의 기본값을 변경할 수 있습니다:
    ```yaml
    # mychart/values.yaml
    postgresql:
      # postgresql 하위 차트의 values.yaml에 정의된 값들을 여기서 재정의
      global:
        storageClass: "fast-ssd"
      auth:
        username: "myadmin"
        password: "mysecretpassword"
    ```

#### 2.1.5. `crds/` 디렉토리 (선택 사항)

*   **목적:** Custom Resource Definitions (CRD) YAML 파일들이 위치하는 디렉토리입니다. CRD는 Kubernetes API를 확장하여 사용자 정의 리소스를 만들 수 있게 해줍니다.
*   **CRD 관리:** `helm install` 시, Helm은 `templates/` 디렉토리의 템플릿을 렌더링하기 전에 `crds/` 디렉토리에 있는 CRD들을 먼저 Kubernetes 클러스터에 적용합니다. 이는 CRD가 클러스터에 정의된 후에 해당 CRD를 사용하는 사용자 정의 리소스들이 생성될 수 있도록 하기 위함입니다.
*   **주의사항:** CRD는 클러스터 전역(global) 리소스입니다. 따라서, CRD의 설치 및 관리는 신중하게 이루어져야 합니다. Helm은 기본적으로 `helm uninstall` 시 CRD를 삭제하지 않으며, CRD 업그레이드도 지원하지 않습니다 (Helm 3.x 기준). CRD 변경은 복잡한 마이그레이션 문제를 야기할 수 있으므로, CRD 관리에 대한 전략을 수립하는 것이 중요합니다.

### 2.2. 공통 Helm 템플릿 패턴 및 함수

Helm 템플릿 작성 시 자주 사용되는 패턴과 내장 함수, 그리고 Go 템플릿 언어의 기능들이 있습니다.

#### 2.2.1. 명명 규칙 (Naming Conventions)

Kubernetes 리소스의 이름을 일관되게 생성하기 위해 헬퍼 템플릿을 사용하는 것이 일반적입니다. 이는 충돌을 방지하고 리소스 식별을 용이하게 합니다.

*   `{{ .Release.Name }}`: 현재 릴리스의 이름입니다. `helm install <릴리스이름> .` 명령에서 사용자가 지정한 `<릴리스이름>` 입니다.
*   `{{ .Chart.Name }}`: `Chart.yaml` 파일에 정의된 차트의 이름입니다.
*   `{{ .Chart.Version }}`: `Chart.yaml` 파일에 정의된 차트의 버전입니다.
*   `{{ include "mychart.fullname" . }}`: 일반적으로 `_helpers.tpl` 파일에 정의된 `mychart.fullname`이라는 명명된 템플릿을 호출하여 전체 리소스 이름을 생성합니다. (위 `_helpers.tpl` 예시 참조) 이 헬퍼는 보통 릴리스 이름과 차트 이름을 조합하여 고유한 이름을 만듭니다.
*   `{{ include "mychart.chart" . }}`: 일반적으로 `_helpers.tpl`에 정의된 헬퍼로, `{{ .Chart.Name }}-{{ .Chart.Version }}` 와 같이 차트 이름과 버전을 조합하여 레이블 등에서 사용됩니다.

#### 2.2.2. 레이블 및 어노테이션 (Labels and Annotations)

모든 Kubernetes 리소스에 공통적인 레이블(labels)과 어노테이션(annotations)을 일관되게 적용하기 위해 헬퍼 템플릿을 사용합니다. 이는 리소스 그룹화, 선택, 관리에 매우 중요합니다.

*   **`_helpers.tpl` 예시 (레이블):**
    ```go
    {{/*
    mychart.labels 템플릿을 정의합니다.
    모든 리소스에 적용될 공통 레이블을 포함합니다.
    */}}
    {{- define "mychart.labels" -}}
    helm.sh/chart: {{ include "mychart.chart" . }}
    {{ include "mychart.selectorLabels" (dict "root" .root "component" .component) }}
    {{- if .root.Chart.AppVersion }}
    app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
    {{- end }}
    app.kubernetes.io/managed-by: {{ .root.Release.Service }}
    {{- end -}}

    {{/*
    mychart.selectorLabels 템플릿을 정의합니다.
    Deployment, StatefulSet 등의 selector에 사용될 레이블입니다.
    컴포넌트 이름을 인자로 받습니다. (예: {{ include "mychart.selectorLabels" (dict "root" . "component" "frontend") }})
    */}}
    {{- define "mychart.selectorLabels" -}}
    app.kubernetes.io/name: {{ include "mychart.name" .root }}
    app.kubernetes.io/instance: {{ .root.Release.Name }}
    {{- if .component }}
    app.kubernetes.io/component: {{ .component }}
    {{- end }}
    {{- end -}}

    {{/*
    mychart.name 템플릿을 정의합니다.
    차트 이름을 반환합니다.
    */}}
    {{- define "mychart.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
    ```
*   **Deployment 템플릿에서의 사용:**
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: {{ include "mychart.fullname" . }}
      labels:
        {{- include "mychart.labels" (dict "root" . "component" "example-component") | nindent 8 }}
    spec:
      selector:
        matchLabels:
          {{- include "mychart.selectorLabels" (dict "root" . "component" "example-component") | nindent 10 }}
      template:
        metadata:
          labels:
            {{- include "mychart.selectorLabels" (dict "root" . "component" "example-component") | nindent 12 }}
    # ... 이하 생략
    ```

#### 2.2.3. `values.yaml` 값 사용

`values.yaml` 파일에 정의된 값은 `{{ .Values.<키> }}` 형태로 템플릿에서 참조합니다. 여기서 `.`은 현재 범위(scope)의 최상위 컨텍스트를 나타냅니다.

*   `{{ .Values.replicaCount }}`: `values.yaml`의 최상위에 있는 `replicaCount` 값을 참조합니다.
*   `{{ .Values.image.repository }}`: `values.yaml` 내의 `image` 객체 하위에 있는 `repository` 값을 참조합니다.
*   `{{ .Values.nonExistentKey | default "defaultValue" }}`: `default` 함수를 사용하여 `values.yaml`에 해당 키가 없거나 값이 `null`일 경우 기본값을 지정할 수 있습니다.
*   `{{ required "A valid foo is required!" .Values.foo }}`: `required` 함수를 사용하여 특정 값이 반드시 제공되어야 함을 명시하고, 없을 경우 에러 메시지와 함께 템플릿 렌더링을 중단시킵니다.

#### 2.2.4. 조건부 블록 (`if/else`)

특정 조건(예: `values.yaml`의 특정 값의 존재 여부 또는 참/거짓 여부)에 따라 매니페스트의 일부를 렌더링하거나 제외할 때 사용합니다.

*   **기본 `if`:**
    ```yaml
    {{- if .Values.serviceAccount.create -}}
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: {{ include "mychart.serviceAccountName" . }} # '.'는 이미 root 컨텍스트이므로 .root 불필요
      labels:
        {{- include "mychart.labels" (dict "root" . "component" "serviceaccount") | nindent 8 }}
    {{- end -}}
    ```
*   **`if/else`:**
    ```yaml
    {{- if .Values.isProduction }}
      replicas: {{ .Values.prodReplicas }}
    {{- else }}
      replicas: 1
    {{- end }}
    ```
*   **다중 조건 (`and`, `or`, `not` 함수 사용):**
    ```yaml
    {{- if and .Values.ingress.enabled .Values.ingress.tlsSecretName }}
    # Ingress와 TLS Secret 이름이 모두 설정된 경우에만 이 블록을 렌더링
    # ...
    {{- end }}
    ```

#### 2.2.5. 범위 지정 (`range`)

`values.yaml` 등에 정의된 목록(배열 또는 맵/딕셔너리)을 순회하며 템플릿의 특정 부분을 반복적으로 생성할 때 사용합니다.

*   **배열 순회 (예: 서비스 포트 목록):**
    ```yaml
    ports:
    {{- range .Values.service.ports }}
      - port: {{ .port }}
        targetPort: {{ .targetPort | default .port }}
        protocol: {{ .protocol | default "TCP" }}
        name: {{ .name }}
    {{- end }}
    ```
    `values.yaml` 예시:
    ```yaml
    service:
      ports:
        - name: http
          port: 80
          targetPort: http # targetPort가 없으면 port와 동일하게 설정됨
        - name: https
          port: 443
          protocol: TCP # protocol이 없으면 TCP로 설정됨
    ```
*   **범위 내 컨텍스트:** `range` 블록 내에서 `.`은 현재 순회 중인 아이템(요소)을 가리킵니다. 위 예에서 `{{ .port }}`는 현재 순회 중인 포트 객체의 `port` 필드를 참조합니다.
*   `range`는 `else` 블록도 가질 수 있어, 목록이 비어있거나 `nil`일 경우 다른 내용을 렌더링할 수 있습니다.

#### 2.2.6. `with` 블록

특정 객체의 컨텍스트(범위) 내에서 템플릿의 일부를 작성하여 반복적인 `.` 사용을 줄이고 가독성을 높일 수 있습니다. `if`와 유사하게, `with`에 전달된 객체가 존재하거나 `nil` 또는 `false`(Go의 zero value)가 아닐 경우에만 내부 블록을 렌더링합니다.

*   **예시:**
    ```yaml
    {{- with .Values.affinity }} # .Values.affinity가 존재하고 nil이 아니면
    affinity:
      {{- toYaml . | nindent 6 }} # toYaml 함수는 객체를 YAML 문자열로 변환하고, nindent는 들여쓰기를 합니다.
                                  # 여기서 '.'은 .Values.affinity를 가리킵니다.
    {{- end }}
    ```
    `values.yaml` 예시:
    ```yaml
    affinity: # 이 affinity 블록이 values.yaml에 정의되어 있어야 with 구문이 실행됨
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: kubernetes.io/os
              operator: In
              values:
              - linux
    ```
    `with` 블록 내에서 `.`은 `.Values.affinity` 객체를 직접 가리키므로, `{{ .nodeAffinity }}`처럼 바로 하위 필드에 접근할 수 있습니다.

#### 2.2.7. 변수 사용

템플릿 내에서 값을 저장하고 재사용하기 위해 변수를 선언할 수 있습니다. 변수는 복잡한 표현식의 결과를 저장하거나, `range` 루프 등에서 특정 값을 유지하는 데 유용합니다.

*   **선언:** `{{ $variableName := "value" }}` 또는 `{{ $variableName := pipelineFunction .Values.someKey }}`
*   **사용:** `{{ $variableName }}`
*   **예시:**
    ```go
    {{- $fullName := include "mychart.fullname" . -}}
    {{- $labels := include "mychart.labels" (dict "root" . "component" "mycomponent") -}}

    apiVersion: v1
    kind: Service
    metadata:
      name: {{ $fullName }}
      labels:
        {{ $labels | nindent 4 }}
    # ...
    ```
    변수는 일반적으로 `$` 기호로 시작합니다.

### 2.3. 간단한 예제

#### 2.3.1. `templates/_helpers.tpl` 예제 (fullname 및 chart)

```go
{{/*
mychart.fullname 템플릿
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
mychart.chart 템플릿 (차트이름-차트버전)
차트 이름과 버전을 조합합니다.
*/}}
{{- define "mychart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
mychart.labels 템플릿
모든 리소스에 공통적으로 적용될 표준 레이블들을 정의합니다.
.root 컨텍스트와 .component 문자열을 필요로 합니다.
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ include "mychart.chart" .root }}
{{ include "mychart.selectorLabels" . }}
{{- if .root.Chart.AppVersion }}
app.kubernetes.io/version: {{ .root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end -}}

{{/*
mychart.selectorLabels 정의 (위에서 이미 수정됨)
파드 셀렉터에 사용될 레이블들을 정의합니다.
.root 컨텍스트와 .component 문자열을 필요로 합니다.
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- if .component }}
app.kubernetes.io/component: {{ .component }}
{{- end }}
{{- end -}}


{{/*
mychart.name 템플릿
차트의 애플리케이션 이름을 반환합니다. .Values.nameOverride가 있으면 그것을 사용합니다.
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
mychart.serviceAccountName 템플릿
사용할 서비스 어카운트 이름을 결정합니다.
Values.serviceAccount.name이 설정되어 있으면 그 값을 사용하고,
아니면 Values.serviceAccount.create가 true일 경우 fullname 기반으로 생성하고,
그것도 아니면 "default"를 반환합니다. (Helm 기본 동작 모방)
*/}}
{{- define "mychart.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- if .Values.serviceAccount.create -}}
{{- include "mychart.fullname" . -}}
{{- else -}}
{{- "default" -}}
{{- end -}}
{{- end -}}
{{- end -}}
```

#### 2.3.2. `values.yaml` 예제

```yaml
# 이 차트의 기본 설정 값들

replicaCount: 1 # 기본 파드 복제본 수

image:
  repository: nginx # 사용할 이미지 저장소
  pullPolicy: IfNotPresent # 이미지 가져오기 정책
  # tag는 기본적으로 Chart.yaml의 appVersion을 사용하도록 설정될 수 있음
  tag: ""

# nameOverride는 차트 이름을 재정의할 때 사용 (예: mychart -> my-custom-name)
nameOverride: ""
# fullnameOverride는 전체 리소스 이름을 재정의할 때 사용 (예: release-name-mychart -> my-custom-fullname)
fullnameOverride: ""

serviceAccount:
  # serviceAccount.create가 true이면 서비스 어카운트 생성 여부 결정
  create: true
  # 생성될 서비스 어카운트에 추가할 어노테이션
  annotations: {}
  # 사용할 서비스 어카운트의 이름. 비어있으면 fullname 기반으로 자동 생성됨.
  # create: false 이고 name이 비어있으면 "default" 서비스 어카운트 사용
  name: ""

podAnnotations: {}
podSecurityContext: {}
  # fsGroup: 2000

securityContext: {}
  # capabilities:
  #   drop:
  #   - ALL
  # readOnlyRootFilesystem: true
  # runAsNonRoot: true
  # runAsUser: 1000

service:
  type: ClusterIP # 서비스 타입
  port: 80 # 서비스 포트

# ingress 설정은 예시로, 실제 사용 시에는 Ingress Controller 종류 및 설정에 맞게 조정 필요
ingress:
  enabled: false
  className: "" # Ingress 클래스 이름 (예: "nginx", "traefik")
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: chart-example.local # 애플리케이션 호스트명
      paths:
        - path: / # 기본 경로
          pathType: ImplementationSpecific # 또는 Prefix 등
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local

resources: {} # 컨테이너 리소스 요청 및 제한 (예: cpu, memory)
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  # targetMemoryUtilizationPercentage: 80

# Node selector, tolerations, affinity 등은 필요에 따라 추가
nodeSelector: {}
tolerations: []
affinity: {}
```

#### 2.3.3. `templates/deployment.yaml` 예제

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" (dict "root" . "component" .Chart.Name) | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "mychart.selectorLabels" (dict "root" . "component" .Chart.Name) | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "mychart.selectorLabels" (dict "root" . "component" .Chart.Name) | nindent 8 }}
        # 필요시 추가적인 파드 레이블을 여기에 정의할 수 있습니다.
    spec:
      serviceAccountName: {{ include "mychart.serviceAccountName" . }} # mychart.serviceAccountName 헬퍼 사용
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80 # Values.service.port 또는 특정 값을 참조할 수도 있음
              protocol: TCP
          # 여기에 livenessProbe, readinessProbe 등을 추가할 수 있습니다.
          # 예시:
          # livenessProbe:
          #   httpGet:
          #     path: /healthz
          #     port: http
          # readinessProbe:
          #   httpGet:
          #     path: /ready
          #     port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

## 3. 차트 개발 모범 사례

*   **일관된 명명 규칙 사용:** 리소스 이름, 헬퍼 템플릿 이름, 값(value)의 키 등에 일관성을 유지하여 가독성과 예측 가능성을 높입니다.
*   **값(Values) 계층 구조화:** `values.yaml` 파일의 값들을 논리적인 그룹으로 묶어 계층적으로 구성합니다. 이렇게 하면 복잡한 설정도 이해하기 쉽고 관리하기 용이해집니다. (예: `image.repository`, `service.port` 등)
*   **명확한 `NOTES.txt` 작성:** 사용자가 차트를 배포한 후 애플리케이션에 쉽게 접근하고 사용할 수 있도록 유용한 정보(접속 URL, 다음 단계, 주요 설정 등)를 제공합니다.
*   **헬퍼 템플릿 적극 활용:** `_helpers.tpl` 파일을 사용하여 반복되는 코드 조각, 복잡한 로직, 이름 및 레이블 생성 규칙 등을 중앙에서 관리합니다. 이는 DRY 원칙을 따르고 유지보수성을 향상시킵니다.
*   **차트 테스트:**
    *   `helm lint <차트경로>`: 차트의 YAML 구문 오류나 권장 사항 위반 여부를 검사합니다.
    *   `helm template <차트경로> --debug > manifest.yaml`: 실제로 클러스터에 배포하지 않고 렌더링된 Kubernetes 매니페스트를 파일로 저장하여 확인하고 디버깅합니다. `--set` 옵션으로 다양한 값 조합을 테스트할 수 있습니다.
    *   로컬 Kubernetes 클러스터(예: Minikube, Kind, Docker Desktop Kubernetes)에 차트를 설치하여 실제 동작을 테스트합니다.
*   **보안 고려:**
    *   Secret을 사용하여 민감한 정보(비밀번호, API 키 등)를 관리하고, `values.yaml`에는 기본값이나 예시만 포함합니다.
    *   PodSecurityContext, SecurityContext 등을 적절히 설정하여 최소 권한 원칙을 따릅니다.
    *   RBAC(Role-Based Access Control) 설정을 통해 서비스 어카운트의 권한을 제한합니다.
    *   NetworkPolicy를 사용하여 파드 간 네트워크 트래픽을 제어합니다.
*   **문서화:** `README.md` 파일에 차트의 목적, 전제 조건, 주요 설정 옵션(`values.yaml` 설명), 사용 예시 등을 상세히 기록합니다.
*   **의존성 관리:** 외부 차트에 의존하는 경우, `Chart.lock` 파일을 사용하여 의존성 버전을 고정하고, `helm dependency update`로 관리합니다.
*   **재정의(Override) 용이성:** 사용자가 차트의 다양한 측면을 쉽게 재정의할 수 있도록 `values.yaml`을 구조화하고, 명확한 인터페이스를 제공합니다.

## 4. 결론

Helm 차트의 기본 구조와 공통 패턴, 그리고 모범 사례를 이해하는 것은 효율적이고 안정적인 Kubernetes 애플리케이션 배포 및 관리에 매우 중요합니다. 이 가이드에서 설명된 구성 요소와 패턴을 활용하여 재사용 가능하고 유지보수하기 쉬운 고품질의 Helm 차트를 개발할 수 있습니다.

Helm 및 차트 개발에 대해 더 자세히 알아보려면 공식 Helm 문서 (helm.sh)를 방문하여 최신 정보와 심층적인 내용을 확인하는 것이 좋습니다.

## 애플리케이션별 Helm 차트 구성 가이드

### 1. Next.js 프론트엔드 서버

Next.js 애플리케이션을 Kubernetes에 배포하기 위한 Helm 차트 구성 요소는 일반적으로 다음과 같습니다.

#### 주요 Kubernetes 리소스

*   **Deployment (`templates/nextjs-deployment.yaml`):**
    *   Next.js 애플리케이션 컨테이너를 관리합니다.
    *   `replicas`: 배포할 파드 수를 `values.yaml` 에서 정의 (`{{ .Values.nextjs.replicaCount }}`).
    *   `image`: 사용할 Docker 이미지 (`{{ .Values.nextjs.image.repository }}:{{ .Values.nextjs.image.tag }}`).
    *   `ports`: 컨테이너가 노출할 포트 (예: `containerPort: {{ .Values.nextjs.service.internalPort }}`).
    *   `envFrom` 또는 `env`: `ConfigMap`이나 `Secret`으로부터 환경 변수를 주입합니다. (예: `NEXT_PUBLIC_API_URL` 등).
        ```yaml
        env:
          - name: NEXT_PUBLIC_API_URL
            value: {{ .Values.nextjs.config.apiUrl | quote }}
          - name: NODE_ENV
            value: {{ .Values.nextjs.config.nodeEnv | quote }}
        ```
    *   Liveness/Readiness 프로브: 애플리케이션 상태를 확인하기 위한 프로브를 설정합니다. Next.js의 경우 특정 헬스 체크 엔드포인트가 있다면 이를 활용합니다.
        ```yaml
        livenessProbe:
          httpGet:
            path: /api/health # 예시 경로, 실제 헬스 체크 경로로 변경
            port: {{ .Values.nextjs.service.internalPort }}
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health # 예시 경로
            port: {{ .Values.nextjs.service.internalPort }}
          initialDelaySeconds: 5
          periodSeconds: 5
        ```
    *   `resources`: CPU 및 메모리 요청/제한을 `values.yaml`에서 설정 (`{{ toYaml .Values.nextjs.resources | nindent 12 }}`).

*   **Service (`templates/nextjs-service.yaml`):**
    *   Next.js 파드에 대한 안정적인 네트워크 엔드포인트를 제공합니다.
    *   `type`: `ClusterIP` (내부용), `NodePort` 또는 `LoadBalancer` (외부 노출용)를 `values.yaml`에서 선택 (`{{ .Values.nextjs.service.type }}`).
    *   `ports`: 서비스가 노출할 포트와 파드의 `targetPort`를 매핑합니다.
        ```yaml
        ports:
          - port: {{ .Values.nextjs.service.externalPort }}
            targetPort: {{ .Values.nextjs.service.internalPort }}
            protocol: TCP
            name: http
        ```
    *   `selector`: `{{- include "mychart.selectorLabels" (dict "root" . "component" "nextjs") | nindent 6 }}`
    *   Deployment `spec.selector.matchLabels`는 `{{- include "mychart.selectorLabels" (dict "root" . "component" "nextjs") | nindent 6 }}`를 사용하고, `spec.template.metadata.labels`는 `{{- include "mychart.labels" (dict "root" . "component" "nextjs") | nindent 8 }}` (또는 최소한 selectorLabels)를 포함해야 합니다. 아래 Deployment 예시를 참조하십시오.
    *   Deployment 예시 (`templates/nextjs-deployment.yaml`):
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: {{ printf "%s-nextjs" (include "mychart.fullname" .) }}
          labels:
            {{- include "mychart.labels" (dict "root" . "component" "nextjs") | nindent 4 }}
        spec:
          replicas: {{ .Values.nextjs.replicaCount }}
          selector:
            matchLabels:
              {{- include "mychart.selectorLabels" (dict "root" . "component" "nextjs") | nindent 6 }}
          template:
            metadata:
              labels:
                {{- include "mychart.labels" (dict "root" . "component" "nextjs") | nindent 8 }} # 또는 mychart.selectorLabels 사용
            spec:
              # ... (나머지 설정은 이전과 동일)
              containers:
                - name: nextjs # {{ .Chart.Name }}-nextjs 와 같이 할 수도 있음
                  image: "{{ .Values.nextjs.image.repository }}:{{ .Values.nextjs.image.tag }}"
                  # ... (ports, env, probes, resources 등)
        ```

*   **Ingress (`templates/nextjs-ingress.yaml`):** (선택 사항, 외부 노출 시)
    *   HTTP/HTTPS 라우팅 규칙을 정의하여 외부에서 Next.js 애플리케이션에 접근할 수 있도록 합니다.
    *   서비스 이름은 `{{ printf "%s-nextjs" (include "mychart.fullname" .) }}` 와 같이 fullname과 컴포넌트명을 조합하여 사용합니다.
    *   `{{ if .Values.nextjs.ingress.enabled }}` ... `{{ end }}` 블록으로 활성화 여부를 제어합니다.
    *   `hosts`: 도메인 이름을 `values.yaml`에서 설정 (`host: {{ .Values.nextjs.ingress.host }}`).
    *   `paths`: 요청 경로와 백엔드 서비스를 매핑합니다.
        ```yaml
        paths:
          - path: {{ .Values.nextjs.ingress.path }}
            pathType: Prefix
            backend:
              service:
                name: {{ printf "%s-nextjs" (include "mychart.fullname" .) }} # fullname-nextjs
                port:
                  number: {{ .Values.nextjs.service.externalPort }}
        ```
    *   TLS 설정: `values.yaml`에서 TLS 시크릿 이름 등을 설정할 수 있습니다.

*   **ConfigMap (`templates/nextjs-configmap.yaml`):** (선택 사항)
    *   애플리케이션 실행에 필요한 환경 변수나 설정 파일들을 관리합니다.
    *   `data`: 키-값 쌍으로 설정 내용을 정의합니다.
        ```yaml
        data:
          NEXT_PUBLIC_API_URL: {{ .Values.nextjs.config.apiUrl | quote }}
          NODE_ENV: {{ .Values.nextjs.config.nodeEnv | quote }}
          # 기타 필요한 설정 값들
        ```
    *   Deployment에서 `envFrom` 또는 `env`를 통해 참조됩니다.

*   **HorizontalPodAutoscaler (HPA) (`templates/nextjs-hpa.yaml`):** (선택 사항)
    *   CPU 또는 메모리 사용량에 따라 파드 수를 자동으로 조절합니다.
    *   `{{ if .Values.nextjs.autoscaling.enabled }}` ... `{{ end }}` 블록으로 활성화 여부를 제어합니다.
    *   `scaleTargetRef`: 대상 `Deployment`를 지정합니다.
    *   `minReplicas`, `maxReplicas`, `targetCPUUtilizationPercentage` 등을 `values.yaml`에서 설정합니다.

#### `values.yaml` 예시 (Next.js 관련 부분)

```yaml
# values.yaml

nextjs:
  replicaCount: 1
  image:
    repository: my-nextjs-app
    tag: latest
    pullPolicy: IfNotPresent

  service:
    type: ClusterIP
    internalPort: 3000 # Next.js 앱이 실행되는 포트
    externalPort: 80   # 서비스가 노출하는 포트

  ingress:
    enabled: false
    host: chart-example.local
    path: /
    # annotations:
    #   kubernetes.io/ingress.class: nginx
    # tls:
    #   - secretName: chart-example-tls
    #     hosts:
    #       - chart-example.local

  config:
    apiUrl: "http://backend-service:8080/api" # 예시 API URL
    nodeEnv: "production"

  resources: {}
    # limits:
    #  cpu: 100m
    #  memory: 128Mi
    # requests:
    #  cpu: 100m
    #  memory: 128Mi

  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 80
    # targetMemoryUtilizationPercentage: 80
```

#### 고려 사항

*   **빌드 프로세스:** Next.js 애플리케이션은 빌드 단계(`next build`)가 필요합니다. Docker 이미지에는 빌드된 정적 파일과 실행 가능한 서버가 포함되어야 합니다.
*   **상태 비저장(Stateless):** 프론트엔드 서버는 일반적으로 상태를 가지지 않도록 설계하는 것이 좋습니다. 사용자 세션 등은 백엔드나 별도의 저장소에서 관리합니다.
*   **헬스 체크 엔드포인트:** 안정적인 운영을 위해 Next.js 애플리케이션에 간단한 _헬스 체크 API_ (예: `/api/health`)를 구현하는 것이 좋습니다.

이 섹션은 Next.js 애플리케이션을 Helm으로 배포하기 위한 기본적인 가이드라인을 제공합니다. 실제 환경과 요구사항에 맞게 각 설정을 조정해야 합니다.

### 2. Spring Boot 백엔드 서버

Spring Boot 애플리케이션을 Kubernetes에 배포하기 위한 Helm 차트 구성 요소는 일반적으로 다음과 같습니다.

#### 주요 Kubernetes 리소스

*   **Deployment (`templates/springboot-deployment.yaml`):**
    *   Spring Boot 애플리케이션 컨테이너를 관리합니다.
    *   `replicas`: 배포할 파드 수를 `values.yaml` 에서 정의 (`{{ .Values.springboot.replicaCount }}`).
    *   `image`: 사용할 Docker 이미지 (`{{ .Values.springboot.image.repository }}:{{ .Values.springboot.image.tag }}`).
    *   `ports`: 컨테이너가 노출할 포트 (예: `containerPort: {{ .Values.springboot.service.internalPort }}`). Spring Boot는 기본적으로 8080 포트를 사용합니다.
    *   `envFrom` 또는 `env`: `ConfigMap`이나 `Secret`으로부터 환경 변수를 주입합니다. (예: 데이터베이스 URL, 사용자 이름, 비밀번호, Spring Profiles 등).
        ```yaml
        env:
          - name: SPRING_PROFILES_ACTIVE
            value: {{ .Values.springboot.config.activeProfiles | quote }}
          - name: DATABASE_URL
            valueFrom:
              secretKeyRef:
                name: {{ include "mychart.fullname" . }}-db-credentials
                key: url
          # 추가 환경 변수들
        ```
    *   Liveness/Readiness 프로브: Spring Boot Actuator (`/actuator/health/liveness`, `/actuator/health/readiness`)를 활용하여 애플리케이션 상태를 확인합니다.
        ```yaml
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: {{ .Values.springboot.service.internalPort }}
          initialDelaySeconds: 60 # 애플리케이션 시작 시간을 고려하여 충분히 길게 설정
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: {{ .Values.springboot.service.internalPort }}
          initialDelaySeconds: 30
          periodSeconds: 10
        ```
    *   `resources`: CPU 및 메모리 요청/제한을 `values.yaml`에서 설정 (`{{ toYaml .Values.springboot.resources | nindent 12 }}`). JVM 기반 애플리케이션은 메모리 설정을 신중하게 해야 합니다.

*   **Service (`templates/springboot-service.yaml`):**
    *   Spring Boot 파드에 대한 안정적인 내부 네트워크 엔드포인트를 제공합니다. 일반적으로 API 서버는 `ClusterIP` 타입을 사용합니다.
    *   `type`: `{{ .Values.springboot.service.type }}` (보통 `ClusterIP`).
    *   `ports`: 서비스가 노출할 포트와 파드의 `targetPort`를 매핑합니다.
        ```yaml
        ports:
          - port: {{ .Values.springboot.service.externalPort }}
            targetPort: {{ .Values.springboot.service.internalPort }}
            protocol: TCP
            name: http
        ```
    *   `selector`: `{{- include "mychart.selectorLabels" (dict "root" . "component" "springboot") | nindent 6 }}`
    *   Deployment `spec.selector.matchLabels`는 `{{- include "mychart.selectorLabels" (dict "root" . "component" "springboot") | nindent 6 }}`를 사용하고, `spec.template.metadata.labels`는 `{{- include "mychart.labels" (dict "root" . "component" "springboot") | nindent 8 }}`를 포함해야 합니다.
    *   Deployment 예시 (`templates/springboot-deployment.yaml`):
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: {{ printf "%s-springboot" (include "mychart.fullname" .) }}
          labels:
            {{- include "mychart.labels" (dict "root" . "component" "springboot") | nindent 4 }}
        spec:
          replicas: {{ .Values.springboot.replicaCount }}
          selector:
            matchLabels:
              {{- include "mychart.selectorLabels" (dict "root" . "component" "springboot") | nindent 6 }}
          template:
            metadata:
              labels:
                {{- include "mychart.labels" (dict "root" . "component" "springboot") | nindent 8 }}
            spec:
              # ... (나머지 설정은 이전과 동일)
              containers:
                - name: springboot # {{ .Chart.Name }}-springboot 와 같이 할 수도 있음
                  image: "{{ .Values.springboot.image.repository }}:{{ .Values.springboot.image.tag }}"
                  # ... (ports, env, probes, resources 등)
        ```

*   **ConfigMap (`templates/springboot-configmap.yaml`):** (선택 사항)
    *   애플리케이션의 비민감성 설정을 관리합니다 (예: `application.properties` 또는 `application.yml`의 일부 내용, 활성 프로파일 등).
    *   Secret 이름 참조 시 `{{ printf "%s-db-credentials" (include "mychart.fullname" .) }}` 와 같이 fullname 기반으로 일관성 있게 작성합니다.
    *   `data`: 키-값 쌍으로 설정 내용을 정의하거나, 파일 전체를 값으로 포함할 수 있습니다.
        ```yaml
        data:
          SPRING_PROFILES_ACTIVE: {{ .Values.springboot.config.activeProfiles | quote }}
          # application.yml: |-
          #   server:
          #     port: {{ .Values.springboot.service.internalPort }}
          #   spring:
          #     application:
          #       name: my-spring-app
        ```
    *   Deployment에서 `envFrom` (ConfigMap 전체를 환경변수로) 또는 `volumes` 와 `volumeMounts` (파일로 마운트)를 통해 참조됩니다.

*   **Secret (`templates/springboot-secret.yaml`):** (선택 사항, 강력 권장)
    *   데이터베이스 연결 정보, API 키, 외부 서비스 자격 증명 등 민감한 데이터를 관리합니다.
    *   `type: Opaque` (기본값) 또는 특정 통합을 위한 다른 타입.
    *   `data`: 값들은 Base64로 인코딩되어 저장되어야 합니다. Helm에서는 `b64enc` 함수를 사용할 수 있으나, `stringData`를 사용하여 평문으로 값을 넣고 Helm이 자동으로 인코딩하도록 하는 것이 편리합니다.
        ```yaml
        # stringData를 사용하면 Helm이 자동으로 Base64 인코딩을 처리합니다.
        stringData:
          db_username: {{ .Values.springboot.secrets.databaseUsername | quote }}
          db_password: {{ .Values.springboot.secrets.databasePassword | quote }}
          api_key: {{ .Values.springboot.secrets.externalApiKey | quote }}
        ```
    *   Deployment에서 `envFrom` 또는 `env` (특정 키를 환경변수로) 또는 `volumes` 와 `volumeMounts` (파일로 마운트)를 통해 참조됩니다.

*   **HorizontalPodAutoscaler (HPA) (`templates/springboot-hpa.yaml`):** (선택 사항)
    *   CPU 또는 메모리 사용량, 또는 커스텀 메트릭에 따라 파드 수를 자동으로 조절합니다.
    *   `{{ if .Values.springboot.autoscaling.enabled }}` ... `{{ end }}` 블록으로 활성화 여부를 제어합니다.
    *   `scaleTargetRef`: 대상 `Deployment`를 지정합니다.
    *   `minReplicas`, `maxReplicas`, `metrics` (예: `targetCPUUtilizationPercentage`) 등을 `values.yaml`에서 설정합니다.

#### `values.yaml` 예시 (Spring Boot 관련 부분)

```yaml
# values.yaml

springboot:
  replicaCount: 2
  image:
    repository: my-springboot-app
    tag: 0.0.1
    pullPolicy: IfNotPresent

  service:
    type: ClusterIP
    internalPort: 8080 # Spring Boot 앱이 실행되는 포트
    externalPort: 8080 # 서비스가 노출하는 포트

  # Ingress는 일반적으로 API 게이트웨이 뒤에 위치하므로 직접 노출하지 않을 수 있습니다.
  # 필요시 Next.js와 유사하게 ingress 설정을 추가할 수 있습니다.
  # ingress:
  #   enabled: false

  config:
    activeProfiles: "kubernetes" # kubernetes 환경용 프로파일
    # 추가적인 비민감성 설정 값들

  secrets: # 실제 값은 CI/CD 파이프라인이나 외부 Secret 관리 도구를 통해 주입하는 것이 좋습니다.
    databaseUsername: "user"
    databasePassword: "password"
    externalApiKey: "supersecretapikey"

  resources:
    limits:
     cpu: "1" # 1 CPU core
     memory: "2Gi" # 2 GiB
    requests:
     cpu: "500m" # 0.5 CPU core
     memory: "1Gi" # 1 GiB

  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 5
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 75
      - type: Resource
        resource:
          name: memory
          target:
            type: Utilization
            averageUtilization: 75
```

#### 고려 사항

*   **Spring Boot Actuator:** 헬스 체크, 메트릭 수집 등을 위해 Actuator를 활성화하고 사용하는 것이 강력히 권장됩니다. (`management.endpoints.web.exposure.include=*` 또는 필요한 엔드포인트만 노출)
*   **JVM 메모리 설정:** 컨테이너 환경에서는 JVM 힙 메모리(`-Xms`, `-Xmx`) 및 기타 메모리 관련 설정을 컨테이너의 메모리 제한에 맞게 신중하게 조정해야 합니다. `JAVA_TOOL_OPTIONS` 환경 변수를 통해 설정할 수 있습니다.
*   **설정 외부화:** `ConfigMap`과 `Secret`을 사용하여 애플리케이션 설정을 외부화하고, Spring Profiles를 활용하여 환경별 설정을 관리합니다.
*   **데이터베이스 마이그레이션:** Flyway나 Liquibase와 같은 도구를 사용하는 경우, 초기화 작업이나 마이그레이션 스크립트 실행을 위한 `Job` 또는 `initContainers`를 고려할 수 있습니다.

이 섹션은 Spring Boot 애플리케이션을 Helm으로 배포하기 위한 기본적인 가이드라인을 제공합니다. 실제 환경과 요구사항에 맞게 각 설정을 조정해야 합니다.

### 3. Socket.io 웹소켓 서버

Socket.io (일반적으로 Node.js 기반) 웹소켓 서버를 Kubernetes에 배포하기 위한 Helm 차트 구성 요소는 다음과 유사하며, 웹소켓의 특성을 고려한 몇 가지 추가 사항이 있을 수 있습니다.

#### 주요 Kubernetes 리소스

*   **Deployment (`templates/socketio-deployment.yaml`):**
    *   Socket.io 애플리케이션 컨테이너를 관리합니다.
    *   `replicas`: 배포할 파드 수 (`{{ .Values.socketio.replicaCount }}`). 웹소켓 서버의 경우 여러 인스턴스 간의 상태 공유 및 라우팅 방식을 고려해야 합니다 (예: Redis adapter 사용).
    *   `image`: 사용할 Docker 이미지 (`{{ .Values.socketio.image.repository }}:{{ .Values.socketio.image.tag }}`).
    *   `ports`: 컨테이너가 노출할 포트 (예: `containerPort: {{ .Values.socketio.service.internalPort }}`).
    *   `envFrom` 또는 `env`: `ConfigMap`이나 `Secret`으로부터 환경 변수를 주입합니다. (예: Redis 연결 정보, CORS 설정 등).
        ```yaml
        env:
          - name: REDIS_HOST
            value: {{ .Values.socketio.config.redisHost | quote }}
          - name: REDIS_PORT
            value: {{ .Values.socketio.config.redisPort | quote }}
          # CORS_ORIGIN, 기타 설정 등
        ```
    *   Liveness/Readiness 프로브: 간단한 HTTP 헬스 체크 엔드포인트를 애플리케이션에 구현하여 사용합니다.
        ```yaml
        livenessProbe:
          httpGet:
            path: /health # 예시 경로, 실제 헬스 체크 경로로 변경
            port: {{ .Values.socketio.service.internalPort }}
          initialDelaySeconds: 30
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /health # 예시 경로
            port: {{ .Values.socketio.service.internalPort }}
          initialDelaySeconds: 15
          periodSeconds: 10
        ```
    *   `resources`: CPU 및 메모리 요청/제한 (`{{ toYaml .Values.socketio.resources | nindent 12 }}`).

*   **Service (`templates/socketio-service.yaml`):**
    *   Socket.io 파드에 대한 안정적인 네트워크 엔드포인트를 제공합니다.
    *   `type`: `ClusterIP`가 일반적이며, 외부 노출은 Ingress를 통해 관리합니다.
    *   `ports`: 서비스가 노출할 포트와 파드의 `targetPort`를 매핑합니다.
        ```yaml
        ports:
          - port: {{ .Values.socketio.service.externalPort }}
            targetPort: {{ .Values.socketio.service.internalPort }}
            protocol: TCP
            name: websocket
        ```
    *   `selector`: `{{- include "mychart.selectorLabels" (dict "root" . "component" "socketio") | nindent 6 }}`
    *   Deployment `spec.selector.matchLabels`는 `{{- include "mychart.selectorLabels" (dict "root" . "component" "socketio") | nindent 6 }}`를 사용하고, `spec.template.metadata.labels`는 `{{- include "mychart.labels" (dict "root" . "component" "socketio") | nindent 8 }}`를 포함해야 합니다.
    *   Deployment 예시 (`templates/socketio-deployment.yaml`):
        ```yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: {{ printf "%s-socketio" (include "mychart.fullname" .) }}
          labels:
            {{- include "mychart.labels" (dict "root" . "component" "socketio") | nindent 4 }}
        spec:
          replicas: {{ .Values.socketio.replicaCount }}
          selector:
            matchLabels:
              {{- include "mychart.selectorLabels" (dict "root" . "component" "socketio") | nindent 6 }}
          template:
            metadata:
              labels:
                {{- include "mychart.labels" (dict "root" . "component" "socketio") | nindent 8 }}
            spec:
              # ... (나머지 설정은 이전과 동일)
              containers:
                - name: socketio # {{ .Chart.Name }}-socketio 와 같이 할 수도 있음
                  image: "{{ .Values.socketio.image.repository }}:{{ .Values.socketio.image.tag }}"
                  # ... (ports, env, probes, resources 등)
        ```

*   **Ingress (`templates/socketio-ingress.yaml`):** (외부 노출 시 필수)
    *   웹소켓 트래픽을 올바르게 라우팅하기 위한 Ingress 설정을 정의합니다. 웹소켓은 긴 연결 시간을 가지므로, Ingress 컨트롤러의 타임아웃 설정 및 웹소켓 지원 여부를 확인해야 합니다 (예: Nginx Ingress Controller의 경우 특정 어노테이션 필요).
    *   **참고:** 아래 어노테이션은 Nginx Ingress Controller에 대한 예시입니다. 사용 중인 Ingress 컨트롤러(예: Traefik, HAProxy Ingress, GKE Ingress 등)의 공식 문서를 참조하여 웹소켓 지원을 위한 정확한 어노테이션이나 설정을 확인해야 합니다.
        *   **Nginx Ingress (ingress-nginx 커뮤니티 버전):** 최신 버전은 웹소켓을 별도 설정 없이 잘 지원하는 편이지만, 타임아웃 등의 설정은 필요할 수 있습니다. (예: `nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"`, `nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"`) 일부 오래된 버전이나 특정 기능에는 `nginx.ingress.kubernetes.io/websocket: "true"` 어노테이션이 사용될 수 있습니다.
        *   **Nginx Inc. Ingress Controller:** `nginx.org/websocket-services: "<service-name>"` 와 같은 어노테이션을 사용합니다.
        *   **Traefik:** 일반적으로 웹소켓을 자동으로 지원하지만, 특정 경로에 대한 라우터 설정이나 미들웨어(예: `buffering`, `circuitBreaker`) 조정이 필요할 수 있습니다. 관련 문서를 확인하십시오.
    *   `{{ if .Values.socketio.ingress.enabled }}` ... `{{ end }}` 블록으로 활성화 여부를 제어합니다.
    *   `annotations`: 웹소켓을 지원하기 위한 Ingress 컨트롤러별 어노테이션을 추가합니다.
        ```yaml
        # 예시: Nginx Ingress Controller 사용 시
        # metadata:
        #   annotations:
        #     nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
        #     nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
        #     # nginx.org/websocket-services: "{{ printf "%s-socketio" (include "mychart.fullname" .) }}" # Nginx Inc. 컨트롤러용
        #     # nginx.ingress.kubernetes.io/websocket: "true" # 일부 커뮤니티 Nginx Ingress 버전용
        #     # 기타 필요한 Ingress 컨트롤러별 웹소켓 관련 어노테이션
        ```
    *   `hosts` 및 `paths` 설정은 Next.js와 유사하게 구성합니다. `pathType: ImplementationSpecific` 또는 `Prefix` 사용.
        ```yaml
        paths:
          - path: {{ .Values.socketio.ingress.path }} # 예: /socket.io
            pathType: ImplementationSpecific # 또는 Prefix
            backend:
              service:
                name: {{ printf "%s-socketio" (include "mychart.fullname" .) }} # fullname-socketio
                port:
                  number: {{ .Values.socketio.service.externalPort }}
        ```
    *   **세션 고정성 (Session Affinity / Sticky Sessions):**
        클라이언트가 항상 동일한 파드에 연결되어야 하는 경우 (특히 여러 Socket.io 인스턴스 간에 Redis와 같은 어댑터를 사용하지 않는 경우), Ingress 컨트롤러 수준에서 세션 고정성 (Session Affinity / Sticky Sessions)을 설정해야 할 수 있습니다.
        ```yaml
        # 예시: Nginx Ingress Controller에서 쿠키 기반 세션 고정성
        # metadata:
        #   annotations:
        #     nginx.ingress.kubernetes.io/affinity: "cookie"
        #     nginx.ingress.kubernetes.io/session-cookie-name: "socketio_route"
        #     nginx.ingress.kubernetes.io/session-cookie-hash: "sha1"
        #     nginx.ingress.kubernetes.io/session-cookie-expires: "172800" # 초 단위
        #     nginx.ingress.kubernetes.io/session-cookie-max-age: "172800" # 초 단위
        ```

*   **ConfigMap (`templates/socketio-configmap.yaml`):** (선택 사항)
    *   애플리케이션 실행에 필요한 환경 변수나 설정을 관리합니다 (예: Redis 호스트, 포트, CORS 설정 등).
        ```yaml
        data:
          REDIS_HOST: {{ .Values.socketio.config.redisHost | quote }}
          REDIS_PORT: {{ .Values.socketio.config.redisPort | quote }}
          CORS_ORIGIN: {{ .Values.socketio.config.corsOrigin | quote }}
        ```

*   **HorizontalPodAutoscaler (HPA) (`templates/socketio-hpa.yaml`):** (선택 사항)
    *   CPU 또는 메모리 사용량에 따라 파드 수를 자동으로 조절합니다. 웹소켓 연결 수에 기반한 커스텀 메트릭을 사용할 수도 있습니다 (설정이 더 복잡함).
    *   `{{ if .Values.socketio.autoscaling.enabled }}` ... `{{ end }}` 블록으로 활성화 여부를 제어합니다.
    *   설정은 Next.js 또는 Spring Boot HPA와 유사합니다.

#### `values.yaml` 예시 (Socket.io 관련 부분)

```yaml
# values.yaml

socketio:
  replicaCount: 2 # Redis adapter 사용 시 여러 복제본 가능
  image:
    repository: my-socketio-app
    tag: latest
    pullPolicy: IfNotPresent

  service:
    type: ClusterIP
    internalPort: 3001 # Socket.io 앱이 실행되는 포트
    externalPort: 80   # 서비스가 외부에 노출하는 포트 (Ingress를 통해)

  ingress:
    enabled: true
    host: socket.example.local
    path: /socket.io # Socket.io 클라이언트가 연결하는 기본 경로
    # pathType: ImplementationSpecific # Ingress 컨트롤러에 따라
    annotations: # 사용하는 Ingress 컨트롤러에 맞게 수정
      # nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
      # nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
      # nginx.ingress.kubernetes.io/rewrite-target: / # 경로 재작성이 필요한 경우
      # nginx.ingress.kubernetes.io/websocket: "true" # 일부 Nginx Ingress 버전
    # tls:
    #   - secretName: socket-example-tls
    #     hosts:
    #       - socket.example.local
    # affinity: # 세션 고정성이 필요한 경우
    #   enabled: false
    #   type: cookie # 예시
    #   cookieName: "socket_io_affinity"

  config:
    redisHost: "redis-headless-service" # Redis 서비스 DNS 이름
    redisPort: "6379"
    corsOrigin: "http://frontend.example.local"

  resources: {}
    # limits:
    #  cpu: 100m
    #  memory: 128Mi
    # requests:
    #  cpu: 100m
    #  memory: 128Mi

  autoscaling:
    enabled: false
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 80
```

#### 고려 사항

*   **웹소켓과 Ingress:** 사용하는 Ingress 컨트롤러(Nginx, Traefik, HAProxy 등)가 웹소켓을 올바르게 지원하고, 필요한 타임아웃 및 버퍼링 설정이 되어 있는지 확인해야 합니다. 관련 어노테이션이 중요합니다.
*   **확장성과 상태 관리:** 여러 Socket.io 인스턴스를 실행할 경우, 모든 클라이언트가 어떤 인스턴스에 연결되든 메시지를 주고받을 수 있도록 Socket.io 어댑터(예: `socket.io-redis`, `socket.io-postgres` 등)를 사용해야 합니다. 이 경우, 해당 백엔드 저장소(예: Redis)도 클러스터 내에 배포되거나 외부에서 접근 가능해야 합니다.
*   **세션 고정성 (Sticky Sessions):** Redis 어댑터 등을 사용하지 않고 단일 서버 내에서만 상태를 관리하는 간단한 구성의 경우, 클라이언트가 항상 동일한 파드에 연결되도록 Ingress 레벨에서 세션 고정성을 설정해야 할 수 있습니다. 하지만 이는 확장성에 불리하므로 어댑터 사용이 권장됩니다.
*   **헬스 체크:** 웹소켓 서버 자체는 HTTP가 아닐 수 있으므로, 헬스 체크를 위한 간단한 HTTP 엔드포인트(예: `/health`)를 Socket.io 애플리케이션에 추가하는 것이 좋습니다.

이 섹션은 Socket.io 웹소켓 서버를 Helm으로 배포하기 위한 기본적인 가이드라인입니다. 특정 요구사항과 환경에 맞춰 설정을 커스터마이징해야 합니다.

### 4. Kafka 서버

Apache Kafka 클러스터를 Kubernetes에 배포하는 것은 복잡할 수 있으며, 일반적으로는 이미 잘 만들어진 공식 Helm 차트나 Bitnami와 같은 신뢰할 수 있는 제공업체의 차트를 사용하는 것이 권장됩니다. 하지만 직접 구성해야 할 경우 고려해야 할 주요 요소는 다음과 같습니다. Kafka는 상태를 저장하므로 `StatefulSet`을 사용합니다.

#### 주요 Kubernetes 리소스 (자체 구성 시)

*   **StatefulSet (`templates/kafka-statefulset.yaml`):**
    *   Kafka 브로커 파드를 관리합니다. 각 파드는 고유하고 안정적인 네트워크 식별자와 스토리지를 갖습니다.
    *   `serviceName`: 파드들의 DNS 이름을 제어하는 헤드리스 서비스의 이름 (`{{ include "mychart.fullname" . }}-kafka-headless`).
    *   `replicas`: Kafka 브로커 수 (`{{ .Values.kafka.replicaCount }}`).
    *   `podManagementPolicy: Parallel` 또는 `OrderedReady`: 파드 생성/삭제 정책. Kafka는 일반적으로 `Parallel`을 사용할 수 있습니다.
    *   `updateStrategy: RollingUpdate` (또는 `OnDelete`).
    *   `image`: 사용할 Kafka Docker 이미지 (`{{ .Values.kafka.image.repository }}:{{ .Values.kafka.image.tag }}`). (예: `apache/kafka`, `bitnami/kafka`, `confluentinc/cp-kafka`)
    *   `ports`: Kafka 브로커 포트 (내부 클라이언트용: 9092, 외부용 리스너 포트 등).
    *   `env`: Kafka 브로커 설정 (브로커 ID, Zookeeper 연결 주소, 리스너 설정, 로그 디렉토리 등). 브로커 ID는 파드 이름이나 순서를 기반으로 동적으로 설정될 수 있습니다.
        ```yaml
        env:
          - name: KAFKA_BROKER_ID
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
            # 중요: 'metadata.name' (예: "kafka-0")에서 숫자 ID "0"을 추출하려면
            #       실제로는 파드 시작 시 실행되는 스크립트나 initContainer가 필요합니다.
            #       Helm 템플릿만으로는 이 문자열 처리가 직접적으로 불가능합니다.
            #       (예: `command`나 `args`에서 쉘 스크립트를 사용하여 KAFKA_BROKER_ID를 설정)
            #       일반적인 Kafka Helm 차트들은 이러한 로직을 포함하고 있습니다.
          - name: KAFKA_ZOOKEEPER_CONNECT
            value: {{ .Values.kafka.config.zookeeperConnect | quote }}
          - name: KAFKA_LISTENERS # 내부 리스너
            value: "INTERNAL://:9092"
          - name: KAFKA_ADVERTISED_LISTENERS # 파드가 자신을 알리는 주소
            # value: "INTERNAL://$(POD_IP):9092" # POD_IP는 downwardAPI로 주입
            # 또는 각 파드별로 고유한 DNS 이름을 사용 (StatefulSet의 장점)
            # 예: INTERNAL://kafka-0.kafka-headless.default.svc.cluster.local:9092
          - name: KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
            value: "INTERNAL:PLAINTEXT"
          - name: KAFKA_INTER_BROKER_LISTENER_NAME
            value: "INTERNAL"
          - name: KAFKA_LOG_DIRS
            value: "/var/lib/kafka/data/logs" # Persistent Volume 경로
          # 기타 필요한 Kafka 설정들
        ```
    *   `volumeMounts`: 데이터 저장을 위한 영구 볼륨 마운트.
    *   Liveness/Readiness 프로브: Kafka는 JMX 메트릭을 통해 상태를 확인할 수 있지만, 간단하게는 TCP 포트 연결을 확인할 수 있습니다.
        ```yaml
        livenessProbe:
          tcpSocket:
            port: 9092 # 내부 리스너 포트
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 9092
          initialDelaySeconds: 15
          periodSeconds: 5
        ```
    *   `resources`: CPU 및 메모리 요청/제한 (`{{ toYaml .Values.kafka.resources | nindent 12 }}`).

*   **VolumeClaimTemplates (StatefulSet 내부에 정의):**
    *   각 Kafka 파드에 대한 `PersistentVolumeClaim`을 동적으로 생성합니다.
        ```yaml
        volumeClaimTemplates:
          - metadata:
              name: kafka-data
            spec:
              accessModes: [ "ReadWriteOnce" ]
              storageClassName: {{ .Values.kafka.persistence.storageClassName | quote }} # 스토리지 클래스
              resources:
                requests:
                  storage: {{ .Values.kafka.persistence.size | quote }} # 스토리지 크기
        ```

*   **Service (Headless) (`templates/kafka-headless-service.yaml`):**
    *   `StatefulSet`의 각 파드에 대한 고유한 DNS 이름을 제공합니다 (예: `kafka-0.kafka-headless.namespace.svc.cluster.local`). Kafka 브로커들이 서로를 발견하고 클라이언트가 특정 파티션 리더에 직접 연결하는 데 사용됩니다.
    *   `clusterIP: None`.
    *   `selector`: `{{- include "mychart.selectorLabels" (dict "root" . "component" "kafka") | nindent 6 }}`
    *   StatefulSet `spec.selector.matchLabels`는 `{{- include "mychart.selectorLabels" (dict "root" . "component" "kafka") | nindent 6 }}`를 사용하고, `spec.template.metadata.labels`는 `{{- include "mychart.labels" (dict "root" . "component" "kafka") | nindent 8 }}`를 포함해야 합니다.
    *   StatefulSet 예시 (`templates/kafka-statefulset.yaml`):
        ```yaml
        apiVersion: apps/v1
        kind: StatefulSet
        metadata:
          name: {{ printf "%s-kafka" (include "mychart.fullname" .) }} # 컴포넌트명 포함 권장
          labels:
            {{- include "mychart.labels" (dict "root" . "component" "kafka") | nindent 4 }}
        spec:
          serviceName: {{ printf "%s-kafka-headless" (include "mychart.fullname" .) }}
          replicas: {{ .Values.kafka.replicaCount }}
          selector:
            matchLabels:
              {{- include "mychart.selectorLabels" (dict "root" . "component" "kafka") | nindent 6 }}
          template:
            metadata:
              labels:
                {{- include "mychart.labels" (dict "root" . "component" "kafka") | nindent 8 }}
            spec:
              # ... (나머지 설정은 이전과 동일)
              containers:
                - name: kafka # {{ .Chart.Name }}-kafka 와 같이 할 수도 있음
                  image: "{{ .Values.kafka.image.repository }}:{{ .Values.kafka.image.tag }}"
                  # ... (env, ports, probes, volumeMounts, resources 등)
          # volumeClaimTemplates 등
        ```
    *   `ports`: 내부 리스너 포트 (예: 9092).

*   **Service (ClusterIP or LoadBalancer) (`templates/kafka-service.yaml`):** (선택 사항)
    *   클러스터 내부 또는 외부의 클라이언트가 Kafka 클러스터에 접속하기 위한 단일 진입점(bootstrap server)을 제공합니다.
    *   `type`: `ClusterIP` (내부용) 또는 `LoadBalancer` (외부용). 외부 노출 시에는 보안 및 리스너 구성에 매우 신중해야 합니다.
    *   `selector`: `{{- include "mychart.selectorLabels" (dict "root" . "component" "kafka") | nindent 6 }}`
    *   `ports`: 외부에서 접속할 포트.

*   **ConfigMap (`templates/kafka-configmap.yaml`):**
    *   Kafka 브로커의 주요 설정 (`server.properties` 내용)을 관리합니다.
    *   `data`: `log.retention.hours`, `default.replication.factor` 등.
        ```yaml
        data:
          KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
          KAFKA_DEFAULT_REPLICATION_FACTOR: {{ .Values.kafka.config.defaultReplicationFactor | quote }}
          KAFKA_NUM_PARTITIONS: {{ .Values.kafka.config.numPartitions | quote }}
          # 기타 server.properties 설정들
        ```
    *   StatefulSet에서 환경 변수로 참조되거나, 설정 파일을 볼륨으로 마운트할 수 있습니다.

*   **Zookeeper 의존성:**
    *   Kafka는 Zookeeper가 필요합니다. Zookeeper는 별도의 Helm 차트 (예: Bitnami Zookeeper 차트)로 배포하고 Kafka 차트에서 해당 서비스 주소를 참조하는 것이 일반적입니다.
    *   `values.yaml`에 Zookeeper 서비스 주소를 설정하는 항목이 있어야 합니다. (`{{ .Values.kafka.config.zookeeperConnect }}`)

#### `values.yaml` 예시 (Kafka 관련 부분)

```yaml
# values.yaml

kafka:
  replicaCount: 3 # 최소 3개의 브로커 권장
  image:
    repository: bitnami/kafka # 예시 이미지
    tag: "3.5" # Kafka 버전
    pullPolicy: IfNotPresent

  # Zookeeper는 별도 차트로 배포했다고 가정
  # zookeeper:
  #   enabled: false

  config:
    zookeeperConnect: "zookeeper-headless:2181" # Zookeeper 서비스 주소
    defaultReplicationFactor: "3" # replicaCount와 일치하거나 작아야 함
    numPartitions: "1"
    # 추가 Kafka 설정들 (server.properties)

  persistence:
    enabled: true
    storageClassName: "standard" # 사용하는 스토리지 클래스
    size: "10Gi" # 브로커당 스토리지 크기

  # 외부 접근을 위한 리스너 설정은 복잡하며, Ingress, NodePort, LoadBalancer 등 다양한 방법과 보안 고려사항이 있습니다.
  # externalAccess:
  #   enabled: false
  #   service:
  #     type: LoadBalancer
  #     port: 9094

  resources: {}
    # limits:
    #  cpu: "1"
    #  memory: "4Gi" # Kafka는 메모리를 많이 사용합니다.
    # requests:
    #  cpu: "500m"
    #  memory: "2Gi"
```

#### 고려 사항

*   **Zookeeper:** Kafka는 Zookeeper에 강하게 의존합니다. 안정적인 Zookeeper 클러스터가 선행되어야 합니다. 최신 Kafka 버전(KRaft 모드)은 Zookeeper 없이 실행될 수 있지만, 아직 널리 사용되지는 않으며 구성이 다릅니다.
*   **상태 저장 애플리케이션 관리:** `StatefulSet`은 파드의 순서, 고유 ID, 영구 스토리지를 보장하지만, 업그레이드나 장애 조치 시 신중한 관리가 필요합니다.
*   **리스너 구성:** Kafka 브로커가 클러스터 내부 및 외부 클라이언트와 통신하는 방법을 정의하는 리스너(`listeners`, `advertised.listeners`) 설정은 매우 중요하고 복잡할 수 있습니다. Kubernetes 환경에서는 파드의 IP가 동적이므로 서비스 디스커버리 메커니즘을 잘 활용해야 합니다.
*   **데이터 내구성 및 복제:** `default.replication.factor`와 토픽별 복제 설정을 통해 데이터 내구성을 확보해야 합니다. 브로커 수와 복제 계수를 고려하여 설정합니다.
*   **보안:** SASL, SSL/TLS를 사용한 인증 및 암호화 설정을 고려해야 하며, 이는 Helm 차트 구성을 더욱 복잡하게 만듭니다.
*   **모니터링:** JMX Exporter와 Prometheus/Grafana를 사용하여 Kafka 클러스터의 주요 메트릭(처리량, 지연 시간, 디스크 사용량 등)을 모니터링하는 것이 필수적입니다.
*   **기존 Helm 차트 활용:** Strimzi, Bitnami, Confluent 등에서 제공하는 Kafka Operator나 Helm 차트는 이러한 복잡성을 많이 해결해주므로, 직접 모든 것을 구성하기보다는 이러한 차트를 커스터마이징하는 것을 우선적으로 고려하는 것이 좋습니다.

이 섹션은 Kafka 클러스터를 Helm으로 배포하기 위한 기본적인 구성 요소와 고려 사항을 설명합니다. 실제 운영 환경에서는 훨씬 더 많은 설정과 세심한 주의가 필요합니다.

### 5. MySQL DB 서버

MySQL 데이터베이스를 Kubernetes에 배포하는 것은 상태 저장 애플리케이션의 특성상 신중한 접근이 필요합니다. Kafka와 마찬가지로, Bitnami와 같은 신뢰할 수 있는 제공업체의 Helm 차트를 사용하거나 Kubernetes Operator를 활용하는 것이 일반적으로 권장됩니다. 직접 구성할 경우 다음은 주요 고려 사항입니다.

#### 주요 Kubernetes 리소스 (자체 구성 시)

*   **StatefulSet (`templates/mysql-statefulset.yaml`):**
    *   MySQL 파드를 관리합니다. 각 파드는 고유한 네트워크 식별자와 영구 스토리지를 갖습니다.
    *   `serviceName`: 파드들의 DNS 이름을 제어하는 헤드리스 서비스의 이름 (`{{ include "mychart.fullname" . }}-mysql-headless`).
    *   `replicas`: MySQL 인스턴스 수 (`{{ .Values.mysql.replicaCount }}`). 단일 인스턴스(replicaCount: 1) 또는 주/복제(Primary/Replica) 구성을 고려할 수 있습니다. 복제 구성은 훨씬 복잡합니다.
    *   `image`: 사용할 MySQL Docker 이미지 (`{{ .Values.mysql.image.repository }}:{{ .Values.mysql.image.tag }}`).
    *   `ports`: MySQL 포트 (기본값: 3306).
    *   `env`: MySQL 설정 (루트 비밀번호, 사용자 데이터베이스, 사용자, 사용자 비밀번호 등). **비밀번호는 반드시 Secret에서 참조해야 합니다.**
        ```yaml
        env:
          - name: MYSQL_ROOT_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ printf "%s-mysql-secret" (include "mychart.fullname" .) }}
                key: mysql-root-password
          - name: MYSQL_DATABASE
            value: {{ .Values.mysql.config.database | quote }}
          - name: MYSQL_USER # 이 환경변수는 아래 readinessProbe에서 사용됩니다.
            value: {{ .Values.mysql.config.user | quote }}
          - name: MYSQL_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ printf "%s-mysql-secret" (include "mychart.fullname" .) }}
                key: mysql-password
          # 기타 MySQL 환경 변수 (예: character_set_server, collation_server)
        ```
    *   `volumeMounts`: 데이터 저장을 위한 영구 볼륨 마운트 (`/var/lib/mysql`).
    *   Liveness/Readiness 프로브: `mysqladmin ping` 명령이나 TCP 포트 연결을 확인할 수 있습니다.
        ```yaml
        livenessProbe:
          exec:
            command: ["mysqladmin", "ping", "-h", "127.0.0.1", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
          initialDelaySeconds: 45
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command: ["mysql", "-h", "127.0.0.1", "-u${MYSQL_USER}", "-p${MYSQL_PASSWORD}", "-e", "SELECT 1"]
          initialDelaySeconds: 30
          periodSeconds: 15
          timeoutSeconds: 5
        ```
    *   `resources`: CPU 및 메모리 요청/제한 (`{{ toYaml .Values.mysql.resources | nindent 12 }}`). 데이터베이스는 I/O 성능도 중요합니다.

*   **VolumeClaimTemplates (StatefulSet 내부에 정의):**
    *   각 MySQL 파드에 대한 `PersistentVolumeClaim`을 동적으로 생성합니다.
        ```yaml
        volumeClaimTemplates:
          - metadata:
              name: mysql-data
            spec:
              accessModes: [ "ReadWriteOnce" ] # 대부분의 스토리지 유형에 적합
              storageClassName: {{ .Values.mysql.persistence.storageClassName | quote }}
              resources:
                requests:
                  storage: {{ .Values.mysql.persistence.size | quote }}
        ```

*   **Service (Headless) (`templates/mysql-headless-service.yaml`):** (선택 사항, 복제 구성 시 유용)
    *   `StatefulSet`의 각 파드에 대한 고유한 DNS 이름을 제공합니다.
    *   `clusterIP: None`.
    *   `selector`: `{{- include "mychart.selectorLabels" (dict "root" . "component" "mysql") | nindent 6 }}`
    *   StatefulSet `spec.selector.matchLabels`는 `{{- include "mychart.selectorLabels" (dict "root" . "component" "mysql") | nindent 6 }}`를 사용하고, `spec.template.metadata.labels`는 `{{- include "mychart.labels" (dict "root" . "component" "mysql") | nindent 8 }}`를 포함해야 합니다.
    *   StatefulSet 예시 (`templates/mysql-statefulset.yaml`):
        ```yaml
        apiVersion: apps/v1
        kind: StatefulSet
        metadata:
          name: {{ printf "%s-mysql" (include "mychart.fullname" .) }} # 컴포넌트명 포함 권장
          labels:
            {{- include "mychart.labels" (dict "root" . "component" "mysql") | nindent 4 }}
        spec:
          serviceName: {{ printf "%s-mysql-headless" (include "mychart.fullname" .) }}
          replicas: {{ .Values.mysql.replicaCount }}
          selector:
            matchLabels:
              {{- include "mychart.selectorLabels" (dict "root" . "component" "mysql") | nindent 6 }}
          template:
            metadata:
              labels:
                {{- include "mychart.labels" (dict "root" . "component" "mysql") | nindent 8 }}
            spec:
              # ... (나머지 설정은 이전과 동일)
              containers:
                - name: mysql # {{ .Chart.Name }}-mysql 와 같이 할 수도 있음
                  image: "{{ .Values.mysql.image.repository }}:{{ .Values.mysql.image.tag }}"
                  # ... (env, ports, probes, volumeMounts, resources 등)
          # volumeClaimTemplates 등
        ```

*   **Service (ClusterIP) (`templates/mysql-service.yaml`):**
    *   클러스터 내부의 애플리케이션들이 MySQL에 접속하기 위한 안정적인 단일 엔드포인트를 제공합니다.
    *   `type: ClusterIP` (일반적). 외부 직접 노출은 권장되지 않습니다.
    *   `selector`: `{{- include "mychart.selectorLabels" (dict "root" . "component" "mysql") | nindent 6 }}` (주 인스턴스를 가리키도록 레이블 셀렉터 조정 필요 가능).
    *   `ports`: MySQL 포트 (3306).

*   **Secret (`templates/mysql-secret.yaml`):**
    *   MySQL 루트 비밀번호 및 애플리케이션 사용자 비밀번호를 안전하게 저장합니다. Secret 이름은 `{{ printf "%s-mysql-secret" (include "mychart.fullname" .) }}` 와 같이 일관성 있게 생성합니다.
    *   `stringData`를 사용하여 Helm이 자동으로 Base64 인코딩하도록 하는 것이 편리합니다.
        ```yaml
        # stringData 사용 시 Helm이 자동 Base64 인코딩
        stringData:
          mysql-root-password: {{ .Values.mysql.secrets.rootPassword | quote }}
          mysql-password: {{ .Values.mysql.secrets.userPassword | quote }}
          # 필요시 추가적인 비밀 값들
        ```
    *   StatefulSet의 환경 변수에서 참조됩니다.

*   **ConfigMap (`templates/mysql-configmap.yaml`):** (선택 사항)
    *   MySQL의 커스텀 설정 (`my.cnf` 또는 `mysqld.cnf` 내용)을 관리합니다.
    *   `data`: `max_connections`, `character_set_server`, `collation_server` 등.
        ```yaml
        data:
          my.cnf: |-
            [mysqld]
            max_connections = {{ .Values.mysql.config.maxConnections | default "151" }}
            character-set-server = {{ .Values.mysql.config.characterSetServer | default "utf8mb4" }}
            collation-server = {{ .Values.mysql.config.collationServer | default "utf8mb4_unicode_ci" }}
        ```
    *   StatefulSet에서 `volumes` 와 `volumeMounts`를 통해 설정 파일을 특정 경로(예: `/etc/mysql/conf.d/custom.cnf`)에 마운트할 수 있습니다.

#### `values.yaml` 예시 (MySQL 관련 부분)

```yaml
# values.yaml

mysql:
  replicaCount: 1 # 단일 인스턴스. 복제 구성은 더 복잡함.
  image:
    repository: mysql
    tag: "8.0" # MySQL 버전
    pullPolicy: IfNotPresent

  config:
    database: "mydatabase"
    user: "myuser"
    # maxConnections: "151"
    # characterSetServer: "utf8mb4"
    # collationServer: "utf8mb4_unicode_ci"

  # 비밀번호는 values.yaml에 직접 저장하는 대신,
  # helm install/upgrade 시 --set 옵션이나 secrets.yaml 파일을 통해 주입하거나,
  # CI/CD 파이프라인에서 관리하는 것이 보안상 좋습니다.
  secrets:
    rootPassword: "verysecretrootpassword" # 개발용. 프로덕션에서는 외부 주입 권장.
    userPassword: "verysecretuserpassword" # 개발용. 프로덕션에서는 외부 주입 권장.

  persistence:
    enabled: true
    storageClassName: "standard" # 사용하는 스토리지 클래스
    size: "8Gi" # 데이터베이스 크기

  # 서비스 타입은 ClusterIP가 일반적입니다.
  service:
    type: ClusterIP
    port: 3306

  resources: {}
    # limits:
    #  cpu: "1"
    #  memory: "2Gi"
    # requests:
    #  cpu: "500m"
    #  memory: "1Gi"
```

#### 고려 사항

*   **데이터 백업 및 복원:** Kubernetes에서 데이터베이스를 운영할 때 가장 중요한 고려 사항 중 하나입니다. `PersistentVolume`의 스냅샷 기능, 또는 `mysqldump`와 같은 도구를 사용한 정기적인 백업 및 복원 절차를 반드시 마련해야 합니다. 이를 위한 `CronJob` 등을 Helm 차트에 포함할 수 있습니다.
*   **보안:** 루트 비밀번호 및 사용자 비밀번호는 `Secret`을 통해 안전하게 관리하고, 네트워크 정책(NetworkPolicy)을 사용하여 허가된 애플리케이션만 MySQL에 접근하도록 제한하는 것이 좋습니다. MySQL 자체의 보안 설정(사용자 권한 등)도 중요합니다.
*   **영구 스토리지 선택:** 사용하는 `StorageClass`가 데이터베이스 워크로드에 적합한 성능과 안정성을 제공하는지 확인해야 합니다 (예: SSD 기반 스토리지).
*   **고가용성 및 복제:** 단일 인스턴스로는 고가용성을 확보할 수 없습니다. 주/복제(Primary/Replica) 또는 클러스터형 솔루션(예: Percona XtraDB Cluster, MySQL InnoDB Cluster)을 고려해야 하며, 이는 Helm 차트 구성을 훨씬 복잡하게 만듭니다. 이 경우 Operator 사용이 강력히 권장됩니다.
*   **초기화 스크립트:** 데이터베이스 스키마 생성, 초기 데이터 입력 등을 위해 `initContainers` 또는 `Job`을 사용하여 초기화 스크립트를 실행할 수 있습니다.
*   **모니터링:** MySQL Exporter와 Prometheus/Grafana를 사용하여 데이터베이스 성능(쿼리 속도, 연결 수, 버퍼 풀 사용량 등)을 모니터링해야 합니다.
*   **기존 Helm 차트 및 Operator 활용:** Bitnami MySQL 차트, Percona MySQL Operator, Oracle MySQL Operator 등은 Kubernetes에서 MySQL을 운영하는 데 필요한 많은 기능(백업, 복제, 모니터링 통합 등)을 제공하므로, 직접 모든 것을 구성하는 것보다 우선적으로 고려하는 것이 좋습니다.

이 섹션은 MySQL 데이터베이스를 Helm으로 배포하기 위한 기본적인 구성 요소와 고려 사항을 설명합니다. 데이터베이스는 애플리케이션의 핵심 구성 요소이므로, 안정성과 데이터 무결성을 확보하기 위한 세심한 계획과 관리가 필수적입니다.

[end of HELM_CHART_COMPONENTS_GUIDE.md]
