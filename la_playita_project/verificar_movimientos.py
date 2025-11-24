"""
Script para verificar que los movimientos de inventario se registren correctamente
"""
import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'la_playita_project.settings')
django.setup()

from inventory.models import MovimientoInventario, Producto
from pos.models import Venta, VentaDetalle

def verificar_movimientos():
    print("=" * 80)
    print("VERIFICACIÓN DE MOVIMIENTOS DE INVENTARIO")
    print("=" * 80)
    
    # 1. Verificar total de movimientos
    total_movimientos = MovimientoInventario.objects.count()
    print(f"\n📊 Total de movimientos registrados: {total_movimientos}")
    
    # 2. Movimientos por tipo
    entradas = MovimientoInventario.objects.filter(tipo_movimiento='entrada').count()
    salidas = MovimientoInventario.objects.filter(tipo_movimiento='salida').count()
    print(f"\n📈 Movimientos de ENTRADA: {entradas}")
    print(f"📉 Movimientos de SALIDA: {salidas}")
    
    # 3. Verificar ventas sin movimientos
    total_ventas = Venta.objects.count()
    ventas_con_movimiento = MovimientoInventario.objects.filter(venta__isnull=False).values('venta').distinct().count()
    ventas_sin_movimiento = total_ventas - ventas_con_movimiento
    
    print(f"\n🛒 Total de ventas: {total_ventas}")
    print(f"✅ Ventas con movimiento registrado: {ventas_con_movimiento}")
    print(f"❌ Ventas SIN movimiento registrado: {ventas_sin_movimiento}")
    
    if ventas_sin_movimiento > 0:
        print("\n⚠️  ADVERTENCIA: Hay ventas sin movimientos de inventario registrados")
        print("    Esto puede indicar ventas antiguas antes de la corrección.")
    
    # 4. Últimos 10 movimientos
    print("\n" + "=" * 80)
    print("ÚLTIMOS 10 MOVIMIENTOS DE INVENTARIO")
    print("=" * 80)
    
    movimientos = MovimientoInventario.objects.select_related(
        'producto', 'lote', 'venta', 'reabastecimiento'
    ).order_by('-fecha_movimiento')[:10]
    
    for mov in movimientos:
        tipo_icon = "📈" if mov.tipo_movimiento == 'entrada' else "📉"
        referencia = ""
        if mov.venta:
            referencia = f"Venta #{mov.venta.id}"
        elif mov.reabastecimiento:
            referencia = f"Reabastecimiento #{mov.reabastecimiento.id}"
        else:
            referencia = "Sin referencia"
        
        print(f"\n{tipo_icon} {mov.tipo_movimiento.upper()}")
        print(f"   Producto: {mov.producto.nombre}")
        print(f"   Cantidad: {mov.cantidad}")
        print(f"   Lote: {mov.lote.numero_lote if mov.lote else 'N/A'}")
        print(f"   Fecha: {mov.fecha_movimiento.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"   Referencia: {referencia}")
        print(f"   Descripción: {mov.descripcion}")
    
    # 5. Verificar consistencia de stock
    print("\n" + "=" * 80)
    print("VERIFICACIÓN DE CONSISTENCIA DE STOCK")
    print("=" * 80)
    
    productos_inconsistentes = []
    productos = Producto.objects.all()[:10]  # Verificar primeros 10 productos
    
    for producto in productos:
        # Calcular stock desde movimientos
        movimientos_producto = MovimientoInventario.objects.filter(producto=producto)
        stock_calculado = sum(mov.cantidad for mov in movimientos_producto)
        
        # Comparar con stock actual
        diferencia = producto.stock_actual - stock_calculado
        
        if abs(diferencia) > 0.01:  # Tolerancia para decimales
            productos_inconsistentes.append({
                'producto': producto.nombre,
                'stock_actual': producto.stock_actual,
                'stock_calculado': stock_calculado,
                'diferencia': diferencia
            })
    
    if productos_inconsistentes:
        print("\n⚠️  PRODUCTOS CON INCONSISTENCIAS:")
        for p in productos_inconsistentes:
            print(f"\n   Producto: {p['producto']}")
            print(f"   Stock en BD: {p['stock_actual']}")
            print(f"   Stock calculado: {p['stock_calculado']}")
            print(f"   Diferencia: {p['diferencia']}")
    else:
        print("\n✅ Los primeros 10 productos tienen stock consistente")
    
    print("\n" + "=" * 80)
    print("VERIFICACIÓN COMPLETADA")
    print("=" * 80)

if __name__ == "__main__":
    verificar_movimientos()
