CREATE DATABASE IF NOT EXISTS finanplus
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE finanplus;

-- =========================================================
-- TABLA: Usuarios
-- =========================================================

CREATE TABLE Usuarios (
    id_usuario CHAR(36) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    moneda_preferida VARCHAR(10) DEFAULT 'COP',
    pais VARCHAR(80),
    foto_perfil VARCHAR(255),
    estado ENUM('ACTIVO', 'INACTIVO', 'SUSPENDIDO') DEFAULT 'ACTIVO'
);

-- =========================================================
-- TABLA: Categorias
-- =========================================================

CREATE TABLE Categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo ENUM('INGRESO', 'GASTO', 'AHORRO', 'INVERSION') NOT NULL,
    icono VARCHAR(100),
    color VARCHAR(20)
);

-- =========================================================
-- TABLA: Registros_Financieros
-- =========================================================

CREATE TABLE Registros_Financieros (
    id_registro CHAR(36) PRIMARY KEY,
    id_usuario CHAR(36) NOT NULL,
    id_categoria INT NOT NULL,

    tipo_movimiento ENUM(
        'INGRESO',
        'GASTO',
        'AHORRO',
        'INVERSION'
    ) NOT NULL,

    monto DECIMAL(15,2) NOT NULL CHECK (monto >= 0),

    descripcion VARCHAR(255),

    fecha_movimiento DATETIME NOT NULL,

    es_recurrente BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_registro_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE,

    CONSTRAINT fk_registro_categoria
        FOREIGN KEY (id_categoria)
        REFERENCES Categorias(id_categoria)
        ON DELETE RESTRICT
);

-- =========================================================
-- TABLA: Metas_Ahorro
-- =========================================================

CREATE TABLE Metas_Ahorro (
    id_meta CHAR(36) PRIMARY KEY,

    id_usuario CHAR(36) NOT NULL,

    nombre VARCHAR(120) NOT NULL,

    descripcion TEXT,

    monto_objetivo DECIMAL(15,2) NOT NULL
        CHECK (monto_objetivo > 0),

    monto_actual DECIMAL(15,2) DEFAULT 0
        CHECK (monto_actual >= 0),

    fecha_objetivo DATE,

    prioridad ENUM(
        'BAJA',
        'MEDIA',
        'ALTA'
    ) DEFAULT 'MEDIA',

    estado ENUM(
        'ACTIVA',
        'COMPLETADA',
        'CANCELADA'
    ) DEFAULT 'ACTIVA',

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_meta_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE
);

-- =========================================================
-- TABLA: Aportes_Meta
-- =========================================================

CREATE TABLE Aportes_Meta (
    id_aporte CHAR(36) PRIMARY KEY,

    id_meta CHAR(36) NOT NULL,

    id_registro CHAR(36) NOT NULL,

    monto DECIMAL(15,2) NOT NULL
        CHECK (monto > 0),

    fecha_aporte DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_aporte_meta
        FOREIGN KEY (id_meta)
        REFERENCES Metas_Ahorro(id_meta)
        ON DELETE CASCADE,

    CONSTRAINT fk_aporte_registro
        FOREIGN KEY (id_registro)
        REFERENCES Registros_Financieros(id_registro)
        ON DELETE CASCADE
);

-- =========================================================
-- TABLA: Inversiones
-- =========================================================

CREATE TABLE Inversiones (
    id_inversion CHAR(36) PRIMARY KEY,

    id_usuario CHAR(36) NOT NULL,

    nombre_activo VARCHAR(150) NOT NULL,

    tipo_activo ENUM(
        'ACCION',
        'ETF',
        'CRIPTO',
        'FONDO',
        'CDT',
        'BONO',
        'OTRO'
    ) NOT NULL,

    monto_invertido DECIMAL(15,2) NOT NULL
        CHECK (monto_invertido >= 0),

    valor_actual DECIMAL(15,2) NOT NULL
        CHECK (valor_actual >= 0),

    rentabilidad DECIMAL(8,2),

    riesgo ENUM(
        'BAJO',
        'MEDIO',
        'ALTO'
    ) DEFAULT 'MEDIO',

    fecha_inversion DATE NOT NULL,

    ultima_actualizacion TIMESTAMP
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_inversion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE
);

-- =========================================================
-- TABLA: Presupuestos
-- =========================================================

CREATE TABLE Presupuestos (
    id_presupuesto CHAR(36) PRIMARY KEY,

    id_usuario CHAR(36) NOT NULL,

    id_categoria INT NOT NULL,

    mes TINYINT NOT NULL
        CHECK (mes BETWEEN 1 AND 12),

    anio SMALLINT NOT NULL,

    limite_gasto DECIMAL(15,2) NOT NULL
        CHECK (limite_gasto >= 0),

    gasto_actual DECIMAL(15,2) DEFAULT 0
        CHECK (gasto_actual >= 0),

    CONSTRAINT uq_presupuesto_periodo
        UNIQUE (id_usuario, id_categoria, mes, anio),

    CONSTRAINT fk_presupuesto_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE,

    CONSTRAINT fk_presupuesto_categoria
        FOREIGN KEY (id_categoria)
        REFERENCES Categorias(id_categoria)
        ON DELETE RESTRICT
);

-- =========================================================
-- TABLA: Recomendaciones_IA
-- =========================================================

CREATE TABLE Recomendaciones_IA (
    id_recomendacion CHAR(36) PRIMARY KEY,

    id_usuario CHAR(36) NOT NULL,

    tipo_recomendacion VARCHAR(100) NOT NULL,

    titulo VARCHAR(200) NOT NULL,

    descripcion TEXT NOT NULL,

    nivel_prioridad ENUM(
        'BAJA',
        'MEDIA',
        'ALTA'
    ) DEFAULT 'MEDIA',

    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    modelo_utilizado VARCHAR(100),

    score_confianza DECIMAL(5,2)
        CHECK (
            score_confianza BETWEEN 0 AND 100
        ),

    fue_aplicada BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_recomendacion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE
);

-- =========================================================
-- TABLA: Notificaciones
-- Soporta la HU-16 (alertas financieras)
-- =========================================================

CREATE TABLE Notificaciones (
    id_notificacion CHAR(36) PRIMARY KEY,

    id_usuario CHAR(36) NOT NULL,

    tipo_alerta ENUM(
        'GASTO_ELEVADO',
        'GASTO_SUPERA_INGRESOS',
        'PRESUPUESTO_EXCEDIDO',
        'META_PROXIMA_VENCER',
        'META_CUMPLIDA'
    ) NOT NULL,

    titulo VARCHAR(200) NOT NULL,

    mensaje TEXT NOT NULL,

    -- Identificador del elemento que originó la alerta
    -- (meta, registro o presupuesto, según el tipo_alerta)
    id_referencia CHAR(36),

    nivel_prioridad ENUM(
        'BAJA',
        'MEDIA',
        'ALTA'
    ) DEFAULT 'MEDIA',

    leida BOOLEAN DEFAULT FALSE,

    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    fecha_lectura DATETIME,

    CONSTRAINT fk_notificacion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE
);

-- =========================================================
-- TABLA: Metricas_Financieras
-- =========================================================

CREATE TABLE Metricas_Financieras (
    id_metrica CHAR(36) PRIMARY KEY,

    id_usuario CHAR(36) NOT NULL,

    fecha_calculo DATETIME NOT NULL,

    ingresos_totales DECIMAL(15,2) DEFAULT 0,

    gastos_totales DECIMAL(15,2) DEFAULT 0,

    tasa_ahorro DECIMAL(5,2),

    flujo_neto DECIMAL(15,2),

    score_financiero DECIMAL(5,2),

    nivel_riesgo ENUM(
        'BAJO',
        'MEDIO',
        'ALTO'
    ),

    CONSTRAINT fk_metrica_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE
);

-- =========================================================
-- TABLA: Movimientos_Recurrentes
-- =========================================================

CREATE TABLE Movimientos_Recurrentes (
    id_recurrencia CHAR(36) PRIMARY KEY,

    id_usuario CHAR(36) NOT NULL,

    tipo_movimiento ENUM(
        'INGRESO',
        'GASTO',
        'AHORRO',
        'INVERSION'
    ) NOT NULL,

    monto_estimado DECIMAL(15,2) NOT NULL
        CHECK (monto_estimado >= 0),

    frecuencia ENUM(
        'DIARIA',
        'SEMANAL',
        'MENSUAL',
        'ANUAL'
    ) NOT NULL,

    id_categoria INT NOT NULL,

    proxima_fecha DATE NOT NULL,

    activo BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_recurrente_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES Usuarios(id_usuario)
        ON DELETE CASCADE,

    CONSTRAINT fk_recurrente_categoria
        FOREIGN KEY (id_categoria)
        REFERENCES Categorias(id_categoria)
        ON DELETE RESTRICT
);

-- =========================================================
-- TABLA: Etiquetas
-- =========================================================

CREATE TABLE Etiquetas (
    id_etiqueta INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE
);

-- =========================================================
-- TABLA: Registro_Etiqueta
-- =========================================================

CREATE TABLE Registro_Etiqueta (
    id_registro CHAR(36) NOT NULL,
    id_etiqueta INT NOT NULL,

    PRIMARY KEY (id_registro, id_etiqueta),

    CONSTRAINT fk_registro_etiqueta_registro
        FOREIGN KEY (id_registro)
        REFERENCES Registros_Financieros(id_registro)
        ON DELETE CASCADE,

    CONSTRAINT fk_registro_etiqueta_etiqueta
        FOREIGN KEY (id_etiqueta)
        REFERENCES Etiquetas(id_etiqueta)
        ON DELETE CASCADE
);

-- =========================================================
-- ÍNDICES IMPORTANTES
-- =========================================================

CREATE INDEX idx_registros_usuario_fecha
ON Registros_Financieros(id_usuario, fecha_movimiento);

CREATE INDEX idx_registros_categoria
ON Registros_Financieros(id_categoria);

CREATE INDEX idx_registros_tipo
ON Registros_Financieros(tipo_movimiento);

CREATE INDEX idx_metricas_usuario
ON Metricas_Financieras(id_usuario);

CREATE INDEX idx_inversiones_usuario
ON Inversiones(id_usuario);

CREATE INDEX idx_presupuestos_usuario
ON Presupuestos(id_usuario);

CREATE INDEX idx_metas_usuario
ON Metas_Ahorro(id_usuario);

CREATE INDEX idx_recomendaciones_usuario
ON Recomendaciones_IA(id_usuario);

CREATE INDEX idx_notificaciones_usuario
ON Notificaciones(id_usuario, leida);