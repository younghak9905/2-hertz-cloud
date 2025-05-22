module.exports = {
    apps: [
{
  name: "spring-backend",
  script: "java",
//      args:
    /*[
    "-javaagent:/home/deploy/pinpoint/pinpoint-agent-3.0.1/pinpoint-bootstrap-3.0.1.jar",
    "-Dpinpoint.agentId=spring-backend-01",
    "-Dpinpoint.applicationName=spring-backend",
    "-Dpinpoint.config=/home/deploy/pinpoint/pinpoint-agent-3.0.1/pinpoint-root.config",
    
    // Java 21 호환성을 위한 추가 옵션
    "--add-opens=java.base/java.lang=ALL-UNNAMED",
    "--add-opens=java.base/java.util=ALL-UNNAMED",
    "--add-opens=java.base/java.lang.reflect=ALL-UNNAMED",
    "--add-opens=java.base/java.nio=ALL-UNNAMED",
    "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED",
    "--add-opens=java.base/java.io=ALL-UNNAMED",
    
    // JVM 메모리 및 GC 옵션
    "-Xms512m",
    "-Xmx1024m",
    "-XX:+UseG1GC",
    "-XX:MaxGCPauseMillis=200",
    "-XX:+HeapDumpOnOutOfMemoryError",
    "-XX:HeapDumpPath=/home/deploy/logs/heapdumps",*/

  //"-jar /home/deploy/2-hertz-be/hertz-be/build/libs/hertz-be-0.0.1-SNAPSHOT.jar",//],//hertz-be-0.0.1-SNAPSHOT.jar
  args: [
    "-javaagent:/home/deploy/signoz/opentelemetry-javaagent.jar",
    "-XX:+UseShenandoahGC",
    "-Xms2g",
    "-Xmx2g",
    "-Xlog:gc*:file=/home/deploy/logs/gc.log:time,uptime,level,tags:filecount=5,filesize=20m",
    "-jar",
    "/home/deploy/2-hertz-be/hertz-be/build/libs/hertz-be-0.0.1-SNAPSHOT.jar"
  ],
  cwd: "/home/deploy/2-hertz-be/hertz-be",
  interpreter: "",
  env: {
          OTEL_RESOURCE_ATTRIBUTES: "service.name=prod-springboot",
          OTEL_EXPORTER_OTLP_HEADERS: "signoz-ingestion-key=83596947-3585-4241-affd-abb16b4a8af6",
          OTEL_EXPORTER_OTLP_ENDPOINT: "https://ingest.us.signoz.cloud:443"
  },
  env_file: "/home/deploy/2-hertz-be/hertz-be/.env",  // .env 파일 경로 지정
  watch: false,  // 백엔드는 코드 변경 watch 필요 없음
  restart_delay: 5000, // 재시작 간격 5초
  max_restarts: 5, // 5번 이상 연속 재시작 실패하면 멈춤
  out_file: "/home/deploy/logs/spring-out.log", // 표준 출력 로그
  error_file: "/home/deploy/logs/spring-err.log", // 에러 로그
  log_date_format: "YYYY-MM-DD HH:mm:ss",
},
{
    name: "next-frontend",
    script: "pnpm",
    args: "start",
    cwd: "/home/deploy/2-hertz-fe",
    interpreter: "", // Node.js 기반 CLI이므로 그대로 비워둠
    env: {
      NODE_ENV: "production",
      PORT: 3000
    },
    watch: false,
    restart_delay: 5000,
    max_restarts: 5,
    out_file: "/home/deploy/logs/next-out.log",
    error_file: "/home/deploy/logs/next-err.log",
    log_date_format: "YYYY-MM-DD HH:mm:ss"
  }
]
};
