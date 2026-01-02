# syntax=docker/dockerfile:1.7

############################
# Build stage
############################
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn package -DskipTests

############################
# Runtime stage
############################
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 10060
ENTRYPOINT ["java", "-jar", "app.jar"]
