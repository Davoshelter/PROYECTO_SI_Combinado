# PROMPT DE DESARROLLO: Sistema POS ElectroShop

Copia y pega este prompt en el asistente de IA que utilizarás para codificar el sistema completo. Este prompt contiene toda la lógica del negocio, el esquema de la base de datos adaptado y las directrices de arquitectura para construir el backend en ASP.NET Core y el frontend en React.

---

```text
Actúa como un Desarrollador de Software Senior Full Stack con experiencia en arquitecturas ágiles, ASP.NET Core (C#), React y bases de datos PostgreSQL (Supabase). Tu tarea es construir el sistema completo de Punto de Venta (POS) y administración comercial llamado "ElectroShop".

A continuación se detallan los requisitos del negocio, el esquema de base de datos relacional de referencia y las especificaciones técnicas de implementación.

---

### 1. PILA TECNOLÓGICA (STACK)
*   **Backend:** ASP.NET Core Web API (versión .NET 8 o superior) en C#.
    *   Uso de controladores REST (`Controllers`).
    *   Acceso a datos mediante Entity Framework Core (EF Core) adaptado a PostgreSQL/Supabase.
    *   Inyección de dependencias, DTOs para solicitudes/respuestas, y FluentValidation para validación de datos.
    *   Manejo global de excepciones mediante middleware.
*   **Frontend:** React (SPA) con JavaScript/TypeScript, React Router DOM para navegación y TailwindCSS para una UI premium y fluida.
    *   Estado de la aplicación gestionado de forma limpia (Zustand, Context API o Redux Toolkit).
    *   Componentes visuales altamente interactivos, responsivos (móvil y escritorio) y animados.
*   **Base de Datos:** Supabase PostgreSQL.
    *   Se requiere adaptar el esquema relacional provisto a la sintaxis y tipos de datos de PostgreSQL.
    *   Configurar políticas de Row Level Security (RLS) en Supabase para asegurar los accesos de acuerdo al rol del usuario autenticado.

---

### 2. ESQUEMA DE BASE DE DATOS (REFERENCIA LOGICA EN MYSQL)
Adapta la estructura lógica de las siguientes tablas MySQL a tipos de datos compatibles con PostgreSQL (ej. convertir `DATETIME` a `TIMESTAMP WITH TIME ZONE`, `LONGTEXT` a `TEXT` u `OID`, `ENUM` a `VARCHAR` con restricciones `CHECK` o tipos ENUM de Postgres, `INT UNSIGNED` a `INTEGER` o `BIGINT`):

1.  **Configuracion (Singleton — Id siempre = 1):** Almacena datos del negocio, tasa de cambio activa (`TipoCambio`), impuestos (`Iva`), secuencias de folios, configuraciones de WhatsApp y firma digital.
2.  **MetodoPago:** Catálogo de métodos activos (Efectivo Tienda, Transferencia/QR, Delivery) con campos de cuenta bancaria e imagen QR (Base64/URL).
3.  **HistorialTipoCambio:** Log que audita cuándo y quién modificó la tasa de cambio (`TipoCambioNuevo`, `TipoCambioAnterior`).
4.  **Rol, Modulo y RolPermiso:** Estructura de Control de Acceso Granular (ACL). Roles como Administrador, Cajero, Vendedor, Repartidor con permisos de Leer, Crear, Editar, Eliminar por cada módulo.
5.  **Categoria y Producto:** Catálogo. Los productos tienen código de barra, stock, stock mínimo, precio de compra y precio de venta en USD.
6.  **Trabajador:** Usuarios del sistema con credenciales (contraseña encriptada) y rol asignado.
7.  **Cliente:** Datos de contacto, CI, clasificación (normal, vip, frecuente), puntos acumulados y total gastado.
8.  **Proveedor y ProveedorCategoria:** Datos de proveedores y las categorías de productos que abastecen.
9.  **Venta y VentaDetalle:** Ventas procesadas, totalizadas en base a productos, impuestos y descuentos. Almacena la dirección de envío (delivery) y un `HashQR` único de verificación.
10. **SesionCaja:** Control de caja diario. Monto de apertura, balance calculado automáticamente por el sistema frente al arqueo físico (JSON con desglose de billetes) y cálculo de diferencias (sobrantes/faltantes).
11. **OrdenCompra y OrdenCompraDetalle:** Solicitud de reabastecimiento a proveedores con estados de tránsito/recepción.
12. **Devolucion y DevolucionDetalle:** Devoluciones de mercadería vinculadas a ventas específicas con motivos y estado de reingreso al inventario.
13. **MovimientoInventario:** Kardex o bitácora de entradas, salidas y ajustes manuales de stock.
14. **Cotizacion y CotizacionDetalle:** Cotizaciones con validez en días, fecha de expiración, total en USD y moneda local (Bs) a la tasa del día, y plantilla de diseño asociada.
15. **PendienteConfiguracion y PendientePeriodo:** Lógica del DSS para control financiero. Registra gastos fijos mensuales (Alquiler, Facturas, Gastos, Ahorros) y calcula el saldo neto sobrante tras deducir estos costos del ingreso bruto por ventas.

---

### 3. REQUISITOS CLAVE DEL NEGOCIO (MVP + DSS)

*   **Conversión de Moneda en Tiempo Real (USD / Bs):** Toda la información de precios base se guarda en dólares (USD). El frontend React debe consultar la tasa de cambio de `Configuracion` y permitir alternar visualmente los precios de catálogo, carrito y totales entre USD y Bolívares.
*   **Flujo del POS (Checkout de Ventas):**
    *   Selección rápida y búsqueda de clientes por CI/Teléfono. Modal de registro exprés de cliente sin cerrar el carrito.
    *   Cálculo automático de subtotales, IVA y descuentos (porcentaje o monto fijo).
    *   Selector de método de pago: si se escoge Transferencia/QR, debe mostrar el código QR configurado; si se escoge "Delivery", se deben solicitar datos mínimos del repartidor y la dirección de envío.
    *   Descuento automatizado de stock físico al confirmar la venta en el backend mediante transacciones atómicas.
*   **Previsualización y Envío de Notas (Tickets/Cotizaciones):**
    *   Visualizar la nota de venta estructurada con apariencia de ticket térmico antes de imprimir o enviar.
    *   Generar un PDF descargable formal para cotizaciones que incluya el logo del negocio configurado y la fecha de validez.
    *   Botón para compartir la nota/cotización por WhatsApp abriendo la API web de WhatsApp (`wa.me`) con el mensaje pre-formateado.
*   **Validación de Autenticidad con QR:**
    *   Cada venta crea un hash único almacenado en la DB (`HashQR`). Este hash se codifica en un código QR que se dibuja en la nota de venta.
    *   Debe existir una ruta pública accesible (ej: `/validar?qr=HASH`) que no requiera inicio de sesión. Al escanear el QR, esta ruta realiza una consulta pública en el backend y renderiza los detalles reales de la compra para certificar que el recibo es auténtico.
*   **Control de Caja y DSS Financiero:**
    *   Un cajero debe abrir una sesión de caja ingresando el monto inicial. Las ventas acumulan dinero.
    *   Al cerrar caja, se ingresa el arqueo físico. El backend calcula y registra diferencias si existen.
    *   Módulo financiero que deduce del ingreso bruto mensual los gastos fijos configurados (Alquiler, Facturas, Gastos, Ahorros) detallando el beneficio neto real.
*   **Control de Accesos Dinámico:**
    *   La navegación del frontend React y los accesos a los endpoints de ASP.NET Core deben ser interceptados por un validador de permisos dinámico (basado en la matriz `RolPermiso` y JWT). Si un usuario no tiene permiso de "Editar" en el módulo "Inventario", el botón de edición en React se oculta y la API de C# rechaza la solicitud HTTP PUT.

---

### 4. INSTRUCCIONES PASO A PASO PARA EL DESARROLLO

Procederemos de forma incremental. Desarrolla las siguientes etapas:

#### ETAPA 1: CONFIGURACIÓN DE BASE DE DATOS Y AUTENTICACIÓN
1. Genera los scripts de migración PostgreSQL equivalentes al esquema lógico provisto.
2. Configura Supabase DB e integra Supabase Auth en el backend de C# como proveedor de identidad, o implementa un middleware JWT sincronizado.
3. Inserta los datos semilla (roles del sistema, módulos y un usuario administrador inicial).

#### ETAPA 2: BACKEND (ASP.NET CORE WEB API)
1. Estructura el proyecto utilizando capas limpias: `API`, `Services` (Lógica de negocio), `Infrastructure` (EF Core, Supabase SDK, Repositorios) y `Core` (Modelos y DTOs).
2. Desarrolla las APIs de configuración, catálogo de productos (con subida de imagen y optimización a WebP en C# o frontend), y CRUD de categorías.
3. Desarrolla la API de Ventas y el POS con control transaccional del stock y registro en el Kardex (`MovimientoInventario`).
4. Implementa el controlador de Cotizaciones con validación temporal de fecha de vencimiento.
5. Desarrolla los servicios DSS: sesión de caja (apertura/cierre/arqueo) e informes financieros de gastos fijos mensuales (`PendientePeriodo`).

#### ETAPA 3: FRONTEND (REACT SPA)
1. Configura el enrutamiento con React Router DOM implementando Guards basados en roles y permisos devueltos por el login.
2. Crea el Dashboard administrativo interactivo con gráficos (ventas del día, productos más vendidos) alimentados por las APIs del backend.
3. Diseña la interfaz del POS (carrito responsivo rápido y checkout con métodos de pago).
4. Desarrolla el catálogo de administración de productos con validaciones dinámicas y carga visual de stock mínimo.
5. Desarrolla los componentes de cotización con descarga de PDF en el cliente (usando jsPDF) y envío dinámico de WhatsApp.
6. Diseña la página pública de validación `/validar` que consume los datos de venta por hash de forma segura y abierta.

#### ETAPA 4: PRUEBAS Y PUESTA A PUNTO
1. Crea pruebas de integración en el backend para validar el flujo completo de Checkout -> Descuento de stock -> Registro de caja.
2. Asegura que la UI de React sea 100% responsive, fluida y con animaciones de micro-interacción refinadas.
```

Comienza por generar la estructura general del proyecto y la migración PostgreSQL inicial basada en el archivo SQL.
