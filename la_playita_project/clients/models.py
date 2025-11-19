from django.db import models
from django.conf import settings  # <--- Esta línea es clave

class Cliente(models.Model):

    nombres = models.CharField(max_length=50)
    apellidos = models.CharField(max_length=50)
    documento = models.CharField(max_length=20, unique=True)
    telefono = models.CharField(max_length=25)
    correo = models.EmailField(max_length=60, unique=True)


    def __str__(self):
        return f"{self.nombres} {self.apellidos}"


    class Meta:
        verbose_name = 'Cliente'
        verbose_name_plural = 'Clientes'
        db_table = 'cliente'
        managed = False



