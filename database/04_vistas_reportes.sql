-- ============================================================================
-- FASE 4: VISTAS PARA REPORTES Y CONSULTAS FRECUENTES
-- Optimizar consultas complejas
-- ============================================================================

USE laplayita;

-- ----------------------------------------------------------------------------
-- 1. VISTA: Dashboard de inventario
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_dashboard_inventario AS
SELECT 
    -- KPIs generales
    COUNT(DISTINCT p.id) as total_productos,
    COUNT(DISTINCT CASE WHEN p.estado = 'activo' THEN p.id END) as productos_activos,
    SUM(p.stock_actual) as unidades_totales,
    SUM(p.stock_actual * p.costo_promedio) as valor_total_inventario,
    
    -- Alertas
    COUNT(DISTINCT CASE WHEN p.stock_actual = 0 AND p.estado = 'activo' THEN p.id END) as productos_sin_stock,
    COUNT(DISTINCT CASE WHEN p.stock_actual < p.stock_minimo AND p.estado = 'activo' THEN p.id END) as productos_stock_bajo,
    COUNT(DISTINCT CASE WHEN p.stock_maximo IS NOT NULL AND p.stock_actual > p.stock_maximo THEN p.id END) as productos_sobre_stock,
    
    -- Lotes
    COUNT(DISTINCT l.id) as total_lotes_activos,
    COUNT(DISTINCT CASE WHEN l.fecha_caducidad < CURDATE() THEN l.id END) as lotes_vencidos,
    COUNT(DISTINCT CASE WHEN l.fecha_caducidad BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN l.id END) as lotes_proximos_vencer,
    
    -- Movimientos del día
    (SELECT COUNT(*) FROM movimiento_inventario WHERE DATE(fecha_movimiento) = CURDATE() AND tipo_movimiento = 'ENTRADA') as entradas_hoy,
    (SELECT COUNT(*) FROM movimiento_inventario WHERE DATE(fecha_movimiento) = CURDATE() AND tipo_movimiento = 'SALIDA') as salidas_hoy,
    
    -- Reabastecimientos
    (SELECT COUNT(*) FROM reabastecimiento WHERE estado = 'solicitado') as ordenes_pendientes,
    (SELECT COUNT(*) FROM reabastecimiento WHERE DATE(fecha) = CURDATE()) as ordenes_hoy
    
FROM producto p
LEFT JOIN lote l ON p.id = l.producto_id AND l.estado = 'activo';

-- ----------------------------------------------------------------------------
-- 2. VISTA: Productos con alertas
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_productos_alertas AS
SELECT 
    p.id as producto_id,
    p.nombre as producto_nombre,
    p.codigo_barras,
    c.nombre as categoria,
    p.stock_actual,
    p.stock_minimo,
    p.stock_maximo,
    p.costo_promedio,
    p.stock_actual * p.costo_promedio as valor_inventario,
    
    -- Estado del stock
    CASE 
        WHEN p.stock_actual = 0 THEN 'SIN_STOCK'
        WHEN p.stock_actual < p.stock_minimo THEN 'STOCK_CRITICO'
        WHEN p.stock_actual < (p.stock_minimo * 1.5) THEN 'STOCK_BAJO'
        WHEN p.stock_maximo IS NOT NULL AND p.stock_actual > p.stock_maximo THEN 'SOBRE_STOCK'
        ELSE 'NORMAL'
    END as estado_stock,
    
    -- Prioridad
    CASE 
        WHEN p.stock_actual = 0 THEN 'CRITICA'
        WHEN p.stock_actual < p.stock_minimo THEN 'ALTA'
        WHEN p.stock_actual < (p.stock_minimo * 1.5) THEN 'MEDIA'
        ELSE 'BAJA'
    END as prioridad,
    
    -- Lotes
    COUNT(DISTINCT l.id) as numero_lotes,
    MIN(l.fecha_caducidad) as proxima_fecha_vencimiento,
    DATEDIFF(MIN(l.fecha_caducidad), CURDATE()) as dias_hasta_vencer,
    
    -- Última actividad
    (SELECT MAX(fecha_movimiento) FROM movimiento_inventario WHERE producto_id = p.id AND tipo_movimiento = 'SALIDA') as ultima_venta,
    (SELECT MAX(fecha_movimiento) FROM movimiento_inventario WHERE producto_id = p.id AND tipo_movimiento = 'ENTRADA') as ultima_compra,
    
    -- Alertas activas
    (SELECT COUNT(*) FROM alerta_inventario WHERE producto_id = p.id AND estado = 'activa') as alertas_activas

FROM producto p
INNER JOIN categoria c ON p.categoria_id = c.id
LEFT JOIN lote l ON p.id = l.producto_id AND l.estado = 'activo' AND l.cantidad_disponible > 0
WHERE p.estado = 'activo'
GROUP BY p.id, p.nombre, p.codigo_barras, c.nombre, p.stock_actual, p.stock_minimo, 
         p.stock_maximo, p.costo_promedio
HAVING estado_stock != 'NORMAL' OR dias_hasta_vencer <= 30
ORDER BY 
    CASE prioridad
        WHEN 'CRITICA' THEN 1
        WHEN 'ALTA' THEN 2
        WHEN 'MEDIA' THEN 3
        ELSE 4
    END,
    dias_hasta_vencer ASC;

-- ----------------------------------------------------------------------------
-- 3. VISTA: Kardex completo por producto
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_kardex_producto AS
SELECT 
    mi.id as movimiento_id,
    mi.fecha_movimiento,
    p.id as producto_id,
    p.nombre as producto_nombre,
    p.codigo_barras,
    c.nombre as categoria,
    l.numero_lote,
    l.fecha_caducidad,
    mi.tipo_movimiento,
    mi.cantidad,
    mi.costo_unitario,
    ABS(mi.cantidad * COALESCE(mi.costo_unitario, p.costo_promedio)) as valor_movimiento,
    mi.descripcion,
    
    -- Origen del movimiento
    CASE 
        WHEN mi.venta_id IS NOT NULL THEN CONCAT('Venta #', mi.venta_id)
        WHEN mi.reabastecimiento_id IS NOT NULL THEN CONCAT('Reabastecimiento #', mi.reabastecimiento_id)
        ELSE 'Ajuste manual'
    END as origen,
    
    -- Usuario
    CONCAT(u.nombres, ' ', u.apellidos) as usuario,
    
    -- Saldo (calculado en aplicación)
    NULL as saldo_cantidad,
    NULL as saldo_valor

FROM movimiento_inventario mi
INNER JOIN producto p ON mi.producto_id = p.id
INNER JOIN categoria c ON p.categoria_id = c.id
LEFT JOIN lote l ON mi.lote_id = l.id
LEFT JOIN usuario u ON mi.usuario_id = u.id
ORDER BY mi.producto_id, mi.fecha_movimiento, mi.id;

-- ----------------------------------------------------------------------------
-- 4. VISTA: Lotes activos con información completa
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_lotes_activos AS
SELECT 
    l.id as lote_id,
    l.numero_lote,
    p.id as producto_id,
    p.nombre as producto_nombre,
    p.codigo_barras,
    c.nombre as categoria,
    l.cantidad_disponible,
    l.costo_unitario_lote,
    l.cantidad_disponible * l.costo_unitario_lote as valor_lote,
    l.fecha_entrada,
    l.fecha_caducidad,
    DATEDIFF(l.fecha_caducidad, CURDATE()) as dias_hasta_vencer,
    l.estado as estado_lote,
    
    -- Clasificación por vencimiento
    CASE 
        WHEN l.fecha_caducidad < CURDATE() THEN 'VENCIDO'
        WHEN DATEDIFF(l.fecha_caducidad, CURDATE()) <= 7 THEN 'CRITICO'
        WHEN DATEDIFF(l.fecha_caducidad, CURDATE()) <= 30 THEN 'PROXIMO'
        ELSE 'NORMAL'
    END as estado_vencimiento,
    
    -- Reabastecimiento origen
    r.id as reabastecimiento_id,
    r.fecha as fecha_reabastecimiento,
    pr.nombre_empresa as proveedor,
    
    -- Alertas
    (SELECT COUNT(*) FROM alerta_inventario WHERE lote_id = l.id AND estado = 'activa') as alertas_activas

FROM lote l
INNER JOIN producto p ON l.producto_id = p.id
INNER JOIN categoria c ON p.categoria_id = c.id
LEFT JOIN reabastecimiento_detalle rd ON l.reabastecimiento_detalle_id = rd.id
LEFT JOIN reabastecimiento r ON rd.reabastecimiento_id = r.id
LEFT JOIN proveedor pr ON r.proveedor_id = pr.id
WHERE l.cantidad_disponible > 0
ORDER BY 
    CASE 
        WHEN l.fecha_caducidad < CURDATE() THEN 1
        WHEN DATEDIFF(l.fecha_caducidad, CURDATE()) <= 7 THEN 2
        WHEN DATEDIFF(l.fecha_caducidad, CURDATE()) <= 30 THEN 3
        ELSE 4
    END,
    l.fecha_caducidad ASC;

-- ----------------------------------------------------------------------------
-- 5. VISTA: Productos más vendidos
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_productos_mas_vendidos AS
SELECT 
    p.id as producto_id,
    p.nombre as producto_nombre,
    p.codigo_barras,
    c.nombre as categoria,
    p.stock_actual,
    p.precio_unitario,
    p.costo_promedio,
    
    -- Ventas últimos 7 días
    COALESCE(SUM(CASE 
        WHEN mi.tipo_movimiento = 'SALIDA' 
         AND mi.fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        THEN ABS(mi.cantidad) 
        ELSE 0 
    END), 0) as ventas_7_dias,
    
    -- Ventas últimos 30 días
    COALESCE(SUM(CASE 
        WHEN mi.tipo_movimiento = 'SALIDA' 
         AND mi.fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        THEN ABS(mi.cantidad) 
        ELSE 0 
    END), 0) as ventas_30_dias,
    
    -- Ventas últimos 90 días
    COALESCE(SUM(CASE 
        WHEN mi.tipo_movimiento = 'SALIDA' 
         AND mi.fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
        THEN ABS(mi.cantidad) 
        ELSE 0 
    END), 0) as ventas_90_dias,
    
    -- Ingresos generados (últimos 30 días)
    COALESCE(SUM(CASE 
        WHEN mi.tipo_movimiento = 'SALIDA' 
         AND mi.fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        THEN ABS(mi.cantidad) * p.precio_unitario
        ELSE 0 
    END), 0) as ingresos_30_dias,
    
    -- Promedio diario
    COALESCE(SUM(CASE 
        WHEN mi.tipo_movimiento = 'SALIDA' 
         AND mi.fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        THEN ABS(mi.cantidad) 
        ELSE 0 
    END), 0) / 30 as promedio_diario,
    
    -- Última venta
    MAX(CASE WHEN mi.tipo_movimiento = 'SALIDA' THEN mi.fecha_movimiento END) as ultima_venta

FROM producto p
INNER JOIN categoria c ON p.categoria_id = c.id
LEFT JOIN movimiento_inventario mi ON p.id = mi.producto_id
WHERE p.estado = 'activo'
GROUP BY p.id, p.nombre, p.codigo_barras, c.nombre, p.stock_actual, p.precio_unitario, p.costo_promedio
HAVING ventas_30_dias > 0
ORDER BY ventas_30_dias DESC;

-- ----------------------------------------------------------------------------
-- 6. VISTA: Valorización por categoría
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_valorizacion_categoria AS
SELECT 
    c.id as categoria_id,
    c.nombre as categoria,
    COUNT(DISTINCT p.id) as total_productos,
    SUM(p.stock_actual) as unidades_totales,
    SUM(p.stock_actual * p.costo_promedio) as valor_total,
    AVG(p.costo_promedio) as costo_promedio,
    
    -- Porcentaje del inventario total
    ROUND(
        (SUM(p.stock_actual * p.costo_promedio) / 
         (SELECT SUM(stock_actual * costo_promedio) FROM producto WHERE estado = 'activo')) * 100,
        2
    ) as porcentaje_valor,
    
    -- Productos con alertas
    COUNT(DISTINCT CASE WHEN p.stock_actual < p.stock_minimo THEN p.id END) as productos_stock_bajo,
    COUNT(DISTINCT CASE WHEN p.stock_actual = 0 THEN p.id END) as productos_sin_stock

FROM categoria c
INNER JOIN producto p ON c.id = p.categoria_id
WHERE p.estado = 'activo'
GROUP BY c.id, c.nombre
ORDER BY valor_total DESC;

-- ----------------------------------------------------------------------------
-- 7. VISTA: Historial de reabastecimientos
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_historial_reabastecimientos AS
SELECT 
    r.id as reabastecimiento_id,
    r.fecha,
    pr.nombre_empresa as proveedor,
    pr.telefono as proveedor_telefono,
    r.estado,
    r.forma_pago,
    r.costo_total,
    r.iva,
    r.costo_total + r.iva as total_con_iva,
    
    -- Detalle de productos
    COUNT(DISTINCT rd.producto_id) as total_productos,
    SUM(rd.cantidad) as total_unidades_solicitadas,
    SUM(rd.cantidad_recibida) as total_unidades_recibidas,
    
    -- Recepción
    CASE 
        WHEN r.estado = 'recibido' THEN 'Completo'
        WHEN r.estado = 'solicitado' THEN 'Pendiente'
        WHEN r.estado = 'cancelado' THEN 'Cancelado'
        ELSE r.estado
    END as estado_recepcion,
    
    -- Usuario que recibió
    GROUP_CONCAT(DISTINCT CONCAT(u.nombres, ' ', u.apellidos) SEPARATOR ', ') as recibido_por,
    MAX(rd.fecha_recepcion) as fecha_recepcion,
    
    r.observaciones

FROM reabastecimiento r
INNER JOIN proveedor pr ON r.proveedor_id = pr.id
LEFT JOIN reabastecimiento_detalle rd ON r.id = rd.reabastecimiento_id
LEFT JOIN usuario u ON rd.recibido_por_id = u.id
GROUP BY r.id, r.fecha, pr.nombre_empresa, pr.telefono, r.estado, 
         r.forma_pago, r.costo_total, r.iva, r.observaciones
ORDER BY r.fecha DESC;

-- ----------------------------------------------------------------------------
-- 8. VISTA: Productos sin movimiento (baja rotación)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW vw_productos_baja_rotacion AS
SELECT 
    p.id as producto_id,
    p.nombre as producto_nombre,
    p.codigo_barras,
    c.nombre as categoria,
    p.stock_actual,
    p.stock_actual * p.costo_promedio as valor_inventario,
    
    -- Última actividad
    MAX(mi.fecha_movimiento) as ultimo_movimiento,
    DATEDIFF(CURDATE(), MAX(mi.fecha_movimiento)) as dias_sin_movimiento,
    
    -- Ventas en diferentes períodos
    COALESCE(SUM(CASE 
        WHEN mi.tipo_movimiento = 'SALIDA' 
         AND mi.fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        THEN ABS(mi.cantidad) 
    END), 0) as ventas_30_dias,
    
    COALESCE(SUM(CASE 
        WHEN mi.tipo_movimiento = 'SALIDA' 
         AND mi.fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
        THEN ABS(mi.cantidad) 
    END), 0) as ventas_90_dias

FROM producto p
INNER JOIN categoria c ON p.categoria_id = c.id
LEFT JOIN movimiento_inventario mi ON p.id = mi.producto_id
WHERE p.estado = 'activo' AND p.stock_actual > 0
GROUP BY p.id, p.nombre, p.codigo_barras, c.nombre, p.stock_actual, p.costo_promedio
HAVING dias_sin_movimiento > 60 OR ventas_90_dias = 0
ORDER BY dias_sin_movimiento DESC, valor_inventario DESC;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN FINAL
-- ----------------------------------------------------------------------------

-- Listar todas las vistas creadas
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'laplayita'
  AND TABLE_NAME LIKE 'vw_%'
ORDER BY TABLE_NAME;

SELECT 'FASE 4 COMPLETADA: Vistas para reportes creadas' AS resultado;
