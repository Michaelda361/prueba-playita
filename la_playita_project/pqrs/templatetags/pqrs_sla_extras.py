from django import template
from django.utils import timezone
from datetime import timedelta

register = template.Library()

@register.filter
def tiempo_restante_sla(fecha_limite):
    """Calcula el tiempo restante hasta la fecha límite de SLA"""
    if not fecha_limite:
        return "Sin SLA"
    
    ahora = timezone.now()
    diferencia = fecha_limite - ahora
    
    if diferencia.total_seconds() < 0:
        # Ya venció
        horas_vencidas = abs(diferencia.total_seconds() / 3600)
        if horas_vencidas < 24:
            return f"Vencido hace {int(horas_vencidas)}h"
        else:
            dias_vencidos = int(horas_vencidas / 24)
            return f"Vencido hace {dias_vencidos}d"
    else:
        # Aún no vence
        horas_restantes = diferencia.total_seconds() / 3600
        if horas_restantes < 1:
            minutos = int(diferencia.total_seconds() / 60)
            return f"{minutos} minutos"
        elif horas_restantes < 24:
            return f"{int(horas_restantes)}h {int((horas_restantes % 1) * 60)}min"
        else:
            dias = int(horas_restantes / 24)
            horas = int(horas_restantes % 24)
            return f"{dias}d {horas}h"


@register.filter
def sla_color_class(fecha_limite):
    """Retorna la clase CSS según el estado del SLA"""
    if not fecha_limite:
        return "text-muted"
    
    ahora = timezone.now()
    diferencia = fecha_limite - ahora
    horas_restantes = diferencia.total_seconds() / 3600
    
    if horas_restantes < 0:
        return "text-danger fw-bold"
    elif horas_restantes < 2:
        return "text-danger"
    elif horas_restantes < 6:
        return "text-warning"
    else:
        return "text-success"


@register.filter
def sla_icono(fecha_limite):
    """Retorna el icono apropiado según el estado del SLA"""
    if not fecha_limite:
        return "bi-dash-circle"
    
    ahora = timezone.now()
    diferencia = fecha_limite - ahora
    horas_restantes = diferencia.total_seconds() / 3600
    
    if horas_restantes < 0:
        return "bi-exclamation-triangle-fill"
    elif horas_restantes < 2:
        return "bi-alarm-fill"
    elif horas_restantes < 6:
        return "bi-hourglass-split"
    else:
        return "bi-check-circle-fill"


@register.simple_tag
def sla_porcentaje(fecha_creacion, fecha_limite):
    """Calcula el porcentaje de tiempo transcurrido del SLA"""
    if not fecha_limite or not fecha_creacion:
        return 0
    
    ahora = timezone.now()
    tiempo_total = (fecha_limite - fecha_creacion).total_seconds()
    tiempo_transcurrido = (ahora - fecha_creacion).total_seconds()
    
    if tiempo_total <= 0:
        return 100
    
    porcentaje = (tiempo_transcurrido / tiempo_total) * 100
    return min(100, max(0, int(porcentaje)))


@register.filter
def tiempo_transcurrido(fecha_creacion):
    """Calcula el tiempo transcurrido desde la fecha de creación"""
    if not fecha_creacion:
        return "0h"
    
    ahora = timezone.now()
    diferencia = ahora - fecha_creacion
    
    horas_transcurridas = diferencia.total_seconds() / 3600
    
    if horas_transcurridas < 1:
        minutos = int(diferencia.total_seconds() / 60)
        return f"{minutos}min"
    elif horas_transcurridas < 24:
        horas = int(horas_transcurridas)
        minutos = int((horas_transcurridas % 1) * 60)
        if minutos > 0:
            return f"{horas}h {minutos}min"
        return f"{horas}h"
    else:
        dias = int(horas_transcurridas / 24)
        horas = int(horas_transcurridas % 24)
        return f"{dias}d {horas}h"
