# 🧅 Onion Architecture Microservice in Aura Language (using Gin Framework)

[![Aura Language](https://img.shields.io/badge/Aura-v0.4.0-blue.svg)](https://auraprojects.dev)
[![Gin Web Framework](https://img.shields.io/badge/Gin%20for%20Aura-v1.0.0-green.svg)](../gin)
[![Architecture](https://img.shields.io/badge/Architecture-Onion%20%2F%20Clean%20%2F%20Hexagonal-orange.svg)](#architecture-overview)
[![Tests](https://img.shields.io/badge/Tests-38%20Passed%20%2F%20100%25%20Success-brightgreen.svg)](#running-tests)

A production-grade **E-Commerce Order Fulfillment & Inventory Management Microservice** built with the **Aura Programming Language** (`aurac` v0.4.0) implementing strict **Onion Architecture** (Clean / Ports & Adapters Architecture) powered by the high-performance **Gin Web Framework for Aura**.

---

## 📑 Table of Contents

- [Architecture Overview](#-architecture-overview)
  - [Concentric Onion Layers](#concentric-onion-layers)
  - [The Dependency Rule](#the-dependency-rule)
- [Layer Directory Structure](#-layer-directory-structure)
- [Deep Dive into Architectural Layers](#-deep-dive-into-architectural-layers)
  - [1. Domain Layer (The Core)](#1-domain-layer-the-core)
  - [2. Application Layer (Use Cases & Ports)](#2-application-layer-use-cases--ports)
  - [3. Infrastructure Layer (Adapters)](#3-infrastructure-layer-adapters)
  - [4. Presentation Layer (HTTP & Gin)](#4-presentation-layer-http--gin)
  - [5. Composition Root (Bootstrap)](#5-composition-root-bootstrap)
- [Request Lifecycle Flow](#-request-lifecycle-flow)
- [API Endpoints Reference](#-api-endpoints-reference)
- [Getting Started & Execution](#-getting-started--execution)
  - [Prerequisites](#prerequisites)
  - [Running the Microservice](#running-the-microservice)
  - [Running the Test Suites](#running-the-test-suites)
  - [Building a Standalone Binary](#building-a-standalone-binary)
- [Aura Language Paradigms Leveraged](#-aura-language-paradigms-leveraged)

---

## 🏛 Architecture Overview

Onion Architecture (introduced by Jeffrey Palermo) relies on concentric rings with **inversion of control**. All code dependencies point strictly **inwards** toward the business domain. The Domain Layer contains enterprise business rules and entities, having **zero dependencies** on external frameworks, databases, or transport protocols.

### Concentric Onion Layers

```mermaid
flowchart TD
    subgraph Presentation ["Presentation Layer (HTTP & Gin Framework)"]
        OH["OrderHttpHandler"]
        PH["ProductHttpHandler"]
        SH["SystemHttpHandler"]
        Router["Gin Router & Middleware Stack"]
    end

    subgraph Infrastructure ["Infrastructure Layer (External Adapters)"]
        OrderRepo["InMemoryOrderRepository"]
        ProductRepo["InMemoryProductRepository"]
        EventBus["CSPEventBus (Fibers & Channels)"]
        Notifier["EmailNotifier"]
        Audit["SecurityAuditAdapter"]
    end

    subgraph Application ["Application Layer (Use Cases & Ports)"]
        Ports["Port Interfaces (IOrderRepo, IProductRepo, INotifier, IEventPub)"]
        DTOs["Request / Response DTOs & Mappers"]
        OrderUC["OrderUseCase"]
        CatalogUC["CatalogUseCase"]
    end

    subgraph Domain ["Domain Layer (Core Business Rules)"]
        Product["Product Aggregate (Stock Invariants)"]
        Order["Order Aggregate (State Transitions)"]
        OrderItem["OrderItem Value Object"]
        PricingService["Pricing Domain Service (VAT & VIP Discounts)"]
        DomainEvents["Domain Events (OrderCreated, Confirmed, Cancelled)"]
        DomainErrors["Pure Domain Errors"]
    end

    Presentation --> Application
    Infrastructure --> Application
    Application --> Domain
```

### The Dependency Rule

```mermaid
flowchart LR
    L4["Presentation / Infrastructure (Outer)"] --> L3["Application Layer (Use Cases)"] --> L2["Domain Services"] --> L1["Domain Entities & Core (Inner)"]
```

1. **Inner layers never know about outer layers**: The Domain layer imports neither Gin, nor databases, nor HTTP libraries.
2. **Ports & Adapters (Dependency Inversion)**: The Application layer defines outbound interfaces (`ports.aura`). The Infrastructure layer provides the concrete implementations (`inmemory_order_repo.aura`, `csp_event_bus.aura`).
3. **Pure Composition Root**: Inversion of control is resolved explicitly at startup in `cmd/server/main.aura` without runtime reflection or magical annotations.

---

## 📂 Layer Directory Structure

```
onion-gin/
├── aura.mod                               # Aura module definition (v0.4.0)
├── aura.lock                              # Dependency lockfile
├── cmd/
│   └── server/
│       └── main.aura                      # Composition Root (Dependency Injection & Bootstrapper)
├── internal/
│   ├── domain/                            # 1. DOMAIN LAYER (Zero external dependencies)
│   │   ├── errors.aura                    # Pure business error constants & predicates
│   │   ├── events.aura                    # DomainEvent struct & lifecycle event types
│   │   ├── model/
│   │   │   ├── order.aura                 # Order aggregate root & OrderItem value object
│   │   │   └── product.aura               # Product aggregate root with stock invariants
│   │   └── service/
│   │       └── pricing_service.aura       # Pure domain service for VAT & discount totals
│   │
│   ├── application/                       # 2. APPLICATION LAYER (Business Use Cases & Contracts)
│   │   ├── dto/
│   │   │   └── order_dto.aura             # Input/Output DTOs & Domain-to-DTO mappers
│   │   ├── interfaces/
│   │   │   └── ports.aura                 # Inbound & Outbound Port interfaces (DIP)
│   │   └── services/
│   │       ├── catalog_service.aura       # CatalogUseCase (Query catalog & restock)
│   │       └── order_service.aura         # OrderUseCase (Place, confirm, and cancel orders)
│   │
│   ├── infrastructure/                    # 3. INFRASTRUCTURE LAYER (External Adapters)
│   │   ├── config/
│   │   │   └── config.aura                # Microservice environment & runtime settings
│   │   ├── external/
│   │   │   ├── audit_adapter.aura         # SecurityAuditAdapter (Security audit trail)
│   │   │   └── email_notifier.aura        # EmailNotifier (Fulfills INotificationService)
│   │   ├── messaging/
│   │   │   └── csp_event_bus.aura         # CSPEventBus (Native Channels & Fibers pub/sub)
│   │   └── persistence/
│   │       ├── inmemory_order_repo.aura   # InMemoryOrderRepository (Fulfills IOrderRepository)
│   │       └── inmemory_product_repo.aura # InMemoryProductRepository (Fulfills IProductRepository)
│   │
│   └── presentation/                      # 4. PRESENTATION LAYER (HTTP Transport & Gin)
│       └── http/
│           ├── order_handler.aura         # OrderHttpHandler (Gin Context request dispatches)
│           ├── product_handler.aura       # ProductHttpHandler (Product catalog & admin endpoints)
│           ├── system_handler.aura        # SystemHttpHandler (Health check, SSE live stream)
│           └── router.aura                # Router aggregator, CORS, and BasicAuth middleware
│
├── tests/                                 # AUTOMATED TEST SUITES (38 tests)
│   ├── domain_test.aura                   # Domain aggregate invariants & pricing unit tests
│   ├── usecase_test.aura                  # Application use case & port integration tests
│   └── http_integration_test.aura         # Full HTTP dispatch tests via Gin ServeHTTP
│
└── scripts/
    └── run_tests.sh                       # Executable test runner script
```

---

## 🔍 Deep Dive into Architectural Layers

### 1. Domain Layer (The Core)
Located at `internal/domain/`. Contains the core enterprise business entities, value objects, and business rules:

- **`Product` Aggregate Root** (`internal/domain/model/product.aura`):
  - Invariant rules: stock cannot be negative, units must be active to reserve.
  - State methods: `CanReserve(quantity)`, `ReserveStock(quantity)`, `ReleaseStock(quantity)`, `Restock(quantity)`.
- **`Order` Aggregate Root & `OrderItem` Value Object** (`internal/domain/model/order.aura`):
  - State machine with strict status transitions: `PENDING` ➔ `CONFIRMED` ➔ `SHIPPED` ➔ `DELIVERED`.
  - Invariant enforcement: Shipped/Delivered orders cannot be cancelled; cancelled orders cannot be confirmed.
- **`PricingService`** (`internal/domain/service/pricing_service.aura`):
  - Pure calculation engine applying VIP customer promotional discounts and statutory VAT taxes.
- **`DomainEvent`** (`internal/domain/events.aura`):
  - First-class events: `ORDER_CREATED`, `ORDER_CONFIRMED`, `ORDER_CANCELLED`.
- **`DomainErrors`** (`internal/domain/errors.aura`):
  - Explicit error predicates (`IsDomainError`) returning type-safe `Result<T, String>`.

### 2. Application Layer (Use Cases & Ports)
Located at `internal/application/`. Orchestrates user interactions, manages domain models, and directs transactions:

- **Ports** (`internal/application/interfaces/ports.aura`):
  - `IOrderRepository`: Save, FindById, FindAll, Update.
  - `IProductRepository`: Save, FindById, FindBySku, FindAll, Update.
  - `INotificationService`: Order placed, confirmed, cancelled email notifications.
  - `IEventPublisher`: Asynchronous publishing of `DomainEvent` instances.
- **Use Cases**:
  - `OrderUseCase`: Coordinates multi-item stock reservation, total calculations, order persistence, email alerts, and CSP domain event publishing. Handles automated inventory restitution upon cancellation.
  - `CatalogUseCase`: Manages product discovery, query filtering, and inventory restocking.
- **DTOs & Mappers** (`internal/application/dto/order_dto.aura`):
  - Decouples inner domain structs from HTTP serialization representations.

### 3. Infrastructure Layer (Adapters)
Located at `internal/infrastructure/`. Implements the ports defined by the application layer:

- **`InMemoryOrderRepository` & `InMemoryProductRepository`**:
  - Thread-safe repository adapters with pre-seeded enterprise items.
- **`CSPEventBus`** (`internal/infrastructure/messaging/csp_event_bus.aura`):
  - Leverages Aura's native Communicating Sequential Processes (`Channel<String>` & `spawn` fibers) for non-blocking asynchronous pub/sub event broadcasting.
- **`EmailNotifier`** (`internal/infrastructure/external/email_notifier.aura`):
  - Adapter recording and dispatching customer communications.
- **`SecurityAuditAdapter`** (`internal/infrastructure/external/audit_adapter.aura`):
  - Records administrative actions and compliance audit logs.

### 4. Presentation Layer (HTTP & Gin)
Located at `internal/presentation/http/`. Exposes HTTP endpoints using the **Gin Web Framework for Aura**:

- **Handlers**:
  - `OrderHttpHandler`: Decodes JSON bodies with schema validation (`ValidateSchema`), delegates to `OrderUseCase`, and serializes responses.
  - `ProductHttpHandler`: Exposes public catalog listings and authenticated admin inventory controls.
  - `SystemHttpHandler`: Exposes `/health`, `/admin/audit`, and `/api/v1/stream` (real-time Server-Sent Events via CSP channels).
- **Router Configuration** (`router.aura`):
  - Route groups (`/api/v1`, `/admin`).
  - Middleware: `Logger()`, `Recovery()`, `CORS()`, `BasicAuth()`.
  - Fallback `NoRoute` 404 handler.

### 5. Composition Root (Bootstrap)
Located at `cmd/server/main.aura`. The single place where all dependencies are wired together:
```aura
// Pure Dependency Injection (No Magic, No Reflection)
let config = LoadConfig();
let mut orderRepo = NewInMemoryOrderRepository();
let mut productRepo = NewInMemoryProductRepository();
let mut eventBus = NewCSPEventBus();
let mut notifier = NewEmailNotifier();
let mut auditAdapter = NewSecurityAuditAdapter();

let pricingService = NewPricingService(config.taxRate, config.vipDiscountRate);

let orderUseCase = NewOrderUseCase(&orderRepo, &productRepo, pricingService, &notifier, &eventBus);
let catalogUseCase = NewCatalogUseCase(&productRepo);

let orderHandler = NewOrderHttpHandler(orderUseCase);
let productHandler = NewProductHttpHandler(catalogUseCase);
let systemHandler = NewSystemHttpHandler(config, &auditAdapter, &eventBus);

let router = SetupRouter(orderHandler, productHandler, systemHandler, config);
router.Run(config.port);
```

---

## 🔄 Request Lifecycle Flow

```mermaid
sequenceDiagram
    autonumber
    actor Client as HTTP Client
    participant Gin as Gin Engine / Router
    participant MW as Middleware (Auth / CORS)
    participant Handler as OrderHttpHandler
    participant DTO as DTO Mapper
    participant UseCase as OrderUseCase
    participant Domain as Order & Product Aggregates
    participant Repo as InMemoryProductRepo
    participant Bus as CSPEventBus (Fiber)

    Client->>Gin: POST /api/v1/orders (JSON body)
    Gin->>MW: Check CORS & pipeline
    MW->>Handler: HandleCreateOrder(c)
    Handler->>Handler: ValidateSchema(body)
    Handler->>DTO: Map to CreateOrderRequestDTO
    Handler->>UseCase: CreateOrder(reqDto)
    
    UseCase->>Repo: FindById(productId)
    Repo-->>UseCase: Product
    UseCase->>Domain: prod.ReserveStock(qty)
    Domain-->>UseCase: Ok(()) (Invariant Enforced)
    UseCase->>Repo: Update(prod)
    
    UseCase->>Domain: NewOrder(items, tax, discount)
    Domain-->>UseCase: Order Aggregate
    UseCase->>Bus: Publish(EventOrderCreated)
    Note over Bus: Fiber publishes asynchronously via Channel<String>
    
    UseCase-->>Handler: Ok(Order)
    Handler->>DTO: ToOrderResponseDTO(order)
    DTO-->>Handler: OrderResponseDTO
    Handler-->>Client: 201 Created (JSON Response)
```

---

## 📡 API Endpoints Reference

| Method | Endpoint | Auth | Description |
|:-------|:---------|:-----|:------------|
| `GET` | `/` | Public | Service index and registered endpoints directory |
| `GET` | `/health` | Public | Microservice health check & uptime probe |
| `GET` | `/api/v1/stream` | Public | Real-time Server-Sent Events (SSE) live data stream via CSP Channels |
| `GET` | `/api/v1/products` | Public | Lists all products (Supports `?instock=true` query param) |
| `GET` | `/api/v1/products/:id` | Public | Retrieves detailed product information by ID |
| `POST` | `/api/v1/orders` | Public | Places a new order and reserves stock atomically |
| `GET` | `/api/v1/orders` | Public | Lists all customer orders (Supports `?status=CONFIRMED` filter) |
| `GET` | `/api/v1/orders/:id` | Public | Retrieves specific order details by ID |
| `POST` | `/api/v1/orders/:id/confirm` | Public | Confirms order moving state to `CONFIRMED` |
| `POST` | `/api/v1/orders/:id/cancel` | Public | Cancels order and automatically restocks reserved inventory |
| `POST` | `/admin/products` | BasicAuth | Protected endpoint to add a new product to the catalog |
| `POST` | `/admin/products/:id/restock` | BasicAuth | Protected endpoint to restock inventory for a product |
| `GET` | `/admin/audit` | BasicAuth | Protected endpoint to retrieve security and system audit logs |

> **Admin BasicAuth Credentials**: `admin` / `onion2026` (`Authorization: Basic YWRtaW46b25pb24yMDI2`)

---

## 🚀 Getting Started & Execution

### Prerequisites
- Aura Language Toolchain (`aurac` / `aura` v0.4.0) installed on your system.
- Node.js runtime (v20+ or v24+).

### Running the Microservice
Start the HTTP server on port `:8080`:
```bash
aura run cmd/server/main.aura
```
Server output:
```text
==================================================================
  Aura Onion-Gin Microservice - Bootstrapping Composition Root    
==================================================================
[Config] Service: Aura Orders & Inventory Microservice | Env: production | Port: :8080
[AUDIT] 🔒 SERVER_INIT by 'system' on 'infrastructure_layer'
[GIN-debug] GET     / --> (4 handlers)
[GIN-debug] GET     /health --> (4 handlers)
[GIN-debug] GET     /api/v1/stream --> (4 handlers)
[GIN-debug] GET     /api/v1/products --> (4 handlers)
[GIN-debug] POST    /api/v1/orders --> (4 handlers)
[GIN-debug] POST    /admin/products --> (5 handlers)

🚀 Onion-Gin Microservice listening on http://localhost:8080
[GIN-debug] Listening and serving HTTP on :8080
```

### Running the Test Suites
Run the full automated test suite containing **38 tests**:
```bash
./scripts/run_tests.sh
```
Or run each layer's test suite individually:
```bash
# 1. Domain Layer Invariant Tests (14 tests)
aura run tests/domain_test.aura

# 2. Application Layer Use Case & Port Tests (13 tests)
aura run tests/usecase_test.aura

# 3. Presentation Layer HTTP Integration Tests via Gin ServeHTTP (11 tests)
aura run tests/http_integration_test.aura
```

### Building a Standalone Binary
To compile the microservice into an optimized standalone executable:
```bash
aura build cmd/server/main.aura -o onion-gin-server --release
./onion-gin-server
```

---

## ⚡ Aura Language Paradigms Leveraged

| Paradigm | How it is used in Onion-Gin |
|:---------|:----------------------------|
| **Result / Option Types** | Eliminates runtime exceptions; all fallible business methods explicitly return `Result<T, String>` or `Option<T>`. |
| **Algebraic Data Types (ADTs)** | Pattern matching (`match res { Ok(v) => ..., Err(e) => ... }`) guarantees exhaustiveness across domain models. |
| **CSP Fibers (`spawn`)** | Background asynchronous processing for domain event publishing without blocking HTTP response times. |
| **Typed Channels (`Channel<T>`)** | Thread-safe inter-fiber communication and HTTP chunked Server-Sent Events (SSE) streaming (`StreamChannel`). |
| **Zero Runtime Reflection** | Struct instances and port interfaces are checked at compile time without dynamic reflection overhead. |
| **Pure Dependency Injection** | High cohesion, low coupling, and 100% unit-testable components across all architectural rings. |

---

## 📄 License
This project is open-source under the MIT License. Built with ❤️ using the **Aura Programming Language** and **Gin Web Framework for Aura**.
