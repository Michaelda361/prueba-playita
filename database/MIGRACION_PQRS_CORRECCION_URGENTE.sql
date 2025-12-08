-- ============================================================================
-- MIGRACIÓN URGENTE: CORRECCIÓN MÓDULO PQRS
-- ============================================================================
-- Fecha: Diciembre 2024
-- Propósito: Sincronizar base de datos con modelos Django
-- Prioridad: CRÍTICA
-- ============================================================================

USE laplayita;

-- Backup de seguridad antes de migrar
CREATE TABLE IF NOT EXISTS pqrs_backup_pre_migracion AS SELECT * FROM pqrs;
CREATE TABLE IF NOT EXISTS pqrs_evento_backup_pre_migracion AS SELECT * FROM pqrs_evento;

-- ============================================================================
-- PASO 1: AGREGAR CAMPOS FALTANTES A TABLA PQRS
-- ============================================================================

-- Campo: asignado_a_id (CRÍTICO)
ALTER TABLE pqrs 
ADD COLUMN IF NOT EXISTS asignado_a_id BIGINT NULL AFTER creado_por_id,
ADD CONSTRAINT fk_pqrs_asignado_a 
    FOREIGN KEY (asignado_a_id) REFERENCES usuario(id) 
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Campo: canal_origen (CRÍTICO)
ALTER TABLE pqrs 
ADD COLUMN IF NOT EXISTS canal_origen VARCHAR(20) DEFAULT 'web' AFTER prioridad;

-- Campo: fecha_primera_respuesta (ALTO)
ALTER TABLE pqrs 
ADD COLUMN IF NOT EXISTS fecha_primera_respuesta DATETIME NULL AFTER fecha_actualizacion;

-- Campo: tiempo_resolucion_horas (ALTO)
ALTER TABLE pqrs 
ADD COLUMN IF NOT EXISTS tiempo_resolucion_horas INT NULL AFTER fecha_cierre;

-- Campos de auditoría adicionales
ALTER TABLE pqrs
ADD COLUMN IF NOT EXISTS ip_creacion VARCHAR(45) NULL AFTER tiempo_resolucion_horas,
ADD COLUMN IF NOT EXISTS user_agent TEXT NULL AFTER ip_creacion,
ADD COLUMN IF NOT EXISTS ultima_modificacion_por_id BIGINT NULL AFTER user_agent,
ADD CONSTRAINT fk_pqrs_ultima_modificacion 
    FOREIGN KEY (ultima_modificacion_por_id) REFERENCES usuario(id) 
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Crear índices para optimización
CREATE INDEX IF NOT EXISTS idx_asignado_a ON pqrs(asignado_a_id);
CREATE INDEX IF NOT EXISTS idx_canal_origen ON pqrs(canal_origen);
CREATE INDEX IF NOT EXISTS idx_fecha_primera_respuesta ON pqrs(fecha_primera_respuesta);

