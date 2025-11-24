# 📘 GUÍA: SISTEMA DE MOVIMIENTOS DE INVENTARIO

## 🎯 Propósito

Esta guía explica cómo funciona el sistema de movimientos de inventario y cómo mantenerlo funcionando correctamente.

---

## 📋 ¿Qué son los Movimientos de Inventario?

Los **movimientos de inventario** son registros que documentan cada entrada o salida de productos en el sistema. Cada movimiento incluye:

- **Producto:** Qué producto se movió
- **Lote:** De qué lote específico
- **Cantidad:** Cuántas unidades (positivo=entrada, negativo=salida)
- **Tipo:** 'entrada' o 'salida'
- **Fecha:** Cuándo ocurrió
- **Referencia:** Venta o reabastecimiento asociado
- **Descripción:** Detalles del movimiento

---

## 🔄 Tipos de Movimientos

### 1. Entradas (cantidad positiva)
- **Reabastecimientos:** Cuando se recibe mercancía de proveedores
- **Ajustes:** Correcciones manuales de inventario
- **Devoluciones:** Productos devueltos por clientes (futuro)

### 2. Salidas (cantidad negativa)
- **Ventas:** Cuando se vende un producto
- **Mermas:** Productos dañados o vencidos (futuro)
- **Ajustes:** Correcciones manuales de inventario

---

## ✅ Funcionamiento Automático

### Ventas (POS)
Cuando se procesa una venta en el POS:

1. Se crea el registro de `Venta`
2. Se crean los `VentaDetalle` para cada producto
3. **Se crea automáticamente un `MovimientoInventario` por cada producto**
4. Se actualiza el stock del lote
5. Se registra el pago

**Código responsable:** `la_playita_project/pos/views.py` función `procesar_venta()`

### Reabastecimientos
Cuando se marca un reabastecimiento como "recibido":

1. Se crea el `Lote` con la mercancía recibida
2. **Se crea automáticamente un `MovimientoInventario`**
3. Se actualiza el stock del producto

**Código responsable:** `la_playita_project/suppliers/views.py` función `reabastecimiento_recibir()`

---

## 🛠️ Scripts de Mantenimiento

### 1. Verificar Estado del Sistema

**Script:** `verificar_movimientos.py`

**Qué hace:**
- Cuenta total de movimientos
- Muestra entradas vs salidas
- Identifica ventas sin movimientos
- Verifica consistencia de stock
- Muestra últimos 10 movimientos

**Uso:**
```bash
cd la_playita_project
python verificar_movimientos.py
```

**Cuándo ejecutar:**
- Semanalmente como rutina
- Después de corregir problemas
- Antes de generar reportes importantes
- Si se sospecha de inconsistencias

---

### 2. Corregir Ventas Antiguas

**Script:** `corregir_movimientos_auto.py`

**Qué hace:**
- Identifica ventas sin movimientos
- Crea movimientos históricos para ellas
- Usa la fecha original de la venta
- Muestra progreso en tiempo real

**Uso:**
```bash
cd la_playita_project
python corregir_movimientos_auto.py
```

**Cuándo ejecutar:**
- Solo si el script de verificación detecta ventas sin movimientos
- Después de restaurar un backup antiguo
- Una sola vez (no es necesario ejecutar repetidamente)

**⚠️ Importante:**
- Este script NO modifica el stock actual
- Solo registra movimientos históricos
- Es seguro ejecutarlo múltiples veces (detecta duplicados)

---

### 3. Monitorear Ventas Recientes

**Script:** `monitorear_ventas_nuevas.py`

**Qué hace:**
- Verifica ventas de los últimos 7 días (configurable)
- Identifica ventas sin movimientos
- Muestra detalles de las últimas 5 ventas
- Alerta si hay problemas

**Uso:**
```bash
cd la_playita_project
python monitorear_ventas_nuevas.py

# Para verificar más días:
python monitorear_ventas_nuevas.py 30  # últimos 30 días
```

**Cuándo ejecutar:**
- Diariamente como monitoreo preventivo
- Después de actualizaciones del sistema
- Si se reportan problemas con ventas

---

## 🧪 Tests Automatizados

**Archivo:** `pos/test_movimientos.py`

**Tests incluidos:**
1. `test_venta_crea_movimiento_inventario` - Venta simple
2. `test_venta_multiple_productos_crea_multiples_movimientos` - Venta múltiple
3. `test_venta_fallida_no_crea_movimiento` - Integridad transaccional

**Ejecutar tests:**
```bash
cd la_playita_project
python manage.py test pos.test_movimientos -v 2
```

**Cuándo ejecutar:**
- Antes de cada deploy
- Después de modificar código de ventas
- Como parte de CI/CD

---

## 🔍 Consultas Útiles

### Ver movimientos de un producto específico
```python
from inventory.models import MovimientoInventario, Producto

producto = Producto.objects.get(nombre='Cerveza Aguila')
movimientos = MovimientoInventario.objects.filter(producto=producto).order_by('-fecha_movimiento')

for mov in movimientos[:10]:
    print(f"{mov.fecha_movimiento} - {mov.tipo_movimiento}: {mov.cantidad} - {mov.descripcion}")
```

### Ver movimientos de una venta
```python
from pos.models import Venta
from inventory.models import MovimientoInventario

venta = Venta.objects.get(id=40)
movimientos = MovimientoInventario.objects.filter(venta=venta)

for mov in movimientos:
    print(f"{mov.producto.nombre}: {mov.cantidad} unidades")
```

### Calcular stock desde movimientos
```python
from inventory.models import MovimientoInventario, Producto

producto = Producto.objects.get(id=1)
movimientos = MovimientoInventario.objects.filter(producto=producto)
stock_calculado = sum(mov.cantidad for mov in movimientos)

print(f"Stock en BD: {producto.stock_actual}")
print(f"Stock calculado: {stock_calculado}")
print(f"Diferencia: {producto.stock_actual - stock_calculado}")
```

---

## 🚨 Solución de Problemas

### Problema: Ventas sin movimientos

**Síntomas:**
- El script de verificación muestra ventas sin movimientos
- Reportes de inventario inconsistentes

**Solución:**
```bash
# 1. Verificar el problema
python la_playita_project/verificar_movimientos.py

# 2. Corregir ventas antiguas
python la_playita_project/corregir_movimientos_auto.py

# 3. Verificar corrección
python la_playita_project/verificar_movimientos.py
```

---

### Problema: Stock inconsistente

**Síntomas:**
- Stock en BD diferente al calculado desde movimientos
- Productos con stock negativo

**Causas posibles:**
1. Ventas antiguas sin movimientos (usar script de corrección)
2. Ajustes manuales en BD sin registrar movimiento
3. Triggers de MySQL deshabilitados

**Solución:**
```bash
# 1. Verificar inconsistencias
python la_playita_project/verificar_movimientos.py

# 2. Si hay ventas sin movimientos, corregir
python la_playita_project/corregir_movimientos_auto.py

# 3. Si persiste, verificar triggers de MySQL
python manage.py dbshell
SHOW TRIGGERS;
```

---

### Problema: Nueva venta no crea movimiento

**Síntomas:**
- Venta se procesa correctamente
- Pero no aparece en movimientos de inventario

**Diagnóstico:**
```bash
# Monitorear ventas recientes
python la_playita_project/monitorear_ventas_nuevas.py 1  # último día
```

**Solución:**
1. Verificar que el código en `pos/views.py` no fue modificado
2. Revisar logs de Django para errores
3. Ejecutar tests:
   ```bash
   python manage.py test pos.test_movimientos
   ```
4. Si los tests fallan, restaurar código desde backup

---

## 📊 Reportes y Análisis

### Reporte de Movimientos por Período
```python
from inventory.models import MovimientoInventario
from django.db.models import Sum
from datetime import datetime, timedelta

# Últimos 30 días
fecha_inicio = datetime.now() - timedelta(days=30)
movimientos = MovimientoInventario.objects.filter(fecha_movimiento__gte=fecha_inicio)

# Entradas vs Salidas
entradas = movimientos.filter(tipo_movimiento='entrada').aggregate(Sum('cantidad'))
salidas = movimientos.filter(tipo_movimiento='salida').aggregate(Sum('cantidad'))

print(f"Entradas: {entradas['cantidad__sum']}")
print(f"Salidas: {abs(salidas['cantidad__sum'])}")
```

### Productos Más Vendidos
```python
from inventory.models import MovimientoInventario
from django.db.models import Sum, Count

# Top 10 productos más vendidos
top_productos = (MovimientoInventario.objects
    .filter(tipo_movimiento='salida', venta__isnull=False)
    .values('producto__nombre')
    .annotate(total_vendido=Sum('cantidad'))
    .order_by('total_vendido')[:10])

for p in top_productos:
    print(f"{p['producto__nombre']}: {abs(p['total_vendido'])} unidades")
```

---

## 🔐 Mejores Prácticas

### ✅ DO (Hacer)
- Ejecutar script de verificación semanalmente
- Monitorear ventas nuevas diariamente
- Ejecutar tests antes de cada deploy
- Documentar cualquier ajuste manual
- Mantener backups regulares

### ❌ DON'T (No Hacer)
- Modificar movimientos existentes manualmente
- Eliminar movimientos de la BD
- Desactivar los triggers de MySQL
- Modificar stock sin crear movimiento
- Ignorar alertas del script de monitoreo

---

## 📞 Soporte

### Recursos
- **Documentación completa:** `CORRECCION_MOVIMIENTOS_INVENTARIO.md`
- **Resumen ejecutivo:** `RESUMEN_CORRECCION.md`
- **Esta guía:** `GUIA_MOVIMIENTOS_INVENTARIO.md`

### Contacto
Si encuentra problemas no cubiertos en esta guía:
1. Ejecutar todos los scripts de diagnóstico
2. Revisar logs de Django
3. Contactar al equipo de desarrollo con:
   - Salida de `verificar_movimientos.py`
   - Salida de `monitorear_ventas_nuevas.py`
   - Logs de error relevantes

---

**Última actualización:** 23 de Noviembre de 2025  
**Versión:** 1.0  
**Mantenedor:** Equipo de Desarrollo La Playita
