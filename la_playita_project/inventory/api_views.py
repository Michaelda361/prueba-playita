from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import connection
from django.db.models import Q, Sum, F, Count
from django.utils import timezone
from datetime import date, timedelta
from .models import (
    Categoria, Producto, Lote, MovimientoInventario,
    AjusteInventario, DescarteProducto, AlertaInventario,
    DevolucionProveedor, DevolucionProveedorDetalle,
    ValorizacionInventario, ConfiguracionAlerta, TasaIVA
)
from .serializers import (
    CategoriaSerializer, ProductoListSerializer, ProductoDetailSerializer,
    LoteSerializer, MovimientoInventarioSerializer,
    AjusteInventarioSerializer, DescarteProductoSerializer,
    AlertaInventarioSerializer, DevolucionProveedorSerializer,
    ValorizacionInventarioSerializer, ConfiguracionAlertaSerializer,
    TasaIVASerializer, DashboardInventarioSerializer, KardexProductoSerializer
)


class CategoriaViewSet(viewsets.ModelViewSet):
    queryset = Categoria.objects.filter(activo=True)
    serializer_class = CategoriaSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['nombre', 'descripcion']
    ordering_fields = ['orden', 'nombre']
    ordering = ['orden', 'nombre']
    
    def perform_create(self, serializer):
        serializer.save(creado_por=self.request.user)
    
    @action(detail=False, methods=['get'])
    def arbol(self, request):
        """Retorna categorías en estructura jerárquica"""
        categorias_raiz = Categoria.objects.filter(parent__isnull=True, activo=True)
        serializer = self.get_serializer(categorias_raiz, many=True)
        return Response(serializer.data)


class ProductoViewSet(viewsets.ModelViewSet):
    queryset = Producto.objects.filter(estado='activo').select_related('categoria', 'tasa_iva')
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['nombre', 'codigo_barras', 'descripcion']
    ordering_fields = ['nombre', 'stock_actual', 'precio_unitario', 'costo_promedio']
    ordering = ['nombre']
    
    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductoDetailSerializer
        return ProductoListSerializer
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filtros personalizados
        categoria_id = self.request.query_params.get('categoria', None)
        estado_stock = self.request.query_params.get('estado_stock', None)
        
        if categoria_id:
            queryset = queryset.filter(categoria_id=categoria_id)
        
        if estado_stock:
            # Soportar múltiples estados separados por coma
            estados = [e.strip() for e in estado_stock.split(',')]
            q_objects = Q()
            
            for estado in estados:
                if estado == 'SIN_STOCK':
                    q_objects |= Q(stock_actual=0)
                elif estado == 'STOCK_CRITICO':
                    q_objects |= Q(stock_actual__lt=F('stock_minimo'), stock_actual__gt=0)
                elif estado == 'STOCK_BAJO':
                    q_objects |= Q(
                        stock_actual__gte=F('stock_minimo'),
                        stock_actual__lt=F('stock_minimo') * 1.5
                    )
                elif estado == 'NORMAL':
                    q_objects |= Q(
                        stock_actual__gte=F('stock_minimo') * 1.5,
                        stock_actual__lte=F('stock_maximo')
                    ) | Q(
                        stock_actual__gte=F('stock_minimo') * 1.5,
                        stock_maximo__isnull=True
                    )
                elif estado == 'SOBRE_STOCK':
                    q_objects |= Q(
                        stock_maximo__isnull=False,
                        stock_actual__gt=F('stock_maximo')
                    )
            
            if q_objects:
                queryset = queryset.filter(q_objects)
        
        return queryset
    
    def perform_create(self, serializer):
        serializer.save(creado_por=self.request.user)
    
    def perform_update(self, serializer):
        serializer.save(modificado_por=self.request.user)
    
    @action(detail=True, methods=['get'])
    def kardex(self, request, pk=None):
        """Retorna el kardex (historial de movimientos) de un producto"""
        producto = self.get_object()
        movimientos = MovimientoInventario.objects.filter(
            producto=producto
        ).select_related('lote', 'usuario').order_by('fecha_movimiento', 'id')
        
        # Calcular saldos
        saldo_cantidad = 0
        saldo_valor = 0
        kardex_data = []
        
        for mov in movimientos:
            saldo_cantidad += mov.cantidad
            if mov.costo_unitario:
                saldo_valor += mov.cantidad * float(mov.costo_unitario)
            
            mov_data = MovimientoInventarioSerializer(mov).data
            mov_data['saldo_cantidad'] = saldo_cantidad
            mov_data['saldo_valor'] = round(saldo_valor, 2)
            kardex_data.append(mov_data)
        
        return Response(kardex_data)
    
    @action(detail=True, methods=['get'])
    def estadisticas(self, request, pk=None):
        """Retorna estadísticas del producto"""
        producto = self.get_object()
        dias = int(request.query_params.get('dias', 30))
        fecha_desde = timezone.now() - timedelta(days=dias)
        
        # Ventas en el período
        ventas = MovimientoInventario.objects.filter(
            producto=producto,
            tipo_movimiento='SALIDA',
            fecha_movimiento__gte=fecha_desde
        ).aggregate(
            total_vendido=Sum('cantidad'),
            total_movimientos=Count('id')
        )
        
        # Última venta y última compra
        ultima_venta = MovimientoInventario.objects.filter(
            producto=producto,
            tipo_movimiento='SALIDA'
        ).order_by('-fecha_movimiento').first()
        
        ultima_compra = MovimientoInventario.objects.filter(
            producto=producto,
            tipo_movimiento='ENTRADA'
        ).order_by('-fecha_movimiento').first()
        
        # Calcular rotación y días de inventario
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT fn_dias_inventario(%s, %s), fn_rotacion_inventario(%s, %s)",
                [pk, dias, pk, dias]
            )
            dias_inventario, rotacion = cursor.fetchone()
        
        return Response({
            'ventas_periodo': abs(ventas['total_vendido'] or 0),
            'total_movimientos': ventas['total_movimientos'],
            'promedio_diario': abs(ventas['total_vendido'] or 0) / dias,
            'ultima_venta': ultima_venta.fecha_movimiento if ultima_venta else None,
            'ultima_compra': ultima_compra.fecha_movimiento if ultima_compra else None,
            'dias_inventario': float(dias_inventario) if dias_inventario else None,
            'rotacion': float(rotacion) if rotacion else None,
        })


class LoteViewSet(viewsets.ModelViewSet):
    queryset = Lote.objects.select_related('producto').order_by('fecha_caducidad')
    serializer_class = LoteSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['numero_lote', 'producto__nombre']
    ordering_fields = ['fecha_caducidad', 'fecha_entrada', 'cantidad_disponible']
    ordering = ['fecha_caducidad']
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filtros
        producto_id = self.request.query_params.get('producto', None)
        estado = self.request.query_params.get('estado', None)
        proximo_vencer = self.request.query_params.get('proximo_vencer', None)
        
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        
        if estado:
            queryset = queryset.filter(estado=estado)
        
        if proximo_vencer:
            dias = int(proximo_vencer)
            fecha_limite = date.today() + timedelta(days=dias)
            queryset = queryset.filter(
                fecha_caducidad__lte=fecha_limite,
                cantidad_disponible__gt=0
            )
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def vencidos(self, request):
        """Retorna lotes vencidos con stock"""
        lotes = self.get_queryset().filter(
            fecha_caducidad__lt=date.today(),
            cantidad_disponible__gt=0
        )
        serializer = self.get_serializer(lotes, many=True)
        return Response(serializer.data)


class MovimientoInventarioViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet de solo lectura para movimientos"""
    queryset = MovimientoInventario.objects.select_related(
        'producto', 'lote', 'usuario'
    ).order_by('-fecha_movimiento')
    serializer_class = MovimientoInventarioSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['producto__nombre', 'descripcion']
    ordering_fields = ['fecha_movimiento', 'tipo_movimiento']
    ordering = ['-fecha_movimiento']
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filtros
        producto_id = self.request.query_params.get('producto', None)
        tipo = self.request.query_params.get('tipo', None)
        fecha_desde = self.request.query_params.get('fecha_desde', None)
        fecha_hasta = self.request.query_params.get('fecha_hasta', None)
        
        if producto_id:
            queryset = queryset.filter(producto_id=producto_id)
        
        if tipo:
            queryset = queryset.filter(tipo_movimiento=tipo)
        
        if fecha_desde:
            queryset = queryset.filter(fecha_movimiento__gte=fecha_desde)
        
        if fecha_hasta:
            queryset = queryset.filter(fecha_movimiento__lte=fecha_hasta)
        
        return queryset


class AjusteInventarioViewSet(viewsets.ModelViewSet):
    queryset = AjusteInventario.objects.select_related(
        'producto', 'lote', 'usuario_ejecuta', 'usuario_autoriza'
    ).order_by('-fecha_ajuste')
    serializer_class = AjusteInventarioSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['fecha_ajuste', 'estado']
    ordering = ['-fecha_ajuste']
    
    def perform_create(self, serializer):
        serializer.save(usuario_ejecuta=self.request.user)
    
    @action(detail=True, methods=['post'])
    def aprobar(self, request, pk=None):
        """Aprueba y aplica un ajuste de inventario"""
        ajuste = self.get_object()
        
        if ajuste.estado != 'pendiente':
            return Response(
                {'error': 'Solo se pueden aprobar ajustes pendientes'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "CALL sp_aplicar_ajuste_inventario(%s, %s)",
                    [pk, request.user.id]
                )
            
            ajuste.refresh_from_db()
            serializer = self.get_serializer(ajuste)
            return Response(serializer.data)
        
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['post'])
    def rechazar(self, request, pk=None):
        """Rechaza un ajuste de inventario"""
        ajuste = self.get_object()
        
        if ajuste.estado != 'pendiente':
            return Response(
                {'error': 'Solo se pueden rechazar ajustes pendientes'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        ajuste.estado = 'rechazado'
        ajuste.usuario_autoriza = request.user
        ajuste.observaciones = request.data.get('observaciones', '')
        ajuste.save()
        
        serializer = self.get_serializer(ajuste)
        return Response(serializer.data)


class DescarteProductoViewSet(viewsets.ModelViewSet):
    queryset = DescarteProducto.objects.select_related(
        'producto', 'lote', 'usuario_ejecuta', 'usuario_autoriza'
    ).order_by('-fecha_descarte')
    serializer_class = DescarteProductoSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['fecha_descarte', 'estado']
    ordering = ['-fecha_descarte']
    
    def perform_create(self, serializer):
        serializer.save(usuario_ejecuta=self.request.user)
    
    @action(detail=True, methods=['post'])
    def aprobar(self, request, pk=None):
        """Aprueba y ejecuta un descarte"""
        descarte = self.get_object()
        
        if descarte.estado != 'pendiente':
            return Response(
                {'error': 'Solo se pueden aprobar descartes pendientes'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            with connection.cursor() as cursor:
                cursor.execute(
                    "CALL sp_aplicar_descarte_producto(%s, %s)",
                    [pk, request.user.id]
                )
            
            descarte.refresh_from_db()
            serializer = self.get_serializer(descarte)
            return Response(serializer.data)
        
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AlertaInventarioViewSet(viewsets.ModelViewSet):
    queryset = AlertaInventario.objects.select_related(
        'producto', 'lote', 'resuelta_por'
    ).order_by('-fecha_generacion')
    serializer_class = AlertaInventarioSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['fecha_generacion', 'prioridad']
    ordering = ['-fecha_generacion']
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filtros
        estado = self.request.query_params.get('estado', None)
        tipo = self.request.query_params.get('tipo', None)
        prioridad = self.request.query_params.get('prioridad', None)
        
        if estado:
            queryset = queryset.filter(estado=estado)
        
        if tipo:
            queryset = queryset.filter(tipo_alerta=tipo)
        
        if prioridad:
            queryset = queryset.filter(prioridad=prioridad)
        
        return queryset
    
    @action(detail=False, methods=['post'])
    def generar(self, request):
        """Genera alertas automáticas"""
        try:
            with connection.cursor() as cursor:
                cursor.execute("CALL sp_generar_alertas_inventario()")
            
            alertas_nuevas = AlertaInventario.objects.filter(
                estado='activa',
                fecha_generacion__gte=timezone.now() - timedelta(minutes=1)
            ).count()
            
            return Response({
                'mensaje': 'Alertas generadas exitosamente',
                'alertas_nuevas': alertas_nuevas
            })
        
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['post'])
    def resolver(self, request, pk=None):
        """Marca una alerta como resuelta"""
        alerta = self.get_object()
        
        alerta.estado = 'resuelta'
        alerta.resuelta_por = request.user
        alerta.fecha_resolucion = timezone.now()
        alerta.notas_resolucion = request.data.get('notas', '')
        alerta.save()
        
        serializer = self.get_serializer(alerta)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def ignorar(self, request, pk=None):
        """Marca una alerta como ignorada"""
        alerta = self.get_object()
        
        alerta.estado = 'ignorada'
        alerta.resuelta_por = request.user
        alerta.fecha_resolucion = timezone.now()
        alerta.notas_resolucion = request.data.get('notas', '')
        alerta.save()
        
        serializer = self.get_serializer(alerta)
        return Response(serializer.data)


class DashboardViewSet(viewsets.ViewSet):
    """ViewSet para dashboard y reportes"""
    permission_classes = [IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def inventario(self, request):
        """Retorna KPIs del dashboard de inventario"""
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM vw_dashboard_inventario")
            columns = [col[0] for col in cursor.description]
            row = cursor.fetchone()
            data = dict(zip(columns, row)) if row else {}
        
        serializer = DashboardInventarioSerializer(data=data)
        serializer.is_valid()
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def alertas_resumen(self, request):
        """Resumen de alertas por tipo y prioridad"""
        alertas = AlertaInventario.objects.filter(estado='activa').values(
            'tipo_alerta', 'prioridad'
        ).annotate(cantidad=Count('id')).order_by('prioridad', 'tipo_alerta')
        
        return Response(list(alertas))
    
    @action(detail=False, methods=['get'])
    def productos_criticos(self, request):
        """Productos que requieren atención inmediata"""
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT * FROM vw_productos_alertas 
                WHERE prioridad IN ('CRITICA', 'ALTA')
                LIMIT 10
            """)
            columns = [col[0] for col in cursor.description]
            rows = cursor.fetchall()
            data = [dict(zip(columns, row)) for row in rows]
        
        return Response(data)
    
    @action(detail=False, methods=['get'])
    def tendencia_stock(self, request):
        """Tendencia de stock de los últimos 7 días"""
        from datetime import datetime, timedelta
        
        fechas = []
        valores = []
        
        for i in range(7, -1, -1):
            fecha = datetime.now() - timedelta(days=i)
            fechas.append(fecha.strftime('%d/%m'))
            
            # Calcular stock total en esa fecha
            total = Producto.objects.filter(estado='activo').aggregate(
                total=Sum('stock_actual')
            )['total'] or 0
            valores.append(total)
        
        return Response({
            'fechas': fechas,
            'valores': valores
        })
    
    @action(detail=False, methods=['get'])
    def top_productos(self, request):
        """Top 5 productos más vendidos del último mes"""
        from datetime import datetime, timedelta
        
        fecha_desde = datetime.now() - timedelta(days=30)
        
        top = MovimientoInventario.objects.filter(
            tipo_movimiento='SALIDA',
            venta__isnull=False,
            fecha_movimiento__gte=fecha_desde
        ).values(
            'producto__nombre',
            'producto__categoria__nombre'
        ).annotate(
            total_vendido=Sum('cantidad')
        ).order_by('total_vendido')[:5]
        
        return Response([{
            'nombre': item['producto__nombre'],
            'categoria': item['producto__categoria__nombre'],
            'total_vendido': item['total_vendido']
        } for item in top])


class ConfiguracionAlertaViewSet(viewsets.ModelViewSet):
    queryset = ConfiguracionAlerta.objects.all()
    serializer_class = ConfiguracionAlertaSerializer
    permission_classes = [IsAuthenticated]


# ============================================================================
# APIS PARA DASHBOARD MEJORADO
# ============================================================================

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Q, F
from decimal import Decimal

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_stats(request):
    """
    Estadísticas principales del dashboard
    """
    from datetime import datetime, timedelta
    
    # Valor total del inventario
    valor_total = Producto.objects.filter(estado='activo').aggregate(
        total=Sum(F('stock_actual') * F('costo_promedio'))
    )['total'] or 0
    
    # Productos activos
    productos_activos = Producto.objects.filter(estado='activo').count()
    
    # Alertas críticas activas
    alertas_criticas = AlertaInventario.objects.filter(
        estado='activa',
        prioridad='critica'
    ).count()
    
    # Movimientos de hoy (considerando zona horaria local)
    from django.utils import timezone
    from datetime import datetime, timedelta
    
    # Obtener la fecha actual en la zona horaria local (Bogotá)
    now_local = timezone.localtime(timezone.now())
    today_local = now_local.date()
    
    # Crear rango para "hoy" en zona horaria local
    hoy_inicio = timezone.make_aware(datetime.combine(today_local, datetime.min.time()))
    hoy_fin = timezone.make_aware(datetime.combine(today_local, datetime.max.time()))
    
    movimientos_hoy = MovimientoInventario.objects.filter(
        fecha_movimiento__gte=hoy_inicio,
        fecha_movimiento__lte=hoy_fin
    ).count()
    
    # Productos sin stock
    productos_sin_stock = Producto.objects.filter(
        estado='activo',
        stock_actual=0
    ).count()
    
    # Productos con stock bajo
    productos_stock_bajo = Producto.objects.filter(
        estado='activo',
        stock_actual__gt=0,
        stock_actual__lt=F('stock_minimo')
    ).count()
    
    # Valor por categoría
    valor_por_categoria = Categoria.objects.filter(
        activo=True
    ).annotate(
        valor=Sum(F('producto__stock_actual') * F('producto__costo_promedio'))
    ).values('nombre', 'valor').order_by('-valor')[:10]
    
    # Movimientos últimos 30 días
    hace_30_dias = datetime.now() - timedelta(days=30)
    movimientos_30_dias = MovimientoInventario.objects.filter(
        fecha_movimiento__gte=hace_30_dias
    ).values('tipo_movimiento').annotate(
        total=Count('id')
    )
    
    # Top 10 productos por valor
    top_productos = Producto.objects.filter(
        estado='activo'
    ).annotate(
        valor_total=F('stock_actual') * F('costo_promedio')
    ).order_by('-valor_total')[:10].values(
        'id', 'nombre', 'stock_actual', 'costo_promedio', 'valor_total'
    )
    
    return Response({
        'valor_total': float(valor_total),
        'productos_activos': productos_activos,
        'alertas_criticas': alertas_criticas,
        'movimientos_hoy': movimientos_hoy,
        'productos_sin_stock': productos_sin_stock,
        'productos_stock_bajo': productos_stock_bajo,
        'valor_por_categoria': list(valor_por_categoria),
        'movimientos_30_dias': list(movimientos_30_dias),
        'top_productos': list(top_productos),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def stock_disponible(request):
    """
    Consulta la vista v_stock_disponible
    """
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT 
                producto_id,
                producto_nombre,
                stock_total,
                stock_reservado,
                stock_disponible,
                stock_minimo,
                stock_maximo
            FROM v_stock_disponible
            WHERE stock_disponible < stock_minimo
            ORDER BY stock_disponible ASC
            LIMIT 50
        """)
        
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]
    
    return Response(results)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def productos_obsoletos(request):
    """
    Consulta la vista v_productos_obsoletos
    """
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT 
                id,
                nombre,
                categoria_nombre,
                stock_actual,
                costo_promedio,
                valor_inmovilizado,
                dias_sin_movimiento,
                ultima_venta,
                dias_desde_ultima_venta
            FROM v_productos_obsoletos
            ORDER BY valor_inmovilizado DESC
            LIMIT 50
        """)
        
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]
    
    return Response(results)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def resumen_alertas_view(request):
    """
    Consulta la vista v_resumen_alertas
    """
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT 
                prioridad,
                tipo_alerta,
                total,
                activas,
                resueltas,
                ignoradas
            FROM v_resumen_alertas
        """)
        
        columns = [col[0] for col in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]
    
    return Response(results)
