-- ============================================================================
-- FASE 2: TABLAS NUEVAS ESENCIALES
-- Agregar funcionalidad crítica que falta
-- ============================================================================

USE laplayita;

-- ----------------------------------------------------------------------------
-- 1. TABLA: ajuste_inventario
-- Para diferencias entre conteo físico y sistema
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ajuste_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    lote_id INT NULL,
    cantidad_sistema INT NOT NULL COMMENT 'Stock según sistema',
    cantidad_fisica INT NOT NULL COMMENT 'Stock según conteo físico',
    diferencia INT NOT NULL COMMENT 'cantidad_fisica - cantidad_sistema',
    motivo ENUM(
        'conteo_fisico',
        'merma',
        'robo',
        'daño',
        'error_sistema',
        'otro'
    ) NOT NULL,
    descripcion TEXT NULL,
    costo_ajuste DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Impacto económico',
    usuario_ejecuta_id BIGINT NOT NULL COMMENT 'Quien hace el ajuste',
    usuario_autoriza_id BIGINT NULL COMMENT 'Quien autoriza (si aplica)',
    fecha_ajuste DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente', 'aprobado', 'rechazado', 'aplicado') NOT NULL DEFAULT 'pendiente',
    observaciones TEXT NULL,
    
    CONSTRAINT fk_ajuste_producto 
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE,
    CONSTRAINT fk_ajuste_lote 
        FOREIGN KEY (lote_id) REFERENCES lote(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_ajuste_ejecuta 
        FOREIGN KEY (usuario_ejecuta_id) REFERENCES usuario(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ajuste_autoriza 
        FOREIGN KEY (usuario_autoriza_id) REFERENCES usuario(id) ON DELETE SET NULL,
        
    INDEX idx_ajuste_fecha (fecha_ajuste),
    INDEX idx_ajuste_estado (estado),
    INDEX idx_ajuste_motivo (motivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Ajustes de inventario por diferencias físicas vs sistema';

-- ----------------------------------------------------------------------------
-- 2. TABLA: descarte_producto
-- Para productos vencidos, dañados o no aptos para venta
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS descarte_producto (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    lote_id INT NULL,
    cantidad INT NOT NULL,
    motivo ENUM(
        'vencido',
        'proximo_vencer',
        'dañado',
        'contaminado',
        'empaque_roto',
        'calidad_baja',
        'otro'
    ) NOT NULL,
    descripcion TEXT NULL,
    costo_unitario DECIMAL(12,2) NOT NULL,
    costo_total DECIMAL(12,2) NOT NULL,
    usuario_ejecuta_id BIGINT NOT NULL,
    usuario_autoriza_id BIGINT NULL,
    fecha_descarte DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado ENUM('pendiente', 'aprobado', 'rechazado', 'ejecutado') NOT NULL DEFAULT 'pendiente',
    evidencia_url VARCHAR(255) NULL COMMENT 'Foto del producto descartado',
    
    CONSTRAINT fk_descarte_producto 
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE,
    CONSTRAINT fk_descarte_lote 
        FOREIGN KEY (lote_id) REFERENCES lote(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_descarte_ejecuta 
        FOREIGN KEY (usuario_ejecuta_id) REFERENCES usuario(id) ON DELETE RESTRICT,
    CONSTRAINT fk_descarte_autoriza 
        FOREIGN KEY (usuario_autoriza_id) REFERENCES usuario(id) ON DELETE SET NULL,
        
    INDEX idx_descarte_fecha (fecha_descarte),
    INDEX idx_descarte_estado (estado),
    INDEX idx_descarte_motivo (motivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Registro de productos descartados';

-- ----------------------------------------------------------------------------
-- 3. TABLA: alerta_inventario
-- Sistema de alertas automáticas
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS alerta_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    lote_id INT NULL,
    tipo_alerta ENUM(
        'stock_bajo',
        'stock_critico',
        'sin_stock',
        'sobre_stock',
        'proximo_vencer',
        'vencido',
        'rotacion_baja'
    ) NOT NULL,
    prioridad ENUM('baja', 'media', 'alta', 'critica') NOT NULL DEFAULT 'media',
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    valor_actual VARCHAR(100) NULL COMMENT 'Ej: Stock actual: 5',
    valor_esperado VARCHAR(100) NULL COMMENT 'Ej: Stock mínimo: 10',
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento DATETIME NULL COMMENT 'Cuándo expira la alerta',
    estado ENUM('activa', 'resuelta', 'ignorada', 'expirada') NOT NULL DEFAULT 'activa',
    resuelta_por_id BIGINT NULL,
    fecha_resolucion DATETIME NULL,
    notas_resolucion TEXT NULL,
    
    CONSTRAINT fk_alerta_producto 
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_alerta_lote 
        FOREIGN KEY (lote_id) REFERENCES lote(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_alerta_resuelta_por 
        FOREIGN KEY (resuelta_por_id) REFERENCES usuario(id) ON DELETE SET NULL,
        
    INDEX idx_alerta_tipo (tipo_alerta),
    INDEX idx_alerta_prioridad (prioridad),
    INDEX idx_alerta_estado (estado),
    INDEX idx_alerta_fecha (fecha_generacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Sistema de alertas automáticas de inventario';

-- ----------------------------------------------------------------------------
-- 4. TABLA: devolucion_proveedor
-- Devoluciones de mercancía a proveedores
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS devolucion_proveedor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reabastecimiento_id INT NOT NULL,
    proveedor_id INT NOT NULL,
    fecha_devolucion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo ENUM(
        'producto_defectuoso',
        'producto_vencido',
        'cantidad_incorrecta',
        'producto_incorrecto',
        'empaque_dañado',
        'otro'
    ) NOT NULL,
    descripcion TEXT NULL,
    costo_total DECIMAL(12,2) NOT NULL,
    estado ENUM('solicitada', 'aprobada', 'rechazada', 'completada') NOT NULL DEFAULT 'solicitada',
    usuario_solicita_id BIGINT NOT NULL,
    fecha_aprobacion DATETIME NULL,
    usuario_aprueba_id BIGINT NULL,
    numero_guia VARCHAR(100) NULL COMMENT 'Número de guía de devolución',
    
    CONSTRAINT fk_devolucion_reabastecimiento 
        FOREIGN KEY (reabastecimiento_id) REFERENCES reabastecimiento(id) ON UPDATE CASCADE,
    CONSTRAINT fk_devolucion_proveedor 
        FOREIGN KEY (proveedor_id) REFERENCES proveedor(id) ON UPDATE CASCADE,
    CONSTRAINT fk_devolucion_solicita 
        FOREIGN KEY (usuario_solicita_id) REFERENCES usuario(id) ON DELETE RESTRICT,
    CONSTRAINT fk_devolucion_aprueba 
        FOREIGN KEY (usuario_aprueba_id) REFERENCES usuario(id) ON DELETE SET NULL,
        
    INDEX idx_devolucion_fecha (fecha_devolucion),
    INDEX idx_devolucion_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Devoluciones de mercancía a proveedores';

-- ----------------------------------------------------------------------------
-- 5. TABLA: devolucion_proveedor_detalle
-- Detalle de productos devueltos
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS devolucion_proveedor_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    devolucion_id INT NOT NULL,
    producto_id INT NOT NULL,
    lote_id INT NULL,
    cantidad INT NOT NULL,
    costo_unitario DECIMAL(12,2) NOT NULL,
    motivo_especifico TEXT NULL,
    
    CONSTRAINT fk_devolucion_detalle_devolucion 
        FOREIGN KEY (devolucion_id) REFERENCES devolucion_proveedor(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_devolucion_detalle_producto 
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON UPDATE CASCADE,
    CONSTRAINT fk_devolucion_detalle_lote 
        FOREIGN KEY (lote_id) REFERENCES lote(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Detalle de productos en devoluciones a proveedores';

-- ----------------------------------------------------------------------------
-- 6. TABLA: valorizacion_inventario
-- Snapshots mensuales para contabilidad
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS valorizacion_inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    periodo VARCHAR(7) NOT NULL COMMENT 'Formato: YYYY-MM',
    fecha_corte DATE NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    costo_unitario DECIMAL(12,2) NOT NULL,
    costo_promedio DECIMAL(12,2) NOT NULL,
    valor_total DECIMAL(12,2) NOT NULL,
    categoria_id INT NOT NULL,
    fecha_generacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    generado_por_id BIGINT NULL,
    
    CONSTRAINT fk_valorizacion_producto 
        FOREIGN KEY (producto_id) REFERENCES producto(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_valorizacion_categoria 
        FOREIGN KEY (categoria_id) REFERENCES categoria(id) ON UPDATE CASCADE,
    CONSTRAINT fk_valorizacion_generado_por 
        FOREIGN KEY (generado_por_id) REFERENCES usuario(id) ON DELETE SET NULL,
        
    UNIQUE KEY uq_valorizacion_periodo_producto (periodo, producto_id),
    INDEX idx_valorizacion_periodo (periodo),
    INDEX idx_valorizacion_fecha_corte (fecha_corte)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Valorización mensual del inventario para contabilidad';

-- ----------------------------------------------------------------------------
-- 7. TABLA: configuracion_alerta
-- Configuración de umbrales de alertas
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS configuracion_alerta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_alerta ENUM(
        'stock_bajo',
        'stock_critico',
        'sobre_stock',
        'proximo_vencer',
        'rotacion_baja'
    ) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    umbral_valor DECIMAL(10,2) NULL COMMENT 'Valor numérico del umbral',
    umbral_porcentaje DECIMAL(5,2) NULL COMMENT 'Porcentaje del umbral',
    dias_anticipacion INT NULL COMMENT 'Días de anticipación para alertas de vencimiento',
    descripcion TEXT NULL,
    notificar_email BOOLEAN NOT NULL DEFAULT FALSE,
    notificar_dashboard BOOLEAN NOT NULL DEFAULT TRUE,
    usuarios_notificar JSON NULL COMMENT 'Array de IDs de usuarios a notificar',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY uq_config_tipo_alerta (tipo_alerta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Configuración de umbrales y comportamiento de alertas';

-- Insertar configuración por defecto
INSERT INTO configuracion_alerta (tipo_alerta, umbral_porcentaje, dias_anticipacion, descripcion) VALUES
('stock_bajo', 150.00, NULL, 'Alerta cuando stock < stock_mínimo × 1.5'),
('stock_critico', 100.00, NULL, 'Alerta cuando stock < stock_mínimo'),
('sobre_stock', 300.00, NULL, 'Alerta cuando stock > stock_máximo'),
('proximo_vencer', NULL, 30, 'Alerta 30 días antes del vencimiento'),
('rotacion_baja', NULL, 90, 'Alerta si no hay ventas en 90 días');

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN FINAL
-- ----------------------------------------------------------------------------

SHOW TABLES LIKE '%ajuste%';
SHOW TABLES LIKE '%descarte%';
SHOW TABLES LIKE '%alerta%';
SHOW TABLES LIKE '%devolucion%';
SHOW TABLES LIKE '%valorizacion%';

SELECT 'FASE 2 COMPLETADA: Tablas nuevas esenciales creadas' AS resultado;
