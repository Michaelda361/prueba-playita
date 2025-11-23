from django import template

register = template.Library()

@register.filter
def calculate_total_pending_value(reabastecimiento):
    """
    Calcula el valor total pendiente de un reabastecimiento.
    """
    total_pending = 0
    for detalle in reabastecimiento.reabastecimientodetalle_set.all():
        total_pending += (detalle.cantidad - detalle.cantidad_recibida) * detalle.costo_unitario
    return total_pending

@register.filter
def subtract(value, arg):
    """
    Resta el argumento (arg) del valor (value).
    """
    try:
        return int(value) - int(arg)
    except (ValueError, TypeError):
        try:
            return float(value) - float(arg)
        except (ValueError, TypeError):
            return ''