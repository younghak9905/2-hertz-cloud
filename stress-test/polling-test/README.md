## 개요

실시간 채팅 기능을 구현하기 전, 우선적으로 **polling 기반 메시지 확인 API**를 적용한 MVP를 개발했습니다.

이때, 프론트엔드에서 3초 간격으로 서버에 /api/v1/new-messages를 반복 요청하기 때문에, **다수의 유저가** 

**동시에 polling할 경우 서버에 과부하가 생길 수 있는지**를 사전에 검증할 필요가 있었습니다.

### k6을 사용한 이유 
wrk, ab, JMeter 등 여러 부하 테스트 도구 중 k6를 선택한 이유는 다음과 같습니다:
	•	sleep()을 이용한 정확한 polling 간격 시뮬레이션 가능
	•	Bearer Token 포함 등 유연한 인증 헤더 처리
	•	CLI 기반으로 가볍고 빠른 실행, 스크립트 기반으로 직관적인 시나리오 구성
	•	실시간 지표 제공 및 Prometheus/Grafana와 연동 가능

🔍 결론적으로, k6는 실제 프론트엔드의 polling 구조를 가장 정확하고 안정적으로 재현할 수 있는 도구였기 때문에 선택하게 되었습니다.


## 환경 세팅
```bash
sudo apt update
sudo apt install gnupg ca-certificates
curl -fsSL https://dl.k6.io/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt update
sudo apt install k6
```
## 실행 방법
```bash
#'Authorization': 'Bearer accessToken' <- 올바른 토큰 값 입력
k6 run new-message-test.js
```

```bash
# 1. Spring Boot 앱 실행 (백그라운드)
java -jar app.jar &

# 2. PID 확인
ps aux | grep java

# 3. 실시간 리소스 확인
top -p <PID>  # or htop
```

### 시뮬레이션 조건 요약

| **항목** | **값** |
| --- | --- |
| 가상 사용자 수 (vus) | 50명 |
| 테스트 시간 (duration) | 30초 |
| 요청 주기 (sleep(3)) | 사용자당 3초에 1번 |
| 총 요청 횟수 | 50명 × (30초 ÷ 3초) = **500회** 요청 발생 예상 |
| RPS (초당 요청 수) | 500 / 30 ≈ **16.7 req/sec** |