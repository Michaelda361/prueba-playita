"""
Script para monitorear que las ventas nuevas registren movimientos correctamente
Ejecutar periódicamente para detectar problemas temprano
"""
import os
import django
from datetime import datetime, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'la_playita_project.settings')
django.setup()

from inventory.models import MovimientoInventario
from pos.models import Venta

def monitorear_ventas_recientes(dias=7):
    """
    Monitorea las ventas de los últimos N días para verificar que tengan movimientos
    
    Args:
        dias: Número de días hacia atrás a verificar (default: 7)
    """
    print("=" * 80)
    print(f"MONITOREO DE VENTAS RECIENTES ({dias} días)")
    print("=" * 80)
    
    # Calcular fecha límite
    fecha_limite = datetime.now() - timedelta(days=dias)
    
    # Obtener ventas recientes
    ventas_recientes = Venta.objects.filter(
        fecha_venta__gte=fecha_limite
    ).order_by('-fecha_venta')
    
    total_ventas = ventas_recientes.count()
    
    if total_ventas == 0:
        print(f"\n✅ No hay ventas en los últimos {dias} días.")
        return
    
    print(f"\n📊 Ventas encontradas: {total_ventas}")
    print(f"📅 Desde: {fecha_limite.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"📅 Hasta: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Verificar cada venta
    ventas_sin_movimiento = []
    ventas_ok = []
    
    for venta in ventas_recientes:
        tiene_movimientos = MovimientoInventario.objects.filter(venta=venta).exists()
        
        if tiene_movimientos:
            ventas_ok.append(venta)
        else:
            ventas_sin_movimiento.append(venta)
    
    # Mostrar resultados
    print("\n" + "=" * 80)
    print("RESULTADOS")
    print("=" * 80)
    
    print(f"\n✅ Ventas con movimientos: {len(ventas_ok)} ({len(ventas_ok)/total_ventas*100:.1f}%)")
    print(f"❌ Ventas sin movimientos: {len(ventas_sin_movimiento)} ({len(ventas_sin_movimiento)/total_ventas*100:.1f}%)")
    
    if ventas_sin_movimiento:
        print("\n⚠️  ALERTA: Ventas sin movimientos detectadas:")
        print("-" * 80)
        for venta in ventas_sin_movimiento:
            print(f"\n❌ Venta #{venta.id}")
            print(f"   Fecha: {venta.fecha_venta.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"   Cliente: {venta.cliente.nombres} {venta.cliente.apellidos}")
            print(f"   Total: ${venta.total_venta}")
            print(f"   Usuario: {venta.usuario.get_full_name()}")
        
        print("\n" + "=" * 80)
        print("⚠️  ACCIÓN REQUERIDA:")
        print("=" * 80)
        print("1. Investigar por qué estas ventas no tienen movimientos")
        print("2. Verificar que el código de procesar_venta esté correcto")
        print("3. Ejecutar script de corrección si es necesario:")
        print("   python la_playita_project/corregir_movimientos_auto.py")
    else:
        print("\n" + "=" * 80)
        print("✅ TODAS LAS VENTAS RECIENTES TIENEN MOVIMIENTOS")
        print("=" * 80)
        print("El sistema está funcionando correctamente.")
    
    # Mostrar últimas 5 ventas con detalles
    print("\n" + "=" * 80)
    print("ÚLTIMAS 5 VENTAS")
    print("=" * 80)
    
    for venta in ventas_recientes[:5]:
        movimientos = MovimientoInventario.objects.filter(venta=venta)
        status = "✅" if movimientos.exists() else "❌"
        
        print(f"\n{status} Venta #{venta.id} - {venta.fecha_venta.strftime('%Y-%m-%d %H:%M')}")
        print(f"   Cliente: {venta.cliente.nombres} {venta.cliente.apellidos}")
        print(f"   Total: ${venta.total_venta}")
        print(f"   Movimientos: {movimientos.count()}")
        
        if movimientos.exists():
            for mov in movimientos:
                print(f"      • {mov.producto.nombre}: {mov.cantidad} unidades")
    
    print("\n" + "=" * 80)
    print("MONITOREO COMPLETADO")
    print("=" * 80)

if __name__ == "__main__":
    import sys
    
    # Permitir especificar días como argumento
    dias = 7
    if len(sys.argv) > 1:
        try:
            dias = int(sys.argv[1])
        except ValueError:
            print("⚠️  Argumento inválido. Usando 7 días por defecto.")
    
    monitorear_ventas_recientes(dias)
