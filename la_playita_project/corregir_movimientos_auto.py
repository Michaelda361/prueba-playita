"""
Script automático para corregir movimientos de inventario faltantes en ventas antiguas
"""
import os
import django
from django.db import transaction

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'la_playita_project.settings')
django.setup()

from inventory.models import MovimientoInventario
from pos.models import Venta, VentaDetalle

def corregir_movimientos_ventas_auto():
    print("=" * 80)
    print("CORRECCIÓN AUTOMÁTICA DE MOVIMIENTOS DE INVENTARIO")
    print("=" * 80)
    
    # Obtener todas las ventas
    ventas = Venta.objects.all().order_by('fecha_venta')
    total_ventas = ventas.count()
    
    print(f"\n📊 Total de ventas a verificar: {total_ventas}")
    
    # Verificar cuáles ventas no tienen movimientos
    ventas_sin_movimiento = []
    
    for venta in ventas:
        tiene_movimientos = MovimientoInventario.objects.filter(venta=venta).exists()
        if not tiene_movimientos:
            ventas_sin_movimiento.append(venta)
    
    print(f"❌ Ventas sin movimientos: {len(ventas_sin_movimiento)}")
    
    if not ventas_sin_movimiento:
        print("\n✅ Todas las ventas tienen movimientos registrados.")
        return
    
    # Procesar ventas sin movimientos
    movimientos_creados = 0
    errores = []
    
    print("\n🔄 Procesando ventas...")
    
    with transaction.atomic():
        for venta in ventas_sin_movimiento:
            try:
                detalles = VentaDetalle.objects.filter(venta=venta).select_related('producto', 'lote')
                
                for detalle in detalles:
                    MovimientoInventario.objects.create(
                        producto=detalle.producto,
                        lote=detalle.lote,
                        cantidad=-detalle.cantidad,
                        tipo_movimiento='salida',
                        descripcion=f'Venta #{venta.id} - {detalle.producto.nombre} (Corrección histórica)',
                        venta=venta,
                        fecha_movimiento=venta.fecha_venta
                    )
                    movimientos_creados += 1
                
                print(f"✅ Venta #{venta.id} ({venta.fecha_venta.strftime('%Y-%m-%d')}) - {detalles.count()} movimientos")
                
            except Exception as e:
                error_msg = f"Error en Venta #{venta.id}: {str(e)}"
                errores.append(error_msg)
                print(f"❌ {error_msg}")
    
    # Resumen
    print("\n" + "=" * 80)
    print("RESUMEN")
    print("=" * 80)
    print(f"\n✅ Movimientos creados: {movimientos_creados}")
    print(f"✅ Ventas corregidas: {len(ventas_sin_movimiento) - len(errores)}")
    print(f"❌ Errores: {len(errores)}")
    
    if errores:
        print("\nErrores:")
        for error in errores:
            print(f"  - {error}")
    
    print("\n" + "=" * 80)
    print("✅ CORRECCIÓN COMPLETADA")
    print("=" * 80)

if __name__ == "__main__":
    corregir_movimientos_ventas_auto()
