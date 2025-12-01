# Actualización de Stock en Tiempo Real - POS

## ✅ Funcionalidad Implementada

### Stock Visual Dinámico
El stock mostrado en las tarjetas de productos ahora se actualiza en tiempo real según las unidades agregadas o quitadas del carrito de compras.

## 🎯 Características

### 1. Cálculo Automático
**Fórmula**: `Stock Disponible = Stock Real - Cantidad en Carrito`

- El sistema mantiene el stock real en un atributo `data-stock-real`
- Calcula automáticamente el stock disponible
- Muestra ambos valores cuando hay productos en el carrito

### 2. Actualización en Tiempo Real

**Se actualiza cuando:**
- ✅ Se agrega un producto al carrito
- ✅ Se quita un producto del carrito
- ✅ Se cambia la cantidad de un producto en el carrito
- ✅ Se vacía el carrito completo
- ✅ Se carga la página (recupera carrito del localStorage)

### 3. Indicadores Visuales

#### Badge de Stock
**Sin productos en carrito:**
```
Stock: 50
Color: Azul (info) o Amarillo (warning si ≤10)
```

**Con productos en carrito:**
```
Stock: 45 (5 en carrito)
Color: Amarillo (warning)
```

#### Botón de Agregar
**Stock disponible:**
- Botón habilitado
- Icono: `+` (plus-circle)
- Color: Azul (primary)

**Sin stock disponible:**
- Botón deshabilitado
- Icono: `x` (x-circle)
- Texto: "Sin stock"
- Color: Gris (disabled)

### 4. Soporte Multi-Lote
- Suma cantidades de todos los lotes del mismo producto
- Actualiza correctamente aunque haya múltiples lotes en el carrito
- Mantiene la integridad del stock por producto

## 🔧 Funciones Implementadas

### `actualizarStockVisual(productoId)`
Actualiza el stock visual de un producto específico:
1. Busca todos los items del producto en el carrito
2. Suma las cantidades totales
3. Calcula stock disponible
4. Actualiza el badge con la información
5. Habilita/deshabilita el botón según disponibilidad

### `actualizarTodosLosStocksVisuales()`
Actualiza todos los productos que están en el carrito:
- Se ejecuta al cargar la página
- Recupera el carrito del localStorage
- Actualiza cada producto único

### Modificaciones en Métodos Existentes
- `agregarAlCarrito()`: Llama a `actualizarStockVisual()`
- `removerDelCarrito()`: Llama a `actualizarStockVisual()`
- `actualizarCantidadCarrito()`: Llama a `actualizarStockVisual()`
- `vaciarCarrito()`: Actualiza todos los productos que estaban en el carrito
- `inicializar()`: Llama a `actualizarTodosLosStocksVisuales()`

## 📊 Ejemplo de Uso

### Escenario 1: Agregar Producto
```
Estado inicial:
- Stock real: 100 unidades
- En carrito: 0 unidades
- Mostrado: "Stock: 100"

Usuario agrega 5 unidades:
- Stock real: 100 unidades (no cambia en BD)
- En carrito: 5 unidades
- Mostrado: "Stock: 95 (5 en carrito)"
```

### Escenario 2: Múltiples Lotes
```
Producto X tiene 2 lotes:
- Lote A: 30 unidades en carrito
- Lote B: 20 unidades en carrito
- Total en carrito: 50 unidades

Stock real: 200
Mostrado: "Stock: 150 (50 en carrito)"
```

### Escenario 3: Stock Agotado
```
Stock real: 10 unidades
Usuario agrega 10 al carrito:
- Mostrado: "Stock: 0 (10 en carrito)"
- Botón: Deshabilitado "Sin stock"
```

## 🎨 Estilos Aplicados

### Colores del Badge
- **bg-info** (azul): Stock normal (>10 unidades disponibles)
- **bg-warning text-dark** (amarillo): Stock bajo (≤10) o productos en carrito
- **bg-success** (verde): No usado actualmente

### Estados del Botón
- **btn-primary**: Habilitado, stock disponible
- **disabled**: Sin stock disponible

## 💾 Persistencia

### LocalStorage
- El carrito se guarda en `localStorage` con clave `carrito_pos`
- Al recargar la página, se recupera el carrito
- Los stocks visuales se actualizan automáticamente

### Datos Guardados
```javascript
{
  producto_id: 123,
  nombre: "Producto X",
  precio: 10000,
  cantidad: 5,
  lote_id: 456,
  max_stock: 100
}
```

## 🔄 Flujo Completo

1. **Carga de Página**
   - Se recupera carrito del localStorage
   - Se actualizan todos los stocks visuales

2. **Agregar Producto**
   - Se agrega al carrito
   - Se actualiza stock visual del producto
   - Badge muestra stock disponible

3. **Modificar Cantidad**
   - Se actualiza cantidad en carrito
   - Se recalcula stock disponible
   - Badge se actualiza en tiempo real

4. **Quitar Producto**
   - Se elimina del carrito
   - Stock visual vuelve al valor real
   - Botón se habilita nuevamente

5. **Vaciar Carrito**
   - Se limpian todos los items
   - Todos los stocks vuelven a valores reales
   - Todos los botones se habilitan

## 📝 Notas Técnicas

- No modifica el stock real en la base de datos
- Solo afecta la visualización en el frontend
- El stock real se valida en el backend al procesar la venta
- Usa `data-stock-real` para mantener el valor original
- Compatible con búsqueda de productos (mantiene el estado)

## 🚀 Beneficios

- ✅ Usuario ve stock disponible en tiempo real
- ✅ Previene agregar más productos de los disponibles
- ✅ Mejora la experiencia de usuario
- ✅ Reduce errores al procesar ventas
- ✅ Feedback visual inmediato
- ✅ No requiere recargar la página

## 🔧 Archivo Modificado

- `la_playita_project/pos/static/pos/js/carrito.js`
  - Nuevas funciones: `actualizarStockVisual()`, `actualizarTodosLosStocksVisuales()`
  - Modificaciones en: `agregarAlCarrito()`, `removerDelCarrito()`, `actualizarCantidadCarrito()`, `vaciarCarrito()`, `inicializar()`
