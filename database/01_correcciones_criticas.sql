-- ============================================================================
-- FASE 1: CORRECCIONES CRÍTICAS
-- Ejecutar ANTES de cualquier desarrollo de UI
-- ============================================================================

USE laplayita;

-- ----------------------------------------------------------------------------
-- 1. ESTANDARIZAR tipo_movimiento en movimiento_inventario
-- ----------------------------------------------------------------------------
-- Problema: Actualmente hay "ENTRADA", "entrada", "SALIDA", "salida"
-- Solución: Convertir a ENUM para consistencia

-- Primero, normalizar datos existentes
UPDATE movimiento_inventario 
SET tipo_movimiento = UPPER(tipo_movimiento)
WHERE tipo_movimiento IN ('entrada', 'salida', 'ajuste', 'devolucion', 'descarte');

-- Verificar que no haya valores raros
SELECT DISTINCT tipo_movimiento, COUNT(*) as cantidad
FROM movimiento_inventario
GROUP BY tipo_movimiento;

-- Ahora convertir la columna a ENUM
ALTER TABLE movimiento_inventario 
MODIFY COLUMN tipo_movimiento ENUM(
    'ENTRADA',
    'SALIDA',
    'AJUSTE',
    'DEVOLUCION',
    'DESCARTE',
    'TRANSFERENCIA'
) NOT NULL;

-- ----------------------------------------------------------------------------
-- 2. AGREGAR estado a producto
-- ----------------------------------------------------------------------------
-- Permite desactivar productos sin eliminarlos

ALTER TABLE producto 
ADD COLUMN estado ENUM('activo', 'inactivo', 'descontinuado') 
NOT NULL DEFAULT 'activo'
AFTER stock_actual;

-- Crear índice para filtros rápidos
CREATE INDEX idx_producto_estado ON producto(estado);

-- ----------------------------------------------------------------------------
-- 3. AGREGAR campos críticos a producto
-- ----------------------------------------------------------------------------

-- Código de barras / SKU para búsqueda rápida
ALTER TABLE producto 
ADD COLUMN codigo_barras VARCHAR(50) NULL 
AFTER nombre,
ADD UNIQUE KEY uq_producto_codigo_barras (codigo_barras);

-- Stock máximo para alertas de sobre-inventario
ALTER TABLE producto 
ADD COLUMN stock_maximo INT NULL 
AFTER stock_minimo,
ADD CONSTRAINT chk_stock_maximo CHECK (stock_maximo IS NULL OR stock_maximo >= stock_minimo);

-- Ubicación física en bodega
ALTER TABLE producto 
ADD COLUMN ubicacion VARCHAR(50) NULL 
COMMENT 'Ej: Pasillo A, Estante 3, Nivel 2'
AFTER descripcion;

-- Imagen del producto
ALTER TABLE producto 
ADD COLUMN imagen_url VARCHAR(255) NULL 
AFTER descripcion;

-- ----------------------------------------------------------------------------
-- 4. MEJORAR categoría con jerarquía
-- ----------------------------------------------------------------------------

-- Permitir categorías padre-hijo
ALTER TABLE categoria 
ADD COLUMN parent_id INT NULL AFTER nombre,
ADD COLUMN descripcion VARCHAR(255) NULL AFTER parent_id,
ADD COLUMN orden INT NOT NULL DEFAULT 0 AFTER descripcion,
ADD COLUMN activo BOOLEAN NOT NULL DEFAULT TRUE AFTER orden,
ADD CONSTRAINT fk_categoria_parent 
    FOREIGN KEY (parent_id) REFERENCES categoria(id) 
    ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX idx_categoria_parent ON categoria(parent_id);
CREATE INDEX idx_categoria_activo ON categoria(activo);

-- ----------------------------------------------------------------------------
-- 5. AGREGAR campos de auditoría a tablas principales
-- ----------------------------------------------------------------------------

-- Producto: quién creó y cuándo
ALTER TABLE producto 
ADD COLUMN creado_por_id BIGINT NULL AFTER tasa_iva_id,
ADD COLUMN fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER creado_por_id,
ADD COLUMN modificado_por_id BIGINT NULL AFTER fecha_creacion,
ADD COLUMN fecha_modificacion DATETIME NULL ON UPDATE CURRENT_TIMESTAMP AFTER modificado_por_id,
ADD CONSTRAINT fk_producto_creado_por 
    FOREIGN KEY (creado_por_id) REFERENCES usuario(id) ON DELETE SET NULL,
ADD CONSTRAINT fk_producto_modificado_por 
    FOREIGN KEY (modificado_por_id) REFERENCES usuario(id) ON DELETE SET NULL;

-- Categoría: auditoría
ALTER TABLE categoria 
ADD COLUMN creado_por_id BIGINT NULL,
ADD COLUMN fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD CONSTRAINT fk_categoria_creado_por 
    FOREIGN KEY (creado_por_id) REFERENCES usuario(id) ON DELETE SET NULL;

-- Proveedor: auditoría
ALTER TABLE proveedor 
ADD COLUMN activo BOOLEAN NOT NULL DEFAULT TRUE AFTER tipo_documento,
ADD COLUMN creado_por_id BIGINT NULL AFTER activo,
ADD COLUMN fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER creado_por_id;

CREATE INDEX idx_proveedor_activo ON proveedor(activo);

-- ----------------------------------------------------------------------------
-- 6. MEJORAR movimiento_inventario con más contexto
-- ----------------------------------------------------------------------------

-- Usuario que realizó el movimiento
ALTER TABLE movimiento_inventario 
ADD COLUMN usuario_id BIGINT NULL AFTER descripcion,
ADD CONSTRAINT fk_movimiento_usuario 
    FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL;

-- Costo unitario al momento del movimiento (para valorización histórica)
ALTER TABLE movimiento_inventario 
ADD COLUMN costo_unitario DECIMAL(12,2) NULL AFTER cantidad;

-- Índices para mejorar performance de reportes
CREATE INDEX idx_movimiento_fecha ON movimiento_inventario(fecha_movimiento);
CREATE INDEX idx_movimiento_tipo ON movimiento_inventario(tipo_movimiento);
CREATE INDEX idx_movimiento_usuario ON movimiento_inventario(usuario_id);

-- ----------------------------------------------------------------------------
-- 7. AGREGAR campos a lote para mejor gestión
-- ----------------------------------------------------------------------------

-- Estado del lote
ALTER TABLE lote 
ADD COLUMN estado ENUM('activo', 'agotado', 'vencido', 'descartado') 
NOT NULL DEFAULT 'activo' AFTER fecha_entrada;

-- Trigger para actualizar estado automáticamente
DELIMITER $$
CREATE TRIGGER trg_lote_actualizar_estado
BEFORE UPDATE ON lote
FOR EACH ROW
BEGIN
    -- Si cantidad es 0, marcar como agotado
    IF NEW.cantidad_disponible = 0 AND OLD.cantidad_disponible > 0 THEN
        SET NEW.estado = 'agotado';
    END IF;
    
    -- Si cantidad vuelve a ser > 0, reactivar
    IF NEW.cantidad_disponible > 0 AND OLD.cantidad_disponible = 0 THEN
        SET NEW.estado = 'activo';
    END IF;
    
    -- Si está vencido
    IF NEW.fecha_caducidad < CURDATE() THEN
        SET NEW.estado = 'vencido';
    END IF;
END$$
DELIMITER ;

CREATE INDEX idx_lote_estado ON lote(estado);
CREATE INDEX idx_lote_fecha_caducidad ON lote(fecha_caducidad);

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN FINAL
-- ----------------------------------------------------------------------------

-- Mostrar estructura actualizada de tablas principales
SHOW CREATE TABLE producto;
SHOW CREATE TABLE categoria;
SHOW CREATE TABLE lote;
SHOW CREATE TABLE movimiento_inventario;
SHOW CREATE TABLE proveedor;

SELECT 'FASE 1 COMPLETADA: Correcciones críticas aplicadas' AS resultado;
