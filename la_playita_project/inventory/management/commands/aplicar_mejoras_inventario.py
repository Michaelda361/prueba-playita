"""
Comando para aplicar mejoras al sistema de inventario
"""
from django.core.management.base import BaseCommand
from django.db import connection
import os


class Command(BaseCommand):
    help = 'Aplica las mejoras al sistema de inventario (tablas, campos, vistas)'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🚀 Iniciando aplicación de mejoras al inventario...'))
        
        # Ruta al archivo SQL
        sql_file = os.path.join('database', '05_tablas_inventario_avanzado.sql')
        
        if not os.path.exists(sql_file):
            self.stdout.write(self.style.ERROR(f'❌ No se encontró el archivo: {sql_file}'))
            return
        
        # Leer el archivo SQL
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # Dividir en statements individuales
        statements = [s.strip() for s in sql_content.split(';') if s.strip() and not s.strip().startswith('--')]
        
        total = len(statements)
        success = 0
        errors = 0
        
        with connection.cursor() as cursor:
            for i, statement in enumerate(statements, 1):
                # Saltar comentarios y líneas vacías
                if not statement or statement.startswith('--') or statement.startswith('/*'):
                    continue
                
                try:
                    cursor.execute(statement)
                    success += 1
                    self.stdout.write(f'✅ [{i}/{total}] Ejecutado correctamente')
                except Exception as e:
                    errors += 1
                    # Algunos errores son esperados (como tablas que ya existen)
                    if 'already exists' in str(e).lower() or 'duplicate' in str(e).lower():
                        self.stdout.write(self.style.WARNING(f'⚠️  [{i}/{total}] Ya existe: {str(e)[:100]}'))
                    else:
                        self.stdout.write(self.style.ERROR(f'❌ [{i}/{total}] Error: {str(e)[:200]}'))
        
        self.stdout.write(self.style.SUCCESS(f'\n✨ Proceso completado:'))
        self.stdout.write(self.style.SUCCESS(f'   ✅ Exitosos: {success}'))
        if errors > 0:
            self.stdout.write(self.style.WARNING(f'   ⚠️  Errores/Advertencias: {errors}'))
        
        self.stdout.write(self.style.SUCCESS('\n🎉 Sistema de inventario mejorado exitosamente!'))
        self.stdout.write(self.style.SUCCESS('\nNuevas funcionalidades disponibles:'))
        self.stdout.write('   📍 Ubicaciones físicas en bodega')
        self.stdout.write('   🔒 Reservas de inventario')
        self.stdout.write('   📋 Conteos físicos')
        self.stdout.write('   🔄 Transferencias entre ubicaciones')
        self.stdout.write('   📊 Análisis de rotación')
        self.stdout.write('   💰 Historial de costos')
        self.stdout.write('   📉 Merma esperada por categoría')
