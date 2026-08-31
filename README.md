# Azzurro Technology Inc. Project Documentation

This document provides comprehensive information about all Azzurro Technology Inc. projects, including installation, usage, and integration with the ATP (AzzurroTech Platform).

## Overview

This repository contains 9 projects across 2 organizations:

### AzzurroTech (Go-based) - **Copyright Azzurro Technology Inc. (MIT License)**
- **atp** (central hub and integration platform)
- **stenella** (data aggregation platform)  
- **shepherd** (firewall and paywall security)
- **song** (magic link authentication)
- **pod** (HTML form database)

### Emperor42 (JavaScript-based) - **Copyright Matthew Salvatore Giancola (MIT License)**
- **veni** (web component discovery)
- **vidi** (data visualization)
- **vici** (change management)
- **vini** (workflow definition)

## Quick Start

### Running the Full System
1. Start the ATP platform (port 8080)
2. Start individual services in separate terminals
3. Access the azzurro.tech website at http://localhost:8080

## Projects Documentation

Each project has its own README.md with detailed documentation. Below is a summary:

### AzzurroTech Projects (Go-based)

#### atp (AzzurroTech Platform)
- **Usage**: Central integration hub at http://localhost:8080
- **Key Features**: Service discovery, client management, billing automation

#### pod (HTML Form Database)
- **Usage**: Web-based database with HTML forms interface at http://localhost:8082
- **Key Features**: SQLite backend, no schema required, CRUD operations

#### song (Magic Link Authentication)
- **Usage**: Passwordless authentication with magic links at http://localhost:8083
- **Key Features**: No passwords stored, time-limited magic links, device tracking

#### shepherd (Security & Billing)
- **Usage**: Firewall protection and automated billing at http://localhost:8084
- **Key Features**: Advanced firewall rules, client management, payment processing

#### stenella (Data Aggregation)
- **Usage**: Data aggregation from multiple sources at http://localhost:8081
- **Key Features**: Multi-source data collection, normalization, real-time processing

### Emperor42 Projects (JavaScript-based)

#### VENI (Web Components)
- **Usage**: Automatic HTML web component discovery and registration
- **Key Features**: Component discovery, no server required

#### VIDI (Data Visualization)
- **Usage**: Card-based data visualization and management
- **Key Features**: Automatic pagination, CORS-aware, local storage support

#### VICI (Change Management)
- **Usage**: Web-based change management with version control
- **Key Features**: CRUD operations, rollback support

#### VINI (Workflow Definition)
- **Usage**: Programmatic workflow definition and execution
- **Key Features**: Local execution, server validation, integrates with VICI/VIDI/VENI

## ATP Integration Pattern

All AzzurroTech projects follow the same ATP integration pattern:

1. **Service Registration**: Each project registers with ATP via `/api/services/register`
2. **Health Checks**: Projects provide health endpoints at `/health`
3. **Configuration Distribution**: ATP manages project configurations
4. **API Gateway**: All requests go through ATP for security and logging
5. **Service Discovery**: ATP discovers and manages all project services

### Example Configuration

```yaml
# atp/config/integrations.yaml
integrations:
  azzurrotech:
    stenella:
      health_check: /health
      data_source: /api/data
      config_endpoint: /api/stenella/config
    pod:
      health_check: /health
      forms_endpoint: /api/forms
      data_endpoint: /api/data
    song:
      health_check: /health
      auth_endpoint: /api/auth
    shepherd:
      health_check: /health
      billing_endpoint: /api/billing
  emperor42:
    VENI:
      template_endpoint: /api/components
    VIDI:
      data_endpoint: /api/data
    VICI:
      changes_endpoint: /api/changes
    VINI:
      workflow_endpoint: /api/workflows
```

## Development Setup

### Prerequisites

- **Go Projects (AzzurroTech)**: Go 1.20+
- **JavaScript Projects (Emperor42)**: Modern web browser with JavaScript support

### Local Development

```bash
# Start ATP platform (port 8080)
cd azzurrotech/atp && ./atp

# Start individual services
cd azzurrotech/stenella && go run .
cd azzurrotech/pod && go run ./cmd
cd azzurrotech/song && ./song --port 8083
cd azzurrotech/shepherd && go run .

# Test integration
 curl http://localhost:8080/api/services
 curl http://localhost:8081/api/data
 curl http://localhost:8082/api/forms
 curl http://localhost:8083/api/auth/generate -d '{"user_id":"test"}'
```

### Building and Testing

#### AzzurroTech Projects (Go)

```bash
# Build individual project
cd azzurrotech/atp
go build ./...

# Run tests
cd azzurrotech/atp
go test ./...

# Build and run
cd azzurrotech/pod
go run ./cmd
```

#### Emperor42 Projects (JavaScript)

```bash
# Test in browser
cd emperor42/vini
# Open browser and load vini.js directly

# Or with Node.js (optional)
node emperor42/vini/vini.js
```

### Integration Testing

```bash
# Start all services
cd azzurrotech/atp && ./atp &
cd azzurrotech/pod && go run ./cmd &
cd azzurrotech/song && ./song --port 8083 &
cd azzurrotech/shepherd && go run . &
cd azzurrotech/stenella && go run . &

# Wait for services to start
sleep 10

# Test cross-service integration
curl http://localhost:8080/api/services
curl http://localhost:8081/api/data
curl http://localhost:8082/api/forms
curl http://localhost:8083/api/auth/generate -d '{"user_id":"test"}'

# Open browser and test full integration
# http://localhost:8080/
```

## Security & Performance

### Security Features

- **Encryption**: AES-256 for sensitive data
- **Authentication**: Magic link-based user authentication
- **Authorization**: Role-based access control
- **Firewall**: Custom firewall rules and access control
- **Audit Trails**: Complete logging and monitoring
- **Input Validation**: Prevents SQL injection and data corruption
- **Local Storage**: Client-side data protection
- **CORS Management**: Cross-origin request control
- **Content Security**: Modern web security practices
- **No External Dependencies**: Self-contained components
- **Password Hashing**: SHA-256 password hashing

### Performance Monitoring

```bash
# Service health endpoints
curl http://localhost:8080/health
curl http://localhost:8081/health
curl http://localhost:8082/health
curl http://localhost:8083/health
curl http://localhost:8084/health
```

### Metrics

- HTTP request/response times
- Service uptime and availability
- Error rates and failure patterns
- Resource utilization (CPU, memory, disk)
- Database connection status
- Authentication success/failure rates

## Deployment & Support

### Local Development

```bash
# Start all services
cd azzurrotech/atp && ./atp &
cd azzurrotech/pod && go run ./cmd &
cd azzurrotech/song && ./song --port 8083 &
cd azzurrotech/shepherd && go run . &
cd azzurrotech/stenella && go run . &

# Wait for services to start
sleep 15

# Test the website
# http://localhost:8080/
```

### Production Features

- **Container Support**: Docker deployment available
- **Load Balancing**: Nginx or similar web server
- **SSL/TLS**: HTTPS encryption
- **Monitoring**: Health checks and metrics
- **Backup**: Database and configuration backups
- **Scaling**: Horizontal scaling support

### Common Issues – Quick Guide

1. **Service startup**: Check logs, ensure dependencies installed
2. **Port conflicts**: Services use different ports (8080-8084)
3. **Database errors**: Check SQLite configuration
4. **Network issues**: Verify firewall and CORS settings
5. **Authentication**: Check magic link configuration

### Quick Debugging

```bash
# Service logs
$ tail -f atp.log

# System resources
$ top
$ free -h

# Service health checks
curl http://localhost:8080/health
curl http://localhost:8081/health
```

### Documentation Resources

- **API Reference**: Detailed API docs in each project README
- **Tutorials**: Getting started guides
- **Examples**: Sample implementations
- **Best Practices**: Development and deployment guidelines

### Community Support

- **GitHub**: Source code and issue tracking
- **Discussions**: Feature requests and feedback
- **Support**: Technical assistance and troubleshooting
- **Contributing**: Project contributions and improvements

## License

### AzzurroTech Projects

© 2025 Azzurro Technology Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Emperor42 Projects

© 2025 Matthew Salvatore Giancola. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Acknowledgments

- Special thanks to all contributors
- Built with Go (AzzurroTech projects) and JavaScript (Emperor42 projects)
- Powered by ATP platform for seamless integration
- Inspired by modern web development practices

---

*Document Version: 1.0*
*Created: 2026-08-25*
*Last Updated: 2026-08-25*
*Status: Complete Project Documentation*