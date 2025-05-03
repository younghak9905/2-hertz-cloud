| **이름** | **설명** | **예시** |
| --- | --- | --- |
| GCP_PROJECT_ID | GCP 프로젝트 ID | my-tuning-project-12345 |
| GCP_ZONE | GCP 인스턴스가 있는 zone | asia-northeast3-a |
| GCP_SA_KEY | GCP 서비스 계정 키 (JSON 전체 내용) | { "type": "service_account", ... } |
| PROD_INSTANCE | 프로덕션 GCE 인스턴스 이름 | prod-instance |
| STAGING_INSTANCE | 스테이징 GCE 인스턴스 이름 | staging-instance |
| PROD_SERVER_HOST | 프로덕션 서버 SSH IP 또는 도메인 | 34.64.xxx.xxx |
| STAGING_SERVER_HOST | 스테이징 서버 SSH IP 또는 도메인 | 34.97.xxx.xxx |
| SSH_USERNAME | SSH 접속 계정명 | deploy |
| SSH_PRIVATE_KEY | SSH 개인 키 (예: ~/.ssh/gcp_tuning_deploy) | -----BEGIN OPENSSH PRIVATE KEY----- ... |
| DISCORD_WEBHOOK_URL | 배포 성공 알림용 Discord Webhook | https://discord.com/api/webhooks/... |