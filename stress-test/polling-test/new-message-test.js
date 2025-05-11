
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 50,             // 50명의 가상 사용자
  duration: '30s',     // 30초간 테스트
};

export default function () {
  const url = 'http://localhost:8080/api/v1/new-messages';
  const params = {
    headers: {
      'Authorization': 'Bearer accessToken',
      'Content-Type': 'application/json',
    },
  };

  const res = http.get(url, params);

  // 응답 코드 체크 (원하면 주석 해제)
  // check(res, { 'status was 200': (r) => r.status === 200 });

  sleep(3); // 3초마다 polling
}