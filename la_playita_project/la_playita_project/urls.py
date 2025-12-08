from django.contrib import admin
from django.urls import path, include
from django.contrib.auth.views import LogoutView
from django.conf import settings
from django.conf.urls.static import static
from core import views as core_views
from users import views as users_views

urlpatterns = [
    # Core y Autenticación (rutas principales)
    path('', core_views.landing_view, name='landing'),
    path('dashboard/', core_views.dashboard_view, name='dashboard'),
    path('admin/', admin.site.urls),

    # Usuarios
    path('users/', include('users.urls', namespace='users')),

    # Inventario
    path('inventory/', include('inventory.urls', namespace='inventory')),

    # Clientes
    path('clients/', include('clients.urls', namespace='clients')),

    # Proveedores
    path('suppliers/', include('suppliers.urls', namespace='suppliers')),

    # Punto de venta
    path('pos/', include('pos.urls', namespace='pos')),

    # PQRS
    path('pqrs/', include('pqrs.urls', namespace='pqrs')),

    # Reportes
    path('reportes/', include('reportes.urls', namespace='reportes')),
]

# Servir archivos media en desarrollo
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
