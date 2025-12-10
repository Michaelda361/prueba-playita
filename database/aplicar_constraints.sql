-- Aplicar constraints de forma segura
USE laplayita;

-- 1. Constraint: Cantidad positiva en lotes
ALTER TABLE lote 
ADD CONSTRAINT chk_lote_cantidad_positiva 
CHECK (cantidad_disponible >= 0);

-- 2. Constraint: Stock positivo en productos
ALTER TABLE producto 
ADD CONSTRAINT chk_producto_stock_positivo 
CHECK (stock_actual >= 0);

-- 3. Constraint: Alertas únicas (modificado para MariaDB)
-- Nota: En MariaDB no se puede usar WHERE en UNIQUE, usamos trigger alternativo
ALTER TABLE alerta_inventario
DROP INDEX IF EXISTS idx_alerta_producto_tipo;

CREATE UNIQUE INDEX idx_alerta_unica 
ON alerta_inventario (producto_id, tipo_alerta, estado);

-- 4. Constraint: Fecha de vencimiento válida
ALTER TABLE lote 
ADD CONSTRAINT chk_lote_fecha_valida 
CHECK (fecha_caducidad >= fecha_entrada);

-- 5. Constraint: Stock máximo mayor que mínimo
ALTER TABLE producto 
ADD CONSTRAINT chk_producto_stock_max_min 
CHECK (stock_maximo IS NULL OR stock_maximo >= stock_minimo);

-- 6. Constraint: Costo unitario positivo
ALTER TABLE lote 
ADD CONSTRAINT chk_lote_costo_positivo 
CHECK (costo_unitario_lote > 0);

ALTER TABLE producto 
ADD CONSTRAINT chk_producto_precio_positivo 
CHECK (precio_unitario > 0);

-- 7. Índices adicionales para performance
CREATE INDEX IF NOT EXISTS idx_lote_estado_cantidad 
ON lote(estado, cantidad_disponible);

CREATE INDEX IF NOT EXISTS idx_lote_fecha_caducidad_estado 
ON lote(fecha_caducidad, estado);

CREATE INDEX IF NOT EXISTS idx_producto_stock_estado 
ON producto(stock_actual, estado);

CREATE INDEX IF NOT EXISTS idx_alerta_prioridad_estado 
ON alerta_inventario(prioridad, estado, fecha_generacion);

SELECT '✅ Constraints e índices aplicados correctamente' AS resultado;
