# 🧅 Microservicio con Arquitectura Onion en Lenguaje Aura (usando Framework Gin)

[![Lenguaje Aura](https://img.shields.io/badge/Aura-v0.4.0-blue.svg)](https://auraprojects.dev)
[![Framework Web Gin](https://img.shields.io/badge/Gin%20para%20Aura-v1.0.0-green.svg)](../gin)
[![Arquitectura](https://img.shields.io/badge/Arquitectura-Onion%20%2F%20Limpia%20%2F%20Hexagonal-orange.svg)](#resumen-de-arquitectura)
[![Pruebas](https://img.shields.io/badge/Pruebas-38%20Superadas%20%2F%20100%25%20%C3%89xito-brightgreen.svg)](#ejecuci%C3%B3n-de-pruebas)

Un microservicio de nivel empresarial para el **Procesamiento de Órdenes y Gestión de Inventario** desarrollado con el **Lenguaje de Programación Aura** (`aurac` v0.4.0) implementando estrictamente la **Arquitectura Onion** (Arquitectura Limpia / Puertos y Adaptadores) impulsado por el framework web de alto rendimiento **Gin para Aura**.

---

## 📑 Tabla de Contenidos

- [Resumen de Arquitectura](#-resumen-de-arquitectura)
  - [Capas Concéntricas Onion](#capas-concéntricas-onion)
  - [Regla de Dependencias](#regla-de-dependencias)
- [Estructura de Directorios](#-estructura-de-directorios)
- [Profundización en las Capas Arquitectónicas](#-profundización-en-las-capas-arquitectónicas)
  - [1. Capa de Dominio (El Núcleo)](#1-capa-de-dominio-el-núcleo)
  - [2. Capa de Aplicación (Casos de Uso y Puertos)](#2-capa-de-aplicación-casos-de-uso-y-puertos)
  - [3. Capa de Infraestructura (Adaptadores)](#3-capa-de-infraestructura-adaptadores)
  - [4. Capa de Presentación (HTTP y Gin)](#4-capa-de-presentación-http-y-gin)
  - [5. Raíz de Composición (Bootstrap)](#5-raíz-de-composición-bootstrap)
- [Ciclo de Vida de una Petición](#-ciclo-de-vida-de-una-petición)
- [Referencia de Endpoints API](#-referencia-de-endpoints-api)
- [Guía de Inicio y Ejecución](#-guía-de-inicio-y-ejecución)
  - [Requisitos Previos](#requisitos-previos)
  - [Ejecutar el Microservicio](#ejecutar-el-microservicio)
  - [Ejecución de Pruebas](#ejecución-de-pruebas)
  - [Compilar un Binario Independiente](#compilar-un-binario-independiente)
- [Paradigmas del Lenguaje Aura Utilizados](#-paradigmas-del-lenguaje-aura-utilizados)

---

## 🏛 Resumen de Arquitectura

La Arquitectura Onion (introducida por Jeffrey Palermo) se basa en anillos concéntricos con **inversión de control**. Todas las dependencias de código apuntan estrictamente hacia el **interior**, es decir, hacia el dominio del negocio. La Capa de Dominio contiene las reglas de negocio y entidades empresariales, teniendo **cero dependencias** de frameworks externos, bases de datos o protocolos de transporte.

### Capas Concéntricas Onion

```mermaid
flowchart TD
    subgraph Presentacion ["Capa de Presentación (HTTP y Framework Gin)"]
        OH["OrderHttpHandler"]
        PH["ProductHttpHandler"]
        SH["SystemHttpHandler"]
        Router["Router Gin y Pila de Middleware"]
    end

    subgraph Infraestructura ["Capa de Infraestructura (Adaptadores Externos)"]
        OrderRepo["InMemoryOrderRepository"]
        ProductRepo["InMemoryProductRepository"]
        EventBus["CSPEventBus (Fibras y Canales)"]
        Notifier["EmailNotifier"]
        Audit["SecurityAuditAdapter"]
    end

    subgraph Aplicacion ["Capa de Aplicación (Casos de Uso y Puertos)"]
        Ports["Interfaces de Puertos (IOrderRepo, IProductRepo, INotifier, IEventPub)"]
        DTOs["DTOs de Petición/Respuesta y Mapeadores"]
        OrderUC["OrderUseCase"]
        CatalogUC["CatalogUseCase"]
    end

    subgraph Dominio ["Capa de Dominio (Reglas de Negocio Puras)"]
        Product["Agregado Product (Invariantes de Stock)"]
        Order["Agregado Order (Transiciones de Estado)"]
        OrderItem["Objeto de Valor OrderItem"]
        PricingService["Servicio de Dominio Pricing (IVA y Descuentos VIP)"]
        DomainEvents["Eventos de Dominio (OrderCreated, Confirmed, Cancelled)"]
        DomainErrors["Errores de Dominio Puros"]
    end

    Presentacion --> Aplicacion
    Infraestructura --> Aplicacion
    Aplicacion --> Dominio
```

### Regla de Dependencias

```mermaid
flowchart LR
    L4["Presentación / Infraestructura (Exterior)"] --> L3["Capa de Aplicación (Casos de Uso)"] --> L2["Servicios de Dominio"] --> L1["Entidades de Dominio y Núcleo (Interior)"]
```

1. **Las capas internas nunca conocen las capas externas**: El dominio no importa ni Gin, ni base de datos, ni librerías HTTP.
2. **Puertos y Adaptadores (Inversión de Dependencias)**: La capa de aplicación define interfaces abstractas (`ports.aura`). La capa de infraestructura proporciona las implementaciones concretas (`inmemory_order_repo.aura`, `csp_event_bus.aura`).
3. **Raíz de Composición Pura**: Las dependencias se resuelven explícitamente en el arranque en `cmd/server/main.aura` sin reflexión en tiempo de ejecución.

---

## 📂 Estructura de Directorios

```
onion-gin/
├── aura.mod                               # Módulo Aura (v0.4.0)
├── aura.lock                              # Lockfile de dependencias
├── cmd/
│   └── server/
│       └── main.aura                      # Raíz de Composición (Inyección de Dependencias y Bootstrap)
├── internal/
│   ├── domain/                            # 1. CAPA DE DOMINIO (Cero dependencias externas)
│   │   ├── errors.aura                    # Constantes y predicados de errores de negocio
│   │   ├── events.aura                    # Struct DomainEvent y tipos de eventos del ciclo de vida
│   │   ├── model/
│   │   │   ├── order.aura                 # Agregado Order y objeto de valor OrderItem
│   │   │   └── product.aura               # Agregado Product con invariantes de stock
│   │   └── service/
│   │       └── pricing_service.aura       # Servicio de dominio para IVA y totales con descuento
│   │
│   ├── application/                       # 2. CAPA DE APLICACIÓN (Casos de Uso y Contratos)
│   │   ├── dto/
│   │   │   └── order_dto.aura             # DTOs de Entrada/Salida y mapeadores Dominio-DTO
│   │   ├── interfaces/
│   │   │   └── ports.aura                 # Interfaces de Puertos de Entrada y Salida (DIP)
│   │   └── services/
│   │       ├── catalog_service.aura       # CatalogUseCase (Consultar catálogo y reabastecer)
│   │       └── order_service.aura         # OrderUseCase (Crear, confirmar y cancelar órdenes)
│   │
│   ├── infrastructure/                    # 3. CAPA DE INFRAESTRUCTURA (Adaptadores Externos)
│   │   ├── config/
│   │   │   └── config.aura                # Configuración de entorno y runtime del microservicio
│   │   ├── external/
│   │   │   ├── audit_adapter.aura         # SecurityAuditAdapter (Pistas de auditoría de seguridad)
│   │   │   └── email_notifier.aura        # EmailNotifier (Cumple INotificationService)
│   │   ├── messaging/
│   │   │   └── csp_event_bus.aura         # CSPEventBus (Pub/Sub nativo con Canales y Fibras)
│   │   └── persistence/
│   │       ├── inmemory_order_repo.aura   # InMemoryOrderRepository (Cumple IOrderRepository)
│   │       └── inmemory_product_repo.aura # InMemoryProductRepository (Cumple IProductRepository)
│   │
│   └── presentation/                      # 4. CAPA DE PRESENTACIÓN (Transporte HTTP y Gin)
│       └── http/
│           ├── order_handler.aura         # OrderHttpHandler (Despacho de peticiones GinContext)
│           ├── product_handler.aura       # ProductHttpHandler (Catálogo y endpoints de administración)
│           ├── system_handler.aura        # SystemHttpHandler (Chequeo de salud, streaming SSE)
│           └── router.aura                # Agregador de rutas, CORS y middleware BasicAuth
│
├── tests/                                 # SUITES DE PRUEBAS AUTOMATIZADAS (38 pruebas)
│   ├── domain_test.aura                   # Pruebas unitarias de invariantes de dominio y precios
│   ├── usecase_test.aura                  # Pruebas de integración de casos de uso y puertos
│   └── http_integration_test.aura         # Pruebas HTTP de extremo a extremo vía Gin ServeHTTP
│
└── scripts/
    └── run_tests.sh                       # Script ejecutable para correr todas las pruebas
```

---

## 📡 Referencia de Endpoints API

| Método | Endpoint | Autenticación | Descripción |
|:-------|:---------|:--------------|:------------|
| `GET` | `/` | Público | Índice del servicio y directorio de endpoints registrados |
| `GET` | `/health` | Público | Chequeo de salud del microservicio y sondeo de estado |
| `GET` | `/api/v1/stream` | Público | Flujo Server-Sent Events (SSE) en tiempo real mediante Canales CSP |
| `GET` | `/api/v1/products` | Público | Lista todos los productos (Soporta parámetro `?instock=true`) |
| `GET` | `/api/v1/products/:id` | Público | Obtiene los detalles de un producto por ID |
| `POST` | `/api/v1/orders` | Público | Crea una orden y reserva stock de inventario de forma atómica |
| `GET` | `/api/v1/orders` | Público | Lista órdenes (Soporta filtro `?status=CONFIRMED`) |
| `GET` | `/api/v1/orders/:id` | Público | Obtiene los detalles de una orden por ID |
| `POST` | `/api/v1/orders/:id/confirm` | Público | Confirma la orden cambiando su estado a `CONFIRMED` |
| `POST` | `/api/v1/orders/:id/cancel` | Público | Cancela la orden y reincorpora el stock reservado |
| `POST` | `/admin/products` | BasicAuth | Endpoint protegido para crear un producto en el catálogo |
| `POST` | `/admin/products/:id/restock` | BasicAuth | Endpoint protegido para ingresar inventario a un producto |
| `GET` | `/admin/audit` | BasicAuth | Endpoint protegido para consultar el log de auditoría del sistema |

> **Credenciales BasicAuth de Administrador**: Usuario `admin` / Contraseña `onion2026` (`Authorization: Basic YWRtaW46b25pb24yMDI2`)

---

## 🚀 Guía de Inicio y Ejecución

### Requisitos Previos
- Compilador de Aura (`aurac` / `aura` v0.4.0) instalado.
- Entorno de ejecución Node.js (v20+ o v24+).

### Ejecutar el Microservicio
```bash
aura run cmd/server/main.aura
```

### Ejecutar las Suites de Pruebas
Ejecutar la suite completa con sus **38 pruebas**:
```bash
./scripts/run_tests.sh
```
O ejecutar cada suite individualmente:
```bash
# 1. Pruebas Unitarias de Dominio (14 pruebas)
aura run tests/domain_test.aura

# 2. Pruebas de Casos de Uso y Puertos de Aplicación (13 pruebas)
aura run tests/usecase_test.aura

# 3. Pruebas de Integración HTTP vía Gin ServeHTTP (11 pruebas)
aura run tests/http_integration_test.aura
```

### Compilar un Binario Independiente
```bash
aura build cmd/server/main.aura -o onion-gin-server --release
./onion-gin-server
```
