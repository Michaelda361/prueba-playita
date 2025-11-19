from django.db import models
from django.conf import settings


class Pqrs(models.Model):
    TIPO_PETICION = 'peticion'
    TIPO_QUEJA = 'queja'
    TIPO_RECLAMO = 'reclamo'
    TIPO_SUGERENCIA = 'sugerencia'

    TIPO_CHOICES = [
        (TIPO_PETICION, 'Petición'),
        (TIPO_QUEJA, 'Queja'),
        (TIPO_RECLAMO, 'Reclamo'),
        (TIPO_SUGERENCIA, 'Sugerencia'),
    ]

    ESTADO_NUEVO = 'nuevo'
    ESTADO_EN_PROCESO = 'en_proceso'
    ESTADO_RESUELTO = 'resuelto'
    ESTADO_CERRADO = 'cerrado'

    ESTADO_CHOICES = [
        (ESTADO_NUEVO, 'Nuevo'),
        (ESTADO_EN_PROCESO, 'En Proceso'),
        (ESTADO_RESUELTO, 'Resuelto'),
        (ESTADO_CERRADO, 'Cerrado'),
    ]

    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES)
    descripcion = models.TextField()
    respuesta = models.TextField(blank=True, null=True)
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='pendiente')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(blank=True, null=True)
    cliente = models.ForeignKey('clients.Cliente', on_delete=models.CASCADE)
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, blank=True, null=True)

    def __str__(self):
        return f'{self.get_tipo_display()} de {self.cliente}'

    class Meta:
        managed = False
        db_table = 'pqrs'


class PqrsHistorial(models.Model):
    pqrs = models.ForeignKey(Pqrs, on_delete=models.CASCADE)
    usuario = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, blank=True, null=True)
    estado_anterior = models.CharField(max_length=20)
    estado_nuevo = models.CharField(max_length=20)
    descripcion_cambio = models.TextField(blank=True, null=True)
    fecha_cambio = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Historial de {self.pqrs}'

    class Meta:
        managed = False
        db_table = 'pqrs_historial'