-- ============================================================================
-- MIGRACIÓN COMPLETA: MEJORAS MÓDULO PQRS
-- ============================================================================
-- Fecha: Diciembre 2024
-- Propósito: Implementar SLA, plantillas, notificaciones y mejoras UX
-- ============================================================================

USE laplayita;

-- ============================================================================
-- PASO 1: TABLA DE CONFIGURACIÓN SLA
-- ============================================================================

CREATE TABLE IF NOT EXISTS pqrs_sla (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(20) NOT NULL,
    prioridad VARCHAR(20) NOT NULL,
    horas_limite INT NOT NULL,
    activo TINYINT(1) DEFAULT 1,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_tipo_prioridad (tipo, prioridad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar configuración de SLA por defecto
INSERT INTO pqrs_sla (tipo, prioridad, horas_limite) VALUES
('peticion', 'baja', 72),
('peticion', 'media', 48),
('peticion', 'alta', 24),
('peticion', 'urgente', 4),
('queja', 'baja', 48),
('queja', 'media', 24),
('queja', 'alta', 12),
('queja', 'urgente', 2),
('reclamo', 'baja', 24),
('reclamo', 'media', 12),
('reclamo', 'alta', 6),
('reclamo', 'urgente', 1),
('sugerencia', 'baja', 168),
('sugerencia', 'media', 120),
('sugerencia', 'alta', 72),
('sugerencia', 'urgente', 24)
ON DUPLICATE KEY UPDATE horas_limite=VALUES(horas_limite);

-- ============================================================================
-- PASO 2: AGREGAR CAMPOS DE SLA A TABLA PQRS
-- ============================================================================

ALTER TABLE pqrs
ADD COLUMN IF NOT EXISTS fecha_limite_sla DATETIME NULL AFTER tiempo_resolucion_horas,
ADD COLUMN IF NOT EXISTS sla_vencido TINYINT(1) DEFAULT 0 AFTER fecha_limite_sla,
ADD COLUMN IF NOT EXISTS ultima_modificacion_por_id BIGINT NULL AFTER sla_vencido,
ADD CONSTRAINT fk_pqrs_ultima_modificacion 
    FOREIGN KEY (ultima_modificacion_por_id) REFERENCES usuario(id) 
    ON DELETE SET NULL ON UPDATE CASCADE;

CREATE INDEX IF NOT EXISTS idx_sla_vencido ON pqrs(sla_vencido);
CREATE INDEX IF NOT EXISTS idx_fecha_limite_sla ON pqrs(fecha_limite_sla);

-- ============================================================================
-- PASO 3: TRIGGER PARA CALCULAR SLA AUTOMÁTICAMENTE
-- ============================================================================

DROP TRIGGER IF EXISTS calcular_sla_insert;

DELIMITER $$
CREATE TRIGGER calcular_sla_insert
BEFORE INSERT ON pqrs
FOR EACH ROW
BEGIN
    DECLARE horas_sla INT;
    
    -- Obtener horas de SLA según tipo y prioridad
    SELECT horas_limite INTO horas_sla
    FROM pqrs_sla
    WHERE tipo = NEW.tipo AND prioridad = NEW.prioridad AND activo = 1
    LIMIT 1;
    
    -- Si se encontró configuración, calcular fecha límite
    IF horas_sla IS NOT NULL THEN
        SET NEW.fecha_limite_sla = DATE_ADD(NEW.fecha_creacion, INTERVAL horas_sla HOUR);
    END IF;
END$$
DELIMITER ;

-- ============================================================================
-- PASO 4: TRIGGER PARA ACTUALIZAR SLA VENCIDO
-- ============================================================================

DROP TRIGGER IF EXISTS verificar_sla_update;

DELIMITER $$
CREATE TRIGGER verificar_sla_update
BEFORE UPDATE ON pqrs
FOR EACH ROW
BEGIN
    -- Verificar si el SLA está vencido
    IF NEW.fecha_limite_sla IS NOT NULL 
       AND NOW() > NEW.fecha_limite_sla 
       AND NEW.estado NOT IN ('cerrado', 'resuelto') THEN
        SET NEW.sla_vencido = 1;
    END IF;
    
    -- Si se resuelve o cierra, marcar SLA como no vencido
    IF NEW.estado IN ('cerrado', 'resuelto') THEN
        SET NEW.sla_vencido = 0;
    END IF;
END$$
DELIMITER ;


-- ============================================================================
-- PASO 5: TABLA DE PLANTILLAS DE RESPUESTA
-- ============================================================================

CREATE TABLE IF NOT EXISTS pqrs_plantilla_respuesta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) NULL COMMENT 'peticion, queja, reclamo, sugerencia',
    categoria VARCHAR(50) NULL COMMENT 'general, producto, servicio, entrega',
    contenido TEXT NOT NULL,
    activa TINYINT(1) DEFAULT 1,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    creado_por_id BIGINT NULL,
    CONSTRAINT fk_plantilla_creado_por 
        FOREIGN KEY (creado_por_id) REFERENCES usuario(id) 
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_plantilla_tipo ON pqrs_plantilla_respuesta(tipo);
CREATE INDEX idx_plantilla_categoria ON pqrs_plantilla_respuesta(categoria);
CREATE INDEX idx_plantilla_activa ON pqrs_plantilla_respuesta(activa);

-- Insertar plantillas de ejemplo
INSERT INTO pqrs_plantilla_respuesta (nombre, tipo, categoria, contenido) VALUES
('Recepción de Petición', 'peticion', 'general', 
'Estimado/a {{cliente_nombre}},

Hemos recibido su petición con número de caso {{numero_caso}}. Nuestro equipo está revisando su solicitud y le responderemos en un plazo máximo de {{sla_horas}} horas.

Gracias por su paciencia.

Atentamente,
Equipo La Playita'),

('Recepción de Queja', 'queja', 'general',
'Estimado/a {{cliente_nombre}},

Lamentamos los inconvenientes que ha experimentado. Hemos registrado su queja con el número {{numero_caso}} y estamos investigando el asunto con prioridad.

Nos pondremos en contacto con usted a la brevedad.

Disculpe las molestias.

Atentamente,
Equipo La Playita'),

('Recepción de Reclamo - Producto', 'reclamo', 'producto',
'Estimado/a {{cliente_nombre}},

Hemos recibido su reclamo sobre el producto. Caso número: {{numero_caso}}.

Estamos revisando su situación con prioridad y le daremos una solución en las próximas {{sla_horas}} horas.

Por favor, conserve el producto y la factura para el proceso de cambio o devolución.

Gracias por su comprensión.

Atentamente,
Equipo La Playita'),

('Agradecimiento por Sugerencia', 'sugerencia', 'general',
'Estimado/a {{cliente_nombre}},

¡Gracias por su sugerencia! Hemos registrado su idea con el número {{numero_caso}}.

Valoramos mucho su aporte y lo tendremos en cuenta para mejorar nuestros servicios.

Atentamente,
Equipo La Playita'),

('Caso Resuelto', NULL, NULL,
'Estimado/a {{cliente_nombre}},

Nos complace informarle que su caso {{numero_caso}} ha sido resuelto.

Solución aplicada: {{solucion}}

Si tiene alguna duda adicional, no dude en contactarnos.

Atentamente,
Equipo La Playita'),

('Solicitud de Información Adicional', NULL, NULL,
'Estimado/a {{cliente_nombre}},

Para poder atender su caso {{numero_caso}} de manera efectiva, necesitamos información adicional:

{{informacion_requerida}}

Por favor, responda este correo con los datos solicitados.

Gracias por su colaboración.

Atentamente,
Equipo La Playita'),

('Escalamiento a Supervisor', NULL, NULL,
'Estimado/a {{cliente_nombre}},

Su caso {{numero_caso}} ha sido escalado a nuestro equipo de supervisión para una atención especializada.

Un supervisor se pondrá en contacto con usted en las próximas horas.

Agradecemos su paciencia.

Atentamente,
Equipo La Playita')
ON DUPLICATE KEY UPDATE contenido=VALUES(contenido);

-- ============================================================================
-- PASO 6: TABLA DE VISTAS GUARDADAS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pqrs_vista_guardada (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    filtros JSON NOT NULL,
    es_publica TINYINT(1) DEFAULT 0,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_vista_usuario 
        FOREIGN KEY (usuario_id) REFERENCES usuario(id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_vista_usuario ON pqrs_vista_guardada(usuario_id);
CREATE INDEX idx_vista_publica ON pqrs_vista_guardada(es_publica);

-- ============================================================================
-- PASO 7: TABLA DE NOTIFICACIONES
-- ============================================================================

CREATE TABLE IF NOT EXISTS pqrs_notificacion (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pqrs_id BIGINT NOT NULL,
    tipo ENUM('email', 'push', 'sms', 'sistema') NOT NULL,
    destinatario VARCHAR(255) NOT NULL,
    asunto VARCHAR(255) NULL,
    contenido TEXT NOT NULL,
    enviado TINYINT(1) DEFAULT 0,
    fecha_envio DATETIME NULL,
    error TEXT NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notificacion_pqrs 
        FOREIGN KEY (pqrs_id) REFERENCES pqrs(id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_notificacion_pqrs ON pqrs_notificacion(pqrs_id);
CREATE INDEX idx_notificacion_enviado ON pqrs_notificacion(enviado);
CREATE INDEX idx_notificacion_fecha ON pqrs_notificacion(fecha_creacion);

-- ============================================================================
-- PASO 8: TABLA DE CATEGORÍAS PERSONALIZADAS
-- ============================================================================

CREATE TABLE IF NOT EXISTS pqrs_categoria_personalizada (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT NULL,
    categoria_padre_id INT NULL,
    activa TINYINT(1) DEFAULT 1,
    orden INT DEFAULT 0,
    icono VARCHAR(50) NULL,
    color VARCHAR(20) NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_categoria_padre 
        FOREIGN KEY (categoria_padre_id) REFERENCES pqrs_categoria_personalizada(id) 
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_categoria_activa ON pqrs_categoria_personalizada(activa);
CREATE INDEX idx_categoria_orden ON pqrs_categoria_personalizada(orden);

-- Insertar categorías base
INSERT INTO pqrs_categoria_personalizada (nombre, descripcion, orden, icono, color) VALUES
('Producto Defectuoso', 'Productos con defectos de fábrica o daños', 1, 'box-seam', '#dc3545'),
('Entrega Tardía', 'Retrasos en la entrega de productos', 2, 'clock-history', '#ffc107'),
('Atención al Cliente', 'Problemas con el servicio de atención', 3, 'headset', '#0d6efd'),
('Precio Incorrecto', 'Discrepancias en precios o cobros', 4, 'currency-dollar', '#fd7e14'),
('Producto Faltante', 'Productos no entregados o faltantes en pedido', 5, 'box-seam-fill', '#dc3545'),
('Calidad del Producto', 'Problemas con la calidad o frescura', 6, 'star-half', '#ffc107'),
('Solicitud de Cambio', 'Cambios o devoluciones de productos', 7, 'arrow-repeat', '#0dcaf0'),
('Felicitación', 'Comentarios positivos y felicitaciones', 8, 'emoji-smile', '#198754'),
('Sugerencia de Mejora', 'Ideas para mejorar el servicio', 9, 'lightbulb', '#20c997'),
('Consulta General', 'Preguntas o consultas generales', 10, 'question-circle', '#6c757d')
ON DUPLICATE KEY UPDATE descripcion=VALUES(descripcion);

-- ============================================================================
-- PASO 9: ACTUALIZAR CASOS EXISTENTES CON SLA
-- ============================================================================

UPDATE pqrs p
INNER JOIN pqrs_sla s ON p.tipo = s.tipo AND p.prioridad = s.prioridad
SET p.fecha_limite_sla = DATE_ADD(p.fecha_creacion, INTERVAL s.horas_limite HOUR)
WHERE p.fecha_limite_sla IS NULL AND s.activo = 1;

-- Marcar casos vencidos
UPDATE pqrs
SET sla_vencido = 1
WHERE fecha_limite_sla IS NOT NULL 
  AND NOW() > fecha_limite_sla 
  AND estado NOT IN ('cerrado', 'resuelto');

-- ============================================================================
-- PASO 10: VISTA PARA DASHBOARD
-- ============================================================================

CREATE OR REPLACE VIEW v_pqrs_dashboard AS
SELECT 
    COUNT(*) as total_casos,
    SUM(CASE WHEN estado = 'nuevo' THEN 1 ELSE 0 END) as casos_nuevos,
    SUM(CASE WHEN estado = 'en_proceso' THEN 1 ELSE 0 END) as casos_en_proceso,
    SUM(CASE WHEN estado = 'resuelto' THEN 1 ELSE 0 END) as casos_resueltos,
    SUM(CASE WHEN estado = 'cerrado' THEN 1 ELSE 0 END) as casos_cerrados,
    SUM(CASE WHEN sla_vencido = 1 THEN 1 ELSE 0 END) as casos_sla_vencido,
    SUM(CASE WHEN prioridad = 'urgente' AND estado NOT IN ('cerrado', 'resuelto') THEN 1 ELSE 0 END) as casos_urgentes_activos,
    AVG(tiempo_resolucion_horas) as tiempo_promedio_resolucion,
    COUNT(DISTINCT cliente_id) as clientes_unicos
FROM pqrs;

-- ============================================================================
-- FINALIZACIÓN
-- ============================================================================

SELECT 'Migración completada exitosamente' as mensaje;
SELECT COUNT(*) as total_pqrs FROM pqrs;
SELECT COUNT(*) as total_plantillas FROM pqrs_plantilla_respuesta;
SELECT COUNT(*) as total_sla_config FROM pqrs_sla;
