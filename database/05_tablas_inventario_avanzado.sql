-- ============================================================================
-- MEJORAS CRÍTICAS PARA SISTEMA DE INVENTARIO PROFESIONAL
-- La Playita - Sistema de Gestión
-- ============================================================================

USE `laplayita`;

-- ============================================================================
-- 1. TABLA: ubicacion_fisica
-- Gestión de ubicaciones físicas en bodega/almacén
-- ============================================================================

DROP TABLE IF EXISTS `ubicacion_fisica`;
CREATE TABLE `ubicacion_fisica` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) NOT NULL UNIQUE COMMENT 'Ej: BOD-A-EST-3-NIV-2',
  `nombre` varchar(100) NOT NULL,
  `tipo` enum('bodega','pasillo','estante','nivel','zona') NOT NULL DEFAULT 'estante',
  `parent_id` int(11) DEFAULT NULL COMMENT 'Ubicación padre (jerárquico)',
  `capacidad_maxima` int(11) DEFAULT NULL COMMENT 'Capacidad en unidades',
  `capacidad_actual` int(11) DEFAULT 0 COMMENT 'Ocupación actual',
  `temperatura_min` decimal(5,2) DEFAULT NULL COMMENT 'Temperatura mínima (°C)',
  `temperatura_max` decimal(5,2) DEFAULT NULL COMMENT 'Temperatura máxima (°C)',
  `requiere_refrigeracion` tinyint(1) DEFAULT 0,
  `activo` tinyint(1) DEFAULT 1,
  `observaciones` text DEFAULT NULL,
  `creado_por_id` bigint(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_ubicacion_codigo` (`codigo`),
  KEY `idx_ubicacion_tipo` (`tipo`),
  KEY `idx_ubicacion_parent` (`parent_id`),
  KEY `fk_ubicacion_creado_por` (`creado_por_id`),
  CONSTRAINT `fk_ubicacion_parent` FOREIGN KEY (`parent_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ubicacion_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ubicaciones físicas en bodega/almacén';


-- ============================================================================
-- 2. TABLA: reserva_inventario
-- Stock comprometido para pedidos/ventas
-- ============================================================================

DROP TABLE IF EXISTS `reserva_inventario`;
CREATE TABLE `reserva_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `tipo_reserva` enum('venta','pedido','transferencia','otro') NOT NULL DEFAULT 'venta',
  `referencia_id` int(11) DEFAULT NULL COMMENT 'ID de venta, pedido, etc.',
  `referencia_tipo` varchar(50) DEFAULT NULL COMMENT 'Tipo de referencia',
  `fecha_reserva` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_expiracion` datetime DEFAULT NULL COMMENT 'Cuándo expira la reserva',
  `estado` enum('activa','liberada','consumida','expirada') NOT NULL DEFAULT 'activa',
  `usuario_reserva_id` bigint(20) NOT NULL,
  `fecha_liberacion` datetime DEFAULT NULL,
  `motivo_liberacion` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_reserva_producto` (`producto_id`),
  KEY `fk_reserva_lote` (`lote_id`),
  KEY `fk_reserva_usuario` (`usuario_reserva_id`),
  KEY `idx_reserva_estado` (`estado`),
  KEY `idx_reserva_fecha_expiracion` (`fecha_expiracion`),
  KEY `idx_reserva_referencia` (`referencia_tipo`, `referencia_id`),
  CONSTRAINT `fk_reserva_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reserva_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_reserva_usuario` FOREIGN KEY (`usuario_reserva_id`) REFERENCES `usuario` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reservas de inventario (stock comprometido)';


-- ============================================================================
-- 3. TABLA: conteo_fisico
-- Inventarios cíclicos y conteos físicos
-- ============================================================================

DROP TABLE IF EXISTS `conteo_fisico`;
CREATE TABLE `conteo_fisico` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `numero_conteo` varchar(50) NOT NULL UNIQUE COMMENT 'Ej: CF-2025-001',
  `tipo_conteo` enum('completo','parcial','ciclico','sorpresa') NOT NULL DEFAULT 'ciclico',
  `fecha_programada` date NOT NULL,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_finalizacion` datetime DEFAULT NULL,
  `estado` enum('programado','en_proceso','completado','cancelado','ajustado') NOT NULL DEFAULT 'programado',
  `ubicacion_id` int(11) DEFAULT NULL COMMENT 'Ubicación específica (si es parcial)',
  `categoria_id` int(11) DEFAULT NULL COMMENT 'Categoría específica (si es parcial)',
  `responsable_id` bigint(20) NOT NULL,
  `supervisor_id` bigint(20) DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  `total_productos` int(11) DEFAULT 0,
  `total_diferencias` int(11) DEFAULT 0,
  `valor_diferencias` decimal(12,2) DEFAULT 0.00,
  `creado_por_id` bigint(20) NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_numero_conteo` (`numero_conteo`),
  KEY `fk_conteo_ubicacion` (`ubicacion_id`),
  KEY `fk_conteo_categoria` (`categoria_id`),
  KEY `fk_conteo_responsable` (`responsable_id`),
  KEY `fk_conteo_supervisor` (`supervisor_id`),
  KEY `fk_conteo_creado_por` (`creado_por_id`),
  KEY `idx_conteo_estado` (`estado`),
  KEY `idx_conteo_fecha` (`fecha_programada`),
  CONSTRAINT `fk_conteo_ubicacion` FOREIGN KEY (`ubicacion_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_responsable` FOREIGN KEY (`responsable_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `fk_conteo_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Conteos físicos de inventario';


-- ============================================================================
-- 4. TABLA: conteo_fisico_detalle
-- Detalle de productos contados
-- ============================================================================

DROP TABLE IF EXISTS `conteo_fisico_detalle`;
CREATE TABLE `conteo_fisico_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conteo_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad_sistema` int(11) NOT NULL COMMENT 'Stock según sistema',
  `cantidad_contada` int(11) DEFAULT NULL COMMENT 'Stock según conteo físico',
  `diferencia` int(11) DEFAULT NULL COMMENT 'cantidad_contada - cantidad_sistema',
  `costo_unitario` decimal(12,2) NOT NULL,
  `valor_diferencia` decimal(12,2) DEFAULT 0.00,
  `estado` enum('pendiente','contado','verificado','ajustado') NOT NULL DEFAULT 'pendiente',
  `observaciones` text DEFAULT NULL,
  `contado_por_id` bigint(20) DEFAULT NULL,
  `fecha_conteo` datetime DEFAULT NULL,
  `verificado_por_id` bigint(20) DEFAULT NULL,
  `fecha_verificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_conteo_detalle_conteo` (`conteo_id`),
  KEY `fk_conteo_detalle_producto` (`producto_id`),
  KEY `fk_conteo_detalle_lote` (`lote_id`),
  KEY `fk_conteo_detalle_contado_por` (`contado_por_id`),
  KEY `fk_conteo_detalle_verificado_por` (`verificado_por_id`),
  KEY `idx_conteo_detalle_estado` (`estado`),
  CONSTRAINT `fk_conteo_detalle_conteo` FOREIGN KEY (`conteo_id`) REFERENCES `conteo_fisico` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conteo_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conteo_detalle_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_detalle_contado_por` FOREIGN KEY (`contado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_detalle_verificado_por` FOREIGN KEY (`verificado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Detalle de conteos físicos';


-- ============================================================================
-- 5. TABLA: transferencia_inventario
-- Movimientos entre ubicaciones
-- ============================================================================

DROP TABLE IF EXISTS `transferencia_inventario`;
CREATE TABLE `transferencia_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `numero_transferencia` varchar(50) NOT NULL UNIQUE COMMENT 'Ej: TRF-2025-001',
  `ubicacion_origen_id` int(11) NOT NULL,
  `ubicacion_destino_id` int(11) NOT NULL,
  `fecha_solicitud` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_envio` datetime DEFAULT NULL,
  `fecha_recepcion` datetime DEFAULT NULL,
  `estado` enum('solicitada','aprobada','en_transito','recibida','cancelada') NOT NULL DEFAULT 'solicitada',
  `motivo` enum('reubicacion','reabastecimiento_interno','optimizacion','otro') NOT NULL,
  `descripcion` text DEFAULT NULL,
  `usuario_solicita_id` bigint(20) NOT NULL,
  `usuario_aprueba_id` bigint(20) DEFAULT NULL,
  `usuario_envia_id` bigint(20) DEFAULT NULL,
  `usuario_recibe_id` bigint(20) DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_numero_transferencia` (`numero_transferencia`),
  KEY `fk_transferencia_origen` (`ubicacion_origen_id`),
  KEY `fk_transferencia_destino` (`ubicacion_destino_id`),
  KEY `fk_transferencia_solicita` (`usuario_solicita_id`),
  KEY `fk_transferencia_aprueba` (`usuario_aprueba_id`),
  KEY `fk_transferencia_envia` (`usuario_envia_id`),
  KEY `fk_transferencia_recibe` (`usuario_recibe_id`),
  KEY `idx_transferencia_estado` (`estado`),
  KEY `idx_transferencia_fecha` (`fecha_solicitud`),
  CONSTRAINT `fk_transferencia_origen` FOREIGN KEY (`ubicacion_origen_id`) REFERENCES `ubicacion_fisica` (`id`),
  CONSTRAINT `fk_transferencia_destino` FOREIGN KEY (`ubicacion_destino_id`) REFERENCES `ubicacion_fisica` (`id`),
  CONSTRAINT `fk_transferencia_solicita` FOREIGN KEY (`usuario_solicita_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `fk_transferencia_aprueba` FOREIGN KEY (`usuario_aprueba_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transferencia_envia` FOREIGN KEY (`usuario_envia_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transferencia_recibe` FOREIGN KEY (`usuario_recibe_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Transferencias entre ubicaciones';


-- ============================================================================
-- 6. TABLA: transferencia_inventario_detalle
-- Detalle de productos transferidos
-- ============================================================================

DROP TABLE IF EXISTS `transferencia_inventario_detalle`;
CREATE TABLE `transferencia_inventario_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `transferencia_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad_solicitada` int(11) NOT NULL,
  `cantidad_enviada` int(11) DEFAULT NULL,
  `cantidad_recibida` int(11) DEFAULT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  `observaciones` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_transferencia_detalle_transferencia` (`transferencia_id`),
  KEY `fk_transferencia_detalle_producto` (`producto_id`),
  KEY `fk_transferencia_detalle_lote` (`lote_id`),
  CONSTRAINT `fk_transferencia_detalle_transferencia` FOREIGN KEY (`transferencia_id`) REFERENCES `transferencia_inventario` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transferencia_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transferencia_detalle_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Detalle de transferencias';


-- ============================================================================
-- 7. TABLA: merma_esperada
-- Porcentajes de merma esperada por categoría
-- ============================================================================

DROP TABLE IF EXISTS `merma_esperada`;
CREATE TABLE `merma_esperada` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `categoria_id` int(11) NOT NULL,
  `porcentaje_merma` decimal(5,2) NOT NULL COMMENT 'Porcentaje esperado de merma',
  `motivo_principal` varchar(255) DEFAULT NULL,
  `descripcion` text DEFAULT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_vigencia_desde` date NOT NULL,
  `fecha_vigencia_hasta` date DEFAULT NULL,
  `creado_por_id` bigint(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_merma_categoria` (`categoria_id`),
  KEY `fk_merma_creado_por` (`creado_por_id`),
  KEY `idx_merma_vigencia` (`fecha_vigencia_desde`, `fecha_vigencia_hasta`),
  CONSTRAINT `fk_merma_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_merma_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Merma esperada por categoría';


-- ============================================================================
-- 8. TABLA: costo_historico
-- Historial de cambios de costo
-- ============================================================================

DROP TABLE IF EXISTS `costo_historico`;
CREATE TABLE `costo_historico` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `costo_anterior` decimal(12,2) NOT NULL,
  `costo_nuevo` decimal(12,2) NOT NULL,
  `diferencia` decimal(12,2) NOT NULL,
  `porcentaje_cambio` decimal(5,2) NOT NULL,
  `motivo` enum('reabastecimiento','ajuste_manual','inflacion','proveedor','otro') NOT NULL,
  `descripcion` text DEFAULT NULL,
  `reabastecimiento_id` int(11) DEFAULT NULL COMMENT 'Si fue por reabastecimiento',
  `usuario_id` bigint(20) DEFAULT NULL,
  `fecha_cambio` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_costo_historico_producto` (`producto_id`),
  KEY `fk_costo_historico_reabastecimiento` (`reabastecimiento_id`),
  KEY `fk_costo_historico_usuario` (`usuario_id`),
  KEY `idx_costo_historico_fecha` (`fecha_cambio`),
  CONSTRAINT `fk_costo_historico_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_costo_historico_reabastecimiento` FOREIGN KEY (`reabastecimiento_id`) REFERENCES `reabastecimiento` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_costo_historico_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de cambios de costo';


-- ============================================================================
-- 9. TABLA: rotacion_inventario
-- Análisis de rotación de productos (calculado periódicamente)
-- ============================================================================

DROP TABLE IF EXISTS `rotacion_inventario`;
CREATE TABLE `rotacion_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `periodo` varchar(7) NOT NULL COMMENT 'Formato: YYYY-MM',
  `stock_inicial` int(11) NOT NULL,
  `stock_final` int(11) NOT NULL,
  `stock_promedio` decimal(12,2) NOT NULL,
  `cantidad_vendida` int(11) NOT NULL,
  `costo_mercancia_vendida` decimal(12,2) NOT NULL,
  `rotacion` decimal(10,2) NOT NULL COMMENT 'Veces que rota el inventario',
  `dias_inventario` decimal(10,2) NOT NULL COMMENT 'Días promedio en inventario',
  `clasificacion_abc` enum('A','B','C') DEFAULT NULL COMMENT 'Clasificación Pareto',
  `fecha_calculo` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rotacion_producto_periodo` (`producto_id`, `periodo`),
  KEY `fk_rotacion_producto` (`producto_id`),
  KEY `idx_rotacion_periodo` (`periodo`),
  KEY `idx_rotacion_clasificacion` (`clasificacion_abc`),
  CONSTRAINT `fk_rotacion_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Análisis de rotación de inventario';


-- ============================================================================
-- 10. AGREGAR CAMPOS FALTANTES A TABLAS EXISTENTES
-- ============================================================================

-- Agregar ubicación física a producto
ALTER TABLE `producto` 
ADD COLUMN `ubicacion_fisica_id` int(11) DEFAULT NULL AFTER `ubicacion`,
ADD COLUMN `sku_alternativo` varchar(50) DEFAULT NULL AFTER `codigo_barras`,
ADD COLUMN `unidad_medida` enum('unidad','caja','paquete','kg','litro','metro','otro') DEFAULT 'unidad' AFTER `sku_alternativo`,
ADD COLUMN `peso` decimal(10,3) DEFAULT NULL COMMENT 'Peso en kg' AFTER `unidad_medida`,
ADD COLUMN `volumen` decimal(10,3) DEFAULT NULL COMMENT 'Volumen en litros' AFTER `peso`,
ADD COLUMN `margen_objetivo` decimal(5,2) DEFAULT NULL COMMENT 'Margen de ganancia objetivo (%)' AFTER `costo_promedio`,
ADD COLUMN `dias_sin_movimiento` int(11) DEFAULT 0 COMMENT 'Días sin ventas' AFTER `stock_actual`,
ADD COLUMN `ultima_venta` datetime DEFAULT NULL AFTER `dias_sin_movimiento`,
ADD KEY `fk_producto_ubicacion_fisica` (`ubicacion_fisica_id`),
ADD KEY `idx_producto_sku_alternativo` (`sku_alternativo`),
ADD KEY `idx_producto_dias_sin_movimiento` (`dias_sin_movimiento`),
ADD CONSTRAINT `fk_producto_ubicacion_fisica` FOREIGN KEY (`ubicacion_fisica_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL;

-- Agregar ubicación física a lote
ALTER TABLE `lote`
ADD COLUMN `ubicacion_fisica_id` int(11) DEFAULT NULL AFTER `estado`,
ADD COLUMN `temperatura_almacenamiento` decimal(5,2) DEFAULT NULL COMMENT 'Temperatura de almacenamiento (°C)' AFTER `ubicacion_fisica_id`,
ADD KEY `fk_lote_ubicacion_fisica` (`ubicacion_fisica_id`),
ADD CONSTRAINT `fk_lote_ubicacion_fisica` FOREIGN KEY (`ubicacion_fisica_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL;

-- Agregar campos a movimiento_inventario
ALTER TABLE `movimiento_inventario`
ADD COLUMN `documento_soporte` varchar(100) DEFAULT NULL COMMENT 'Número de factura, remisión, etc.' AFTER `descripcion`,
ADD COLUMN `ubicacion_origen_id` int(11) DEFAULT NULL AFTER `documento_soporte`,
ADD COLUMN `ubicacion_destino_id` int(11) DEFAULT NULL AFTER `ubicacion_origen_id`,
ADD COLUMN `transferencia_id` int(11) DEFAULT NULL AFTER `reabastecimiento`,
ADD KEY `fk_movimiento_ubicacion_origen` (`ubicacion_origen_id`),
ADD KEY `fk_movimiento_ubicacion_destino` (`ubicacion_destino_id`),
ADD KEY `fk_movimiento_transferencia` (`transferencia_id`),
ADD CONSTRAINT `fk_movimiento_ubicacion_origen` FOREIGN KEY (`ubicacion_origen_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
ADD CONSTRAINT `fk_movimiento_ubicacion_destino` FOREIGN KEY (`ubicacion_destino_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
ADD CONSTRAINT `fk_movimiento_transferencia` FOREIGN KEY (`transferencia_id`) REFERENCES `transferencia_inventario` (`id`) ON DELETE SET NULL;

-- Agregar campos a reabastecimiento
ALTER TABLE `reabastecimiento`
ADD COLUMN `fecha_estimada_entrega` date DEFAULT NULL AFTER `fecha`,
ADD COLUMN `orden_compra` varchar(100) DEFAULT NULL AFTER `fecha_estimada_entrega`,
ADD COLUMN `factura_proveedor` varchar(100) DEFAULT NULL AFTER `orden_compra`,
ADD COLUMN `tiempo_entrega_dias` int(11) DEFAULT NULL COMMENT 'Días reales de entrega' AFTER `factura_proveedor`,
ADD KEY `idx_reabastecimiento_orden_compra` (`orden_compra`),
ADD KEY `idx_reabastecimiento_factura` (`factura_proveedor`);

-- Agregar campos a proveedor
ALTER TABLE `proveedor`
ADD COLUMN `calificacion` decimal(3,2) DEFAULT NULL COMMENT 'Calificación de 1 a 5' AFTER `direccion`,
ADD COLUMN `tiempo_entrega_promedio` int(11) DEFAULT NULL COMMENT 'Días promedio de entrega' AFTER `calificacion`,
ADD COLUMN `terminos_pago` varchar(100) DEFAULT NULL COMMENT 'Ej: 30 días, Contado, etc.' AFTER `tiempo_entrega_promedio`,
ADD COLUMN `activo` tinyint(1) DEFAULT 1 AFTER `terminos_pago`,
ADD KEY `idx_proveedor_calificacion` (`calificacion`),
ADD KEY `idx_proveedor_activo` (`activo`);

-- Agregar campos a categoria
ALTER TABLE `categoria`
ADD COLUMN `imagen_url` varchar(255) DEFAULT NULL AFTER `descripcion`,
ADD COLUMN `color_identificador` varchar(7) DEFAULT NULL COMMENT 'Color hex: #RRGGBB' AFTER `imagen_url`,
ADD COLUMN `icono` varchar(50) DEFAULT NULL COMMENT 'Nombre del icono' AFTER `color_identificador`;


-- ============================================================================
-- 11. DATOS INICIALES
-- ============================================================================

-- Ubicaciones físicas de ejemplo
INSERT INTO `ubicacion_fisica` (`codigo`, `nombre`, `tipo`, `parent_id`, `capacidad_maxima`, `activo`) VALUES
('BOD-A', 'Bodega Principal A', 'bodega', NULL, 10000, 1),
('BOD-A-PAS-1', 'Pasillo 1', 'pasillo', 1, 2000, 1),
('BOD-A-PAS-1-EST-1', 'Estante 1', 'estante', 2, 500, 1),
('BOD-A-PAS-1-EST-2', 'Estante 2', 'estante', 2, 500, 1),
('BOD-A-PAS-1-EST-3', 'Estante 3', 'estante', 2, 500, 1),
('BOD-B', 'Bodega Refrigerada B', 'bodega', NULL, 5000, 1),
('BOD-B-ZONA-1', 'Zona Refrigerada 1', 'zona', 6, 2000, 1);

-- Actualizar ubicación de productos existentes
UPDATE `ubicacion_fisica` SET `capacidad_actual` = 0 WHERE `id` > 0;

-- Merma esperada por categoría
INSERT INTO `merma_esperada` (`categoria_id`, `porcentaje_merma`, `motivo_principal`, `fecha_vigencia_desde`) VALUES
(1, 2.50, 'Vencimiento de lácteos', '2025-01-01'),
(2, 1.50, 'Deterioro de quesos', '2025-01-01'),
(3, 0.50, 'Rotura de botellas', '2025-01-01'),
(4, 0.30, 'Rotura de botellas', '2025-01-01'),
(5, 1.00, 'Deterioro de dulces', '2025-01-01'),
(6, 2.00, 'Rotura de empaques', '2025-01-01');


-- ============================================================================
-- 12. VISTAS ÚTILES
-- ============================================================================

-- Vista: Stock disponible vs reservado
DROP VIEW IF EXISTS `v_stock_disponible`;
CREATE VIEW `v_stock_disponible` AS
SELECT 
    p.id AS producto_id,
    p.nombre AS producto_nombre,
    p.stock_actual AS stock_total,
    COALESCE(SUM(CASE WHEN r.estado = 'activa' THEN r.cantidad ELSE 0 END), 0) AS stock_reservado,
    p.stock_actual - COALESCE(SUM(CASE WHEN r.estado = 'activa' THEN r.cantidad ELSE 0 END), 0) AS stock_disponible,
    p.stock_minimo,
    p.stock_maximo
FROM producto p
LEFT JOIN reserva_inventario r ON p.id = r.producto_id AND r.estado = 'activa'
GROUP BY p.id;

-- Vista: Productos sin movimiento (obsoletos)
DROP VIEW IF EXISTS `v_productos_obsoletos`;
CREATE VIEW `v_productos_obsoletos` AS
SELECT 
    p.id,
    p.nombre,
    p.categoria_id,
    c.nombre AS categoria_nombre,
    p.stock_actual,
    p.costo_promedio,
    p.stock_actual * p.costo_promedio AS valor_inmovilizado,
    p.dias_sin_movimiento,
    p.ultima_venta,
    DATEDIFF(CURDATE(), p.ultima_venta) AS dias_desde_ultima_venta
FROM producto p
INNER JOIN categoria c ON p.categoria_id = c.id
WHERE p.dias_sin_movimiento > 90 
  AND p.stock_actual > 0
  AND p.estado = 'activo'
ORDER BY p.dias_sin_movimiento DESC;

-- Vista: Resumen de alertas por prioridad
DROP VIEW IF EXISTS `v_resumen_alertas`;
CREATE VIEW `v_resumen_alertas` AS
SELECT 
    prioridad,
    tipo_alerta,
    COUNT(*) AS total,
    COUNT(CASE WHEN estado = 'activa' THEN 1 END) AS activas,
    COUNT(CASE WHEN estado = 'resuelta' THEN 1 END) AS resueltas,
    COUNT(CASE WHEN estado = 'ignorada' THEN 1 END) AS ignoradas
FROM alerta_inventario
WHERE fecha_generacion >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY prioridad, tipo_alerta
ORDER BY 
    FIELD(prioridad, 'critica', 'alta', 'media', 'baja'),
    total DESC;


-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
