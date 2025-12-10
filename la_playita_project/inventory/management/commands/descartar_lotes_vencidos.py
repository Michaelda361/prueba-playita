from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import date
from inventory.models import Lote, DescarteProducto, MovimientoInventario, Producto
from users.models import Usuario


class Command(BaseCommand):
    help = 'Descarta automáticamente todos los lotes vencidos'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Simula el descarte sin ejecutarlo',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        # Obtener usuario admin para auditoría
        admin_user = Usuario.objects.filter(rol__nombre='Administrador').first()
        
        if not admin_user:
            self.stdout.write(self.style.ERROR('No se encontró usuario administrador'))
            return
        
        # Buscar lotes vencidos con stock (incluye los ya marcados como vencidos)
        lotes_vencidos = Lote.objects.filter(
            fecha_caducidad__lt=date.today(),
            cantidad_disponible__gt=0
        ).exclude(
            estado='descartado'
        ).select_related('producto')
        
        total_lotes = lotes_vencidos.count()
        
        if total_lotes == 0:
            self.stdout.write(self.style.SUCCESS('✅ No hay lotes vencidos para descartar'))
            return
        
        self.stdout.write(f'\n📦 Encontrados {total_lotes} lotes vencidos:\n')
        
        total_unidades = 0
        total_costo = 0
        
        for lote in lotes_vencidos:
            dias_vencido = (date.today() - lote.fecha_caducidad).days
            costo_lote = lote.cantidad_disponible * lote.costo_unitario_lote
            
            self.stdout.write(
                f'  🔴 {lote.numero_lote:15} | {lote.producto.nombre:30} | '
                f'Cant: {lote.cantidad_disponible:3} | Vencido hace {dias_vencido:3} días | '
                f'Costo: ${costo_lote:,.0f}'
            )
            
            total_unidades += lote.cantidad_disponible
            total_costo += costo_lote
            
            if not dry_run:
                # Crear registro de descarte
                descarte = DescarteProducto.objects.create(
                    producto=lote.producto,
                    lote=lote,
                    cantidad=lote.cantidad_disponible,
                    motivo='vencido',
                    descripcion=f'Descarte automático - Vencido hace {dias_vencido} días',
                    costo_unitario=lote.costo_unitario_lote,
                    costo_total=costo_lote,
                    usuario_ejecuta=admin_user,
                    usuario_autoriza=admin_user,
                    estado='ejecutado'
                )
                
                # Crear movimiento de inventario
                MovimientoInventario.objects.create(
                    producto=lote.producto,
                    lote=lote,
                    cantidad=-lote.cantidad_disponible,
                    costo_unitario=lote.costo_unitario_lote,
                    tipo_movimiento='DESCARTE',
                    descripcion=f'Descarte automático lote vencido - {lote.numero_lote}',
                    usuario=admin_user
                )
                
                # Actualizar usando SQL directo para evitar triggers
                from django.db import connection
                with connection.cursor() as cursor:
                    # Primero ajustar el stock del producto si está desincronizado
                    producto = lote.producto
                    if producto.stock_actual < lote.cantidad_disponible:
                        self.stdout.write(
                            self.style.WARNING(
                                f'  ⚠️  Stock desincronizado en {producto.nombre}: '
                                f'Sistema={producto.stock_actual}, Lote={lote.cantidad_disponible}. Ajustando...'
                            )
                        )
                        cursor.execute(
                            "UPDATE producto SET stock_actual = %s WHERE id = %s",
                            [lote.cantidad_disponible, producto.id]
                        )
                    
                    # Ahora actualizar el lote (el trigger restará correctamente)
                    cursor.execute(
                        "UPDATE lote SET cantidad_disponible = 0, estado = 'descartado' WHERE id = %s",
                        [lote.id]
                    )
        
        self.stdout.write(f'\n📊 RESUMEN:')
        self.stdout.write(f'  Total lotes: {total_lotes}')
        self.stdout.write(f'  Total unidades: {total_unidades}')
        self.stdout.write(f'  Costo total: ${total_costo:,.0f}')
        
        if dry_run:
            self.stdout.write(self.style.WARNING('\n⚠️  DRY RUN - No se ejecutaron cambios'))
        else:
            self.stdout.write(self.style.SUCCESS(f'\n✅ {total_lotes} lotes descartados exitosamente'))
