"""
Comando para asignar ubicaciones a productos existentes
"""
from django.core.management.base import BaseCommand
from inventory.models import Producto, UbicacionFisica, Categoria


class Command(BaseCommand):
    help = 'Asigna ubicaciones físicas a productos existentes'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🚀 Asignando ubicaciones a productos...'))
        
        # Obtener ubicaciones disponibles
        estantes = UbicacionFisica.objects.filter(tipo='estante', activo=True)
        zona_refrigerada = UbicacionFisica.objects.filter(
            codigo='BOD-B-ZONA-1'
        ).first()
        
        if not estantes.exists():
            self.stdout.write(self.style.ERROR('❌ No hay estantes disponibles. Ejecuta primero: inicializar_ubicaciones'))
            return
        
        # Categorías que requieren refrigeración
        categorias_refrigeradas = ['Lacteos', 'Quesos']
        
        productos_actualizados = 0
        
        for producto in Producto.objects.filter(ubicacion_fisica__isnull=True):
            # Determinar ubicación según categoría
            if producto.categoria.nombre in categorias_refrigeradas and zona_refrigerada:
                producto.ubicacion_fisica = zona_refrigerada
                ubicacion_nombre = zona_refrigerada.nombre
            else:
                # Asignar a estantes de forma rotativa
                estante = estantes[productos_actualizados % estantes.count()]
                producto.ubicacion_fisica = estante
                ubicacion_nombre = estante.nombre
            
            producto.save()
            productos_actualizados += 1
            self.stdout.write(f'✅ {producto.nombre} → {ubicacion_nombre}')
        
        self.stdout.write(self.style.SUCCESS(f'\n🎉 {productos_actualizados} productos actualizados!'))
