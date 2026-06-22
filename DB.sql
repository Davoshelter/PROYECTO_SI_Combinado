-- -------------------------------------------------------------
-- Adaptación del Schema de Base de Datos para PostgreSQL / Supabase
-- Base de Datos: ElectroShop
-- -------------------------------------------------------------

-- 1. Eliminar tablas existentes (en orden inverso de dependencias para evitar conflictos de claves foráneas)
DROP TABLE IF EXISTS PendientePeriodo CASCADE;
DROP TABLE IF EXISTS PendienteConfiguracion CASCADE;
DROP TABLE IF EXISTS CotizacionDetalle CASCADE;
DROP TABLE IF EXISTS Cotizacion CASCADE;
DROP TABLE IF EXISTS MovimientoInventario CASCADE;
DROP TABLE IF EXISTS DevolucionDetalle CASCADE;
DROP TABLE IF EXISTS Devolucion CASCADE;
DROP TABLE IF EXISTS OrdenCompraDetalle CASCADE;
DROP TABLE IF EXISTS OrdenCompra CASCADE;
DROP TABLE IF EXISTS SesionCaja CASCADE;
DROP TABLE IF EXISTS VentaDetalle CASCADE;
DROP TABLE IF EXISTS Venta CASCADE;
DROP TABLE IF EXISTS Producto CASCADE;
DROP TABLE IF EXISTS ProveedorCategoria CASCADE;
DROP TABLE IF EXISTS Proveedor CASCADE;
DROP TABLE IF EXISTS Cliente CASCADE;
DROP TABLE IF EXISTS Trabajador CASCADE;
DROP TABLE IF EXISTS HistorialTipoCambio CASCADE;
DROP TABLE IF EXISTS RolPermiso CASCADE;
DROP TABLE IF EXISTS Modulo CASCADE;
DROP TABLE IF EXISTS Rol CASCADE;
DROP TABLE IF EXISTS MetodoPago CASCADE;
DROP TABLE IF EXISTS Configuracion CASCADE;

-- 2. Eliminar tipos personalizados (ENUMs) existentes
DROP TYPE IF EXISTS plantilla_tipo CASCADE;
DROP TYPE IF EXISTS estado_activo_inactivo CASCADE;
DROP TYPE IF EXISTS condicion_pago_tipo CASCADE;
DROP TYPE IF EXISTS cliente_tipo CASCADE;
DROP TYPE IF EXISTS unidad_producto_tipo CASCADE;
DROP TYPE IF EXISTS venta_estado CASCADE;
DROP TYPE IF EXISTS caja_estado CASCADE;
DROP TYPE IF EXISTS orden_compra_estado CASCADE;
DROP TYPE IF EXISTS reembolso_metodo CASCADE;
DROP TYPE IF EXISTS estado_devolucion CASCADE;
DROP TYPE IF EXISTS devolucion_motivo CASCADE;
DROP TYPE IF EXISTS movimiento_tipo CASCADE;
DROP TYPE IF EXISTS cotizacion_estado CASCADE;

-- 3. Crear tipos personalizados (ENUMs)
CREATE TYPE plantilla_tipo AS ENUM ('T1', 'T2', 'T3', 'T4', 'T5', 'T6');
CREATE TYPE estado_activo_inactivo AS ENUM ('activo', 'inactivo');
CREATE TYPE condicion_pago_tipo AS ENUM ('7 días', '15 días', '30 días', '45 días', '60 días', 'Contado');
CREATE TYPE cliente_tipo AS ENUM ('normal', 'frecuente', 'vip');
CREATE TYPE unidad_producto_tipo AS ENUM ('und', 'kg', 'lt', 'gr');
CREATE TYPE venta_estado AS ENUM ('completada', 'cancelada');
CREATE TYPE caja_estado AS ENUM ('abierta', 'cerrada');
CREATE TYPE orden_compra_estado AS ENUM ('pendiente', 'enviada', 'recibida');
CREATE TYPE reembolso_metodo AS ENUM ('efectivo', 'tarjeta', 'transferencia');
CREATE TYPE estado_devolucion AS ENUM ('procesada', 'pendiente');
CREATE TYPE devolucion_motivo AS ENUM (
    'Producto vencido',
    'Producto en mal estado',
    'Empaque dañado',
    'Producto incorrecto',
    'Cambio de decisión',
    'Defecto de fábrica',
    'Otro'
);
CREATE TYPE movimiento_tipo AS ENUM ('entrada', 'salida', 'ajuste');
CREATE TYPE cotizacion_estado AS ENUM ('pendiente', 'aceptada', 'rechazada', 'vencida');

-- 4. Creación de Tablas

-- 4.1. Configuracion (singleton — un solo registro, Id siempre = 1)
CREATE TABLE Configuracion (
    Id                    INT           NOT NULL DEFAULT 1 PRIMARY KEY,
    Nombre                VARCHAR(100)  NOT NULL,
    RazonSocial           VARCHAR(150)      NULL,
    Ruc                   VARCHAR(20)       NULL,
    Direccion             VARCHAR(255)      NULL,
    Ciudad                VARCHAR(100)      NULL,
    Pais                  VARCHAR(100)      NULL,
    Telefono              VARCHAR(30)       NULL,
    Celular               VARCHAR(30)       NULL,
    Email                 VARCHAR(150)      NULL,
    SitioWeb              VARCHAR(255)      NULL,
    RegimenTributario     VARCHAR(100)      NULL,
    LogoImagen            VARCHAR(255)      NULL,
    Iva                   DECIMAL(5,2)  NOT NULL,
    PrefijoFactura        VARCHAR(20)   NOT NULL,
    SecuencialFactura     INT           NOT NULL,
    SecuencialCotizacion  INT           NOT NULL,
    MonedaBase            VARCHAR(10)   NOT NULL,
    SimboloMoneda         VARCHAR(10)   NOT NULL,
    MonedaVisualizacion   VARCHAR(10)   NOT NULL,
    TipoCambio            DECIMAL(10,4) NOT NULL,
    MensajeRecibo         TEXT              NULL,
    PieFactura            TEXT              NULL,
    PlantillaRecibo       plantilla_tipo NOT NULL,
    PlantillaCotizacion   plantilla_tipo NOT NULL,
    CodigoPaisWhatsapp    VARCHAR(10)   NOT NULL,
    MensajeWhatsapp       TEXT              NULL,
    ClaveFirmaDigital     VARCHAR(100)      NULL,
    CreadoEn              TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn         TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_config_singleton CHECK (Id = 1)
);

-- 4.2. MetodoPago
CREATE TABLE MetodoPago (
    Id              SERIAL PRIMARY KEY,
    Clave           VARCHAR(30)  NOT NULL UNIQUE,
    Nombre          VARCHAR(80)  NOT NULL,
    Icono           VARCHAR(50)      NULL,
    Activo          BOOLEAN      NOT NULL,
    Banco           VARCHAR(100)     NULL,
    NombreCuenta    VARCHAR(100)     NULL,
    NumeroCuenta    VARCHAR(50)      NULL,
    Titular         VARCHAR(100)     NULL,
    ImagenQR        TEXT             NULL,
    CreadoEn        TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4.3. HistorialTipoCambio
CREATE TABLE HistorialTipoCambio (
    Id                    SERIAL PRIMARY KEY,
    TipoCambioAnterior    DECIMAL(10,4) NOT NULL,
    TipoCambioNuevo       DECIMAL(10,4) NOT NULL,
    Fecha                 TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    IdTrabajador          INT               NULL,
    CreadoEn              TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4.4. Rol
CREATE TABLE Rol (
    Id            SERIAL PRIMARY KEY,
    Nombre        VARCHAR(50)  NOT NULL,
    Descripcion   VARCHAR(255)     NULL,
    Color         VARCHAR(7)   NOT NULL,
    EsSistema     BOOLEAN      NOT NULL,
    CreadoEn      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4.5. Modulo
CREATE TABLE Modulo (
    Id      SERIAL PRIMARY KEY,
    Clave   VARCHAR(30)  NOT NULL UNIQUE,
    Nombre  VARCHAR(60)  NOT NULL,
    Orden   SMALLINT     NOT NULL
);

-- 4.6. RolPermiso
CREATE TABLE RolPermiso (
    Id        SERIAL PRIMARY KEY,
    IdRol     INT     NOT NULL,
    IdModulo  INT     NOT NULL,
    Leer      BOOLEAN NOT NULL,
    Crear     BOOLEAN NOT NULL,
    Editar    BOOLEAN NOT NULL,
    Eliminar  BOOLEAN NOT NULL,

    CONSTRAINT uk_rol_modulo UNIQUE (IdRol, IdModulo),
    CONSTRAINT fk_rp_rol    FOREIGN KEY (IdRol)    REFERENCES Rol(Id)    ON DELETE CASCADE,
    CONSTRAINT fk_rp_modulo FOREIGN KEY (IdModulo) REFERENCES Modulo(Id) ON DELETE CASCADE
);

-- 4.7. Categoria
CREATE TABLE Categoria (
    Id            SERIAL PRIMARY KEY,
    Nombre        VARCHAR(100) NOT NULL,
    Descripcion   VARCHAR(255)     NULL,
    Icono         VARCHAR(50)  NOT NULL,
    Color         VARCHAR(7)   NOT NULL,
    ColorFondo    VARCHAR(9)       NULL,
    CreadoEn      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4.8. Trabajador
CREATE TABLE Trabajador (
    Id            SERIAL PRIMARY KEY,
    Nombre        VARCHAR(100) NOT NULL,
    IdRol         INT          NOT NULL,
    Email         VARCHAR(150)     NULL,
    Password      VARCHAR(255)     NOT NULL,
    Telefono      VARCHAR(30)      NULL,
    Direccion     VARCHAR(255)     NULL,
    Estado        estado_activo_inactivo NOT NULL,
    FechaIngreso  DATE         NOT NULL,
    Salario       DECIMAL(10,2) NOT NULL,
    Avatar        VARCHAR(5)       NULL,
    ColorAvatar   VARCHAR(7)       NULL,
    CreadoEn      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_trab_rol FOREIGN KEY (IdRol) REFERENCES Rol(Id)
);

CREATE INDEX idx_trab_estado ON Trabajador (Estado);
CREATE INDEX idx_trab_rol ON Trabajador (IdRol);

-- FK diferida: HistorialTipoCambio → Trabajador
ALTER TABLE HistorialTipoCambio
    ADD CONSTRAINT fk_htc_trabajador
    FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id) ON DELETE SET NULL;

-- 4.9. Cliente
CREATE TABLE Cliente (
    Id              SERIAL PRIMARY KEY,
    Nombre          VARCHAR(150)  NOT NULL,
    Email           VARCHAR(150)      NULL,
    Telefono        VARCHAR(30)       NULL,
    CI              VARCHAR(20)       NULL,
    Direccion       VARCHAR(255)      NULL,
    Tipo            cliente_tipo  NOT NULL,
    Puntos          INT           NOT NULL,
    TotalCompras    INT           NOT NULL,
    TotalGastado    DECIMAL(12,2) NOT NULL,
    FechaRegistro   DATE          NOT NULL,
    CreadoEn        TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cli_tipo ON Cliente (Tipo);

-- 4.10. Proveedor
CREATE TABLE Proveedor (
    Id              SERIAL PRIMARY KEY,
    Nombre          VARCHAR(150) NOT NULL,
    Contacto        VARCHAR(100)     NULL,
    Ruc             VARCHAR(20)      NULL,
    Email           VARCHAR(150)     NULL,
    Telefono        VARCHAR(30)      NULL,
    Direccion       VARCHAR(255)     NULL,
    CondicionPago   condicion_pago_tipo NOT NULL,
    Estado          estado_activo_inactivo NOT NULL,
    CreadoEn        TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_prov_estado ON Proveedor (Estado);

-- 4.11. ProveedorCategoria
CREATE TABLE ProveedorCategoria (
    IdProveedor INT NOT NULL,
    IdCategoria INT NOT NULL,

    PRIMARY KEY (IdProveedor, IdCategoria),
    CONSTRAINT fk_pc_proveedor FOREIGN KEY (IdProveedor) REFERENCES Proveedor(Id)  ON DELETE CASCADE,
    CONSTRAINT fk_pc_categoria FOREIGN KEY (IdCategoria) REFERENCES Categoria(Id) ON DELETE CASCADE
);

-- 4.12. Producto
CREATE TABLE Producto (
    Id                SERIAL PRIMARY KEY,
    Codigo            VARCHAR(20)   NOT NULL UNIQUE,
    Nombre            VARCHAR(200)  NOT NULL,
    IdCategoria       INT           NOT NULL,
    PrecioCompra      DECIMAL(10,2) NOT NULL,
    PrecioVenta       DECIMAL(10,2) NOT NULL,
    Stock             INT           NOT NULL,
    StockMinimo       INT           NOT NULL,
    Unidad            unidad_producto_tipo NOT NULL,
    Estado            estado_activo_inactivo NOT NULL,
    IdProveedor       INT               NULL,
    UnidadesVendidas  INT           NOT NULL,
    Imagen            TEXT              NULL,
    CreadoEn          TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn     TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_prod_categoria FOREIGN KEY (IdCategoria) REFERENCES Categoria(Id),
    CONSTRAINT fk_prod_proveedor FOREIGN KEY (IdProveedor) REFERENCES Proveedor(Id) ON DELETE SET NULL
);

CREATE INDEX idx_prod_categoria ON Producto (IdCategoria);
CREATE INDEX idx_prod_estado ON Producto (Estado);
CREATE INDEX idx_prod_proveedor ON Producto (IdProveedor);

-- 4.13. Venta
CREATE TABLE Venta (
    Id                  SERIAL PRIMARY KEY,
    Fecha               TIMESTAMPTZ   NOT NULL,
    IdCliente           INT           NOT NULL,
    IdTrabajador        INT           NOT NULL,
    IdMetodoPago        INT           NOT NULL,
    Subtotal            DECIMAL(12,2) NOT NULL,
    Descuento           DECIMAL(5,2)  NOT NULL,
    MontoDescuento      DECIMAL(12,2) NOT NULL,
    Impuesto            DECIMAL(12,2) NOT NULL,
    Total               DECIMAL(12,2) NOT NULL,
    EfectivoRecibido    DECIMAL(12,2)     NULL,
    DireccionEnvio      VARCHAR(255)      NULL,
    Estado              venta_estado  NOT NULL,
    HashQR              VARCHAR(64)       NULL,
    CreadoEn            TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_vta_cliente    FOREIGN KEY (IdCliente)    REFERENCES Cliente(Id),
    CONSTRAINT fk_vta_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id),
    CONSTRAINT fk_vta_metodo     FOREIGN KEY (IdMetodoPago) REFERENCES MetodoPago(Id)
);

CREATE INDEX idx_vta_fecha      (Fecha);
CREATE INDEX idx_vta_cliente    (IdCliente);
CREATE INDEX idx_vta_trabajador (IdTrabajador);
CREATE INDEX idx_vta_metodo     (IdMetodoPago);

-- 4.14. VentaDetalle
CREATE TABLE VentaDetalle (
    Id              SERIAL PRIMARY KEY,
    IdVenta         INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    PrecioUnitario  DECIMAL(10,2) NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_vd_venta    FOREIGN KEY (IdVenta)    REFERENCES Venta(Id)    ON DELETE CASCADE,
    CONSTRAINT fk_vd_producto FOREIGN KEY (IdProducto) REFERENCES Producto(Id)
);

CREATE INDEX idx_vd_venta    (IdVenta);
CREATE INDEX idx_vd_producto (IdProducto);

-- 4.15. SesionCaja
CREATE TABLE SesionCaja (
    Id              SERIAL PRIMARY KEY,
    IdTrabajador    INT           NOT NULL,
    FechaApertura   TIMESTAMPTZ   NOT NULL,
    FechaCierre     TIMESTAMPTZ       NULL,
    MontoApertura   DECIMAL(12,2) NOT NULL,
    ConteoEfectivo  JSONB             NULL,
    MontoCierre     DECIMAL(12,2)     NULL,
    MontoEsperado   DECIMAL(12,2)     NULL,
    Diferencia      DECIMAL(12,2)     NULL,
    Estado          caja_estado   NOT NULL,
    Notas           TEXT              NULL,
    CreadoEn        TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sc_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id)
);

CREATE INDEX idx_sc_estado     (Estado);
CREATE INDEX idx_sc_trabajador (IdTrabajador);
CREATE INDEX idx_sc_apertura   (FechaApertura);

-- 4.16. OrdenCompra
CREATE TABLE OrdenCompra (
    Id              SERIAL PRIMARY KEY,
    Fecha           DATE          NOT NULL,
    IdProveedor     INT           NOT NULL,
    IdTrabajador    INT           NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,
    Impuesto        DECIMAL(12,2) NOT NULL,
    Total           DECIMAL(12,2) NOT NULL,
    Estado          orden_compra_estado NOT NULL,
    FechaEsperada   DATE          NOT NULL,
    FechaRecepcion  DATE              NULL,
    Notas           TEXT              NULL,
    CreadoEn        TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_oc_proveedor  FOREIGN KEY (IdProveedor)  REFERENCES Proveedor(Id),
    CONSTRAINT fk_oc_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id)
);

CREATE INDEX idx_oc_estado    (Estado);
CREATE INDEX idx_oc_proveedor (IdProveedor);
CREATE INDEX idx_oc_fecha     (Fecha);

-- 4.17. OrdenCompraDetalle
CREATE TABLE OrdenCompraDetalle (
    Id              SERIAL PRIMARY KEY,
    IdOrdenCompra   INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    CostoUnitario   DECIMAL(10,2) NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_ocd_orden    FOREIGN KEY (IdOrdenCompra) REFERENCES OrdenCompra(Id) ON DELETE CASCADE,
    CONSTRAINT fk_ocd_producto FOREIGN KEY (IdProducto)    REFERENCES Producto(Id)
);

CREATE INDEX idx_ocd_orden (IdOrdenCompra);

-- 4.18. Devolucion
CREATE TABLE Devolucion (
    Id                SERIAL PRIMARY KEY,
    Fecha             TIMESTAMPTZ   NOT NULL,
    IdVenta           INT           NOT NULL,
    IdTrabajador      INT           NOT NULL,
    Total             DECIMAL(12,2) NOT NULL,
    MetodoReembolso   reembolso_metodo NOT NULL,
    Reingreso         BOOLEAN       NOT NULL,
    Estado            devolucion_estado NOT NULL,
    Notas             TEXT              NULL,
    CreadoEn          TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dev_venta      FOREIGN KEY (IdVenta)      REFERENCES Venta(Id),
    CONSTRAINT fk_dev_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id)
);

CREATE INDEX idx_dev_venta (IdVenta);
CREATE INDEX idx_dev_fecha (Fecha);

-- 4.19. DevolucionDetalle
CREATE TABLE DevolucionDetalle (
    Id              SERIAL PRIMARY KEY,
    IdDevolucion    INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    PrecioUnitario  DECIMAL(10,2) NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,
    Motivo          devolucion_motivo NOT NULL,

    CONSTRAINT fk_dd_devolucion FOREIGN KEY (IdDevolucion) REFERENCES Devolucion(Id) ON DELETE CASCADE,
    CONSTRAINT fk_dd_producto   FOREIGN KEY (IdProducto)   REFERENCES Producto(Id)
);

CREATE INDEX idx_dd_devolucion (IdDevolucion);

-- 4.20. MovimientoInventario
CREATE TABLE MovimientoInventario (
    Id              SERIAL PRIMARY KEY,
    Fecha           TIMESTAMPTZ   NOT NULL,
    Tipo            movimiento_tipo NOT NULL,
    IdProducto      INT          NOT NULL,
    Cantidad        INT          NOT NULL,
    Motivo          VARCHAR(255) NOT NULL,
    IdProveedor     INT              NULL,
    IdTrabajador    INT          NOT NULL,
    CreadoEn        TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_mi_producto   FOREIGN KEY (IdProducto)   REFERENCES Producto(Id),
    CONSTRAINT fk_mi_proveedor  FOREIGN KEY (IdProveedor)  REFERENCES Proveedor(Id)   ON DELETE SET NULL,
    CONSTRAINT fk_mi_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id)
);

CREATE INDEX idx_mi_tipo     (Tipo);
CREATE INDEX idx_mi_producto (IdProducto);
CREATE INDEX idx_mi_fecha    (Fecha);

-- 4.21. Cotizacion
CREATE TABLE Cotizacion (
    Id                  SERIAL PRIMARY KEY,
    Numero              VARCHAR(20)   NOT NULL UNIQUE,
    IdCliente           INT               NULL,
    ClienteNombre       VARCHAR(150)  NOT NULL,
    ClienteCI           VARCHAR(20)       NULL,
    ClienteTelefono     VARCHAR(30)       NULL,
    ClienteEmail        VARCHAR(150)      NULL,
    DescuentoGlobal     DECIMAL(5,2)  NOT NULL,
    Subtotal            DECIMAL(12,2) NOT NULL,
    MontoDescuento      DECIMAL(12,2) NOT NULL,
    Total               DECIMAL(12,2) NOT NULL,
    TotalMonedaLocal    DECIMAL(12,2) NOT NULL,
    TipoCambio          DECIMAL(10,4) NOT NULL,
    MonedaLocal         VARCHAR(10)   NOT NULL,
    DiasValidez         INT           NOT NULL,
    FechaVencimiento    DATE          NOT NULL,
    Notas               TEXT              NULL,
    Estado              cotizacion_estado NOT NULL,
    FechaCreacion       TIMESTAMPTZ   NOT NULL,
    IdTrabajador        INT           NOT NULL,
    Plantilla           plantilla_tipo NOT NULL,
    HashQR              VARCHAR(64)       NULL,
    CreadoEn            TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn       TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cot_cliente    FOREIGN KEY (IdCliente)    REFERENCES Cliente(Id)    ON DELETE SET NULL,
    CONSTRAINT fk_cot_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id)
);

CREATE INDEX idx_cot_estado  (Estado);
CREATE INDEX idx_cot_cliente (IdCliente);
CREATE INDEX idx_cot_fecha   (FechaCreacion);

-- 4.22. CotizacionDetalle
CREATE TABLE CotizacionDetalle (
    Id              SERIAL PRIMARY KEY,
    IdCotizacion    INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    PrecioUnitario  DECIMAL(10,2) NOT NULL,
    Descuento       DECIMAL(5,2)  NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_cd_cotizacion FOREIGN KEY (IdCotizacion) REFERENCES Cotizacion(Id) ON DELETE CASCADE,
    CONSTRAINT fk_cd_producto   FOREIGN KEY (IdProducto)   REFERENCES Producto(Id)
);

CREATE INDEX idx_cd_cotizacion (IdCotizacion);

-- 4.23. PendienteConfiguracion
CREATE TABLE PendienteConfiguracion (
    Id            INT           NOT NULL DEFAULT 1 PRIMARY KEY,
    Ahorros       DECIMAL(12,2) NOT NULL,
    Gastos        DECIMAL(12,2) NOT NULL,
    Facturas      DECIMAL(12,2) NOT NULL,
    Alquiler      DECIMAL(12,2) NOT NULL,
    ActualizadoEn TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_pendiente_singleton CHECK (Id = 1)
);

-- 4.24. PendientePeriodo
CREATE TABLE PendientePeriodo (
    Id            SERIAL PRIMARY KEY,
    Periodo       VARCHAR(7)    NOT NULL UNIQUE,
    Etiqueta      VARCHAR(50)   NOT NULL,
    IngresoBruto  DECIMAL(12,2) NOT NULL,
    Ahorros       DECIMAL(12,2) NOT NULL,
    Gastos        DECIMAL(12,2) NOT NULL,
    Facturas      DECIMAL(12,2) NOT NULL,
    Alquiler      DECIMAL(12,2) NOT NULL,
    TotalFijo     DECIMAL(12,2) NOT NULL,
    Sobrante      DECIMAL(12,2) NOT NULL,
    Notas         TEXT              NULL,
    CerradoEn     TIMESTAMPTZ       NULL,
    CreadoEn      TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. Disparadores (Triggers) para simular ON UPDATE CURRENT_TIMESTAMP en PostgreSQL

-- 5.1. Función disparadora reutilizable
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ActualizadoEn = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5.2. Asignación de Triggers a las tablas correspondientes
CREATE TRIGGER trg_configuracion_actualizadoen BEFORE UPDATE ON Configuracion FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_metodopago_actualizadoen BEFORE UPDATE ON MetodoPago FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_rol_actualizadoen BEFORE UPDATE ON Rol FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_categoria_actualizadoen BEFORE UPDATE ON Categoria FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_trabajador_actualizadoen BEFORE UPDATE ON Trabajador FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_cliente_actualizadoen BEFORE UPDATE ON Cliente FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_proveedor_actualizadoen BEFORE UPDATE ON Proveedor FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_producto_actualizadoen BEFORE UPDATE ON Producto FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_ordencompra_actualizadoen BEFORE UPDATE ON OrdenCompra FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_cotizacion_actualizadoen BEFORE UPDATE ON Cotizacion FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_pendienteconfiguracion_actualizadoen BEFORE UPDATE ON PendienteConfiguracion FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
