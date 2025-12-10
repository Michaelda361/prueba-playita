-- ============================================================================
-- FASE 3: STORED PROCEDURES Y FUNCIONES MEJORADAS
-- Lógica de negocio en la base de datos
-- ============================================================================

USE laplayita;

-- ----------------------------------------------------------------------------
-- 1. PROCEDURE: Generar alertas automáticas
-- ----------------------------------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_generar_alertas_inventario$$

CREATE PROCEDURE sp_generar_alertas_inventario()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_producto_id INT;
    DECLARE v_producto_nombre VARCHAR(50);
    DECLARE v_stock_actual INT;
    DECLARE v_stock_minimo INT;
    DECLARE v_stock_maximo INT;
    DECLARE v_lote_id INT;
    DECLARE v_numero_lote VARCHAR(50);
    DECLARE v_fecha_caducidad DATE;
    DECLARE v_cantidad_lote INT;
    DECLARE v_dias_vencer INT;
    
    -- Cursor para productos con stock bajo
    DECLARE cur_stock_bajo CURSOR FOR
        SELECT p.id, p.nombre, p.stock_actual, p.stock_minimo
        FROM producto p
        WHERE p.estado = 'activo'
          AND p.stock_actual < (p.stock_minimo * 1.5)
          AND p.stock_actual > 0
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.producto_id = p.id
                AND a.tipo_alerta = 'stock_bajo'
                AND a.estado = 'activa'
          );
    
    -- Cursor para productos sin stock
    DECLARE cur_sin_stock CURSOR FOR
        SELECT p.id, p.nombre, p.stock_actual, p.stock_minimo
        FROM producto p
        WHERE p.estado = 'activo'
          AND p.stock_actual = 0
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.producto_id = p.id
                AND a.tipo_alerta = 'sin_stock'
                AND a.estado = 'activa'
          );
    
    -- Cursor para lotes próximos a vencer
    DECLARE cur_proximo_vencer CURSOR FOR
        SELECT l.id, l.numero_lote, l.producto_id, p.nombre, l.fecha_caducidad, l.cantidad_disponible,
               DATEDIFF(l.fecha_caducidad, CURDATE()) as dias_vencer
        FROM lote l
        INNER JOIN producto p ON l.producto_id = p.id
        WHERE l.estado = 'activo'
          AND l.cantidad_disponible > 0
          AND l.fecha_caducidad BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.lote_id = l.id
                AND a.tipo_alerta = 'proximo_vencer'
                AND a.estado = 'activa'
          );
    
    -- Cursor para lotes vencidos
    DECLARE cur_vencido CURSOR FOR
        SELECT l.id, l.numero_lote, l.producto_id, p.nombre, l.fecha_caducidad, l.cantidad_disponible
        FROM lote l
        INNER JOIN producto p ON l.producto_id = p.id
        WHERE l.estado IN ('activo', 'vencido')
          AND l.cantidad_disponible > 0
          AND l.fecha_caducidad < CURDATE()
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.lote_id = l.id
                AND a.tipo_alerta = 'vencido'
                AND a.estado = 'activa'
          );
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Generar alertas de stock bajo
    OPEN cur_stock_bajo;
    read_loop_bajo: LOOP
        FETCH cur_stock_bajo INTO v_producto_id, v_producto_nombre, v_stock_actual, v_stock_minimo;
        IF done THEN
            LEAVE read_loop_bajo;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            'stock_bajo',
            IF(v_stock_actual < v_stock_minimo, 'alta', 'media'),
            CONCAT('Stock bajo: ', v_producto_nombre),
            CONCAT('El producto "', v_producto_nombre, '" tiene stock bajo y requiere reabastecimiento.'),
            CONCAT('Stock actual: ', v_stock_actual),
            CONCAT('Stock mínimo: ', v_stock_minimo),
            'activa'
        );
    END LOOP;
    CLOSE cur_stock_bajo;
    
    -- Generar alertas de sin stock
    SET done = FALSE;
    OPEN cur_sin_stock;
    read_loop_sin: LOOP
        FETCH cur_sin_stock INTO v_producto_id, v_producto_nombre, v_stock_actual, v_stock_minimo;
        IF done THEN
            LEAVE read_loop_sin;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            'sin_stock',
            'critica',
            CONCAT('RUPTURA DE STOCK: ', v_producto_nombre),
            CONCAT('El producto "', v_producto_nombre, '" no tiene stock disponible.'),
            'Stock actual: 0',
            CONCAT('Stock mínimo: ', v_stock_minimo),
            'activa'
        );
    END LOOP;
    CLOSE cur_sin_stock;
    
    -- Generar alertas de próximo a vencer
    SET done = FALSE;
    OPEN cur_proximo_vencer;
    read_loop_vencer: LOOP
        FETCH cur_proximo_vencer INTO v_lote_id, v_numero_lote, v_producto_id, v_producto_nombre, 
                                       v_fecha_caducidad, v_cantidad_lote, v_dias_vencer;
        IF done THEN
            LEAVE read_loop_vencer;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, lote_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            v_lote_id,
            'proximo_vencer',
            IF(v_dias_vencer <= 7, 'alta', 'media'),
            CONCAT('Lote próximo a vencer: ', v_producto_nombre),
            CONCAT('El lote ', v_numero_lote, ' del producto "', v_producto_nombre, 
                   '" vence en ', v_dias_vencer, ' días.'),
            CONCAT('Cantidad: ', v_cantidad_lote, ' unidades'),
            CONCAT('Vence: ', DATE_FORMAT(v_fecha_caducidad, '%d/%m/%Y')),
            'activa'
        );
    END LOOP;
    CLOSE cur_proximo_vencer;
    
    -- Generar alertas de vencido
    SET done = FALSE;
    OPEN cur_vencido;
    read_loop_vencido: LOOP
        FETCH cur_vencido INTO v_lote_id, v_numero_lote, v_producto_id, v_producto_nombre, 
                                v_fecha_caducidad, v_cantidad_lote;
        IF done THEN
            LEAVE read_loop_vencido;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, lote_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            v_lote_id,
            'vencido',
            'critica',
            CONCAT('LOTE VENCIDO: ', v_producto_nombre),
            CONCAT('El lote ', v_numero_lote, ' del producto "', v_producto_nombre, 
                   '" está vencido y debe ser descartado.'),
            CONCAT('Cantidad: ', v_cantidad_lote, ' unidades'),
            CONCAT('Venció: ', DATE_FORMAT(v_fecha_caducidad, '%d/%m/%Y')),
            'activa'
        );
        
        -- Actualizar estado del lote a vencido
        UPDATE lote SET estado = 'vencido' WHERE id = v_lote_id;
    END LOOP;
    CLOSE cur_vencido;
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 2. PROCEDURE: Aplicar ajuste de inventario
-- ----------------------------------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_aplicar_ajuste_inventario$$

CREATE PROCEDURE sp_aplicar_ajuste_inventario(
    IN p_ajuste_id INT,
    IN p_usuario_autoriza_id BIGINT
)
BEGIN
    DECLARE v_producto_id INT;
    DECLARE v_lote_id INT;
    DECLARE v_diferencia INT;
    DECLARE v_descripcion TEXT;
    DECLARE v_estado VARCHAR(20);
    
    -- Obtener datos del ajuste
    SELECT producto_id, lote_id, diferencia, descripcion, estado
    INTO v_producto_id, v_lote_id, v_diferencia, v_descripcion, v_estado
    FROM ajuste_inventario
    WHERE id = p_ajuste_id;
    
    -- Validar que el ajuste existe y está pendiente
    IF v_estado != 'pendiente' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El ajuste ya fue procesado o no está pendiente';
    END IF;
    
    START TRANSACTION;
    
    -- Si hay lote específico, ajustar el lote
    IF v_lote_id IS NOT NULL THEN
        UPDATE lote 
        SET cantidad_disponible = cantidad_disponible + v_diferencia
        WHERE id = v_lote_id;
    END IF;
    
    -- Registrar movimiento
    INSERT INTO movimiento_inventario (
        producto_id, lote_id, cantidad, tipo_movimiento, 
        descripcion, usuario_id, costo_unitario
    )
    SELECT 
        v_producto_id,
        v_lote_id,
        v_diferencia,
        'AJUSTE',
        CONCAT('Ajuste de inventario #', p_ajuste_id, ': ', v_descripcion),
        p_usuario_autoriza_id,
        p.costo_promedio
    FROM producto p
    WHERE p.id = v_producto_id;
    
    -- Actualizar estado del ajuste
    UPDATE ajuste_inventario
    SET estado = 'aplicado',
        usuario_autoriza_id = p_usuario_autoriza_id
    WHERE id = p_ajuste_id;
    
    COMMIT;
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 3. PROCEDURE: Aplicar descarte de producto
-- ----------------------------------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_aplicar_descarte_producto$$

CREATE PROCEDURE sp_aplicar_descarte_producto(
    IN p_descarte_id INT,
    IN p_usuario_autoriza_id BIGINT
)
BEGIN
    DECLARE v_producto_id INT;
    DECLARE v_lote_id INT;
    DECLARE v_cantidad INT;
    DECLARE v_descripcion TEXT;
    DECLARE v_estado VARCHAR(20);
    DECLARE v_costo_unitario DECIMAL(12,2);
    
    -- Obtener datos del descarte
    SELECT producto_id, lote_id, cantidad, descripcion, estado, costo_unitario
    INTO v_producto_id, v_lote_id, v_cantidad, v_descripcion, v_estado, v_costo_unitario
    FROM descarte_producto
    WHERE id = p_descarte_id;
    
    -- Validar que el descarte existe y está pendiente
    IF v_estado != 'pendiente' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El descarte ya fue procesado o no está pendiente';
    END IF;
    
    START TRANSACTION;
    
    -- Si hay lote específico, descontar del lote
    IF v_lote_id IS NOT NULL THEN
        UPDATE lote 
        SET cantidad_disponible = cantidad_disponible - v_cantidad
        WHERE id = v_lote_id;
        
        -- Si el lote queda en 0, marcarlo como descartado
        UPDATE lote 
        SET estado = 'descartado'
        WHERE id = v_lote_id AND cantidad_disponible = 0;
    END IF;
    
    -- Registrar movimiento
    INSERT INTO movimiento_inventario (
        producto_id, lote_id, cantidad, tipo_movimiento, 
        descripcion, usuario_id, costo_unitario
    ) VALUES (
        v_producto_id,
        v_lote_id,
        -v_cantidad,
        'DESCARTE',
        CONCAT('Descarte #', p_descarte_id, ': ', v_descripcion),
        p_usuario_autoriza_id,
        v_costo_unitario
    );
    
    -- Actualizar estado del descarte
    UPDATE descarte_producto
    SET estado = 'ejecutado',
        usuario_autoriza_id = p_usuario_autoriza_id
    WHERE id = p_descarte_id;
    
    -- Resolver alerta si existe
    UPDATE alerta_inventario
    SET estado = 'resuelta',
        resuelta_por_id = p_usuario_autoriza_id,
        fecha_resolucion = NOW(),
        notas_resolucion = CONCAT('Descarte aplicado #', p_descarte_id)
    WHERE lote_id = v_lote_id
      AND tipo_alerta IN ('vencido', 'proximo_vencer')
      AND estado = 'activa';
    
    COMMIT;
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 4. FUNCTION: Calcular días de inventario de un producto
-- ----------------------------------------------------------------------------

DELIMITER $$

DROP FUNCTION IF EXISTS fn_dias_inventario$$

CREATE FUNCTION fn_dias_inventario(p_producto_id INT, p_dias_analisis INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock_actual INT;
    DECLARE v_ventas_periodo INT;
    DECLARE v_promedio_diario DECIMAL(10,2);
    DECLARE v_dias_inventario DECIMAL(10,2);
    
    -- Obtener stock actual
    SELECT stock_actual INTO v_stock_actual
    FROM producto
    WHERE id = p_producto_id;
    
    -- Calcular ventas en el período
    SELECT COALESCE(SUM(ABS(cantidad)), 0) INTO v_ventas_periodo
    FROM movimiento_inventario
    WHERE producto_id = p_producto_id
      AND tipo_movimiento = 'SALIDA'
      AND fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL p_dias_analisis DAY);
    
    -- Calcular promedio diario
    IF v_ventas_periodo > 0 THEN
        SET v_promedio_diario = v_ventas_periodo / p_dias_analisis;
        SET v_dias_inventario = v_stock_actual / v_promedio_diario;
    ELSE
        SET v_dias_inventario = 999; -- Sin ventas = inventario infinito
    END IF;
    
    RETURN v_dias_inventario;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 5. FUNCTION: Calcular rotación de inventario
-- ----------------------------------------------------------------------------

DELIMITER $$

DROP FUNCTION IF EXISTS fn_rotacion_inventario$$

CREATE FUNCTION fn_rotacion_inventario(p_producto_id INT, p_dias_analisis INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_costo_promedio DECIMAL(12,2);
    DECLARE v_stock_actual INT;
    DECLARE v_costo_ventas DECIMAL(12,2);
    DECLARE v_inventario_promedio DECIMAL(12,2);
    DECLARE v_rotacion DECIMAL(10,2);
    
    -- Obtener datos del producto
    SELECT costo_promedio, stock_actual 
    INTO v_costo_promedio, v_stock_actual
    FROM producto
    WHERE id = p_producto_id;
    
    -- Calcular costo de ventas en el período
    SELECT COALESCE(SUM(ABS(cantidad) * costo_unitario), 0) INTO v_costo_ventas
    FROM movimiento_inventario
    WHERE producto_id = p_producto_id
      AND tipo_movimiento = 'SALIDA'
      AND fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL p_dias_analisis DAY);
    
    -- Inventario promedio (simplificado)
    SET v_inventario_promedio = v_stock_actual * v_costo_promedio;
    
    -- Calcular rotación
    IF v_inventario_promedio > 0 THEN
        SET v_rotacion = v_costo_ventas / v_inventario_promedio;
    ELSE
        SET v_rotacion = 0;
    END IF;
    
    RETURN v_rotacion;
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- 6. PROCEDURE: Generar valorización mensual
-- ----------------------------------------------------------------------------

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_generar_valorizacion_mensual$$

CREATE PROCEDURE sp_generar_valorizacion_mensual(
    IN p_periodo VARCHAR(7), -- Formato: YYYY-MM
    IN p_usuario_id BIGINT
)
BEGIN
    DECLARE v_fecha_corte DATE;
    
    -- Calcular fecha de corte (último día del mes)
    SET v_fecha_corte = LAST_DAY(CONCAT(p_periodo, '-01'));
    
    -- Eliminar valorización existente para ese período
    DELETE FROM valorizacion_inventario WHERE periodo = p_periodo;
    
    -- Insertar valorización
    INSERT INTO valorizacion_inventario (
        periodo, fecha_corte, producto_id, cantidad, costo_unitario, 
        costo_promedio, valor_total, categoria_id, generado_por_id
    )
    SELECT 
        p_periodo,
        v_fecha_corte,
        p.id,
        p.stock_actual,
        COALESCE(
            (SELECT l.costo_unitario_lote 
             FROM lote l 
             WHERE l.producto_id = p.id 
               AND l.cantidad_disponible > 0 
             ORDER BY l.fecha_entrada 
             LIMIT 1),
            p.costo_promedio
        ) as costo_unitario,
        p.costo_promedio,
        p.stock_actual * p.costo_promedio as valor_total,
        p.categoria_id,
        p_usuario_id
    FROM producto p
    WHERE p.estado = 'activo';
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- VERIFICACIÓN FINAL
-- ----------------------------------------------------------------------------

-- Mostrar procedures creados
SHOW PROCEDURE STATUS WHERE Db = 'laplayita' AND Name LIKE 'sp_%';

-- Mostrar funciones creadas
SHOW FUNCTION STATUS WHERE Db = 'laplayita' AND Name LIKE 'fn_%';

SELECT 'FASE 3 COMPLETADA: Stored procedures y funciones creadas' AS resultado;
