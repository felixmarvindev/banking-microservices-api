# syntax=docker/dockerfile:1.7

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom first to leverage dependency cache
COPY pom.xml .

# Download dependencies (shared cache)
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -B

# Copy source
COPY src ./src

# Build the JAR (reuse same cache)
RUN --mount=type=cache,target=/root/.m2 \
    mvn package -DskipTests

# Runtime image
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 10080
ENTRYPOINT ["java", "-jar", "app.jar"]
