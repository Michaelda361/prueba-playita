"""
Script para corregir movimientos de inventario faltantes en ventas antiguas
ADVERTENCIA: Este script creará movimientos de inventario para ventas que no los tienen.
"""
import os
import django
from django.db import transaction

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'la_playita_project.settings')
django.setup()

from inventory.models import MovimientoInventario
from pos.models import Venta, VentaDetalle

def corregir_movimientos_ventas():
    print("=" * 80)
    print("CORRECCIÓN DE MOVIMIENTOS DE INVENTARIO PARA VENTAS ANTIGUAS")
    print("=" * 80)
    
    # Obtener todas las ventas
    ventas = Venta.objects.all().order_by('fecha_venta')
    total_ventas = ventas.count()
    
    print(f"\n📊 Total de ventas a verificar: {total_ventas}")
    
    # Verificar cuáles ventas no tienen movimientos
    ventas_sin_movimiento = []
    
    for venta in ventas:
        # Verificar si esta venta tiene movimientos registrados
        tiene_movimientos = MovimientoInventario.objects.filter(venta=venta).exists()
        
        if not tiene_movimientos:
            ventas_sin_movimiento.append(venta)
    
    print(f"❌ Ventas sin movimientos: {len(ventas_sin_movimiento)}")
    
    if not ventas_sin_movimiento:
        print("\n✅ Todas las ventas tienen movimientos registrados. No hay nada que corregir.")
        return
    
    # Preguntar confirmación
    print("\n⚠️  ADVERTENCIA: Este script creará movimientos de inventario para las ventas sin registro.")
    print("   Esto NO afectará el stock actual (ya fue descontado), solo registra el movimiento histórico.")
    
    respuesta = input("\n¿Desea continuar? (si/no): ").strip().lower()
    
    if respuesta not in ['si', 's', 'yes', 'y']:
        print("\n❌ Operación cancelada por el usuario.")
        return
    
    # Procesar ventas sin movimientos
    movimientos_creados = 0
    errores = []
    
    with transaction.atomic():
        for venta in ventas_sin_movimiento:
            try:
                # Obtener detalles de la venta
                detalles = VentaDetalle.objects.filter(venta=venta).select_related('producto', 'lote')
                
                for detalle in detalles:
                    # Crear movimiento de inventario
                    MovimientoInventario.objects.create(
                        producto=detalle.producto,
                        lote=detalle.lote,
                        cantidad=-detalle.cantidad,  # Negativo porque es salida
                        tipo_movimiento='salida',
                        descripcion=f'Venta #{venta.id} - {detalle.producto.nombre} (Corrección histórica)',
                        venta=venta,
                        fecha_movimiento=venta.fecha_venta  # Usar la fecha original de la venta
                    )
                    movimientos_creados += 1
                
                print(f"✅ Venta #{venta.id} - {detalles.count()} movimientos creados")
                
            except Exception as e:
                error_msg = f"Error en Venta #{venta.id}: {str(e)}"
                errores.append(error_msg)
                print(f"❌ {error_msg}")
    
    # Resumen
    print("\n" + "=" * 80)
    print("RESUMEN DE LA CORRECCIÓN")
    print("=" * 80)
    print(f"\n✅ Movimientos creados: {movimientos_creados}")
    print(f"❌ Errores encontrados: {len(errores)}")
    
    if errores:
        print("\nDetalles de errores:")
        for error in errores:
            print(f"  - {error}")
    
    print("\n" + "=" * 80)
    print("CORRECCIÓN COMPLETADA")
    print("=" * 80)
    print("\nPuede ejecutar 'python verificar_movimientos.py' para verificar los cambios.")

if __name__ == "__main__":
    corregir_movimientos_ventas()
