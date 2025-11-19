from django import forms
from .models import Venta, Pedido, PedidoDetalle
from clients.models import Cliente
from inventory.models import Producto


class VentaForm(forms.ModelForm):
    """Formulario para crear una venta"""
    cliente = forms.ModelChoiceField(
        queryset=Cliente.objects.all(),
        required=False,
        label="Cliente (Opcional)",
        widget=forms.Select(attrs={
            'class': 'form-control',
            'id': 'cliente-select'
        })
    )

    METODO_CHOICES = [
        ('efectivo', 'Efectivo'),
        ('tarjeta_debito', 'Tarjeta Débito'),
        ('tarjeta_credito', 'Tarjeta Crédito'),
        ('transferencia', 'Transferencia'),
        ('cheque', 'Cheque'),
    ]

    # metodo_pago no es campo del modelo Venta (se guarda en tabla `pago`),
    # lo declaramos como campo de formulario independiente.
    metodo_pago = forms.ChoiceField(
        choices=METODO_CHOICES,
        required=True,
        widget=forms.Select(attrs={
            'class': 'form-control',
            'id': 'metodo-pago-select'
        })
    )

    class Meta:
        model = Venta
        # `metodo_pago` no puede ir en Meta.fields porque no es campo del modelo Venta
        fields = ('cliente', 'canal_venta')
        widgets = {
            'canal_venta': forms.Select(attrs={
                'class': 'form-control',
                'id': 'canal-venta-select'
            }),
        }


class ProductoSearchForm(forms.Form):
    """Formulario para buscar productos"""
    busqueda = forms.CharField(
        max_length=100,
        required=False,
        label="Buscar producto",
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Buscar por nombre o código...',
            'id': 'product-search-input'
        })
    )


class CarritoItemForm(forms.Form):
    """Formulario para agregar items al carrito"""
    producto_id = forms.IntegerField(widget=forms.HiddenInput())
    cantidad = forms.IntegerField(
        min_value=1,
        initial=1,
        widget=forms.NumberInput(attrs={
            'class': 'form-control',
            'min': '1'
        })
    )
    lote_id = forms.IntegerField(
        required=False,
        widget=forms.HiddenInput()
    )


class PedidoForm(forms.ModelForm):
    """Formulario para crear un pedido"""
    cliente = forms.ModelChoiceField(
        queryset=Cliente.objects.all(),
        label="Cliente",
        widget=forms.Select(attrs={
            'class': 'form-control'
        })
    )

    class Meta:
        model = Pedido
        fields = ('cliente', 'observaciones')
        widgets = {
            'observaciones': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 4,
                'placeholder': 'Notas adicionales del pedido...'
            }),
        }


class PedidoDetalleForm(forms.ModelForm):
    """Formulario para detalles de pedido"""
    producto = forms.ModelChoiceField(
        queryset=Producto.objects.all(),
        label="Producto",
        widget=forms.Select(attrs={
            'class': 'form-control'
        })
    )

    class Meta:
        model = PedidoDetalle
        fields = ('producto', 'cantidad', 'precio_unitario')
        widgets = {
            'cantidad': forms.NumberInput(attrs={
                'class': 'form-control',
                'min': '1'
            }),
            'precio_unitario': forms.NumberInput(attrs={
                'class': 'form-control',
                'step': '0.01',
                'type': 'number'
            }),
        }
