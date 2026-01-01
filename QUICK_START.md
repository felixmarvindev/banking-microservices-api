# Quick Start Guide

## Local Development

1. **Start Infrastructure Services**:
   ```bash
   docker-compose up -d postgresql zookeeper kafka mongodb mail-dev
   ```

2. **Start Microservices** (in separate terminals or use IDE):
   - Discovery Service (port 8761)
   - Config Server (port 8888)
   - Gateway (port 8222)
   - Auth Service (port 10070)
   - Account Service (port 10080)
   - Transaction Service (port 10090)
   - Loan Service (port 10060)
   - Notification Service (port 10050)

3. **Access Swagger UI**:
   - Auth: http://localhost:10070/swagger-ui/index.html
   - Account: http://localhost:10080/swagger-ui/index.html
   - Transaction: http://localhost:10090/swagger-ui/index.html
   - Loan: http://localhost:10060/swagger-ui/index.html
   - Notification: http://localhost:10050/swagger-ui/index.html
   - Gateway: http://localhost:8222/swagger-ui.html

## Docker Deployment

1. **Build and Start All Services**:
   ```bash
   docker-compose build
   docker-compose up -d
   ```

2. **Or Use Deployment Script**:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Access Services**:
   - API Gateway: http://localhost:8222
   - Swagger Aggregator: http://localhost:8222/swagger-aggregator.html
   - Eureka Dashboard: http://localhost:8761

## VPS Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed VPS deployment instructions.

## Service Endpoints

All services are accessible through the API Gateway at `http://localhost:8222`:

- Auth: `/api/v1/auth/**`
- Account: `/api/v1/accounts/**`
- Transaction: `/api/v1/transactions/**`
- Loan: `/api/v1/loans/**`

Swagger UI endpoints:
- `/auth-service/swagger-ui/index.html`
- `/account-service/swagger-ui/index.html`
- `/transaction-service/swagger-ui/index.html`
- `/loan-service/swagger-ui/index.html`
- `/notification-service/swagger-ui/index.html`

