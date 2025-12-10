from django.db import models
from django.utils import timezone
from django.conf import settings


class Categoria(models.Model):
    nombre = models.CharField(max_length=25)
    parent = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='subcategorias')
    descripcion = models.CharField(max_length=255, null=True, blank=True)
    imagen_url = models.CharField(max_length=255, null=True, blank=True)
    color_identificador = models.CharField(max_length=7, null=True, blank=True, help_text="Color hex: #RRGGBB")
    icono = models.CharField(max_length=50, null=True, blank=True, help_text="Nombre del icono")
    orden = models.IntegerField(default=0)
    activo = models.BooleanField(default=True)
    creado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='categorias_creadas')
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nombre

    class Meta:
        db_table = 'categoria'
        managed = False
        ordering = ['orden', 'nombre']


class TasaIVA(models.Model):
    nombre = models.CharField(max_length=50, unique=True)
    porcentaje = models.DecimalField(max_digits=5, decimal_places=2, help_text="Porcentaje de IVA (ej. 19.00 para 19%)")

    def __str__(self):
        return f"{self.nombre} ({self.porcentaje}%)"

    class Meta:
        db_table = 'tasa_iva'
        managed = False


class Producto(models.Model):
    ESTADO_CHOICES = [
        ('activo', 'Activo'),
        ('inactivo', 'Inactivo'),
        ('descontinuado', 'Descontinuado'),
    ]
    
    UNIDAD_MEDIDA_CHOICES = [
        ('unidad', 'Unidad'),
        ('caja', 'Caja'),
        ('paquete', 'Paquete'),
        ('kg', 'Kilogramo'),
        ('litro', 'Litro'),
        ('metro', 'Metro'),
        ('otro', 'Otro'),
    ]
    
    nombre = models.CharField(unique=True, max_length=50)
    codigo_barras = models.CharField(max_length=50, unique=True, null=True, blank=True)
    sku_alternativo = models.CharField(max_length=50, null=True, blank=True)
    precio_unitario = models.DecimalField(max_digits=12, decimal_places=2)
    descripcion = models.CharField(max_length=255, blank=True, null=True)
    imagen_url = models.CharField(max_length=255, null=True, blank=True)
    ubicacion = models.CharField(max_length=50, null=True, blank=True, help_text="Ej: Pasillo A, Estante 3, Nivel 2")
    ubicacion_fisica = models.ForeignKey('UbicacionFisica', on_delete=models.SET_NULL, null=True, blank=True, related_name='productos')
    unidad_medida = models.CharField(max_length=20, choices=UNIDAD_MEDIDA_CHOICES, default='unidad')
    peso = models.DecimalField(max_digits=10, decimal_places=3, null=True, blank=True, help_text="Peso en kg")
    volumen = models.DecimalField(max_digits=10, decimal_places=3, null=True, blank=True, help_text="Volumen en litros")
    stock_minimo = models.PositiveIntegerField(default=10)
    stock_maximo = models.IntegerField(null=True, blank=True)
    categoria = models.ForeignKey(Categoria, on_delete=models.PROTECT, default=1)
    stock_actual = models.PositiveIntegerField(default=0, help_text="Calculado automáticamente a partir de los lotes.")
    dias_sin_movimiento = models.IntegerField(default=0, help_text="Días sin ventas")
    ultima_venta = models.DateTimeField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='activo')
    costo_promedio = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, help_text="Costo promedio ponderado, calculado automáticamente.")
    margen_objetivo = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, help_text="Margen de ganancia objetivo (%)")
    tasa_iva = models.ForeignKey(TasaIVA, on_delete=models.PROTECT, default=1, help_text="Tasa de IVA aplicable al producto.")
    creado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='productos_creados')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    modificado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='productos_modificados')
    fecha_modificacion = models.DateTimeField(auto_now=True, null=True, blank=True)

    def __str__(self):
        return self.nombre
    
    @property
    def estado_stock(self):
        """Retorna el estado del stock basado en umbrales"""
        if self.stock_actual == 0:
            return 'SIN_STOCK'
        elif self.stock_actual < self.stock_minimo:
            return 'STOCK_CRITICO'
        elif self.stock_actual < (self.stock_minimo * 1.5):
            return 'STOCK_BAJO'
        elif self.stock_maximo and self.stock_actual > self.stock_maximo:
            return 'SOBRE_STOCK'
        return 'NORMAL'

    class Meta:
        db_table = 'producto'
        managed = False
        ordering = ['nombre']


class Lote(models.Model):
    ESTADO_CHOICES = [
        ('activo', 'Activo'),
        ('agotado', 'Agotado'),
        ('vencido', 'Vencido'),
        ('descartado', 'Descartado'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='lotes')
    reabastecimiento_detalle = models.ForeignKey('suppliers.ReabastecimientoDetalle', on_delete=models.CASCADE, null=True, blank=True)
    numero_lote = models.CharField(max_length=50)
    cantidad_disponible = models.PositiveIntegerField()
    costo_unitario_lote = models.DecimalField(max_digits=12, decimal_places=2)
    fecha_caducidad = models.DateField()
    fecha_entrada = models.DateTimeField(default=timezone.now)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='activo')
    ubicacion_fisica = models.ForeignKey('UbicacionFisica', on_delete=models.SET_NULL, null=True, blank=True, related_name='lotes')
    temperatura_almacenamiento = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, help_text="Temperatura de almacenamiento (°C)")

    def __str__(self):
        return f"Lote {self.numero_lote} ({self.producto.nombre})"
    
    @property
    def dias_hasta_vencer(self):
        """Calcula días hasta el vencimiento"""
        from datetime import date
        delta = self.fecha_caducidad - date.today()
        return delta.days
    
    @property
    def estado_vencimiento(self):
        """Retorna el estado basado en días hasta vencer"""
        dias = self.dias_hasta_vencer
        if dias < 0:
            return 'VENCIDO'
        elif dias <= 7:
            return 'CRITICO'
        elif dias <= 30:
            return 'PROXIMO'
        return 'NORMAL'

    class Meta:
        db_table = 'lote'
        managed = False
        unique_together = (('producto', 'numero_lote'),)
        ordering = ['fecha_caducidad']


class MovimientoInventario(models.Model):
    TIPO_CHOICES = [
        ('ENTRADA', 'Entrada'),
        ('SALIDA', 'Salida'),
        ('AJUSTE', 'Ajuste'),
        ('DEVOLUCION', 'Devolución'),
        ('DESCARTE', 'Descarte'),
        ('TRANSFERENCIA', 'Transferencia'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.DO_NOTHING, related_name='movimientos')
    lote = models.ForeignKey(Lote, on_delete=models.SET_NULL, blank=True, null=True, related_name='movimientos')
    cantidad = models.IntegerField()
    costo_unitario = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    tipo_movimiento = models.CharField(max_length=20, choices=TIPO_CHOICES)
    fecha_movimiento = models.DateTimeField(default=timezone.now)
    descripcion = models.CharField(max_length=255, blank=True, null=True)
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='movimientos_inventario')
    venta = models.ForeignKey('pos.Venta', on_delete=models.SET_NULL, blank=True, null=True)
    reabastecimiento = models.ForeignKey('suppliers.Reabastecimiento', on_delete=models.SET_NULL, blank=True, null=True)

    def __str__(self):
        return f"{self.tipo_movimiento} - {self.producto.nombre} ({self.cantidad})"

    class Meta:
        db_table = 'movimiento_inventario'
        managed = False
        ordering = ['-fecha_movimiento']



class AjusteInventario(models.Model):
    MOTIVO_CHOICES = [
        ('conteo_fisico', 'Conteo Físico'),
        ('merma', 'Merma'),
        ('robo', 'Robo'),
        ('daño', 'Daño'),
        ('error_sistema', 'Error de Sistema'),
        ('otro', 'Otro'),
    ]
    
    ESTADO_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('aprobado', 'Aprobado'),
        ('rechazado', 'Rechazado'),
        ('aplicado', 'Aplicado'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='ajustes')
    lote = models.ForeignKey(Lote, on_delete=models.SET_NULL, null=True, blank=True, related_name='ajustes')
    cantidad_sistema = models.IntegerField(help_text="Stock según sistema")
    cantidad_fisica = models.IntegerField(help_text="Stock según conteo físico")
    diferencia = models.IntegerField(help_text="cantidad_fisica - cantidad_sistema")
    motivo = models.CharField(max_length=20, choices=MOTIVO_CHOICES)
    descripcion = models.TextField(null=True, blank=True)
    costo_ajuste = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, help_text="Impacto económico")
    usuario_ejecuta = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.RESTRICT, related_name='ajustes_ejecutados')
    usuario_autoriza = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='ajustes_autorizados')
    fecha_ajuste = models.DateTimeField(auto_now_add=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='pendiente')
    observaciones = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"Ajuste #{self.id} - {self.producto.nombre} ({self.diferencia:+d})"
    
    class Meta:
        db_table = 'ajuste_inventario'
        managed = False
        ordering = ['-fecha_ajuste']


class DescarteProducto(models.Model):
    MOTIVO_CHOICES = [
        ('vencido', 'Vencido'),
        ('proximo_vencer', 'Próximo a Vencer'),
        ('dañado', 'Dañado'),
        ('contaminado', 'Contaminado'),
        ('empaque_roto', 'Empaque Roto'),
        ('calidad_baja', 'Calidad Baja'),
        ('otro', 'Otro'),
    ]
    
    ESTADO_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('aprobado', 'Aprobado'),
        ('rechazado', 'Rechazado'),
        ('ejecutado', 'Ejecutado'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='descartes')
    lote = models.ForeignKey(Lote, on_delete=models.SET_NULL, null=True, blank=True, related_name='descartes')
    cantidad = models.IntegerField()
    motivo = models.CharField(max_length=20, choices=MOTIVO_CHOICES)
    descripcion = models.TextField(null=True, blank=True)
    costo_unitario = models.DecimalField(max_digits=12, decimal_places=2)
    costo_total = models.DecimalField(max_digits=12, decimal_places=2)
    usuario_ejecuta = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.RESTRICT, related_name='descartes_ejecutados')
    usuario_autoriza = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='descartes_autorizados')
    fecha_descarte = models.DateTimeField(auto_now_add=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='pendiente')
    evidencia_url = models.CharField(max_length=255, null=True, blank=True, help_text="Foto del producto descartado")
    
    def save(self, *args, **kwargs):
        if not self.costo_total:
            self.costo_total = self.cantidad * self.costo_unitario
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"Descarte #{self.id} - {self.producto.nombre} ({self.cantidad} unidades)"
    
    class Meta:
        db_table = 'descarte_producto'
        managed = False
        ordering = ['-fecha_descarte']


class AlertaInventario(models.Model):
    TIPO_CHOICES = [
        ('stock_bajo', 'Stock Bajo'),
        ('stock_critico', 'Stock Crítico'),
        ('sin_stock', 'Sin Stock'),
        ('sobre_stock', 'Sobre Stock'),
        ('proximo_vencer', 'Próximo a Vencer'),
        ('vencido', 'Vencido'),
        ('rotacion_baja', 'Rotación Baja'),
    ]
    
    PRIORIDAD_CHOICES = [
        ('baja', 'Baja'),
        ('media', 'Media'),
        ('alta', 'Alta'),
        ('critica', 'Crítica'),
    ]
    
    ESTADO_CHOICES = [
        ('activa', 'Activa'),
        ('resuelta', 'Resuelta'),
        ('ignorada', 'Ignorada'),
        ('expirada', 'Expirada'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='alertas')
    lote = models.ForeignKey(Lote, on_delete=models.CASCADE, null=True, blank=True, related_name='alertas')
    tipo_alerta = models.CharField(max_length=20, choices=TIPO_CHOICES)
    prioridad = models.CharField(max_length=10, choices=PRIORIDAD_CHOICES, default='media')
    titulo = models.CharField(max_length=255)
    mensaje = models.TextField()
    valor_actual = models.CharField(max_length=100, null=True, blank=True)
    valor_esperado = models.CharField(max_length=100, null=True, blank=True)
    fecha_generacion = models.DateTimeField(auto_now_add=True)
    fecha_vencimiento = models.DateTimeField(null=True, blank=True, help_text="Cuándo expira la alerta")
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='activa')
    resuelta_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='alertas_resueltas')
    fecha_resolucion = models.DateTimeField(null=True, blank=True)
    notas_resolucion = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.get_prioridad_display()}: {self.titulo}"
    
    class Meta:
        db_table = 'alerta_inventario'
        managed = False
        ordering = ['-fecha_generacion']


class DevolucionProveedor(models.Model):
    MOTIVO_CHOICES = [
        ('producto_defectuoso', 'Producto Defectuoso'),
        ('producto_vencido', 'Producto Vencido'),
        ('cantidad_incorrecta', 'Cantidad Incorrecta'),
        ('producto_incorrecto', 'Producto Incorrecto'),
        ('empaque_dañado', 'Empaque Dañado'),
        ('otro', 'Otro'),
    ]
    
    ESTADO_CHOICES = [
        ('solicitada', 'Solicitada'),
        ('aprobada', 'Aprobada'),
        ('rechazada', 'Rechazada'),
        ('completada', 'Completada'),
    ]
    
    reabastecimiento = models.ForeignKey('suppliers.Reabastecimiento', on_delete=models.CASCADE, related_name='devoluciones')
    proveedor = models.ForeignKey('suppliers.Proveedor', on_delete=models.CASCADE, related_name='devoluciones')
    fecha_devolucion = models.DateTimeField(auto_now_add=True)
    motivo = models.CharField(max_length=30, choices=MOTIVO_CHOICES)
    descripcion = models.TextField(null=True, blank=True)
    costo_total = models.DecimalField(max_digits=12, decimal_places=2)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='solicitada')
    usuario_solicita = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.RESTRICT, related_name='devoluciones_solicitadas')
    fecha_aprobacion = models.DateTimeField(null=True, blank=True)
    usuario_aprueba = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='devoluciones_aprobadas')
    numero_guia = models.CharField(max_length=100, null=True, blank=True, help_text="Número de guía de devolución")
    
    def __str__(self):
        return f"Devolución #{self.id} - {self.proveedor.nombre_empresa}"
    
    class Meta:
        db_table = 'devolucion_proveedor'
        managed = False
        ordering = ['-fecha_devolucion']


class DevolucionProveedorDetalle(models.Model):
    devolucion = models.ForeignKey(DevolucionProveedor, on_delete=models.CASCADE, related_name='detalles')
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    lote = models.ForeignKey(Lote, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad = models.IntegerField()
    costo_unitario = models.DecimalField(max_digits=12, decimal_places=2)
    motivo_especifico = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.producto.nombre} - {self.cantidad} unidades"
    
    class Meta:
        db_table = 'devolucion_proveedor_detalle'
        managed = False


class ValorizacionInventario(models.Model):
    periodo = models.CharField(max_length=7, help_text="Formato: YYYY-MM")
    fecha_corte = models.DateField()
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='valorizaciones')
    cantidad = models.IntegerField()
    costo_unitario = models.DecimalField(max_digits=12, decimal_places=2)
    costo_promedio = models.DecimalField(max_digits=12, decimal_places=2)
    valor_total = models.DecimalField(max_digits=12, decimal_places=2)
    categoria = models.ForeignKey(Categoria, on_delete=models.CASCADE)
    fecha_generacion = models.DateTimeField(auto_now_add=True)
    generado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='valorizaciones_generadas')
    
    def __str__(self):
        return f"Valorización {self.periodo} - {self.producto.nombre}"
    
    class Meta:
        db_table = 'valorizacion_inventario'
        managed = False
        unique_together = (('periodo', 'producto'),)
        ordering = ['-periodo', 'producto__nombre']


class ConfiguracionAlerta(models.Model):
    TIPO_CHOICES = [
        ('stock_bajo', 'Stock Bajo'),
        ('stock_critico', 'Stock Crítico'),
        ('sobre_stock', 'Sobre Stock'),
        ('proximo_vencer', 'Próximo a Vencer'),
        ('rotacion_baja', 'Rotación Baja'),
    ]
    
    tipo_alerta = models.CharField(max_length=20, choices=TIPO_CHOICES, unique=True)
    activo = models.BooleanField(default=True)
    umbral_valor = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text="Valor numérico del umbral")
    umbral_porcentaje = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, help_text="Porcentaje del umbral")
    dias_anticipacion = models.IntegerField(null=True, blank=True, help_text="Días de anticipación para alertas de vencimiento")
    descripcion = models.TextField(null=True, blank=True)
    notificar_email = models.BooleanField(default=False)
    notificar_dashboard = models.BooleanField(default=True)
    usuarios_notificar = models.JSONField(null=True, blank=True, help_text="Array de IDs de usuarios a notificar")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_modificacion = models.DateTimeField(auto_now=True, null=True, blank=True)
    
    def __str__(self):
        return f"Config: {self.get_tipo_alerta_display()}"
    
    class Meta:
        db_table = 'configuracion_alerta'
        managed = False


# ============================================================================
# MODELOS AVANZADOS DE INVENTARIO
# ============================================================================

class UbicacionFisica(models.Model):
    TIPO_CHOICES = [
        ('bodega', 'Bodega'),
        ('pasillo', 'Pasillo'),
        ('estante', 'Estante'),
        ('nivel', 'Nivel'),
        ('zona', 'Zona'),
    ]
    
    codigo = models.CharField(max_length=20, unique=True, help_text="Ej: BOD-A-EST-3-NIV-2")
    nombre = models.CharField(max_length=100)
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES, default='estante')
    parent = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='hijos')
    capacidad_maxima = models.IntegerField(null=True, blank=True, help_text="Capacidad en unidades")
    capacidad_actual = models.IntegerField(default=0, help_text="Ocupación actual")
    temperatura_min = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, help_text="Temperatura mínima (°C)")
    temperatura_max = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True, help_text="Temperatura máxima (°C)")
    requiere_refrigeracion = models.BooleanField(default=False)
    activo = models.BooleanField(default=True)
    observaciones = models.TextField(null=True, blank=True)
    creado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='ubicaciones_creadas')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.codigo} - {self.nombre}"
    
    @property
    def porcentaje_ocupacion(self):
        if self.capacidad_maxima and self.capacidad_maxima > 0:
            return (self.capacidad_actual / self.capacidad_maxima) * 100
        return 0
    
    class Meta:
        db_table = 'ubicacion_fisica'
        managed = False
        ordering = ['codigo']
        verbose_name = 'Ubicación Física'
        verbose_name_plural = 'Ubicaciones Físicas'


class ReservaInventario(models.Model):
    TIPO_CHOICES = [
        ('venta', 'Venta'),
        ('pedido', 'Pedido'),
        ('transferencia', 'Transferencia'),
        ('otro', 'Otro'),
    ]
    
    ESTADO_CHOICES = [
        ('activa', 'Activa'),
        ('liberada', 'Liberada'),
        ('consumida', 'Consumida'),
        ('expirada', 'Expirada'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='reservas')
    lote = models.ForeignKey(Lote, on_delete=models.SET_NULL, null=True, blank=True, related_name='reservas')
    cantidad = models.IntegerField()
    tipo_reserva = models.CharField(max_length=20, choices=TIPO_CHOICES, default='venta')
    referencia_id = models.IntegerField(null=True, blank=True, help_text="ID de venta, pedido, etc.")
    referencia_tipo = models.CharField(max_length=50, null=True, blank=True, help_text="Tipo de referencia")
    fecha_reserva = models.DateTimeField(auto_now_add=True)
    fecha_expiracion = models.DateTimeField(null=True, blank=True, help_text="Cuándo expira la reserva")
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='activa')
    usuario_reserva = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.RESTRICT, related_name='reservas_creadas')
    fecha_liberacion = models.DateTimeField(null=True, blank=True)
    motivo_liberacion = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"Reserva #{self.id} - {self.producto.nombre} ({self.cantidad})"
    
    class Meta:
        db_table = 'reserva_inventario'
        managed = False
        ordering = ['-fecha_reserva']


class ConteoFisico(models.Model):
    TIPO_CHOICES = [
        ('completo', 'Completo'),
        ('parcial', 'Parcial'),
        ('ciclico', 'Cíclico'),
        ('sorpresa', 'Sorpresa'),
    ]
    
    ESTADO_CHOICES = [
        ('programado', 'Programado'),
        ('en_proceso', 'En Proceso'),
        ('completado', 'Completado'),
        ('cancelado', 'Cancelado'),
        ('ajustado', 'Ajustado'),
    ]
    
    numero_conteo = models.CharField(max_length=50, unique=True, help_text="Ej: CF-2025-001")
    tipo_conteo = models.CharField(max_length=20, choices=TIPO_CHOICES, default='ciclico')
    fecha_programada = models.DateField()
    fecha_inicio = models.DateTimeField(null=True, blank=True)
    fecha_finalizacion = models.DateTimeField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='programado')
    ubicacion = models.ForeignKey(UbicacionFisica, on_delete=models.SET_NULL, null=True, blank=True, help_text="Ubicación específica (si es parcial)")
    categoria = models.ForeignKey(Categoria, on_delete=models.SET_NULL, null=True, blank=True, help_text="Categoría específica (si es parcial)")
    responsable = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.RESTRICT, related_name='conteos_responsable')
    supervisor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='conteos_supervisor')
    observaciones = models.TextField(null=True, blank=True)
    total_productos = models.IntegerField(default=0)
    total_diferencias = models.IntegerField(default=0)
    valor_diferencias = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    creado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.RESTRICT, related_name='conteos_creados')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.numero_conteo} - {self.get_tipo_conteo_display()}"
    
    class Meta:
        db_table = 'conteo_fisico'
        managed = False
        ordering = ['-fecha_programada']


class ConteoFisicoDetalle(models.Model):
    ESTADO_CHOICES = [
        ('pendiente', 'Pendiente'),
        ('contado', 'Contado'),
        ('verificado', 'Verificado'),
        ('ajustado', 'Ajustado'),
    ]
    
    conteo = models.ForeignKey(ConteoFisico, on_delete=models.CASCADE, related_name='detalles')
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    lote = models.ForeignKey(Lote, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad_sistema = models.IntegerField(help_text="Stock según sistema")
    cantidad_contada = models.IntegerField(null=True, blank=True, help_text="Stock según conteo físico")
    diferencia = models.IntegerField(null=True, blank=True, help_text="cantidad_contada - cantidad_sistema")
    costo_unitario = models.DecimalField(max_digits=12, decimal_places=2)
    valor_diferencia = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='pendiente')
    observaciones = models.TextField(null=True, blank=True)
    contado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='conteos_realizados')
    fecha_conteo = models.DateTimeField(null=True, blank=True)
    verificado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='conteos_verificados')
    fecha_verificacion = models.DateTimeField(null=True, blank=True)
    
    def save(self, *args, **kwargs):
        if self.cantidad_contada is not None:
            self.diferencia = self.cantidad_contada - self.cantidad_sistema
            self.valor_diferencia = self.diferencia * self.costo_unitario
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.conteo.numero_conteo} - {self.producto.nombre}"
    
    class Meta:
        db_table = 'conteo_fisico_detalle'
        managed = False


class TransferenciaInventario(models.Model):
    ESTADO_CHOICES = [
        ('solicitada', 'Solicitada'),
        ('aprobada', 'Aprobada'),
        ('en_transito', 'En Tránsito'),
        ('recibida', 'Recibida'),
        ('cancelada', 'Cancelada'),
    ]
    
    MOTIVO_CHOICES = [
        ('reubicacion', 'Reubicación'),
        ('reabastecimiento_interno', 'Reabastecimiento Interno'),
        ('optimizacion', 'Optimización'),
        ('otro', 'Otro'),
    ]
    
    numero_transferencia = models.CharField(max_length=50, unique=True, help_text="Ej: TRF-2025-001")
    ubicacion_origen = models.ForeignKey(UbicacionFisica, on_delete=models.RESTRICT, related_name='transferencias_origen')
    ubicacion_destino = models.ForeignKey(UbicacionFisica, on_delete=models.RESTRICT, related_name='transferencias_destino')
    fecha_solicitud = models.DateTimeField(auto_now_add=True)
    fecha_envio = models.DateTimeField(null=True, blank=True)
    fecha_recepcion = models.DateTimeField(null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='solicitada')
    motivo = models.CharField(max_length=30, choices=MOTIVO_CHOICES)
    descripcion = models.TextField(null=True, blank=True)
    usuario_solicita = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.RESTRICT, related_name='transferencias_solicitadas')
    usuario_aprueba = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='transferencias_aprobadas')
    usuario_envia = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='transferencias_enviadas')
    usuario_recibe = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='transferencias_recibidas')
    observaciones = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.numero_transferencia} - {self.ubicacion_origen} → {self.ubicacion_destino}"
    
    class Meta:
        db_table = 'transferencia_inventario'
        managed = False
        ordering = ['-fecha_solicitud']


class TransferenciaInventarioDetalle(models.Model):
    transferencia = models.ForeignKey(TransferenciaInventario, on_delete=models.CASCADE, related_name='detalles')
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    lote = models.ForeignKey(Lote, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad_solicitada = models.IntegerField()
    cantidad_enviada = models.IntegerField(null=True, blank=True)
    cantidad_recibida = models.IntegerField(null=True, blank=True)
    costo_unitario = models.DecimalField(max_digits=12, decimal_places=2)
    observaciones = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.transferencia.numero_transferencia} - {self.producto.nombre}"
    
    class Meta:
        db_table = 'transferencia_inventario_detalle'
        managed = False


class MermaEsperada(models.Model):
    categoria = models.ForeignKey(Categoria, on_delete=models.CASCADE, related_name='mermas_esperadas')
    porcentaje_merma = models.DecimalField(max_digits=5, decimal_places=2, help_text="Porcentaje esperado de merma")
    motivo_principal = models.CharField(max_length=255, null=True, blank=True)
    descripcion = models.TextField(null=True, blank=True)
    activo = models.BooleanField(default=True)
    fecha_vigencia_desde = models.DateField()
    fecha_vigencia_hasta = models.DateField(null=True, blank=True)
    creado_por = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='mermas_creadas')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.categoria.nombre} - {self.porcentaje_merma}%"
    
    class Meta:
        db_table = 'merma_esperada'
        managed = False
        ordering = ['categoria__nombre']


class CostoHistorico(models.Model):
    MOTIVO_CHOICES = [
        ('reabastecimiento', 'Reabastecimiento'),
        ('ajuste_manual', 'Ajuste Manual'),
        ('inflacion', 'Inflación'),
        ('proveedor', 'Cambio de Proveedor'),
        ('otro', 'Otro'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='costos_historicos')
    costo_anterior = models.DecimalField(max_digits=12, decimal_places=2)
    costo_nuevo = models.DecimalField(max_digits=12, decimal_places=2)
    diferencia = models.DecimalField(max_digits=12, decimal_places=2)
    porcentaje_cambio = models.DecimalField(max_digits=5, decimal_places=2)
    motivo = models.CharField(max_length=20, choices=MOTIVO_CHOICES)
    descripcion = models.TextField(null=True, blank=True)
    reabastecimiento = models.ForeignKey('suppliers.Reabastecimiento', on_delete=models.SET_NULL, null=True, blank=True, help_text="Si fue por reabastecimiento")
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    fecha_cambio = models.DateTimeField(auto_now_add=True)
    
    def save(self, *args, **kwargs):
        self.diferencia = self.costo_nuevo - self.costo_anterior
        if self.costo_anterior > 0:
            self.porcentaje_cambio = (self.diferencia / self.costo_anterior) * 100
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.producto.nombre} - {self.fecha_cambio.strftime('%Y-%m-%d')}"
    
    class Meta:
        db_table = 'costo_historico'
        managed = False
        ordering = ['-fecha_cambio']


class RotacionInventario(models.Model):
    CLASIFICACION_CHOICES = [
        ('A', 'A - Alta Rotación'),
        ('B', 'B - Rotación Media'),
        ('C', 'C - Baja Rotación'),
    ]
    
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name='rotaciones')
    periodo = models.CharField(max_length=7, help_text="Formato: YYYY-MM")
    stock_inicial = models.IntegerField()
    stock_final = models.IntegerField()
    stock_promedio = models.DecimalField(max_digits=12, decimal_places=2)
    cantidad_vendida = models.IntegerField()
    costo_mercancia_vendida = models.DecimalField(max_digits=12, decimal_places=2)
    rotacion = models.DecimalField(max_digits=10, decimal_places=2, help_text="Veces que rota el inventario")
    dias_inventario = models.DecimalField(max_digits=10, decimal_places=2, help_text="Días promedio en inventario")
    clasificacion_abc = models.CharField(max_length=1, choices=CLASIFICACION_CHOICES, null=True, blank=True)
    fecha_calculo = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.producto.nombre} - {self.periodo}"
    
    class Meta:
        db_table = 'rotacion_inventario'
        managed = False
        unique_together = (('producto', 'periodo'),)
        ordering = ['-periodo', 'producto__nombre']
