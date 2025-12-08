from django.db import models
from django.conf import settings
from django.utils import timezone

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

    CATEGORIA_GENERAL = 'general'
    CATEGORIA_PRODUCTO = 'producto'
    CATEGORIA_SERVICIO = 'servicio'
    CATEGORIA_ENTREGA = 'entrega'

    CATEGORIA_CHOICES = [
        (CATEGORIA_GENERAL, 'General'),
        (CATEGORIA_PRODUCTO, 'Producto'),
        (CATEGORIA_SERVICIO, 'Servicio'),
        (CATEGORIA_ENTREGA, 'Entrega'),
    ]

    PRIORIDAD_BAJA = 'baja'
    PRIORIDAD_MEDIA = 'media'
    PRIORIDAD_ALTA = 'alta'
    PRIORIDAD_URGENTE = 'urgente'

    PRIORIDAD_CHOICES = [
        (PRIORIDAD_BAJA, 'Baja'),
        (PRIORIDAD_MEDIA, 'Media'),
        (PRIORIDAD_ALTA, 'Alta'),
        (PRIORIDAD_URGENTE, 'Urgente'),
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

    CANAL_WEB = 'web'
    CANAL_TELEFONO = 'telefono'
    CANAL_EMAIL = 'email'
    CANAL_PRESENCIAL = 'presencial'

    CANAL_CHOICES = [
        (CANAL_WEB, 'Web'),
        (CANAL_TELEFONO, 'Teléfono'),
        (CANAL_EMAIL, 'Email'),
        (CANAL_PRESENCIAL, 'Presencial'),
    ]

    numero_caso = models.CharField(max_length=20, unique=True, editable=False)
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES)
    categoria = models.CharField(max_length=50, choices=CATEGORIA_CHOICES, default=CATEGORIA_GENERAL)
    prioridad = models.CharField(max_length=20, choices=PRIORIDAD_CHOICES, default=PRIORIDAD_MEDIA)
    canal_origen = models.CharField(max_length=20, choices=CANAL_CHOICES, default=CANAL_WEB)
    descripcion = models.TextField()
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default=ESTADO_NUEVO)
    fecha_creacion = models.DateTimeField(default=timezone.now)
    fecha_actualizacion = models.DateTimeField(auto_now=True, null=True)
    fecha_primera_respuesta = models.DateTimeField(null=True, blank=True)
    fecha_cierre = models.DateTimeField(null=True, blank=True)
    tiempo_resolucion_horas = models.IntegerField(null=True, blank=True)
    fecha_limite_sla = models.DateTimeField(null=True, blank=True)
    sla_vencido = models.BooleanField(default=False)
    ultima_modificacion_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='pqrs_modificados',
        db_column='ultima_modificacion_por_id'
    )
    cliente = models.ForeignKey(
        'clients.Cliente',
        on_delete=models.RESTRICT,
        db_column='cliente_id'
    )
    creado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.RESTRICT,
        related_name='pqrs_creados',
        db_column='creado_por_id'
    )
    asignado_a = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='pqrs_asignados',
        db_column='asignado_a_id'
    )

    def __str__(self):
        return f'{self.numero_caso} - {self.get_tipo_display()} de {self.cliente}'

    class Meta:
        managed = False
        db_table = 'pqrs'
        ordering = ['-fecha_creacion']


class PqrsEvento(models.Model):
    EVENTO_CREACION = 'creacion'
    EVENTO_ESTADO = 'estado'
    EVENTO_RESPUESTA = 'respuesta'
    EVENTO_NOTA = 'nota'

    TIPO_EVENTO_CHOICES = [
        (EVENTO_CREACION, 'Creación de PQRS'),
        (EVENTO_ESTADO, 'Cambio de Estado'),
        (EVENTO_RESPUESTA, 'Respuesta al Cliente'),
        (EVENTO_NOTA, 'Nota Interna'),
    ]

    pqrs = models.ForeignKey(
        Pqrs,
        related_name='eventos',
        on_delete=models.CASCADE,
        db_column='pqrs_id'
    )
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        db_column='usuario_id'
    )
    tipo_evento = models.CharField(max_length=20, choices=TIPO_EVENTO_CHOICES)
    comentario = models.TextField(blank=True, null=True)
    es_visible_cliente = models.BooleanField(default=True)
    enviado_por_correo = models.BooleanField(default=False)
    fecha_envio_correo = models.DateTimeField(null=True, blank=True)
    fecha_evento = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f'Evento de {self.get_tipo_evento_display()} en {self.pqrs}'

    class Meta:
        managed = False
        db_table = 'pqrs_evento'
        ordering = ['-fecha_evento']


class PqrsAdjunto(models.Model):
    pqrs = models.ForeignKey(
        Pqrs,
        related_name='adjuntos',
        on_delete=models.CASCADE,
        db_column='pqrs_id'
    )
    nombre_archivo = models.CharField(max_length=255)
    ruta_archivo = models.CharField(max_length=500)
    tipo_mime = models.CharField(max_length=100)
    tamano_bytes = models.BigIntegerField()
    descripcion = models.CharField(max_length=255, blank=True, null=True)
    subido_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='subido_por_id'
    )
    fecha_subida = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f'{self.nombre_archivo} - {self.pqrs.numero_caso}'

    class Meta:
        managed = False
        db_table = 'pqrs_adjunto'
        ordering = ['-fecha_subida']


class PqrsCalificacion(models.Model):
    PUNTUACION_MUY_MALO = 1
    PUNTUACION_MALO = 2
    PUNTUACION_REGULAR = 3
    PUNTUACION_BUENO = 4
    PUNTUACION_EXCELENTE = 5

    PUNTUACION_CHOICES = [
        (PUNTUACION_MUY_MALO, '⭐ Muy malo'),
        (PUNTUACION_MALO, '⭐⭐ Malo'),
        (PUNTUACION_REGULAR, '⭐⭐⭐ Regular'),
        (PUNTUACION_BUENO, '⭐⭐⭐⭐ Bueno'),
        (PUNTUACION_EXCELENTE, '⭐⭐⭐⭐⭐ Excelente'),
    ]

    pqrs = models.OneToOneField(
        Pqrs,
        on_delete=models.CASCADE,
        related_name='calificacion',
        db_column='pqrs_id'
    )
    puntuacion = models.IntegerField(choices=PUNTUACION_CHOICES)
    comentario = models.TextField(blank=True, null=True)
    fecha_calificacion = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f'Calificación {self.puntuacion}⭐ para {self.pqrs.numero_caso}'

    class Meta:
        managed = False
        db_table = 'pqrs_calificacion'
        ordering = ['-fecha_calificacion']


class PqrsEscalamiento(models.Model):
    pqrs = models.ForeignKey(
        Pqrs,
        related_name='escalamientos',
        on_delete=models.CASCADE,
        db_column='pqrs_id'
    )
    escalado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='escalamientos_realizados',
        db_column='escalado_por_id'
    )
    escalado_a = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='escalamientos_recibidos',
        db_column='escalado_a_id'
    )
    motivo = models.TextField()
    fecha_escalamiento = models.DateTimeField(default=timezone.now)
    resuelto = models.BooleanField(default=False)
    fecha_resolucion = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f'Escalamiento de {self.pqrs.numero_caso} a {self.escalado_a}'

    class Meta:
        managed = False
        db_table = 'pqrs_escalamiento'
        ordering = ['-fecha_escalamiento']



class PqrsSla(models.Model):
    """Configuración de SLA por tipo y prioridad"""
    tipo = models.CharField(max_length=20, choices=Pqrs.TIPO_CHOICES)
    prioridad = models.CharField(max_length=20, choices=Pqrs.PRIORIDAD_CHOICES)
    horas_limite = models.IntegerField()
    activo = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(default=timezone.now)
    fecha_actualizacion = models.DateTimeField(auto_now=True, null=True)
    
    class Meta:
        managed = False
        db_table = 'pqrs_sla'
        unique_together = ['tipo', 'prioridad']
        verbose_name = 'SLA de PQRS'
        verbose_name_plural = 'SLAs de PQRS'
    
    def __str__(self):
        return f"{self.get_tipo_display()} - {self.get_prioridad_display()}: {self.horas_limite}h"


class PqrsPlantillaRespuesta(models.Model):
    """Plantillas predefinidas para respuestas rápidas"""
    nombre = models.CharField(max_length=100)
    tipo = models.CharField(max_length=20, choices=Pqrs.TIPO_CHOICES, null=True, blank=True)
    categoria = models.CharField(max_length=50, choices=Pqrs.CATEGORIA_CHOICES, null=True, blank=True)
    contenido = models.TextField()
    activa = models.BooleanField(default=True)
    fecha_creacion = models.DateTimeField(default=timezone.now)
    fecha_actualizacion = models.DateTimeField(auto_now=True, null=True)
    creado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_column='creado_por_id'
    )
    
    class Meta:
        managed = False
        db_table = 'pqrs_plantilla_respuesta'
        ordering = ['nombre']
        verbose_name = 'Plantilla de Respuesta'
        verbose_name_plural = 'Plantillas de Respuesta'
    
    def __str__(self):
        return self.nombre
    
    def renderizar(self, pqrs):
        """Renderiza la plantilla con datos del PQRS"""
        contenido = self.contenido
        contenido = contenido.replace('{{cliente_nombre}}', f"{pqrs.cliente.nombres} {pqrs.cliente.apellidos}")
        contenido = contenido.replace('{{numero_caso}}', pqrs.numero_caso)
        
        # Calcular horas SLA
        if pqrs.fecha_limite_sla:
            from datetime import datetime
            horas_restantes = (pqrs.fecha_limite_sla - timezone.now()).total_seconds() / 3600
            contenido = contenido.replace('{{sla_horas}}', str(int(horas_restantes)))
        
        return contenido


class PqrsVistaGuardada(models.Model):
    """Vistas guardadas de filtros personalizados"""
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        db_column='usuario_id'
    )
    nombre = models.CharField(max_length=100)
    filtros = models.JSONField()
    es_publica = models.BooleanField(default=False)
    fecha_creacion = models.DateTimeField(default=timezone.now)
    fecha_actualizacion = models.DateTimeField(auto_now=True, null=True)
    
    class Meta:
        managed = False
        db_table = 'pqrs_vista_guardada'
        ordering = ['nombre']
        verbose_name = 'Vista Guardada'
        verbose_name_plural = 'Vistas Guardadas'
    
    def __str__(self):
        return f"{self.nombre} - {self.usuario.username}"


class PqrsNotificacion(models.Model):
    """Registro de notificaciones enviadas"""
    TIPO_EMAIL = 'email'
    TIPO_PUSH = 'push'
    TIPO_SMS = 'sms'
    TIPO_SISTEMA = 'sistema'
    
    TIPO_CHOICES = [
        (TIPO_EMAIL, 'Email'),
        (TIPO_PUSH, 'Push'),
        (TIPO_SMS, 'SMS'),
        (TIPO_SISTEMA, 'Sistema'),
    ]
    
    pqrs = models.ForeignKey(
        Pqrs,
        on_delete=models.CASCADE,
        related_name='notificaciones',
        db_column='pqrs_id'
    )
    tipo = models.CharField(max_length=10, choices=TIPO_CHOICES)
    destinatario = models.CharField(max_length=255)
    asunto = models.CharField(max_length=255, null=True, blank=True)
    contenido = models.TextField()
    enviado = models.BooleanField(default=False)
    fecha_envio = models.DateTimeField(null=True, blank=True)
    error = models.TextField(null=True, blank=True)
    fecha_creacion = models.DateTimeField(default=timezone.now)
    
    class Meta:
        managed = False
        db_table = 'pqrs_notificacion'
        ordering = ['-fecha_creacion']
        verbose_name = 'Notificación'
        verbose_name_plural = 'Notificaciones'
    
    def __str__(self):
        return f"{self.get_tipo_display()} a {self.destinatario}"


class PqrsCategoriaPersonalizada(models.Model):
    """Categorías personalizables con jerarquía"""
    nombre = models.CharField(max_length=100, unique=True)
    descripcion = models.TextField(null=True, blank=True)
    categoria_padre = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='subcategorias',
        db_column='categoria_padre_id'
    )
    activa = models.BooleanField(default=True)
    orden = models.IntegerField(default=0)
    icono = models.CharField(max_length=50, null=True, blank=True)
    color = models.CharField(max_length=20, null=True, blank=True)
    fecha_creacion = models.DateTimeField(default=timezone.now)
    
    class Meta:
        managed = False
        db_table = 'pqrs_categoria_personalizada'
        ordering = ['orden', 'nombre']
        verbose_name = 'Categoría Personalizada'
        verbose_name_plural = 'Categorías Personalizadas'
    
    def __str__(self):
        if self.categoria_padre:
            return f"{self.categoria_padre.nombre} > {self.nombre}"
        return self.nombre
