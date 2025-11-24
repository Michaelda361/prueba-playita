from django.apps import AppConfig


class PqrsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'pqrs'

    def ready(self):
        import pqrs.signals
