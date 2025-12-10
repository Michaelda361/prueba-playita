-- ============================================================================
-- MEJORAS DE CONSTRAINTS PARA INVENTARIO
-- Fecha: 2025-12-09
-- Propósito: Agregar validaciones a nivel de BD sin afectar otras apps
-- ============================================================================

-- IMPORTANTE: Ejecutar DESPUÉS de corregir inconsistencias con el script Python
-- Hacer BACKUP antes de ejecutar

USE laplayita;

-- ============================================================================
-- 1. CONSTRAINT: Cantidad positiva en lotes
-- ============================================================================
-- Previene que los lotes tengan cantidad negativa

-- Verificar primero que no haya datos negativos
SELECT 'Verificando lotes con cantidad negativa...' AS paso;
SELECT COUNT(*) AS lotes_negativos 
FROM lote 
WHERE cantidad_disponible < 0;

-- Si el resultado es 0, es seguro agregar el constraint
ALTER TABLE lote 
ADD CONSTRAINT chk_lote_cantidad_positiva 
CHECK (cantidad_disponible >= 0);

SELECT '✅ Constraint agregado: chk_lote_cantidad_positiva' AS resultado;

-- ============================================================================
-- 2. CONSTRAINT: Stock positivo en productos
-- ============================================================================
-- Previene que los productos tengan stock negativo

-- Verificar primero
SELECT 'Verificando productos con stock negativo...' AS paso;
SELECT COUNT(*) AS productos_negativos 
FROM producto 
WHERE stock_actual < 0;

-- Si el resultado es 0, es seguro agregar el constraint
ALTER TABLE producto 
ADD CONSTRAINT chk_producto_stock_positivo 
CHECK (stock_actual >= 0);

SELECT '✅ Constraint agregado: chk_producto_stock_positivo' AS resultado;

-- ============================================================================
-- 3. ÍNDICE ÚNICO: Alertas activas sin duplicados
-- ============================================================================
-- Previene alertas duplicadas del mismo tipo para el mismo producto

-- Verificar primero que no haya duplicados
SELECT 'Verificando alertas duplicadas...' AS paso;
SELECT producto_id, tipo_alerta, COUNT(*) as cantidad
FROM alerta_inventario
WHERE estado = 'activa'
GROUP BY producto_id, tipo_alerta
HAVING COUNT(*) > 1;

-- Si no hay resultados, es seguro crear el índice
-- NOTA: En MariaDB/MySQL no se puede usar WHERE en índices únicos
-- Alternativa: Usar constraint único compuesto
ALTER TABLE alerta_inventario
ADD CONSTRAINT uq_alerta_producto_tipo_activa
UNIQUE (producto_id, tipo_alerta, estado);

SELECT '✅ Constraint agregado: uq_alerta_producto_tipo_activa' AS resultado;

-- ============================================================================
-- 4. CONSTRAINT: Fecha de vencimiento válida
-- ============================================================================
-- Asegura que la fecha de vencimiento sea posterior a la fecha de entrada

ALTER TABLE lote 
ADD CONSTRAINT chk_lote_fecha_valida 
CHECK (fecha_caducidad >= fecha_entrada);

SELECT '✅ Constraint agregado: chk_lote_fecha_valida' AS resultado;

-- ============================================================================
-- 5. CONSTRAINT: Stock máximo mayor que mínimo
-- ============================================================================
-- Asegura que el stock máximo sea mayor al mínimo (si está definido)

ALTER TABLE producto 
ADD CONSTRAINT chk_producto_stock_max_min 
CHECK (stock_maximo IS NULL OR stock_maximo >= stock_minimo);

SELECT '✅ Constraint agregado: chk_producto_stock_max_min' AS resultado;

-- ============================================================================
-- 6. CONSTRAINT: Costo unitario positivo
-- ============================================================================
-- Asegura que los costos sean positivos

ALTER TABLE lote 
ADD CONSTRAINT chk_lote_costo_positivo 
CHECK (costo_unitario_lote > 0);

ALTER TABLE producto 
ADD CONSTRAINT chk_producto_precio_positivo 
CHECK (precio_unitario > 0);

SELECT '✅ Constraints de costos agregados' AS resultado;

-- ============================================================================
-- 7. ÍNDICES ADICIONALES PARA PERFORMANCE
-- ============================================================================
-- Mejoran el rendimiento de consultas frecuentes

-- Índice para búsquedas por estado de lote
CREATE INDEX idx_lote_estado_cantidad 
ON lote(estado, cantidad_disponible);

-- Índice para búsquedas por fecha de vencimiento
CREATE INDEX idx_lote_fecha_caducidad_estado 
ON lote(fecha_caducidad, estado);

-- Índice para búsquedas de productos por stock
CREATE INDEX idx_producto_stock_estado 
ON producto(stock_actual, estado);

-- Índice para alertas por prioridad
CREATE INDEX idx_alerta_prioridad_estado 
ON alerta_inventario(prioridad, estado, fecha_generacion);

SELECT '✅ Índices de performance agregados' AS resultado;

-- ============================================================================
-- 8. VERIFICACIÓN FINAL
-- ============================================================================

SELECT 'Verificando constraints agregados...' AS paso;

SELECT 
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE,
    TABLE_NAME
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN ('producto', 'lote', 'alerta_inventario')
AND CONSTRAINT_NAME LIKE 'chk_%' OR CONSTRAINT_NAME LIKE 'uq_%'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;

-- ============================================================================
-- RESUMEN
-- ============================================================================

SELECT '
============================================================
  RESUMEN DE MEJORAS APLICADAS
============================================================

✅ Constraints de validación:
   - Cantidad positiva en lotes
   - Stock positivo en productos
   - Fechas de vencimiento válidas
   - Stock máximo > mínimo
   - Costos positivos

✅ Constraints de integridad:
   - Alertas únicas por producto/tipo/estado

✅ Índices de performance:
   - Búsquedas por estado y cantidad
   - Búsquedas por fecha de vencimiento
   - Búsquedas por stock
   - Búsquedas por prioridad de alertas

⚠️  IMPORTANTE:
   - Estos constraints NO afectan otras apps
   - Solo aplican a tablas de inventario
   - Previenen inconsistencias futuras
   - No modifican datos existentes

📋 SIGUIENTE PASO:
   - Ejecutar diagnostico_db.py para verificar
   - Probar creación de productos/lotes
   - Verificar que las validaciones funcionen

============================================================
' AS resumen;

-- ============================================================================
-- ROLLBACK (En caso de problemas)
-- ============================================================================
-- Descomentar y ejecutar solo si necesitas revertir los cambios

/*
-- Eliminar constraints
ALTER TABLE lote DROP CONSTRAINT IF EXISTS chk_lote_cantidad_positiva;
ALTER TABLE lote DROP CONSTRAINT IF EXISTS chk_lote_fecha_valida;
ALTER TABLE lote DROP CONSTRAINT IF EXISTS chk_lote_costo_positivo;

ALTER TABLE producto DROP CONSTRAINT IF EXISTS chk_producto_stock_positivo;
ALTER TABLE producto DROP CONSTRAINT IF EXISTS chk_producto_stock_max_min;
ALTER TABLE producto DROP CONSTRAINT IF EXISTS chk_producto_precio_positivo;

ALTER TABLE alerta_inventario DROP CONSTRAINT IF EXISTS uq_alerta_producto_tipo_activa;

-- Eliminar índices
DROP INDEX IF EXISTS idx_lote_estado_cantidad ON lote;
DROP INDEX IF EXISTS idx_lote_fecha_caducidad_estado ON lote;
DROP INDEX IF EXISTS idx_producto_stock_estado ON producto;
DROP INDEX IF EXISTS idx_alerta_prioridad_estado ON alerta_inventario;

SELECT '⚠️  Constraints e índices eliminados (ROLLBACK)' AS resultado;
*/
