# Backend ASP.NET Core Web API — ElectroShop POS (Supabase)

## Contexto

El proyecto actual en [API_SI.csproj](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/API_SI.csproj) es un .NET 9 Web API vacío (solo tiene el template WeatherForecast). Se construirá el backend completo con **Models** (entidades EF Core) y **Controllers** REST para todas las 24 tablas del esquema PostgreSQL adaptado en [DB.sql](file:///d:/PROYECTO_SI_Combinado/DB.sql).

---

## User Review Required

> [!IMPORTANT]
> **Conexión a Supabase:** Se configurará el `ConnectionString` en `appsettings.json` con un placeholder que deberás reemplazar con tu URL de conexión real de Supabase (la encuentras en Project Settings → Database → Connection string → .NET).

> [!IMPORTANT]
> **Autenticación JWT:** Se implementará un middleware JWT básico que valide tokens. Deberás configurar tu `JwtSecret` en `appsettings.json`. Si prefieres usar Supabase Auth directamente, se puede adaptar después.

> [!WARNING]
> **Archivos que se eliminarán:** Se borrarán los archivos del template: `WeatherForecast.cs` y `Controllers/WeatherForecastController.cs`.

---

## Proposed Changes

### Paquetes NuGet Requeridos

Se agregarán los siguientes paquetes al [API_SI.csproj](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/API_SI.csproj):

| Paquete | Propósito |
|---------|-----------|
| `Npgsql.EntityFrameworkCore.PostgreSQL` | Proveedor EF Core para PostgreSQL/Supabase |
| `Microsoft.EntityFrameworkCore.Design` | Herramientas de migración EF Core |
| `Microsoft.AspNetCore.Authentication.JwtBearer` | Autenticación JWT |
| `BCrypt.Net-Next` | Hash de contraseñas para trabajadores |
| `System.IdentityModel.Tokens.Jwt` | Generación de tokens JWT |

---

### Estructura de Carpetas

```
API_SI/API_SI/
├── Controllers/          ← 15 Controllers REST
│   ├── AuthController.cs
│   ├── ConfiguracionController.cs
│   ├── MetodoPagoController.cs
│   ├── RolesController.cs
│   ├── ModulosController.cs
│   ├── CategoriasController.cs
│   ├── TrabajadoresController.cs
│   ├── ClientesController.cs
│   ├── ProveedoresController.cs
│   ├── ProductosController.cs
│   ├── VentasController.cs
│   ├── SesionCajaController.cs
│   ├── OrdenCompraController.cs
│   ├── DevolucionesController.cs
│   ├── MovimientosInventarioController.cs
│   ├── CotizacionesController.cs
│   ├── PendientesController.cs
│   └── ValidarController.cs
├── Models/               ← 24 Entidades EF Core
│   ├── Configuracion.cs
│   ├── MetodoPago.cs
│   ├── HistorialTipoCambio.cs
│   ├── Rol.cs
│   ├── Modulo.cs
│   ├── RolPermiso.cs
│   ├── Categoria.cs
│   ├── Trabajador.cs
│   ├── Cliente.cs
│   ├── Proveedor.cs
│   ├── ProveedorCategoria.cs
│   ├── Producto.cs
│   ├── Venta.cs
│   ├── VentaDetalle.cs
│   ├── SesionCaja.cs
│   ├── OrdenCompra.cs
│   ├── OrdenCompraDetalle.cs
│   ├── Devolucion.cs
│   ├── DevolucionDetalle.cs
│   ├── MovimientoInventario.cs
│   ├── Cotizacion.cs
│   ├── CotizacionDetalle.cs
│   ├── PendienteConfiguracion.cs
│   └── PendientePeriodo.cs
├── DTOs/                 ← Request/Response DTOs
│   ├── Auth/
│   │   ├── LoginRequest.cs
│   │   └── LoginResponse.cs
│   ├── Configuracion/
│   │   └── ConfiguracionUpdateDto.cs
│   ├── Ventas/
│   │   ├── CrearVentaRequest.cs
│   │   └── VentaDetalleDto.cs
│   ├── Cotizaciones/
│   │   ├── CrearCotizacionRequest.cs
│   │   └── CotizacionDetalleDto.cs
│   ├── OrdenCompra/
│   │   ├── CrearOrdenCompraRequest.cs
│   │   └── OrdenCompraDetalleDto.cs
│   ├── Devoluciones/
│   │   ├── CrearDevolucionRequest.cs
│   │   └── DevolucionDetalleDto.cs
│   ├── SesionCaja/
│   │   ├── AbrirCajaRequest.cs
│   │   └── CerrarCajaRequest.cs
│   └── Pendientes/
│       └── CerrarPeriodoRequest.cs
├── Data/
│   └── AppDbContext.cs   ← DbContext con Fluent API
├── Middleware/
│   └── ExceptionMiddleware.cs
├── Program.cs            ← Configuración DI, Auth, CORS, EF Core
├── appsettings.json      ← ConnectionString + JWT config
└── appsettings.Development.json
```

---

### Componente: Data (DbContext)

#### [NEW] [AppDbContext.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Data/AppDbContext.cs)

- Registra los 24 `DbSet<T>` para cada entidad.
- Configura en `OnModelCreating` con Fluent API:
  - Mapeos de nombres de tabla (`ToTable("Configuracion")`).
  - Conversiones de ENUMs PostgreSQL a `string` usando `.HasConversion<string>()`.
  - Relaciones, claves compuestas (`ProveedorCategoria`), restricciones `CHECK`, y valores por defecto.
  - Datos semilla: roles del sistema (Administrador, Cajero, Vendedor, Repartidor), módulos del sistema, permisos del administrador, y un trabajador administrador inicial.

---

### Componente: Models (24 entidades)

#### [NEW] Carpeta `Models/` — 24 archivos

Cada entidad C# mapea exactamente a una tabla PostgreSQL. Decisiones clave:

- Los ENUMs de PostgreSQL se representan como `string` en C# (EF Core los mapea con `HasConversion<string>()`). Esto evita dependencias con el proveedor Npgsql para tipos custom.
- Las propiedades de navegación se incluyen para facilitar las consultas con `.Include()`.
- `DateTimeOffset` se usa para todas las columnas `TIMESTAMPTZ`.
- `JsonDocument` (o `Dictionary<string, object>`) para la columna `JSONB` de `SesionCaja.ConteoEfectivo`.

Ejemplo representativo — `Producto.cs`:
```csharp
public class Producto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = null!;
    public string Nombre { get; set; } = null!;
    public int IdCategoria { get; set; }
    public decimal PrecioCompra { get; set; }
    public decimal PrecioVenta { get; set; }
    public int Stock { get; set; }
    public int StockMinimo { get; set; }
    public string Unidad { get; set; } = null!;       // "und","kg","lt","gr"
    public string Estado { get; set; } = null!;        // "activo","inactivo"
    public int? IdProveedor { get; set; }
    public int UnidadesVendidas { get; set; }
    public string? Imagen { get; set; }
    public DateTimeOffset CreadoEn { get; set; }
    public DateTimeOffset ActualizadoEn { get; set; }

    // Navegación
    public Categoria Categoria { get; set; } = null!;
    public Proveedor? Proveedor { get; set; }
    public ICollection<VentaDetalle> VentaDetalles { get; set; } = new List<VentaDetalle>();
}
```

---

### Componente: Controllers (18 controllers)

Todos los controllers siguen el patrón `[ApiController]` + `[Route("api/[controller]")]` con inyección de `AppDbContext`.

#### [NEW] [AuthController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/AuthController.cs)
- `POST /api/auth/login` — Valida email/password con BCrypt, genera JWT con claims de IdTrabajador, Nombre, IdRol, y permisos.

#### [NEW] [ConfiguracionController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/ConfiguracionController.cs)
- `GET /api/configuracion` — Retorna el singleton (Id=1).
- `PUT /api/configuracion` — Actualiza la configuración. Si cambia `TipoCambio`, registra en `HistorialTipoCambio`.

#### [NEW] [MetodoPagoController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/MetodoPagoController.cs)
- CRUD completo: `GET`, `GET/{id}`, `POST`, `PUT/{id}`, `DELETE/{id}`.

#### [NEW] [RolesController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/RolesController.cs)
- CRUD de roles + gestión de permisos (`GET /api/roles/{id}/permisos`, `PUT /api/roles/{id}/permisos`).

#### [NEW] [ModulosController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/ModulosController.cs)
- `GET /api/modulos` — Lista todos los módulos del sistema.

#### [NEW] [CategoriasController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/CategoriasController.cs)
- CRUD completo con conteo de productos por categoría.

#### [NEW] [TrabajadoresController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/TrabajadoresController.cs)
- CRUD completo. El `POST` hashea la contraseña con BCrypt. Include del Rol.

#### [NEW] [ClientesController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/ClientesController.cs)
- CRUD completo + búsqueda por CI/Teléfono (`GET /api/clientes/buscar?q=`).

#### [NEW] [ProveedoresController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/ProveedoresController.cs)
- CRUD completo + gestión de categorías asociadas (`PUT /api/proveedores/{id}/categorias`).

#### [NEW] [ProductosController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/ProductosController.cs)
- CRUD completo con Include de Categoria y Proveedor. Búsqueda por código/nombre.

#### [NEW] [VentasController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/VentasController.cs)
- `GET /api/ventas` — Lista con filtros de fecha, cliente, trabajador.
- `GET /api/ventas/{id}` — Detalle completo con Include de detalles, cliente, trabajador, método de pago.
- `POST /api/ventas` — **Lógica transaccional**: Crea venta + detalles, descuenta stock, registra movimientos de inventario, actualiza `UnidadesVendidas`, `TotalCompras` y `TotalGastado` del cliente, genera `HashQR` (SHA256).

#### [NEW] [SesionCajaController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/SesionCajaController.cs)
- `POST /api/sesioncaja/abrir` — Abre sesión de caja con monto inicial.
- `PUT /api/sesioncaja/{id}/cerrar` — Cierra caja con arqueo físico (JSON de billetes), calcula monto esperado y diferencia.
- `GET /api/sesioncaja/actual` — Retorna la sesión abierta del trabajador actual.
- `GET /api/sesioncaja` — Historial de sesiones.

#### [NEW] [OrdenCompraController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/OrdenCompraController.cs)
- CRUD + cambio de estado (`PUT /api/ordencompra/{id}/recibir` — Actualiza stock de productos al recibir + registra movimientos de inventario).

#### [NEW] [DevolucionesController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/DevolucionesController.cs)
- `POST /api/devoluciones` — Crea devolución transaccional: si `Reingreso = true`, restituye stock + registra movimiento de inventario.
- `GET /api/devoluciones` + `GET /api/devoluciones/{id}`.

#### [NEW] [MovimientosInventarioController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/MovimientosInventarioController.cs)
- `GET /api/movimientos` — Kardex/bitácora con filtros por producto, tipo, fecha.
- `POST /api/movimientos` — Ajuste manual de stock.

#### [NEW] [CotizacionesController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/CotizacionesController.cs)
- CRUD completo. El `POST` genera número secuencial basado en `Configuracion.SecuencialCotizacion`, calcula `TotalMonedaLocal` usando `TipoCambio`, genera `HashQR`.
- `PUT /api/cotizaciones/{id}/estado` — Cambiar estado (aceptar, rechazar).

#### [NEW] [PendientesController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/PendientesController.cs)
- `GET /api/pendientes/configuracion` + `PUT` — Config de gastos fijos.
- `GET /api/pendientes/periodos` — Lista períodos.
- `POST /api/pendientes/periodos/cerrar` — Cierra el período actual calculando el sobrante (IngresoBruto - gastos fijos).

#### [NEW] [ValidarController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/ValidarController.cs)
- `GET /api/validar?qr={hash}` — **Ruta pública** (sin autenticación). Busca venta/cotización por HashQR y retorna datos para verificación de autenticidad.

#### [DELETE] [WeatherForecastController.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Controllers/WeatherForecastController.cs)

---

### Componente: DTOs

#### [NEW] Carpeta `DTOs/` — ~15 archivos

DTOs de entrada para operaciones complejas (ventas, cotizaciones, caja, devoluciones, órdenes de compra). Esto separa la capa de transporte de las entidades y permite validación limpia. Las operaciones CRUD simples usarán las entidades directamente.

---

### Componente: Middleware

#### [NEW] [ExceptionMiddleware.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Middleware/ExceptionMiddleware.cs)
- Captura excepciones no manejadas y retorna respuestas JSON estandarizadas con código HTTP apropiado.

---

### Componente: Configuración

#### [MODIFY] [Program.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/Program.cs)
- Registrar `AppDbContext` con `UseNpgsql`.
- Configurar autenticación JWT Bearer.
- Configurar CORS (permisivo para desarrollo).
- Registrar middleware de excepciones.
- Eliminar referencia a `WeatherForecast`.

#### [MODIFY] [appsettings.json](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/appsettings.json)
- Agregar `ConnectionStrings.DefaultConnection` con placeholder de Supabase.
- Agregar sección `Jwt` con `Secret`, `Issuer`, `Audience`, `ExpirationMinutes`.

#### [MODIFY] [API_SI.csproj](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/API_SI.csproj)
- Agregar los 4 paquetes NuGet requeridos.

#### [DELETE] [WeatherForecast.cs](file:///d:/PROYECTO_SI_Combinado/API_SI/API_SI/WeatherForecast.cs)

---

## Datos Semilla (Seed Data)

Se insertarán mediante `HasData()` en el DbContext:

| Tabla | Datos |
|-------|-------|
| **Rol** | Administrador, Cajero, Vendedor, Repartidor |
| **Modulo** | Dashboard, POS, Productos, Categorias, Clientes, Trabajadores, Proveedores, Inventario, Ventas, Cotizaciones, Compras, Devoluciones, Caja, Reportes, Configuracion |
| **RolPermiso** | El rol Administrador tiene todos los permisos en todos los módulos |
| **Trabajador** | Admin inicial (email: `admin@electroshop.com`, password: `Admin123!`) |
| **Configuracion** | Registro singleton con valores por defecto |
| **MetodoPago** | Efectivo, Transferencia/QR, Delivery |
| **PendienteConfiguracion** | Registro singleton con valores por defecto (0.00) |

---

## Verification Plan

### Automated Tests
```bash
cd d:\PROYECTO_SI_Combinado\API_SI\API_SI
dotnet build
dotnet run
```

### Manual Verification
- Verificar que la API compile sin errores.
- Verificar que los endpoints respondan correctamente usando Swagger/OpenAPI.
- Validar que la conexión a Supabase funcione (requiere que el usuario configure su connection string).
