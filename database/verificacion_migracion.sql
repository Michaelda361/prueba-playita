-- ============================================================================
-- SCRIPT DE VERIFICACIÓN POST-MIGRACIÓN
-- Ejecutar después de aplicar todos los scripts de migración
-- ============================================================================

USE laplayita;

SET @resultado = '';

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 1: Estructura de producto
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 1: Estructura de producto' as '';
SELECT '========================================' as '';

SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_KEY
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'laplayita'
  AND TABLE_NAME = 'producto'
  AND COLUMN_NAME IN ('codigo_barras', 'stock_maximo', 'ubicacion', 'imagen_url', 'estado', 
                      'creado_por_id', 'fecha_creacion', 'modificado_por_id', 'fecha_modificacion')
ORDER BY ORDINAL_POSITION;

-- Verificar que tipo_movimiento es ENUM
SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 2: tipo_movimiento es ENUM' as '';
SELECT '========================================' as '';

SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'laplayita'
  AND TABLE_NAME = 'movimiento_inventario'
  AND COLUMN_NAME = 'tipo_movimiento';

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 3: Tablas nuevas creadas
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 3: Tablas nuevas' as '';
SELECT '========================================' as '';

SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    CREATE_TIME,
    TABLE_COMMENT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'laplayita'
  AND TABLE_NAME IN (
      'ajuste_inventario',
      'descarte_producto',
      'alerta_inventario',
      'devolucion_proveedor',
      'devolucion_proveedor_detalle',
      'valorizacion_inventario',
      'configuracion_alerta'
  )
ORDER BY TABLE_NAME;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 4: Stored Procedures
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 4: Stored Procedures' as '';
SELECT '========================================' as '';

SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'laplayita'
  AND ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_NAME LIKE 'sp_%'
ORDER BY ROUTINE_NAME;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 5: Funciones
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 5: Funciones' as '';
SELECT '========================================' as '';

SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'laplayita'
  AND ROUTINE_TYPE = 'FUNCTION'
  AND ROUTINE_NAME LIKE 'fn_%'
ORDER BY ROUTINE_NAME;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 6: Vistas
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 6: Vistas para reportes' as '';
SELECT '========================================' as '';

SELECT 
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'laplayita'
  AND TABLE_NAME LIKE 'vw_%'
ORDER BY TABLE_NAME;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 7: Índices creados
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 7: Índices nuevos' as '';
SELECT '========================================' as '';

SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'laplayita'
  AND INDEX_NAME IN (
      'idx_producto_estado',
      'idx_movimiento_fecha',
      'idx_movimiento_tipo',
      'idx_movimiento_usuario',
      'idx_lote_estado',
      'idx_lote_fecha_caducidad',
      'idx_categoria_parent',
      'idx_categoria_activo',
      'idx_proveedor_activo'
  )
ORDER BY TABLE_NAME, INDEX_NAME;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 8: Configuración de alertas
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 8: Configuración alertas' as '';
SELECT '========================================' as '';

SELECT 
    tipo_alerta,
    activo,
    umbral_valor,
    umbral_porcentaje,
    dias_anticipacion,
    descripcion
FROM configuracion_alerta
ORDER BY tipo_alerta;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 9: Triggers en lote
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 9: Triggers en lote' as '';
SELECT '========================================' as '';

SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'laplayita'
  AND EVENT_OBJECT_TABLE = 'lote'
ORDER BY TRIGGER_NAME;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 10: Probar vista de dashboard
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 10: Dashboard (datos reales)' as '';
SELECT '========================================' as '';

SELECT * FROM vw_dashboard_inventario;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 11: Probar generación de alertas
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 11: Generar alertas' as '';
SELECT '========================================' as '';

-- Limpiar alertas antiguas para prueba
DELETE FROM alerta_inventario WHERE estado = 'activa';

-- Generar alertas
CALL sp_generar_alertas_inventario();

-- Mostrar alertas generadas
SELECT 
    tipo_alerta,
    prioridad,
    COUNT(*) as cantidad
FROM alerta_inventario
WHERE estado = 'activa'
GROUP BY tipo_alerta, prioridad
ORDER BY 
    CASE prioridad
        WHEN 'critica' THEN 1
        WHEN 'alta' THEN 2
        WHEN 'media' THEN 3
        ELSE 4
    END;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 12: Probar funciones
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 12: Funciones (muestra)' as '';
SELECT '========================================' as '';

SELECT 
    p.id,
    p.nombre,
    p.stock_actual,
    fn_dias_inventario(p.id, 30) as dias_inventario_30d,
    fn_rotacion_inventario(p.id, 30) as rotacion_30d
FROM producto p
WHERE p.estado = 'activo'
  AND p.stock_actual > 0
LIMIT 5;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN 13: Integridad referencial
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN 13: Foreign Keys nuevas' as '';
SELECT '========================================' as '';

SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'laplayita'
  AND REFERENCED_TABLE_NAME IS NOT NULL
  AND TABLE_NAME IN (
      'ajuste_inventario',
      'descarte_producto',
      'alerta_inventario',
      'devolucion_proveedor',
      'producto',
      'categoria',
      'movimiento_inventario'
  )
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- ----------------------------------------------------------------------------
-- RESUMEN FINAL
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'RESUMEN DE VERIFICACIÓN' as '';
SELECT '========================================' as '';

SELECT 
    'Tablas nuevas' as componente,
    COUNT(*) as cantidad
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'laplayita'
  AND TABLE_NAME IN (
      'ajuste_inventario',
      'descarte_producto',
      'alerta_inventario',
      'devolucion_proveedor',
      'devolucion_proveedor_detalle',
      'valorizacion_inventario',
      'configuracion_alerta'
  )

UNION ALL

SELECT 
    'Stored Procedures' as componente,
    COUNT(*) as cantidad
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'laplayita'
  AND ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_NAME LIKE 'sp_%'

UNION ALL

SELECT 
    'Funciones' as componente,
    COUNT(*) as cantidad
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'laplayita'
  AND ROUTINE_TYPE = 'FUNCTION'
  AND ROUTINE_NAME LIKE 'fn_%'

UNION ALL

SELECT 
    'Vistas' as componente,
    COUNT(*) as cantidad
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'laplayita'
  AND TABLE_NAME LIKE 'vw_%'

UNION ALL

SELECT 
    'Alertas activas' as componente,
    COUNT(*) as cantidad
FROM alerta_inventario
WHERE estado = 'activa';

-- ----------------------------------------------------------------------------
-- CHECKLIST FINAL
-- ----------------------------------------------------------------------------

SELECT '========================================' as '';
SELECT 'CHECKLIST DE MIGRACIÓN' as '';
SELECT '========================================' as '';

SELECT 
    '✓ Fase 1: Correcciones críticas' as paso,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = 'laplayita'
              AND TABLE_NAME = 'producto'
              AND COLUMN_NAME = 'codigo_barras'
        ) THEN '✅ COMPLETADO'
        ELSE '❌ FALTA'
    END as estado

UNION ALL

SELECT 
    '✓ Fase 2: Tablas nuevas' as paso,
    CASE 
        WHEN (
            SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = 'laplayita'
              AND TABLE_NAME IN ('ajuste_inventario', 'descarte_producto', 'alerta_inventario')
        ) = 3 THEN '✅ COMPLETADO'
        ELSE '❌ FALTA'
    END as estado

UNION ALL

SELECT 
    '✓ Fase 3: Stored Procedures' as paso,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES
            WHERE ROUTINE_SCHEMA = 'laplayita'
              AND ROUTINE_NAME = 'sp_generar_alertas_inventario'
        ) THEN '✅ COMPLETADO'
        ELSE '❌ FALTA'
    END as estado

UNION ALL

SELECT 
    '✓ Fase 4: Vistas' as paso,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM INFORMATION_SCHEMA.VIEWS
            WHERE TABLE_SCHEMA = 'laplayita'
              AND TABLE_NAME = 'vw_dashboard_inventario'
        ) THEN '✅ COMPLETADO'
        ELSE '❌ FALTA'
    END as estado;

SELECT '========================================' as '';
SELECT 'VERIFICACIÓN COMPLETADA' as '';
SELECT '========================================' as '';
