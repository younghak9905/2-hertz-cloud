# 1단계: Gradle + JDK 21을 사용해 빌드
FROM gradle:8.5-jdk21 AS builder

WORKDIR /app
COPY . .
RUN chmod +x ./gradlew

# 테스트를 생략한 빌드
RUN ./gradlew clean build -x test

# 2단계: JAR만 실행하는 가벼운 이미지
FROM eclipse-temurin:21-jdk

WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]