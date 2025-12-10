from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .api_views import (
    CategoriaViewSet, ProductoViewSet, LoteViewSet,
    MovimientoInventarioViewSet, AjusteInventarioViewSet,
    DescarteProductoViewSet, AlertaInventarioViewSet,
    DashboardViewSet, ConfiguracionAlertaViewSet,
    dashboard_stats, stock_disponible, productos_obsoletos, resumen_alertas_view
)

router = DefaultRouter()
router.register(r'categorias', CategoriaViewSet, basename='categoria')
router.register(r'productos', ProductoViewSet, basename='producto')
router.register(r'lotes', LoteViewSet, basename='lote')
router.register(r'movimientos', MovimientoInventarioViewSet, basename='movimiento')
router.register(r'ajustes', AjusteInventarioViewSet, basename='ajuste')
router.register(r'descartes', DescarteProductoViewSet, basename='descarte')
router.register(r'alertas', AlertaInventarioViewSet, basename='alerta')
router.register(r'dashboard', DashboardViewSet, basename='dashboard')
router.register(r'configuracion-alertas', ConfiguracionAlertaViewSet, basename='configuracion-alerta')

urlpatterns = [
    path('', include(router.urls)),
    # Nuevas APIs para dashboard mejorado
    path('dashboard-stats/', dashboard_stats, name='dashboard-stats'),
    path('stock-disponible/', stock_disponible, name='stock-disponible'),
    path('productos-obsoletos/', productos_obsoletos, name='productos-obsoletos'),
    path('resumen-alertas/', resumen_alertas_view, name='resumen-alertas'),
]
