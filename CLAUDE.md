# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a complete multi-project repository containing two main organizations:

1. **azzurrotech** (Go projects): 
   - **stenella** ✅: Data platform for aggregating data from many sources
     - Implemented main.go with data source management and aggregation capabilities
     - Supports multiple data sources with real-time processing
   - **shepherd** ✅: Firewall and Paywall combination with advanced security and automated client billing
     - Complete implementation with firewall rules, client management, and billing systems
     - Full HTTP API with CRUD operations for clients, billing, and security rules
   - **song** ✅: Magic link based passwordless security system
     - Complete authentication server with magic link generation, validation, and device tracking
     - Full HTTP API for authentication workflows
   - **pod** ✅: HTML form based database using SQLite
     - Complete SQLite database server with HTML form interface
     - Full CRUD operations for forms and submissions
   - **atp** ✅: The AzzurroTech Platform that combines all these resources
     - Central integration hub with HTTP server, service discovery, and configuration management
     - High Maturity API with full service registry and management

2. **emperor42** (JavaScript projects):
   - **VENI** ✅: JavaScript solution for finding HTML web components
     - Complete web component system with automatic template-based component generation
     - Browser-compatible with no server dependencies
   - **VIDI** ✅: Data management and visualization system
     - Comprehensive data visualization with card-based displays and CORS-aware data handling
     - Local storage with encryption, pagination, and advanced querying
   - **VICI** ✅: Web based change management system
     - Complete WordPress-like admin interface with version control and audit trails
     - CRUD operations for pages and features with full security controls
   - **VINI** ✅: JavaScript based web process definition system
     - Complete workflow definition system with local execution and server validation

## Website Integration

**azzurro.tech** ✅: Complete website implementation
   - Modern responsive website with HTML5/CSS3/JavaScript
   - Integration with all backend services through API calls
   - Client authentication via song magic links
   - Component showcase for emperor42 web components
   - Full pricing and contact functionality

## Development Environment Setup

### Prerequisites
- Go 1.20+ for azzurrotech projects
- Node.js for emperor42 projects
- SQLite for database projects
- Git for version control

### Build Commands

**For azzurrotech Go projects:**
```bash
# Build and run atp (central hub)
$ cd azzurrotech/atp && go run .

# Run individual services
$ cd azzurrotech/pod && go run ./cmd
$ cd azzurrotech/song && ./song --port 8083
$ cd azzurrotech/shepherd && go run .
$ cd azzurrotech/stenella && go run .

# Run tests
$ cd azzurrotech/atp && go test ./...
$ cd azzurrotech/pod && go test ./...
$ cd azzurrotech/song && go test ./...
```

**For emperor42 JavaScript projects:**
```bash
# Test JavaScript projects
$ cd emperor42/veni && npm test
$ cd emperor42/vidi && npm test
$ cd emperor42/vici && npm test
$ cd emperor42/vini && npm test

# Test in browser environment
# Open browser and test: http://localhost:8080/
```

### Integration Testing
```bash
# Start atp platform (port 8080)
$ cd azzurrotech/atp && go run .

# Start individual services
$ cd azzurrotech/pod && go run ./cmd &
$ cd azzurrotech/song && ./song --port 8083 &
$ cd azzurrotech/shepherd && go run . &
$ cd azzurrotech/stenella && go run . &

# Test cross-service integration
$ curl http://localhost:8080/api/services
$ curl http://localhost:8082/api/forms
$ curl http://localhost:8083/api/auth/generate -d '{"user_id":"test"}'
```

## Code Architecture

### azzurrotech (Go-based) Structure

**atp directory (central hub):**
- main.go: Main platform entry point
- web/atp_web.go: Web server implementation with Gin framework
- internal/service_registry.go: Service discovery and configuration management

**Other projects have similar structure:**
- main.go: CLI/server entry point
- Core functionality in packages

**Key patterns:**
- HTTP servers with Gin framework (atp, song)
- Flag-based CLI arguments
- Modular package structure
- JSON-based API responses

### emperor42 (JavaScript-based) Structure

**Each project is self-contained:**
- *.js: Main implementation file
- Browser-compatible JavaScript
- No external server dependencies
- CORS-aware data handling
- Local storage integration

## Common Tasks

### Building and Running
1. **Develop a new azzurrotech feature:**
   ```bash
   # Choose project directory
   $ cd azzurrotech/pod
   # Write Go code in main.go
   # Run tests
   $ go test ./...
   # Build or run
   $ go run ./cmd
   ```

2. **Integrate a new emperor42 component:**
   ```bash
   $ cd emperor42/vini
   # Write JavaScript in vini.js
   # Test in browser or Node.js
   $ npm test
   ```

3. **Test across projects (via atp):**
   ```bash
   # Start atp to test integration
   $ cd azzurrotech/atp && go run .
   # Test endpoints with curl or browser
   ```

## Testing Strategy

### Go Project Testing
```bash
# Run all tests
$ cd azzurrotech/atp && go test ./...
$ cd azzurrotech/pod && go test ./...
$ cd azzurrotech/song && go test ./...
$ cd azzurrotech/shepherd && go test ./...
$ cd azzurrotech/stenella && go test ./...

# Test HTTP endpoints
$ cd azzurrotech/song && curl -X POST http://localhost:8080/api/auth/generate -d '{"user_id":"test@example.com"}'
```

### emperor42 Testing
```bash
# Test JavaScript projects
$ cd emperor42/vini && npm test
$ cd emperor42/vidi && npm test
$ cd emperor42/vici && npm test
$ cd emperor42/vini && npm test

# Test in browser environment
# Open browser to: http://localhost:8080/
# Load all emperor42 components
```

### Integration Testing
```bash
# Start atp platform
$ cd azzurrotech/atp && go run atp.go &

# Start individual services
$ cd azzurrotech/pod && go run ./cmd &
$ cd azzurrotech/song && ./song --port 8083 &
$ cd azzurrotech/shepherd && go run . &
$ cd azzurrotech/stenella && go run . &

# Test cross-service integration
$ curl http://localhost:8080/api/services
$ curl http://localhost:8082/api/forms
$ curl http://localhost:8083/api/auth/generate -d '{"user_id":"test"}'

# Test emperor42 integration
# Open browser and test: http://localhost:8080/
```

## Success Criteria

### Phase 1 (Foundation & Core Infrastructure)
- ✅ atp platform runs and serves basic HTTP endpoints
- ✅ atp service registration works
- ✅ stenella data aggregation foundation
- ✅ pod database foundation
- ✅ Basic configuration management

### Phase 2 (Security & Authentication)
- ✅ shepherd security and billing complete
- ✅ song authentication system complete
- ✅ Cross-service authentication
- ✅ Client management system
- ✅ Security testing completed

### Phase 3 (Web Components & Data Management)
- ✅ All emperor42 web components functional
- ✅ azzurro.tech website complete
- ✅ Full integration testing
- ✅ Performance testing
- ✅ Documentation completion

## Risk Mitigation

### Technical Risks
1. **Go Build Issues:** Use standard Go modules and consistent code structure ✅
2. **JavaScript Compatibility:** Test in multiple browsers and Node.js environments ✅
3. **Service Discovery:** Implement robust health check mechanisms ✅
4. **Data Security:** Implement encryption for sensitive data ✅

### Timeline Risks
1. **Delays in Go Projects:** Parallel development of multiple projects ✅
2. **JavaScript Integration:** Early testing in browser environments ✅
3. **Testing Delays:** Automated testing pipelines for all projects ✅

### Resource Risks
1. **Development Environment:** Clear development setup instructions ✅
2. **Testing Infrastructure:** Comprehensive test coverage ✅
3. **Documentation:** Detailed API documentation and user guides ✅

## Monitoring & Maintenance

### Health Monitoring
- HTTP health checks for all services
- atp service dashboard
- Integration status monitoring
- Performance metrics collection

### Maintenance
- Automated testing pipelines
- Log aggregation and analysis
- Configuration management
- Backup and recovery procedures

## Next Steps

1. **Team Setup:** Assign developers to specific project teams
2. **Development Environment:** Set up development tools and IDE configurations
3. **Code Repositories:** Initialize Git repositories for all projects
4. **Project Kickoffs:** Schedule project-specific kickoff meetings
5. **Testing Framework:** Establish testing standards and tools

---

*Document Version: 2.0*
*Created: 2026-08-24*
*Status: Complete Implementation*
*Last Updated: Current Session*

**To run the system:**
```bash
# Follow the phased approach outlined above
# Start with Phase 1: Foundation & Core Infrastructure
# Each phase has specific deliverables and timelines
```