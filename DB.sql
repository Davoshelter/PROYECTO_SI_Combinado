
DROP DATABASE IF EXISTS electroshop_db;

CREATE DATABASE electroshop_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE electroshop_db;

DROP USER IF EXISTS 'electroshop'@'localhost';

CREATE USER 'electroshop'@'localhost' IDENTIFIED BY 'ElectroShop2026!';

GRANT ALL PRIVILEGES ON electroshop_db.* TO 'electroshop'@'localhost';

FLUSH PRIVILEGES;

--  1. Configuracion  (singleton — un solo registro, Id siempre = 1)
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
    SecuencialFactura     INT UNSIGNED  NOT NULL,
    SecuencialCotizacion  INT UNSIGNED  NOT NULL,
    MonedaBase            VARCHAR(10)   NOT NULL,
    SimboloMoneda         VARCHAR(10)   NOT NULL,
    MonedaVisualizacion   VARCHAR(10)   NOT NULL,
    TipoCambio            DECIMAL(10,4) NOT NULL,
    MensajeRecibo         TEXT              NULL,
    PieFactura            TEXT              NULL,
    PlantillaRecibo       ENUM('T1','T2','T3','T4','T5','T6') NOT NULL,
    PlantillaCotizacion   ENUM('T1','T2','T3','T4','T5','T6') NOT NULL,
    CodigoPaisWhatsapp    VARCHAR(10)   NOT NULL,
    MensajeWhatsapp       TEXT              NULL,
    ClaveFirmaDigital     VARCHAR(100)      NULL,
    CreadoEn              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_config_singleton CHECK (Id = 1)
) ENGINE=InnoDB;


CREATE TABLE MetodoPago (
    Id              INT          AUTO_INCREMENT PRIMARY KEY,
    Clave           VARCHAR(30)  NOT NULL UNIQUE,
    Nombre          VARCHAR(80)  NOT NULL,
    Icono           VARCHAR(50)      NULL,
    Activo          BOOLEAN      NOT NULL,
    Banco           VARCHAR(100)     NULL,
    NombreCuenta    VARCHAR(100)     NULL,
    NumeroCuenta    VARCHAR(50)      NULL,
    Titular         VARCHAR(100)     NULL,
    ImagenQR        LONGTEXT         NULL,
    CreadoEn        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE HistorialTipoCambio (
    Id                    INT           AUTO_INCREMENT PRIMARY KEY,
    TipoCambioAnterior    DECIMAL(10,4) NOT NULL,
    TipoCambioNuevo       DECIMAL(10,4) NOT NULL,
    Fecha                 DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    IdTrabajador          INT               NULL,
    CreadoEn              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


CREATE TABLE Rol (
    Id            INT          AUTO_INCREMENT PRIMARY KEY,
    Nombre        VARCHAR(50)  NOT NULL,
    Descripcion   VARCHAR(255)     NULL,
    Color         VARCHAR(7)   NOT NULL,
    EsSistema     BOOLEAN      NOT NULL,
    CreadoEn      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Modulo (
    Id      INT          AUTO_INCREMENT PRIMARY KEY,
    Clave   VARCHAR(30)  NOT NULL UNIQUE,
    Nombre  VARCHAR(60)  NOT NULL,
    Orden   SMALLINT     NOT NULL
) ENGINE=InnoDB;

CREATE TABLE RolPermiso (
    Id        INT     AUTO_INCREMENT PRIMARY KEY,
    IdRol     INT     NOT NULL,
    IdModulo  INT     NOT NULL,
    Leer      BOOLEAN NOT NULL,
    Crear     BOOLEAN NOT NULL,
    Editar    BOOLEAN NOT NULL,
    Eliminar  BOOLEAN NOT NULL,

    UNIQUE KEY uk_rol_modulo (IdRol, IdModulo),
    CONSTRAINT fk_rp_rol    FOREIGN KEY (IdRol)    REFERENCES Rol(Id)    ON DELETE CASCADE,
    CONSTRAINT fk_rp_modulo FOREIGN KEY (IdModulo) REFERENCES Modulo(Id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Categoria (
    Id            INT          AUTO_INCREMENT PRIMARY KEY,
    Nombre        VARCHAR(100) NOT NULL,
    Descripcion   VARCHAR(255)     NULL,
    Icono         VARCHAR(50)  NOT NULL,
    Color         VARCHAR(7)   NOT NULL,
    ColorFondo    VARCHAR(9)       NULL,
    CreadoEn      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Trabajador (
    Id            INT          AUTO_INCREMENT PRIMARY KEY,
    Nombre        VARCHAR(100) NOT NULL,
    IdRol         INT          NOT NULL,
    Email         VARCHAR(150)     NULL,
    Password      VARCHAR(255)     NOT NULL,
    Telefono      VARCHAR(30)      NULL,
    Direccion     VARCHAR(255)     NULL,
    Estado        ENUM('activo','inactivo') NOT NULL,
    FechaIngreso  DATE         NOT NULL,
    Salario       DECIMAL(10,2) NOT NULL,
    Avatar        VARCHAR(5)       NULL,
    ColorAvatar   VARCHAR(7)       NULL,
    CreadoEn      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_trab_rol FOREIGN KEY (IdRol) REFERENCES Rol(Id),
    INDEX idx_trab_estado (Estado),
    INDEX idx_trab_rol    (IdRol)
) ENGINE=InnoDB;

-- FK diferida: HistorialTipoCambio → Trabajador
ALTER TABLE HistorialTipoCambio
    ADD CONSTRAINT fk_htc_trabajador
    FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id) ON DELETE SET NULL;


CREATE TABLE Cliente (
    Id              INT           AUTO_INCREMENT PRIMARY KEY,
    Nombre          VARCHAR(150)  NOT NULL,
    Email           VARCHAR(150)      NULL,
    Telefono        VARCHAR(30)       NULL,
    CI              VARCHAR(20)       NULL,
    Direccion       VARCHAR(255)      NULL,
    Tipo            ENUM('normal','frecuente','vip') NOT NULL,
    Puntos          INT           NOT NULL,
    TotalCompras    INT UNSIGNED  NOT NULL,
    TotalGastado    DECIMAL(12,2) NOT NULL,
    FechaRegistro   DATE          NOT NULL,
    CreadoEn        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_cli_tipo (Tipo)
) ENGINE=InnoDB;

CREATE TABLE Proveedor (
    Id              INT          AUTO_INCREMENT PRIMARY KEY,
    Nombre          VARCHAR(150) NOT NULL,
    Contacto        VARCHAR(100)     NULL,
    Ruc             VARCHAR(20)      NULL,
    Email           VARCHAR(150)     NULL,
    Telefono        VARCHAR(30)      NULL,
    Direccion       VARCHAR(255)     NULL,
    CondicionPago   ENUM('7 días','15 días','30 días','45 días','60 días','Contado') NOT NULL,
    Estado          ENUM('activo','inactivo') NOT NULL,
    CreadoEn        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_prov_estado (Estado)
) ENGINE=InnoDB;

CREATE TABLE ProveedorCategoria (
    IdProveedor INT NOT NULL,
    IdCategoria INT NOT NULL,

    PRIMARY KEY (IdProveedor, IdCategoria),
    CONSTRAINT fk_pc_proveedor FOREIGN KEY (IdProveedor) REFERENCES Proveedor(Id)  ON DELETE CASCADE,
    CONSTRAINT fk_pc_categoria FOREIGN KEY (IdCategoria) REFERENCES Categoria(Id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Producto (
    Id                INT           AUTO_INCREMENT PRIMARY KEY,
    Codigo            VARCHAR(20)   NOT NULL UNIQUE,
    Nombre            VARCHAR(200)  NOT NULL,
    IdCategoria       INT           NOT NULL,
    PrecioCompra      DECIMAL(10,2) NOT NULL,
    PrecioVenta       DECIMAL(10,2) NOT NULL,
    Stock             INT           NOT NULL,
    StockMinimo       INT           NOT NULL,
    Unidad            ENUM('und','kg','lt','gr') NOT NULL,
    Estado            ENUM('activo','inactivo')  NOT NULL,
    IdProveedor       INT               NULL,
    UnidadesVendidas  INT UNSIGNED  NOT NULL,
    Imagen            LONGTEXT          NULL,
    CreadoEn          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_prod_categoria FOREIGN KEY (IdCategoria) REFERENCES Categoria(Id),
    CONSTRAINT fk_prod_proveedor FOREIGN KEY (IdProveedor) REFERENCES Proveedor(Id) ON DELETE SET NULL,
    INDEX idx_prod_categoria (IdCategoria),
    INDEX idx_prod_estado    (Estado),
    INDEX idx_prod_proveedor (IdProveedor)
) ENGINE=InnoDB;

CREATE TABLE Venta (
    Id                  INT           AUTO_INCREMENT PRIMARY KEY,
    Fecha               DATETIME      NOT NULL,
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
    Estado              ENUM('completada','cancelada') NOT NULL,
    HashQR              VARCHAR(64)       NULL,
    CreadoEn            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_vta_cliente    FOREIGN KEY (IdCliente)    REFERENCES Cliente(Id),
    CONSTRAINT fk_vta_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id),
    CONSTRAINT fk_vta_metodo     FOREIGN KEY (IdMetodoPago) REFERENCES MetodoPago(Id),
    INDEX idx_vta_fecha      (Fecha),
    INDEX idx_vta_cliente    (IdCliente),
    INDEX idx_vta_trabajador (IdTrabajador),
    INDEX idx_vta_metodo     (IdMetodoPago)
) ENGINE=InnoDB;

CREATE TABLE VentaDetalle (
    Id              INT           AUTO_INCREMENT PRIMARY KEY,
    IdVenta         INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    PrecioUnitario  DECIMAL(10,2) NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_vd_venta    FOREIGN KEY (IdVenta)    REFERENCES Venta(Id)    ON DELETE CASCADE,
    CONSTRAINT fk_vd_producto FOREIGN KEY (IdProducto) REFERENCES Producto(Id),
    INDEX idx_vd_venta    (IdVenta),
    INDEX idx_vd_producto (IdProducto)
) ENGINE=InnoDB;


CREATE TABLE SesionCaja (
    Id              INT           AUTO_INCREMENT PRIMARY KEY,
    IdTrabajador    INT           NOT NULL,
    FechaApertura   DATETIME      NOT NULL,
    FechaCierre     DATETIME          NULL,
    MontoApertura   DECIMAL(12,2) NOT NULL,
    ConteoEfectivo  JSON              NULL,
    MontoCierre     DECIMAL(12,2)     NULL,
    MontoEsperado   DECIMAL(12,2)     NULL,
    Diferencia      DECIMAL(12,2)     NULL,
    Estado          ENUM('abierta','cerrada') NOT NULL,
    Notas           TEXT              NULL,
    CreadoEn        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sc_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id),
    INDEX idx_sc_estado     (Estado),
    INDEX idx_sc_trabajador (IdTrabajador),
    INDEX idx_sc_apertura   (FechaApertura)
) ENGINE=InnoDB;


CREATE TABLE OrdenCompra (
    Id              INT           AUTO_INCREMENT PRIMARY KEY,
    Fecha           DATE          NOT NULL,
    IdProveedor     INT           NOT NULL,
    IdTrabajador    INT           NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,
    Impuesto        DECIMAL(12,2) NOT NULL,
    Total           DECIMAL(12,2) NOT NULL,
    Estado          ENUM('pendiente','enviada','recibida') NOT NULL,
    FechaEsperada   DATE          NOT NULL,
    FechaRecepcion  DATE              NULL,
    Notas           TEXT              NULL,
    CreadoEn        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_oc_proveedor  FOREIGN KEY (IdProveedor)  REFERENCES Proveedor(Id),
    CONSTRAINT fk_oc_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id),
    INDEX idx_oc_estado    (Estado),
    INDEX idx_oc_proveedor (IdProveedor),
    INDEX idx_oc_fecha     (Fecha)
) ENGINE=InnoDB;


CREATE TABLE OrdenCompraDetalle (
    Id              INT           AUTO_INCREMENT PRIMARY KEY,
    IdOrdenCompra   INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    CostoUnitario   DECIMAL(10,2) NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_ocd_orden    FOREIGN KEY (IdOrdenCompra) REFERENCES OrdenCompra(Id) ON DELETE CASCADE,
    CONSTRAINT fk_ocd_producto FOREIGN KEY (IdProducto)    REFERENCES Producto(Id),
    INDEX idx_ocd_orden (IdOrdenCompra)
) ENGINE=InnoDB;


CREATE TABLE Devolucion (
    Id                INT           AUTO_INCREMENT PRIMARY KEY,
    Fecha             DATETIME      NOT NULL,
    IdVenta           INT           NOT NULL,
    IdTrabajador      INT           NOT NULL,
    Total             DECIMAL(12,2) NOT NULL,
    MetodoReembolso   ENUM('efectivo','tarjeta','transferencia') NOT NULL,
    Reingreso         BOOLEAN       NOT NULL,
    Estado            ENUM('procesada','pendiente') NOT NULL,
    Notas             TEXT              NULL,
    CreadoEn          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_dev_venta      FOREIGN KEY (IdVenta)      REFERENCES Venta(Id),
    CONSTRAINT fk_dev_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id),
    INDEX idx_dev_venta (IdVenta),
    INDEX idx_dev_fecha (Fecha)
) ENGINE=InnoDB;


CREATE TABLE DevolucionDetalle (
    Id              INT           AUTO_INCREMENT PRIMARY KEY,
    IdDevolucion    INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    PrecioUnitario  DECIMAL(10,2) NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,
    Motivo          ENUM(
                        'Producto vencido',
                        'Producto en mal estado',
                        'Empaque dañado',
                        'Producto incorrecto',
                        'Cambio de decisión',
                        'Defecto de fábrica',
                        'Otro'
                    ) NOT NULL,

    CONSTRAINT fk_dd_devolucion FOREIGN KEY (IdDevolucion) REFERENCES Devolucion(Id) ON DELETE CASCADE,
    CONSTRAINT fk_dd_producto   FOREIGN KEY (IdProducto)   REFERENCES Producto(Id),
    INDEX idx_dd_devolucion (IdDevolucion)
) ENGINE=InnoDB;


CREATE TABLE MovimientoInventario (
    Id              INT          AUTO_INCREMENT PRIMARY KEY,
    Fecha           DATETIME     NOT NULL,
    Tipo            ENUM('entrada','salida','ajuste') NOT NULL,
    IdProducto      INT          NOT NULL,
    Cantidad        INT          NOT NULL,
    Motivo          VARCHAR(255) NOT NULL,
    IdProveedor     INT              NULL,
    IdTrabajador    INT          NOT NULL,
    CreadoEn        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_mi_producto   FOREIGN KEY (IdProducto)   REFERENCES Producto(Id),
    CONSTRAINT fk_mi_proveedor  FOREIGN KEY (IdProveedor)  REFERENCES Proveedor(Id)   ON DELETE SET NULL,
    CONSTRAINT fk_mi_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id),
    INDEX idx_mi_tipo     (Tipo),
    INDEX idx_mi_producto (IdProducto),
    INDEX idx_mi_fecha    (Fecha)
) ENGINE=InnoDB;


CREATE TABLE Cotizacion (
    Id                  INT           AUTO_INCREMENT PRIMARY KEY,
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
    Estado              ENUM('pendiente','aceptada','rechazada','vencida') NOT NULL,
    FechaCreacion       DATETIME      NOT NULL,
    IdTrabajador        INT           NOT NULL,
    Plantilla           ENUM('T1','T2','T3','T4','T5','T6') NOT NULL,
    HashQR              VARCHAR(64)       NULL,
    CreadoEn            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ActualizadoEn       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_cot_cliente    FOREIGN KEY (IdCliente)    REFERENCES Cliente(Id)    ON DELETE SET NULL,
    CONSTRAINT fk_cot_trabajador FOREIGN KEY (IdTrabajador) REFERENCES Trabajador(Id),
    INDEX idx_cot_estado  (Estado),
    INDEX idx_cot_cliente (IdCliente),
    INDEX idx_cot_fecha   (FechaCreacion)
) ENGINE=InnoDB;


CREATE TABLE CotizacionDetalle (
    Id              INT           AUTO_INCREMENT PRIMARY KEY,
    IdCotizacion    INT           NOT NULL,
    IdProducto      INT           NOT NULL,
    Cantidad        INT           NOT NULL,
    PrecioUnitario  DECIMAL(10,2) NOT NULL,
    Descuento       DECIMAL(5,2)  NOT NULL,
    Subtotal        DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_cd_cotizacion FOREIGN KEY (IdCotizacion) REFERENCES Cotizacion(Id) ON DELETE CASCADE,
    CONSTRAINT fk_cd_producto   FOREIGN KEY (IdProducto)   REFERENCES Producto(Id),
    INDEX idx_cd_cotizacion (IdCotizacion)
) ENGINE=InnoDB;

CREATE TABLE PendienteConfiguracion (
    Id            INT           NOT NULL DEFAULT 1 PRIMARY KEY,
    Ahorros       DECIMAL(12,2) NOT NULL,
    Gastos        DECIMAL(12,2) NOT NULL,
    Facturas      DECIMAL(12,2) NOT NULL,
    Alquiler      DECIMAL(12,2) NOT NULL,
    ActualizadoEn DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_pendiente_singleton CHECK (Id = 1)
) ENGINE=InnoDB;


CREATE TABLE PendientePeriodo (
    Id            INT           AUTO_INCREMENT PRIMARY KEY,
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
    CerradoEn     DATETIME          NULL,
    CreadoEn      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
