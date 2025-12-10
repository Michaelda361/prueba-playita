from rest_framework import serializers
from .models import (
    Categoria, Producto, Lote, MovimientoInventario,
    AjusteInventario, DescarteProducto, AlertaInventario,
    DevolucionProveedor, DevolucionProveedorDetalle,
    ValorizacionInventario, ConfiguracionAlerta, TasaIVA
)


class CategoriaSerializer(serializers.ModelSerializer):
    subcategorias = serializers.SerializerMethodField()
    
    class Meta:
        model = Categoria
        fields = ['id', 'nombre', 'parent', 'descripcion', 'orden', 'activo', 
                  'creado_por', 'fecha_creacion', 'subcategorias']
        read_only_fields = ['creado_por', 'fecha_creacion']
    
    def get_subcategorias(self, obj):
        if obj.subcategorias.exists():
            return CategoriaSerializer(obj.subcategorias.all(), many=True).data
        return []


class TasaIVASerializer(serializers.ModelSerializer):
    class Meta:
        model = TasaIVA
        fields = ['id', 'nombre', 'porcentaje']


class ProductoListSerializer(serializers.ModelSerializer):
    """Serializer ligero para listados"""
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    estado_stock = serializers.ReadOnlyField()
    valor_inventario = serializers.SerializerMethodField()
    
    class Meta:
        model = Producto
        fields = ['id', 'nombre', 'codigo_barras', 'precio_unitario', 'stock_actual', 
                  'stock_minimo', 'stock_maximo', 'categoria_nombre', 'estado', 
                  'estado_stock', 'costo_promedio', 'valor_inventario', 'imagen_url']
    
    def get_valor_inventario(self, obj):
        return float(obj.stock_actual * obj.costo_promedio)


class ProductoDetailSerializer(serializers.ModelSerializer):
    """Serializer completo para detalle"""
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    tasa_iva_info = TasaIVASerializer(source='tasa_iva', read_only=True)
    estado_stock = serializers.ReadOnlyField()
    lotes_activos = serializers.SerializerMethodField()
    alertas_activas = serializers.SerializerMethodField()
    
    class Meta:
        model = Producto
        fields = '__all__'
        read_only_fields = ['stock_actual', 'costo_promedio', 'creado_por', 
                            'fecha_creacion', 'modificado_por', 'fecha_modificacion']
    
    def get_lotes_activos(self, obj):
        lotes = obj.lotes.filter(estado='activo', cantidad_disponible__gt=0)
        return LoteSerializer(lotes, many=True).data
    
    def get_alertas_activas(self, obj):
        alertas = obj.alertas.filter(estado='activa')
        return AlertaInventarioSerializer(alertas, many=True).data


class LoteSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    dias_hasta_vencer = serializers.ReadOnlyField()
    estado_vencimiento = serializers.ReadOnlyField()
    valor_lote = serializers.SerializerMethodField()
    proveedor_nombre = serializers.SerializerMethodField()
    
    class Meta:
        model = Lote
        fields = ['id', 'producto', 'producto_nombre', 'numero_lote', 
                  'cantidad_disponible', 'costo_unitario_lote', 'valor_lote',
                  'fecha_caducidad', 'fecha_entrada', 'estado', 
                  'dias_hasta_vencer', 'estado_vencimiento', 'proveedor_nombre']
        read_only_fields = ['estado']
    
    def get_valor_lote(self, obj):
        return float(obj.cantidad_disponible * obj.costo_unitario_lote)
    
    def get_proveedor_nombre(self, obj):
        """Obtiene el proveedor desde el reabastecimiento_detalle"""
        if obj.reabastecimiento_detalle and obj.reabastecimiento_detalle.reabastecimiento:
            return obj.reabastecimiento_detalle.reabastecimiento.proveedor.nombre_empresa
        return None


class MovimientoInventarioSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    lote_numero = serializers.CharField(source='lote.numero_lote', read_only=True, allow_null=True)
    usuario_nombre = serializers.SerializerMethodField()
    valor_movimiento = serializers.SerializerMethodField()
    
    class Meta:
        model = MovimientoInventario
        fields = ['id', 'producto', 'producto_nombre', 'lote', 'lote_numero',
                  'cantidad', 'costo_unitario', 'tipo_movimiento', 'fecha_movimiento',
                  'descripcion', 'usuario', 'usuario_nombre', 'valor_movimiento',
                  'venta', 'reabastecimiento']
        read_only_fields = ['fecha_movimiento']
    
    def get_usuario_nombre(self, obj):
        if obj.usuario:
            return f"{obj.usuario.first_name} {obj.usuario.last_name}".strip() or obj.usuario.username
        return None
    
    def get_valor_movimiento(self, obj):
        if obj.costo_unitario:
            return float(abs(obj.cantidad) * obj.costo_unitario)
        return None


class AjusteInventarioSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    usuario_ejecuta_nombre = serializers.SerializerMethodField()
    usuario_autoriza_nombre = serializers.SerializerMethodField()
    
    class Meta:
        model = AjusteInventario
        fields = '__all__'
        read_only_fields = ['diferencia', 'fecha_ajuste', 'usuario_ejecuta']
    
    def get_usuario_ejecuta_nombre(self, obj):
        if obj.usuario_ejecuta:
            return f"{obj.usuario_ejecuta.first_name} {obj.usuario_ejecuta.last_name}".strip() or obj.usuario_ejecuta.username
        return None
    
    def get_usuario_autoriza_nombre(self, obj):
        if obj.usuario_autoriza:
            return f"{obj.usuario_autoriza.first_name} {obj.usuario_autoriza.last_name}".strip() or obj.usuario_autoriza.username
        return None
    
    def validate(self, data):
        # Calcular diferencia automáticamente
        data['diferencia'] = data['cantidad_fisica'] - data['cantidad_sistema']
        return data


class DescarteProductoSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    lote_numero = serializers.CharField(source='lote.numero_lote', read_only=True, allow_null=True)
    usuario_ejecuta_nombre = serializers.SerializerMethodField()
    usuario_autoriza_nombre = serializers.SerializerMethodField()
    
    class Meta:
        model = DescarteProducto
        fields = '__all__'
        read_only_fields = ['costo_total', 'fecha_descarte', 'usuario_ejecuta']
    
    def get_usuario_ejecuta_nombre(self, obj):
        if obj.usuario_ejecuta:
            return f"{obj.usuario_ejecuta.first_name} {obj.usuario_ejecuta.last_name}".strip() or obj.usuario_ejecuta.username
        return None
    
    def get_usuario_autoriza_nombre(self, obj):
        if obj.usuario_autoriza:
            return f"{obj.usuario_autoriza.first_name} {obj.usuario_autoriza.last_name}".strip() or obj.usuario_autoriza.username
        return None


class AlertaInventarioSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    lote_numero = serializers.CharField(source='lote.numero_lote', read_only=True, allow_null=True)
    resuelta_por_nombre = serializers.SerializerMethodField()
    prioridad_display = serializers.CharField(source='get_prioridad_display', read_only=True)
    tipo_display = serializers.CharField(source='get_tipo_alerta_display', read_only=True)
    
    class Meta:
        model = AlertaInventario
        fields = '__all__'
        read_only_fields = ['fecha_generacion']
    
    def get_resuelta_por_nombre(self, obj):
        if obj.resuelta_por:
            return f"{obj.resuelta_por.first_name} {obj.resuelta_por.last_name}".strip() or obj.resuelta_por.username
        return None


class DevolucionProveedorDetalleSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    lote_numero = serializers.CharField(source='lote.numero_lote', read_only=True, allow_null=True)
    subtotal = serializers.SerializerMethodField()
    
    class Meta:
        model = DevolucionProveedorDetalle
        fields = ['id', 'producto', 'producto_nombre', 'lote', 'lote_numero',
                  'cantidad', 'costo_unitario', 'subtotal', 'motivo_especifico']
    
    def get_subtotal(self, obj):
        return float(obj.cantidad * obj.costo_unitario)


class DevolucionProveedorSerializer(serializers.ModelSerializer):
    proveedor_nombre = serializers.CharField(source='proveedor.nombre_empresa', read_only=True)
    usuario_solicita_nombre = serializers.SerializerMethodField()
    usuario_aprueba_nombre = serializers.SerializerMethodField()
    detalles = DevolucionProveedorDetalleSerializer(many=True, read_only=True)
    
    class Meta:
        model = DevolucionProveedor
        fields = '__all__'
        read_only_fields = ['fecha_devolucion', 'usuario_solicita']
    
    def get_usuario_solicita_nombre(self, obj):
        if obj.usuario_solicita:
            return f"{obj.usuario_solicita.first_name} {obj.usuario_solicita.last_name}".strip() or obj.usuario_solicita.username
        return None
    
    def get_usuario_aprueba_nombre(self, obj):
        if obj.usuario_aprueba:
            return f"{obj.usuario_aprueba.first_name} {obj.usuario_aprueba.last_name}".strip() or obj.usuario_aprueba.username
        return None


class ValorizacionInventarioSerializer(serializers.ModelSerializer):
    producto_nombre = serializers.CharField(source='producto.nombre', read_only=True)
    categoria_nombre = serializers.CharField(source='categoria.nombre', read_only=True)
    generado_por_nombre = serializers.SerializerMethodField()
    
    class Meta:
        model = ValorizacionInventario
        fields = '__all__'
        read_only_fields = ['fecha_generacion']
    
    def get_generado_por_nombre(self, obj):
        if obj.generado_por:
            return f"{obj.generado_por.first_name} {obj.generado_por.last_name}".strip() or obj.generado_por.username
        return None


class ConfiguracionAlertaSerializer(serializers.ModelSerializer):
    tipo_display = serializers.CharField(source='get_tipo_alerta_display', read_only=True)
    
    class Meta:
        model = ConfiguracionAlerta
        fields = '__all__'
        read_only_fields = ['fecha_creacion', 'fecha_modificacion']


# Serializers para vistas de base de datos (read-only)
class DashboardInventarioSerializer(serializers.Serializer):
    """Serializer para la vista vw_dashboard_inventario"""
    total_productos = serializers.IntegerField()
    productos_activos = serializers.IntegerField()
    unidades_totales = serializers.IntegerField()
    valor_total_inventario = serializers.DecimalField(max_digits=12, decimal_places=2)
    productos_sin_stock = serializers.IntegerField()
    productos_stock_bajo = serializers.IntegerField()
    productos_sobre_stock = serializers.IntegerField()
    total_lotes_activos = serializers.IntegerField()
    lotes_vencidos = serializers.IntegerField()
    lotes_proximos_vencer = serializers.IntegerField()
    entradas_hoy = serializers.IntegerField()
    salidas_hoy = serializers.IntegerField()
    ordenes_pendientes = serializers.IntegerField()
    ordenes_hoy = serializers.IntegerField()


class KardexProductoSerializer(serializers.Serializer):
    """Serializer para la vista vw_kardex_producto"""
    movimiento_id = serializers.IntegerField()
    fecha_movimiento = serializers.DateTimeField()
    producto_id = serializers.IntegerField()
    producto_nombre = serializers.CharField()
    codigo_barras = serializers.CharField(allow_null=True)
    categoria = serializers.CharField()
    numero_lote = serializers.CharField(allow_null=True)
    fecha_caducidad = serializers.DateField(allow_null=True)
    tipo_movimiento = serializers.CharField()
    cantidad = serializers.IntegerField()
    costo_unitario = serializers.DecimalField(max_digits=12, decimal_places=2, allow_null=True)
    valor_movimiento = serializers.DecimalField(max_digits=12, decimal_places=2)
    descripcion = serializers.CharField(allow_null=True)
    origen = serializers.CharField()
    usuario = serializers.CharField(allow_null=True)
