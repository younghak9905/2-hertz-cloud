import http from 'k6/http';
import { check, sleep } from 'k6';

// ✅ 옵션 설정
export const options = {
  vus: 50,              // 가상 사용자 수
  duration: '30s',      // 테스트 지속 시간
};

// ✅ 테스트 대상 API URL과 쿼리 파라미터
const BASE_URL = 'https://hertz-tuning.com'; // 실제 서비스 도메인으로 교체
const PAGE = 0;
const SIZE = 10;
const TOKEN = 'Bearer your-access-token'; // 필요 시 토큰 입력

// ✅ 테스트 시나리오
export default function () {
  const url = `${BASE_URL}/api/v1/channel?page=${PAGE}&size=${SIZE}`;
  const params = {
    headers: {
      Authorization: TOKEN, // 필요 없으면 제거
    },
  };

  const res = http.get(url, params);

  // ✅ 응답 확인
  check(res, {
    '응답 코드가 200인가': (r) => r.status === 200,
//    '정상 메시지 포함': (r) => r.json().message === '채널방 목록이 정상적으로 조회되었습니다.',
//    '채널방 리스트 있음': (r) => r.json().data.list.length >= 0,
  });

  sleep(3); // 풀링 (3초)
}