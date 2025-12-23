# Traversium Config Server

Spring Cloud Config Server for managing centralized configuration across Traversium microservices.

## Overview

This Config Server provides externalized configuration management for all Traversium microservices. It supports both local file-based configuration (for development) and Git-based configuration (for production) with automatic refresh capabilities via Spring Cloud Bus and Kafka.

## Features

- Centralized configuration management
- Automatic configuration refresh via Kafka
- GitHub webhook support for instant updates
- Prometheus metrics integration
- Health checks and actuator endpoints
- Docker support

## Prerequisites

- Java 17+
- Maven 3.6+
- Kafka (optional, for automatic refresh)
- Docker (optional, for containerized deployment)

## Quick Start

### Local Development

1. **Build the project:**
   ```bash
   mvn clean package
   ```

2. **Run the Config Server:**
   ```bash
   java -jar target/TraversiumConfigServer-1.0.0-SNAPSHOT.jar
   ```

3. **Access the Config Server:**
   - Server runs on: `http://localhost:8888`
   - Health check: `http://localhost:8888/actuator/health`
   - Metrics: `http://localhost:8888/actuator/prometheus`

## Configuration Modes

### Native Profile (Local Development)

Uses local file system for configuration files.

**Configuration (`application.properties`):**
```properties
spring.profiles.active=native
spring.cloud.config.server.native.search-locations=file:///path/to/config
```

**File Structure:**
```
config/
├── UserService.properties
├── UserService-dev.properties
├── OtherService.properties
└── OtherService-prod.properties
```

**Access Configuration:**
- `http://localhost:8888/{application}/{profile}`
- Example: `http://localhost:8888/user-service/dev`

### Git Profile (Production)

Uses GitHub repository for configuration files.

**Configuration (`application.properties`):**
```properties
spring.cloud.config.server.git.uri=https://github.com/your-username/config-repo
spring.cloud.config.server.git.default-label=main
spring.cloud.config.server.git.clone-on-start=true
```

## Automatic Configuration Refresh

### Setup with Kafka

1. **Start Kafka:**
   ```bash
   docker run -d --name kafka -p 29092:29092 apache/kafka:latest
   ```

2. **Enable Kafka in Config Server:**
   Uncomment Kafka configuration in `application.properties`:
   ```properties
   spring.kafka.bootstrap-servers=localhost:29092
   spring.cloud.stream.kafka.binder.brokers=localhost:29092
   ```

3. **Configure GitHub Webhook:** (not needed for local development)
   - Go to your config repository → Settings → Webhooks
   - Add webhook:
     - **Payload URL:** `http://your-server:8888/monitor`
     - **Content type:** `application/json`
     - **Events:** Just the push event

4. **Client Configuration:**

   Add to client microservices `pom.xml`:
   ```xml
   <dependency>
       <groupId>org.springframework.cloud</groupId>
       <artifactId>spring-cloud-starter-config</artifactId>
   </dependency>
   <dependency>
       <groupId>org.springframework.cloud</groupId>
       <artifactId>spring-cloud-starter-bus-kafka</artifactId>
   </dependency>
   ```

   Add to client `application.properties`:
   ```properties
   spring.config.import=configserver:http://localhost:8888
   spring.application.name=user-service
   spring.kafka.bootstrap-servers=localhost:29092
   ```

   Annotate beans that need refresh:
   ```kotlin
   @RefreshScope
   @RestController
   class MyController {
       @Value("\${some.property}")
       lateinit var property: String
   }
   ```

## Endpoints

### Actuator Endpoints

| Endpoint | Description |
|----------|-------------|
| `/actuator/health` | Health check |
| `/actuator/info` | Application info |
| `/actuator/prometheus` | Prometheus metrics |
| `/actuator/refresh` | Manual refresh trigger |
| `/actuator/busrefresh` | Broadcast refresh to all clients |

### Config Endpoints

| Endpoint | Description |
|----------|-------------|
| `/{application}/{profile}` | Get configuration as JSON |
| `/{application}/{profile}/{label}` | Get configuration from specific branch/tag |
| `/{application}-{profile}.properties` | Get as properties file |
| `/{application}-{profile}.yml` | Get as YAML file |
| `/monitor` | GitHub webhook receiver |

## Docker Compose Example

```yaml
version: '3.8'

services:
  config-server:
    build: .
    ports:
      - "8888:8888"
    environment:
      - SPRING_PROFILES_ACTIVE=native
      - SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS=file:///config
      - SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
    volumes:
      - ./config:/config
    depends_on:
      - kafka

  kafka:
    image: apache/kafka:latest
    ports:
      - "29092:29092"
```

## Environment Variables

Override configuration using environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_PORT` | Server port | `8888` |
| `SPRING_PROFILES_ACTIVE` | Active profile | `native` |
| `SPRING_KAFKA_BOOTSTRAP_SERVERS` | Kafka bootstrap servers | `localhost:29092` |
| `SPRING_CLOUD_CONFIG_SERVER_GIT_URI` | Git repository URI | - |
| `SPRING_CLOUD_CONFIG_SERVER_NATIVE_SEARCH_LOCATIONS` | Local config path | - |