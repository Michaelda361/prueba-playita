from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Pqrs, PqrsEvento

@receiver(post_save, sender=Pqrs)
def log_pqrs_creation(sender, instance, created, **kwargs):
    if created:
        usuario = instance.usuario
        PqrsEvento.objects.create(
            pqrs=instance,
            usuario=usuario,
            tipo_evento=PqrsEvento.EVENTO_CREACION,
            comentario=f'PQRS creado por {usuario.get_full_name() if usuario else "Sistema"}.'
        )
