# syntax=docker/dockerfile:1.7

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

COPY pom.xml .

RUN --mount=type=cache,target=/root/.m2 \
    sh -c 'set -e; \
    for i in 1 2 3; do \
        if mvn dependency:go-offline -B; then \
            exit 0; \
        else \
            echo "Attempt $i failed, cleaning corrupted artifacts..."; \
            find /root/.m2/repository -name "*.lastUpdated" -delete || true; \
            find /root/.m2/repository -name "*.lock" -delete || true; \
            rm -rf /root/.m2/repository/com/google/guava/guava/16.0.1 || true; \
            rm -rf /root/.m2/repository/org/apache/maven/surefire/surefire-shared-utils/3.2.5 || true; \
            [ $i -lt 3 ] && sleep 10 || exit 1; \
        fi; \
    done'

COPY src ./src

RUN --mount=type=cache,target=/root/.m2 \
    mvn package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 10090
ENTRYPOINT ["java", "-jar", "app.jar"]

