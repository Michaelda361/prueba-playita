from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from datetime import timedelta
from .models import Pqrs, PqrsEvento, PqrsSla

@receiver(post_save, sender=Pqrs)
def log_pqrs_creation(sender, instance, created, **kwargs):
    if created:
        # Verificar si ya existe un evento de creación para evitar duplicados
        existe_evento = PqrsEvento.objects.filter(
            pqrs=instance,
            tipo_evento=PqrsEvento.EVENTO_CREACION
        ).exists()
        
        if not existe_evento:
            usuario = instance.creado_por
            PqrsEvento.objects.create(
                pqrs=instance,
                usuario=usuario,
                tipo_evento=PqrsEvento.EVENTO_CREACION,
                comentario=f'PQRS creado: {instance.get_tipo_display()}'
            )
        
        # Asignar SLA automáticamente si no tiene uno asignado
        if not instance.fecha_limite_sla:
            try:
                sla_config = PqrsSla.objects.get(
                    tipo=instance.tipo,
                    prioridad=instance.prioridad,
                    activo=True
                )
                instance.fecha_limite_sla = instance.fecha_creacion + timedelta(hours=sla_config.horas_limite)
                # Usar update para evitar recursión infinita
                Pqrs.objects.filter(pk=instance.pk).update(fecha_limite_sla=instance.fecha_limite_sla)
            except PqrsSla.DoesNotExist:
                # Si no hay configuración de SLA, no hacer nada
                pass
