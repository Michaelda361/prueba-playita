"""
Comando para inicializar ubicaciones físicas de ejemplo
"""
from django.core.management.base import BaseCommand
from inventory.models import UbicacionFisica


class Command(BaseCommand):
    help = 'Inicializa ubicaciones físicas de ejemplo'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🚀 Inicializando ubicaciones físicas...'))
        
        # Verificar si ya existen ubicaciones
        if UbicacionFisica.objects.exists():
            self.stdout.write(self.style.WARNING('⚠️  Ya existen ubicaciones. Saltando...'))
            return
        
        # Crear bodega principal
        bodega_a = UbicacionFisica.objects.create(
            codigo='BOD-A',
            nombre='Bodega Principal A',
            tipo='bodega',
            capacidad_maxima=10000,
            activo=True
        )
        self.stdout.write('✅ Bodega Principal A creada')
        
        # Crear pasillos
        pasillo_1 = UbicacionFisica.objects.create(
            codigo='BOD-A-PAS-1',
            nombre='Pasillo 1',
            tipo='pasillo',
            parent=bodega_a,
            capacidad_maxima=2000,
            activo=True
        )
        
        # Crear estantes en pasillo 1
        for i in range(1, 4):
            UbicacionFisica.objects.create(
                codigo=f'BOD-A-PAS-1-EST-{i}',
                nombre=f'Estante {i}',
                tipo='estante',
                parent=pasillo_1,
                capacidad_maxima=500,
                activo=True
            )
        
        self.stdout.write('✅ Pasillo 1 con 3 estantes creado')
        
        # Crear bodega refrigerada
        bodega_b = UbicacionFisica.objects.create(
            codigo='BOD-B',
            nombre='Bodega Refrigerada B',
            tipo='bodega',
            capacidad_maxima=5000,
            temperatura_min=2.0,
            temperatura_max=8.0,
            requiere_refrigeracion=True,
            activo=True
        )
        self.stdout.write('✅ Bodega Refrigerada B creada')
        
        # Crear zona refrigerada
        UbicacionFisica.objects.create(
            codigo='BOD-B-ZONA-1',
            nombre='Zona Refrigerada 1',
            tipo='zona',
            parent=bodega_b,
            capacidad_maxima=2000,
            temperatura_min=2.0,
            temperatura_max=8.0,
            requiere_refrigeracion=True,
            activo=True
        )
        self.stdout.write('✅ Zona Refrigerada 1 creada')
        
        total = UbicacionFisica.objects.count()
        self.stdout.write(self.style.SUCCESS(f'\n🎉 {total} ubicaciones físicas creadas exitosamente!'))
