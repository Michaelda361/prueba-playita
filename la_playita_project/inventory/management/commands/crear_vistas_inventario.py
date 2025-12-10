"""
Comando para crear vistas útiles de inventario
"""
from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = 'Crea vistas útiles para el sistema de inventario'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🚀 Creando vistas de inventario...'))
        
        vistas = [
            # Vista: Stock disponible vs reservado
            """
            CREATE OR REPLACE VIEW v_stock_disponible AS
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
            GROUP BY p.id
            """,
            
            # Vista: Productos obsoletos
            """
            CREATE OR REPLACE VIEW v_productos_obsoletos AS
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
            ORDER BY p.dias_sin_movimiento DESC
            """,
            
            # Vista: Resumen de alertas
            """
            CREATE OR REPLACE VIEW v_resumen_alertas AS
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
                total DESC
            """,
        ]
        
        with connection.cursor() as cursor:
            for i, vista in enumerate(vistas, 1):
                try:
                    cursor.execute(vista)
                    self.stdout.write(f'✅ [{i}/{len(vistas)}] Vista creada correctamente')
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f'❌ [{i}/{len(vistas)}] Error: {str(e)[:150]}'))
        
        self.stdout.write(self.style.SUCCESS('\n🎉 Vistas creadas exitosamente!'))
