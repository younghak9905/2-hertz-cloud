import http from 'k6/http';
import { sleep, check } from 'k6';

// 테스트 구성 옵션
export const options = {
  vus: 50,          // 50명의 가상 사용자
  duration: '30s',  // 30초간 테스트
};

// API 구성 설정
const API_BASE_URL = 'host'; // 실제 API 도메인으로 변경 필요
const API_ENDPOINT = '/api/v1/channel-rooms';
const CHANNEL_ROOM_ID = 3;
const PAGE_SIZE = 20;
const ACCESS_TOKEN = 'AccessToken';// 사전 테스트 실행 - 시작 전 API 가 정상 작동하는지 확인
export function setup() {
  // API URL 구성
  const url = `${API_BASE_URL}${API_ENDPOINT}/${CHANNEL_ROOM_ID}?page=0&size=${PAGE_SIZE}`;
  
  // 헤더 설정
  const params = {
    headers: {
      'Authorization': `Bearer ${ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
  };
  
  console.log('사전 테스트: API 연결 확인 중...');
  console.log(`요청 URL: ${url}`);
  
  // API 호출
  const res = http.get(url, params);
  
  console.log(`사전 테스트 응답 상태: ${res.status}`);
  console.log('응답 본문:');
  console.log(res.body);
  
  // 응답 검사
  const success = res.status === 200;
  
  // 테스트 실패 시
  if (!success) {
    console.error('사전 테스트 실패. API 연결을 확인하세요.');
    console.error(`응답 상태: ${res.status}`);
    console.error(`응답 본문: ${res.body}`);
    throw new Error('사전 테스트 실패로 테스트를 중단합니다.');
  }
  
  console.log('사전 테스트 성공. 5초 후 테스트를 시작합니다...');
  sleep(5);
  
  return { accessToken: ACCESS_TOKEN };
}

// 메인 테스트 함수
export default function (data) {
  // API URL 구성 (무작위 페이지)
  const page = Math.floor(Math.random() * 1); // 0-2 페이지
  const url = `${API_BASE_URL}${API_ENDPOINT}/${CHANNEL_ROOM_ID}?page=${page}&size=${PAGE_SIZE}`;
  
  // 헤더 설정
  const params = {
    headers: {
      'Authorization': `Bearer ${data.accessToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  // API 호출
  const res = http.get(url, params);
  
  // 응답 검증 (선택적)
  check(res, {
    'API 응답이 성공적임 (200)': (r) => r.status === 200,
    '응답이 유효한 JSON 형식임': (r) => {
      try {
        JSON.parse(r.body);
        return true;
      } catch (e) {
        return false;
      }
    },
  });
  
  // 3초 대기 (풀링 주기)
  sleep(3);
}