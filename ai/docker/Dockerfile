# 기본 이미지로 Python 3.10 슬림 버전 사용
# slim-bullseye는 Debian Bullseye 기반의 경량화된 이미지로, 필수 패키지만 포함
# 일반 Python 이미지보다 용량이 작아 빌드 및 배포 시간 단축
FROM python:3.10-slim-bullseye

# 컨테이너 내부의 작업 디렉토리 설정
# 이후 모든 명령어는 이 디렉토리를 기준으로 실행됨
WORKDIR /app

# 컨테이너 환경변수 설정
ENV PYTHONUNBUFFERED=1 \         # Python 출력 버퍼링 비활성화 - 로그가 실시간으로 표시됨
    PYTHONDONTWRITEBYTECODE=1 \  # .pyc 파일(바이트코드) 생성 방지 - 이미지 크기 감소 및 디버깅 용이
    PYTHONOPTIMIZE=2 \           # Python 최적화 레벨 2 설정 - assert 문과 docstring 제거하여 메모리 절약
    PORT=8000 \                  # 애플리케이션 포트 설정
    # CPU 성능 최적화를 위한 스레드 설정 - 각 라이브러리의 스레드 수 제한
    OMP_NUM_THREADS=1 \          # OpenMP 스레드 수 제한 - 스레드 경쟁 방지
    MKL_NUM_THREADS=1 \          # Intel MKL 라이브러리 스레드 수 제한
    NUMEXPR_NUM_THREADS=1 \      # NumExpr 라이브러리 스레드 수 제한
    OPENBLAS_NUM_THREADS=1 \     # OpenBLAS 라이브러리 스레드 수 제한
    TOKENIZERS_PARALLELISM=false \ # Hugging Face 토크나이저 병렬 처리 비활성화 - 메모리 사용량 감소
    SENTENCE_TRANSFORMERS_HOME=/app/models # 모델 캐시 위치 지정

# 필수 시스템 패키지 설치
# --no-install-recommends: 추천 패키지는 설치하지 않아 이미지 크기 최소화
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \            # 컴파일 도구 (gcc, make 등) - 일부 Python 패키지의 C 확장 컴파일에 필요
    libblas-dev \                # BLAS 라이브러리 - 벡터/행렬 연산 가속화
    liblapack-dev \              # LAPACK 라이브러리 - 선형대수 연산 가속화
    libjemalloc-dev \            # jemalloc 메모리 할당기 - 메모리 단편화 감소 및 성능 향상
    curl \                       # 네트워크 요청 도구 - 헬스체크 및 다운로드에 사용
    procps \                     # 프로세스 관리 도구 - 성능 모니터링에 유용
    && apt-get clean \           # apt 캐시 정리
    && rm -rf /var/lib/apt/lists/*  # apt 패키지 목록 정리 - 이미지 크기 감소

# jemalloc 메모리 할당기 활성화
# 기본 malloc보다 효율적인 메모리 관리로 메모리 단편화 감소 및 할당/해제 성능 향상
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# 의존성 파일 복사 및 설치
# 애플리케이션 코드보다 먼저 의존성을 복사/설치하여 캐시 활용도 향상
COPY requirements.txt requirements-dev.txt* ./
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt && \
    if [ -f requirements-dev.txt ]; then \
        pip install --no-cache-dir -r requirements-dev.txt; \
    fi

# 로그 및 모델 디렉토리 생성
# 볼륨 마운트 포인트로 사용될 디렉토리 미리 생성
RUN mkdir -p /app/logs /app/models

# 애플리케이션 코드 복사
# 종속성이 변경되지 않은 경우 이전 레이어 캐시를 재사용할 수 있도록 마지막에 수행
COPY app /app/

# 모델 사전 다운로드
# 컨테이너 시작 시 다운로드 지연을 방지하기 위해 빌드 시점에 모델 다운로드
# 첫 요청 지연(cold start) 방지
RUN python -c "from sentence_transformers import SentenceTransformer; model = SentenceTransformer('jhgan/ko-sbert-nli')"

# 컨테이너가 리스닝할 포트 노출
# Docker에게 컨테이너가 어떤 포트를 사용할지 알려주는 문서화 목적 (실제로 포트를 열지는 않음)
EXPOSE 8000

# 컨테이너 시작 시 실행할 명령
# Gunicorn을 WSGI 서버로 사용하여 FastAPI 애플리케이션 실행
CMD ["sh", "-c", "gunicorn app.main:app \
    --workers=${GUNICORN_WORKERS:-4} \    # 워커 프로세스 수 (기본값 4, 환경변수로 조정 가능)
    --worker-class=uvicorn.workers.UvicornWorker \  # Uvicorn ASGI 워커 사용 (FastAPI 요구사항)
    --bind=0.0.0.0:8000 \                 # 모든 인터페이스에서 접근 가능하도록 바인딩
    --timeout=180 \                        # 워커 타임아웃 설정 (초) - 긴 요청 처리 대비
    --max-requests=500 \                   # 워커당 최대 요청 수 - 메모리 누수 방지를 위한 재시작
    --max-requests-jitter=50 \             # 최대 요청 수에 무작위성 추가 - 모든 워커가 동시에 재시작되는 것 방지
    --preload \                            # 애플리케이션 사전 로드 - 워커 간 메모리 공유로 효율성 증가
    --worker-tmp-dir=/dev/shm \            # 임시 파일을 RAM에 저장 - I/O 성능 향상
    --access-logfile=- \                   # 접근 로그를 표준 출력으로 전송
    --error-logfile=- \                    # 오류 로그를 표준 출력으로 전송
    --log-level=info"]                     # 로그 상세 수준 설정