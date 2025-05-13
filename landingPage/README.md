## 📋 상세 설명
- AWS Activate 신청을 위한 랜딩페이지 추가
- nginx 설정 추가

```
  # 랜딩 페이지 경로 추가
    location /landing/ {
        alias /home/deploy/2-hertz-cloud/landingPage;
        index index.html;
        try_files $uri $uri/ =404;
    }
```

```
sudo chown -R nginx:nginx /home/deploy/2-hertz-cloud/landingPage
sudo chmod -R 755 /home/deploy/2-hertz-cloud/landingPage

sudo nginx -t  # 설정 문법 검사
sudo systemctl reload nginx  # 설정 적용
```