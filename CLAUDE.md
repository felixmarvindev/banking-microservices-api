# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Spring Boot microservices-based online banking system with event-driven architecture using Apache Kafka. The system consists of 8 services organized in a layered architecture with service discovery, centralized configuration, and API gateway patterns.

## Architecture

### Service Layers

**Infrastructure Layer:**
- **Discovery Service** (port 8761): Eureka server for service registration and discovery
- **Config Server** (port 8888): Centralized configuration management using Spring Cloud Config with native profile (configurations stored in `services/config-server/src/main/resources/configurations/`)
- **API Gateway** (port 8222): Spring Cloud Gateway with WebFlux-based routing and OAuth2 resource server security

**Business Services:**
- **Auth Service** (port 10070): JWT-based authentication with EhCache for performance
- **Account Service** (port 10080): Account management with Kafka event publishing
- **Transaction Service** (port 10090): Transaction processing with Feign clients to Account/Auth services
- **Loan Service** (port 10060): Loan management with Feign clients for account verification
- **Notification Service** (port 10050): Email notifications via Kafka consumers (MongoDB + PostgreSQL hybrid storage)

### Key Architectural Patterns

**Event-Driven Communication:**
- Kafka topics: `transaction-events`, `account-events`
- Transaction/Account services publish events via `KafkaTemplate`
- Notification service consumes events with dedicated `@KafkaListener` container factories
- Event classes in each service: `TransactionEvent`, `AccountEvent` (with matching DTOs)

**Synchronous Communication:**
- Feign clients for inter-service calls (e.g., `TransactionService` → `AccountClient`, `AuthClient`)
- Discovery-based service resolution via Eureka

**Security:**
- Gateway uses Spring WebFlux Security with OAuth2 JWT resource server
- Public paths: `/eureka/**`, `/api/v1/**`, `/swagger-ui/**`, `/actuator/**`
- Authenticated routes require valid JWT tokens

**Database per Service:**
- Each business service has its own PostgreSQL database (auth, account, transaction, loan, notification)
- Notification service also uses MongoDB for message storage
- All services use JPA/Hibernate with standard repository pattern

## Common Commands

### Building

Build all services:
```bash
mvn clean install
```

Build specific service:
```bash
cd services/<service-name>
mvn clean package
```

Build without tests:
```bash
mvn clean install -DskipTests
```

### Running Services

**Full stack with Docker:**
```bash
docker-compose build
docker-compose up -d
```

Or use deployment script:
```bash
chmod +x deploy.sh
./deploy.sh
```

**Local development (infrastructure only):**
```bash
docker-compose up -d postgresql zookeeper kafka mongodb mail-dev
```

Then run services individually from IDE or:
```bash
cd services/<service-name>
mvn spring-boot:run
```

**Service startup order for local development:**
1. Discovery Service (8761)
2. Config Server (8888)
3. Gateway (8222)
4. Auth Service (10070)
5. Business services (Account, Transaction, Loan, Notification)

### Testing

Run all tests:
```bash
mvn test
```

Run tests for specific service:
```bash
cd services/<service-name>
mvn test
```

Run specific test class:
```bash
mvn test -Dtest=AccountApplicationTests
```

### Accessing Services

**API Gateway endpoints:**
- Base URL: `http://localhost:8222`
- Routes: `/api/v1/auth/**`, `/api/v1/accounts/**`, `/api/v1/transactions/**`, `/api/v1/loans/**`
- Swagger Aggregator: `http://localhost:8222/swagger-aggregator.html`

**Direct service endpoints (bypass gateway):**
- Auth: `http://localhost:10070/swagger-ui/index.html`
- Account: `http://localhost:10080/swagger-ui/index.html`
- Transaction: `http://localhost:10090/swagger-ui/index.html`
- Loan: `http://localhost:10060/swagger-ui/index.html`
- Notification: `http://localhost:10050/swagger-ui/index.html`

**Infrastructure:**
- Eureka Dashboard: `http://localhost:8761`
- Zipkin: `http://localhost:9411`
- pgAdmin: `http://localhost:5050` (login: pgadmin4@pgadmin.org / admin)
- Mongo Express: `http://localhost:8081`
- Maildev UI: `http://localhost:1080`
- Keycloak: `http://localhost:9098` (admin / admin)

### Docker Management

Stop all services:
```bash
docker-compose down
```

View logs:
```bash
docker-compose logs -f <service-name>
```

Rebuild specific service:
```bash
docker-compose build <service-name>
docker-compose up -d <service-name>
```

## Code Structure

Each service follows standard Spring Boot layered architecture:

```
services/<service-name>/
├── src/main/java/com/example/<service>/
│   ├── <Service>Application.java       # Main Spring Boot application
│   ├── controller/                     # REST controllers
│   ├── service/                        # Business logic
│   ├── repository/                     # JPA repositories
│   ├── entity/ or model/               # JPA entities
│   ├── dto/                            # Data Transfer Objects
│   ├── config/                         # Configuration classes (Kafka, OpenAPI, etc.)
│   ├── event/                          # Kafka event DTOs (if applicable)
│   ├── client/ or <dependency>/        # Feign clients (if applicable)
│   └── exception/                      # Custom exceptions
├── src/main/resources/
│   ├── application.yml                 # Service configuration
│   └── Dockerfile                      # Docker build configuration
└── pom.xml                             # Maven dependencies
```

## Key Technologies & Versions

- Java 21
- Spring Boot 3.3.3
- Spring Cloud 2023.0.1
- PostgreSQL (JPA/Hibernate)
- MongoDB (Notification service only)
- Apache Kafka 7.4.0
- Keycloak 24.0.2
- Lombok (annotation processing required)
- SpringDoc OpenAPI 2.3.0
- ModelMapper 3.0.0
- JJWT 0.12.5

## Development Notes

**Configuration Management:**
- Service-specific configs are in `services/config-server/src/main/resources/configurations/<service-name>.yml`
- Local profile uses embedded config, docker profile imports from config-server
- Each service has `spring.config.import=optional:configserver:http://localhost:8888` in application.yml

**Kafka Event Publishing Pattern:**
- Publishers use `KafkaTemplate<String, Object>` injected via constructor
- Events sent to topics: `kafkaTemplate.send("topic-name", eventObject)`
- Consumers use `@KafkaListener` with dedicated container factories

**Feign Client Pattern:**
- Annotated with `@FeignClient(name = "service-name")` (uses Eureka for discovery)
- Located in client/ or service-specific package (e.g., `auth/`, `account/`)
- Enable with `@EnableFeignClients` on main application class

**Database Initialization:**
- Databases are auto-created by services using `spring.jpa.hibernate.ddl-auto=update`
- PostgreSQL credentials: postgres/admin@123 (see docker-compose.yml)

**Caching:**
- Auth service uses EhCache for authentication performance
- Cache configuration in service-specific config classes

**OpenAPI/Swagger:**
- Each service has `OpenApiConfig.java` for API documentation
- Gateway aggregates all service APIs at `/swagger-aggregator.html`

## Common Issues

**Service won't connect to Eureka:**
- Verify Discovery Service is running on 8761
- Check `EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE` environment variable

**Kafka events not being consumed:**
- Ensure Kafka is running: `docker-compose ps kafka`
- Check Zookeeper is healthy: `docker-compose ps zookeeper`
- Verify topic creation: Kafka auto-creates topics on first publish

**Database connection errors:**
- Ensure PostgreSQL container is running: `docker-compose ps postgresql`
- Database names match service names (e.g., `jdbc:postgresql://localhost:5432/auth`)

**Gateway returns 401/403:**
- Check if endpoint is in public paths list in `SecurityConfig.java`
- Verify JWT token is valid if accessing authenticated routes

**Feign client failures:**
- Ensure target service is registered in Eureka (check dashboard)
- Verify service names match between `@FeignClient(name="...")` and `spring.application.name`
