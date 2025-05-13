## 📋 상세 설명
- AWS Activate 신청을 위한 랜딩페이지 추가
- nginx 설정 추가

```
  # 랜딩 페이지 경로 추가
    location = /landing {
        return 301 /landing/;
    }

    location /landing/ {
        alias /var/www/landingPage/;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
```

```
sudo mkdir -p /var/www/landingPage
sudo cp -r /home/devops/2-hertz-cloud/landingPage/* /var/www/landingPage/

sudo chown -R www-data:www-data /var/www/landingPage
sudo chmod -R o+rx /var/www/landingPage

sudo nginx -t  # 설정 문법 검사
sudo systemctl reload nginx  # 설정 적용
```