# Online Banking Microservices API

A modern, scalable online banking system built using a microservices architecture with **Java**, **Spring Boot**, **Apache Kafka**, **PostgreSQL**, **JPA/Hibernate**, **Docker**, and more. This project demonstrates a modular, event-driven banking application with services for account management, transactions, loans, notifications, and authentication.

![Image](https://github.com/user-attachments/assets/29e57f8d-6344-42cd-892b-de8f6235b590)


## Table of Contents
- [Features](#features)
- [Technologies](#technologies)
- [Prerequisites](#prerequisites)
- [Setup and Installation](#setup-and-installation)
- [Running the Application](#running-the-application)
- [Services](#services)
- [Environment Variables](#environment-variables)
- [Contributing](#contributing)
- [License](#license)

---

## Features
- **Account Management**: Create, update, and manage user accounts and balances.
- **Transaction Processing**: Handle transfers, payments, and transaction history.
- **Loan Management**: Process loan applications, schedules, and credit scoring.
- **Notification System**: Send emails and SMS notifications using event-driven architecture.
- **Authentication**: Secure user authentication with JWT/OAuth2 via Keycloak.
- **Service Discovery**: Dynamic service registration and discovery with Eureka.
- **Distributed Tracing**: Monitor requests with Zipkin.
- **Caching**: Improve performance with EhCache .
- **Event-Driven Communication**: Asynchronous messaging with Kafka.

---

## Technologies
- **Backend**: Java, Spring Boot, Spring Cloud
- **Databases**: PostgreSQL (JPA/Hibernate), MongoDB
- **Message Broker**: Apache Kafka, Zookeeper
- **Authentication**: Keycloak (JWT/OAuth2)
- **Service Discovery**: Netflix Eureka
- **API Gateway**: Spring Cloud Gateway
- **Distributed Tracing**: Zipkin
---
## Prerequisites
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 1.29 or higher
- **Java**: JDK 17 (for local development)
- **Maven**: For building Spring Boot services
- **Git**: To clone the repository
- **Containerization**: Docker, Docker Compose
- **Monitoring**: pgAdmin, Mongo Express
- **Email Testing**: Maildev

----
## Setup and Installation
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/online-banking-microservices-api.git
   cd online-banking-microservices-api
   ```
2. **Build the Project (optional, if running locally without Docker):**
  ```bash
 mvn clean install
```
3. **Configure Environment Variables:**
     - See the Environment Variables (#environment-variables) section for details.
     - Update the docker-compose.yml file if needed.
---
## Running the Application

### Quick Start (Docker)

1. **Start the Services with Docker Compose**:
   ```bash
   docker-compose build
   docker-compose up -d
   ```

   Or use the deployment script:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

2. **Verify Services:**
- **API Gateway**: `http://localhost:8222`
- **Swagger Aggregator**: `http://localhost:8222/swagger-aggregator.html`
- **Eureka Discovery**: `http://localhost:8761`
- PostgreSQL: `localhost:5432`
- Keycloak: `localhost:9098`
- pgAdmin: `localhost:5050`
- Zipkin: `localhost:9411`
- MongoDB: `localhost:27017`
- Mongo Express: `localhost:8081`
- Kafka: `localhost:9092`
- Maildev: `localhost:1080` (UI), `localhost:1025` (SMTP)

3. **Access Swagger UI**:
   - Through Gateway: `http://localhost:8222/auth-service/swagger-ui/index.html`
   - Direct access: `http://localhost:10070/swagger-ui/index.html` (Auth Service)

4. **Stop the Services**:
   ```bash
   docker-compose down
   ```

### VPS Deployment

For production deployment on a VPS, see [DEPLOYMENT.md](DEPLOYMENT.md) for detailed step-by-step instructions.

### Local Development

For local development without Docker, see [QUICK_START.md](QUICK_START.md).
## Services
```markdown
| Service                | Description                          | Port       |
|------------------------|--------------------------------------|------------|
| **API Gateway**        | Central entry point                  | 8222       |
| **Eureka Discovery**   | Service registry                     | 8761       |
| **Config Server**      | Configuration management             | 8888       |
| **Auth Service**       | Authentication & Authorization       | 10070      |
| **Account Service**    | Account management                   | 10080      |
| **Transaction Service**| Transaction processing               | 10090      |
| **Loan Service**       | Loan management                      | 10060      |
| **Notification Service**| Notifications                        | 10050      |
| **PostgreSQL**         | Relational database for core data    | 5432       |
| **Keycloak**           | Authentication and authorization     | 9098       |
| **pgAdmin**            | PostgreSQL management UI             | 5050       |
| **Zipkin**             | Distributed tracing                  | 9411       |
| **MongoDB**            | NoSQL database for notifications     | 27017      |
| **Mongo Express**      | MongoDB management UI                | 8081       |
| **Zookeeper**          | Kafka coordination                   | 22181      |
| **Kafka**              | Message broker                       | 9092       |
| **Maildev**            | Email testing server                 | 1080, 1025 |
```
---
## Environment Variables
The following environment variables are defined in `docker-compose.yml`. Customize them as needed:

| Variable                     | Default Value             | Description                     |
|------------------------------|---------------------------|---------------------------------|
| `POSTGRES_USER`              | `postgres`                | PostgreSQL username             |
| `POSTGRES_PASSWORD`          | `admin@123`               | PostgreSQL password             |
| `KEYCLOAK_ADMIN`             | `admin`                   | Keycloak admin username         |
| `KEYCLOAK_ADMIN_PASSWORD`    | `admin`                   | Keycloak admin password         |
| `PGADMIN_DEFAULT_EMAIL`      | `pgadmin4@pgadmin.org`    | pgAdmin login email             |
| `PGADMIN_DEFAULT_PASSWORD`   | `admin`                   | pgAdmin login password          |
| `MONGO_INITDB_ROOT_USERNAME` | `root`                    | MongoDB root username           |
| `MONGO_INITDB_ROOT_PASSWORD` | `password`                | MongoDB root password           |

---

## Contributing
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m "Add your feature"`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a Pull Request.


