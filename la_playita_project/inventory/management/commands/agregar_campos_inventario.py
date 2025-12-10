"""
Comando para agregar campos faltantes a las tablas de inventario
"""
from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = 'Agrega campos faltantes a las tablas de inventario'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🚀 Agregando campos faltantes...'))
        
        queries = [
            # Agregar campos a producto
            """
            ALTER TABLE producto 
            ADD COLUMN ubicacion_fisica_id int(11) DEFAULT NULL AFTER ubicacion,
            ADD COLUMN sku_alternativo varchar(50) DEFAULT NULL AFTER codigo_barras,
            ADD COLUMN unidad_medida enum('unidad','caja','paquete','kg','litro','metro','otro') DEFAULT 'unidad' AFTER sku_alternativo,
            ADD COLUMN peso decimal(10,3) DEFAULT NULL AFTER unidad_medida,
            ADD COLUMN volumen decimal(10,3) DEFAULT NULL AFTER peso,
            ADD COLUMN margen_objetivo decimal(5,2) DEFAULT NULL AFTER costo_promedio,
            ADD COLUMN dias_sin_movimiento int(11) DEFAULT 0 AFTER stock_actual,
            ADD COLUMN ultima_venta datetime DEFAULT NULL AFTER dias_sin_movimiento
            """,
            
            # Agregar índices a producto
            """
            ALTER TABLE producto
            ADD KEY fk_producto_ubicacion_fisica (ubicacion_fisica_id),
            ADD KEY idx_producto_sku_alternativo (sku_alternativo),
            ADD KEY idx_producto_dias_sin_movimiento (dias_sin_movimiento)
            """,
            
            # Agregar constraint a producto
            """
            ALTER TABLE producto
            ADD CONSTRAINT fk_producto_ubicacion_fisica 
            FOREIGN KEY (ubicacion_fisica_id) REFERENCES ubicacion_fisica(id) ON DELETE SET NULL
            """,
            
            # Agregar campos a lote
            """
            ALTER TABLE lote
            ADD COLUMN ubicacion_fisica_id int(11) DEFAULT NULL AFTER estado,
            ADD COLUMN temperatura_almacenamiento decimal(5,2) DEFAULT NULL AFTER ubicacion_fisica_id
            """,
            
            # Agregar índice a lote
            """
            ALTER TABLE lote
            ADD KEY fk_lote_ubicacion_fisica (ubicacion_fisica_id)
            """,
            
            # Agregar constraint a lote
            """
            ALTER TABLE lote
            ADD CONSTRAINT fk_lote_ubicacion_fisica 
            FOREIGN KEY (ubicacion_fisica_id) REFERENCES ubicacion_fisica(id) ON DELETE SET NULL
            """,
            
            # Agregar campos a movimiento_inventario
            """
            ALTER TABLE movimiento_inventario
            ADD COLUMN documento_soporte varchar(100) DEFAULT NULL AFTER descripcion,
            ADD COLUMN ubicacion_origen_id int(11) DEFAULT NULL AFTER documento_soporte,
            ADD COLUMN ubicacion_destino_id int(11) DEFAULT NULL AFTER ubicacion_origen_id,
            ADD COLUMN transferencia_id int(11) DEFAULT NULL AFTER reabastecimiento_id
            """,
            
            # Agregar índices a movimiento_inventario
            """
            ALTER TABLE movimiento_inventario
            ADD KEY fk_movimiento_ubicacion_origen (ubicacion_origen_id),
            ADD KEY fk_movimiento_ubicacion_destino (ubicacion_destino_id),
            ADD KEY fk_movimiento_transferencia (transferencia_id)
            """,
            
            # Agregar constraints a movimiento_inventario
            """
            ALTER TABLE movimiento_inventario
            ADD CONSTRAINT fk_movimiento_ubicacion_origen 
            FOREIGN KEY (ubicacion_origen_id) REFERENCES ubicacion_fisica(id) ON DELETE SET NULL
            """,
            
            """
            ALTER TABLE movimiento_inventario
            ADD CONSTRAINT fk_movimiento_ubicacion_destino 
            FOREIGN KEY (ubicacion_destino_id) REFERENCES ubicacion_fisica(id) ON DELETE SET NULL
            """,
            
            """
            ALTER TABLE movimiento_inventario
            ADD CONSTRAINT fk_movimiento_transferencia 
            FOREIGN KEY (transferencia_id) REFERENCES transferencia_inventario(id) ON DELETE SET NULL
            """,
            
            # Agregar campos a reabastecimiento
            """
            ALTER TABLE reabastecimiento
            ADD COLUMN fecha_estimada_entrega date DEFAULT NULL AFTER fecha,
            ADD COLUMN orden_compra varchar(100) DEFAULT NULL AFTER fecha_estimada_entrega,
            ADD COLUMN factura_proveedor varchar(100) DEFAULT NULL AFTER orden_compra,
            ADD COLUMN tiempo_entrega_dias int(11) DEFAULT NULL AFTER factura_proveedor
            """,
            
            # Agregar índices a reabastecimiento
            """
            ALTER TABLE reabastecimiento
            ADD KEY idx_reabastecimiento_orden_compra (orden_compra),
            ADD KEY idx_reabastecimiento_factura (factura_proveedor)
            """,
            
            # Agregar campos a proveedor
            """
            ALTER TABLE proveedor
            ADD COLUMN calificacion decimal(3,2) DEFAULT NULL AFTER direccion,
            ADD COLUMN tiempo_entrega_promedio int(11) DEFAULT NULL AFTER calificacion,
            ADD COLUMN terminos_pago varchar(100) DEFAULT NULL AFTER tiempo_entrega_promedio,
            ADD COLUMN activo tinyint(1) DEFAULT 1 AFTER terminos_pago
            """,
            
            # Agregar índices a proveedor
            """
            ALTER TABLE proveedor
            ADD KEY idx_proveedor_calificacion (calificacion),
            ADD KEY idx_proveedor_activo (activo)
            """,
            
            # Agregar campos a categoria
            """
            ALTER TABLE categoria
            ADD COLUMN imagen_url varchar(255) DEFAULT NULL AFTER descripcion,
            ADD COLUMN color_identificador varchar(7) DEFAULT NULL AFTER imagen_url,
            ADD COLUMN icono varchar(50) DEFAULT NULL AFTER color_identificador
            """,
        ]
        
        success = 0
        warnings = 0
        errors = 0
        
        with connection.cursor() as cursor:
            for i, query in enumerate(queries, 1):
                try:
                    cursor.execute(query)
                    success += 1
                    self.stdout.write(f'✅ [{i}/{len(queries)}] Ejecutado correctamente')
                except Exception as e:
                    error_msg = str(e)
                    if 'Duplicate column' in error_msg or 'already exists' in error_msg:
                        warnings += 1
                        self.stdout.write(self.style.WARNING(f'⚠️  [{i}/{len(queries)}] Campo ya existe (OK)'))
                    elif 'Duplicate key' in error_msg:
                        warnings += 1
                        self.stdout.write(self.style.WARNING(f'⚠️  [{i}/{len(queries)}] Índice ya existe (OK)'))
                    else:
                        errors += 1
                        self.stdout.write(self.style.ERROR(f'❌ [{i}/{len(queries)}] Error: {error_msg[:150]}'))
        
        self.stdout.write(self.style.SUCCESS(f'\n✨ Proceso completado:'))
        self.stdout.write(self.style.SUCCESS(f'   ✅ Exitosos: {success}'))
        if warnings > 0:
            self.stdout.write(self.style.WARNING(f'   ⚠️  Advertencias: {warnings}'))
        if errors > 0:
            self.stdout.write(self.style.ERROR(f'   ❌ Errores: {errors}'))
        
        self.stdout.write(self.style.SUCCESS('\n🎉 Campos agregados exitosamente!'))
