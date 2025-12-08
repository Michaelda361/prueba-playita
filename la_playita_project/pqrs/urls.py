from django.urls import path
from . import views

app_name = 'pqrs'

urlpatterns = [
    path('', views.pqrs_dashboard, name='pqrs_dashboard'),
    path('lista/', views.pqrs_list, name='pqrs_list'),
    path('crear/', views.pqrs_create, name='pqrs_create'),
    path('estadisticas/', views.pqrs_estadisticas, name='pqrs_estadisticas'),
    path('<int:pk>/', views.pqrs_detail, name='pqrs_detail'),
    path('<int:pk>/update/', views.pqrs_update, name='pqrs_update'),
    path('<int:pk>/asignar/', views.pqrs_asignar, name='pqrs_asignar'),
    path('<int:pk>/calificar/', views.pqrs_calificar, name='pqrs_calificar'),
    path('<int:pk>/escalar/', views.pqrs_escalar, name='pqrs_escalar'),
    path('<int:pk>/adjunto/', views.pqrs_upload_adjunto, name='pqrs_upload_adjunto'),
    path('<int:pk>/eliminar/', views.pqrs_delete, name='pqrs_delete'),
]