# Azzurro Tech Website

## Overview

Azzurro Tech is a complete web platform combining the power of AzzurroTech projects (Go-based services) and Emperor42 projects (JavaScript web components) into one seamless platform.

## Features

### Platform Services
- **Stenella Data Platform** - Enterprise data aggregation and normalization
- **Shepherd Security** - Advanced firewall protection and automated client billing
- **Song Authentication** - Passwordless magic link authentication
- **Pod Database** - HTML form-based database with SQLite backend

### Web Components
- **VENI** - Web component system for automatic component generation
- **VIDI** - Data visualization with card-based displays
- **VICI** - Change management with WordPress-like admin interface
- **VINI** - Workflow definition system for user flow management

## Technology Stack

### Backend (AzzurroTech - Go)
- **Go 1.20+** - High-performance server framework
- **Gin Framework** - HTTP server with REST API
- **SQLite** - Local database storage
- **CORS** - Cross-origin resource sharing

### Frontend (Emperor42 - JavaScript)
- **Vanilla JavaScript** - No external dependencies
- **Web Components** - Modern web component standard
- **Local Storage** - Client-side data management
- **Encryption** - AES-256 data encryption

### Website (Azzurro.tech)
- **HTML5/CSS3** - Modern responsive design
- **JavaScript** - Interactive user interface
- **REST APIs** - Integration with backend services
- **Mobile First** - Responsive across all devices

## Getting Started

### Running the Platform

1. **Start the ATP platform (central hub)**
```bash
cd azzurrotech/atp
./atp
# or
go run .
```

2. **Start individual services**
```bash
# Stenella data platform
cd azzurrotech/stenella
go run .

# Pod database
cd azzurrotech/pod
go run ./cmd

# Song authentication
cd azzurrotech/song
./song --port 8083

# Shepherd security
cd azzurrotech/shepherd
go run .
```

3. **Test the website**
```bash
# The website is already running locally at:
# http://localhost:8080

# Access the platform:
# - http://localhost:8080/
# - http://localhost:8080/clients
# - http://localhost:8080/services
# - http://localhost:8080/billing
```

### API Testing

```bash
# Test service discovery
curl http://localhost:8080/api/services

# Test stenella data platform
curl http://localhost:8081/api/data

# Test pod database
curl http://localhost:8082/api/forms

# Test song authentication
curl -X POST http://localhost:8083/api/auth/generate -d '{"user_id":"test@example.com"}'

# Test shepherd security
curl http://localhost:8084/api/firewall/rules
```

### Emperor42 Components Testing

```bash
# Test web components in browser
# Open browser and load:
# http://localhost:8080/
# All components will be automatically loaded and functional
```

## Development

### AzzurroTech Projects (Go)
```bash
# Build and test individual projects
$ cd azzurrotech/atp
$ go build ./...
$ go test ./...

$ cd azzurrotech/pod
$ go run ./cmd
$ go test ./...

$ cd azzurrotech/song
$ ./song --port 8083
$ go test ./...

$ cd azzurrotech/shepherd
$ go run .
$ go test ./...

$ cd azzurrotech/stenella
$ go run .
$ go test ./...
```

### Emperor42 Projects (JavaScript)
```bash
# Test JavaScript projects
$ cd emperor42/veni
$ npm test

$ cd emperor42/vidi
$ npm test

$ cd emperor42/vici
$ npm test

$ cd emperor42/vini
$ npm test
```

### Integration Testing
```bash
# Full integration test with all services running
$ cd azzurrotech/atp
$ go run . &
$ cd azzurrotech/pod
$ go run ./cmd &
$ cd azzurrotech/song
$ ./song --port 8083 &
$ cd azzurrotech/shepherd
$ go run . &
$ cd azzurrotech/stenella
$ go run . &

# Test all endpoints
$ curl http://localhost:8080/api/services
$ curl http://localhost:8081/api/data
$ curl http://localhost:8082/api/forms
$ curl http://localhost:8083/api/auth/generate -d '{"user_id":"test"}'
$ curl http://localhost:8084/api/firewall/rules

# Open browser and test: http://localhost:8080/
```

## Architecture

### AzzurroTech Platform
- **ATP (AzzurroTech Platform)** - Central integration hub
- **Stenella** - Data aggregation from multiple sources
- **Pod** - HTML form database with SQLite backend
- **Song** - Passwordless authentication service
- **Shepherd** - Security and billing management

### Emperor42 Platform
- **VENI** - Web component discovery and generation
- **VIDI** - Data visualization and management
- **VICI** - Change management and version control
- **VINI** - Workflow definition and execution

### Integration
- **Configuration-based** - All services register through ATP
- **HTTP APIs** - RESTful communication between services
- **Health Checks** - Service monitoring and discovery
- **CORS Support** - Cross-origin requests
- **Authentication** - Magic link-based user authentication

## Security Features

### AzzurroTech Security
- **Encryption** - AES-256 for sensitive data
- **Authentication** - Magic link-based user authentication
- **Authorization** - Role-based access control
- **Firewall** - Custom firewall rules and access control
- **Audit Trails** - Complete logging and monitoring

### Emperor42 Security
- **Local Storage** - Client-side data protection
- **CORS Management** - Cross-origin request control
- **Content Security** - Modern web security practices
- **No External Dependencies** - Self-contained components

## Performance

- **Go Backend** - High-performance server architecture
- **Local Storage** - Reduced latency through client-side storage
- **Caching** - Multi-level caching for frequently accessed data
- **Compression** - Gzip compression for API responses
- **Connection Pooling** - Efficient database connection management

## Customization

### Backend Configuration
- All AzzurroTech projects can be configured through environment variables
- Database paths and ports can be customized
- Authentication methods and billing configurations are flexible

### Frontend Customization
- All Emperor42 components are customizable through options
- Website theming can be modified through CSS variables
- Component behavior can be overridden through configuration

## Deployment

### Local Development
```bash
# Start ATP platform
$ cd azzurrotech/atp
$ go run .

# Start individual services in separate terminals
$ cd azzurrotech/pod
$ go run ./cmd

$ cd azzurrotech/song
$ ./song --port 8083

$ cd azzurrotech/shepherd
$ go run .

$ cd azzurrotech/stenella
$ go run .
```

### Production Deployment
- **Docker Support** - Containerized deployment
- **Load Balancing** - Nginx or similar web server
- **SSL/TLS** - HTTPS encryption
- **Monitoring** - Health checks and metrics
- **Backup** - Database and configuration backups

## Monitoring

### Health Checks
```bash
# Service health endpoints
$ curl http://localhost:8080/health
$ curl http://localhost:8081/health
$ curl http://localhost:8082/health
$ curl http://localhost:8083/health
$ curl http://localhost:8084/health
```

### Metrics
- HTTP request/response times
- Service uptime and availability
- Error rates and failure patterns
- Resource utilization (CPU, memory, disk)
- Database connection status

### Logging
- Application logs for each service
- Security audit trails
- Performance metrics
- Error reporting and alerting

## Support

### Documentation
- **API Reference** - Complete API documentation
- **Tutorials** - Step-by-step guides
- **Examples** - Sample implementations
- **Best Practices** - Development and deployment guidelines

### Community
- **GitHub** - Source code and issues
- **Discussions** - Feature requests and feedback
- **Support** - Technical support and assistance
- **Contributing** - Project contributions and improvements

## License

© 2025 Azzurro Technology Inc. All rights reserved.

---

*Azzurro Tech - The Complete Web Platform Stack*

**Version:** 1.0.0
**Last Updated:** 2026-08-24
**Status:** Production Ready