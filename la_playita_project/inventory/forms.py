from django import forms
from django.core.validators import MinValueValidator
from .models import Producto, Lote, Categoria
from suppliers.models import Reabastecimiento, ReabastecimientoDetalle # Ensure Reabastecimiento is imported
from datetime import date
from django.forms import inlineformset_factory


class ProductoForm(forms.ModelForm):
    precio_unitario = forms.DecimalField(
        max_digits=12, 
        decimal_places=0,
        validators=[MinValueValidator(0)],
        widget=forms.NumberInput(attrs={'class': 'form-control', 'step': '1'})
    )
    stock_minimo = forms.IntegerField(
        validators=[MinValueValidator(0)],
        widget=forms.NumberInput(attrs={'class': 'form-control'})
    )

    class Meta:
        model = Producto
        fields = ['nombre', 'precio_unitario', 'descripcion', 'stock_minimo', 'categoria']
        widgets = {
            'nombre': forms.TextInput(attrs={'class': 'form-control'}),
            'descripcion': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'categoria': forms.Select(attrs={'class': 'form-select'}),
        }

class CategoriaForm(forms.ModelForm):
    class Meta:
        model = Categoria
        fields = ['nombre']
        widgets = {
            'nombre': forms.TextInput(attrs={'class': 'form-control'}),
        }

class LoteForm(forms.ModelForm):
    cantidad_disponible = forms.IntegerField(
        label="Cantidad",
        validators=[MinValueValidator(1)],
        widget=forms.NumberInput(attrs={'class': 'form-control'})
    )
    costo_unitario_lote = forms.DecimalField(
        label="Costo por Unidad",
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(0)],
        widget=forms.NumberInput(attrs={'class': 'form-control', 'step': '1'})
    )

    class Meta:
        model = Lote
        fields = [
            'producto', 'numero_lote', 'cantidad_disponible', 'costo_unitario_lote', 
            'fecha_caducidad'
        ]
        widgets = {
            'producto': forms.Select(attrs={'class': 'form-select'}),
            'numero_lote': forms.TextInput(attrs={'class': 'form-control'}),
            'fecha_caducidad': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
        }

    def clean_fecha_caducidad(self):
        fecha_caducidad = self.cleaned_data.get('fecha_caducidad')
        if fecha_caducidad and fecha_caducidad < date.today():
            raise forms.ValidationError("La fecha de caducidad no puede ser anterior a la fecha actual.")
        return fecha_caducidad


class ReabastecimientoForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        initial_creation = kwargs.pop('initial_creation', False)
        super().__init__(*args, **kwargs)
        if initial_creation:
            # Restrict choices for 'estado' when creating a new restock
            self.fields['estado'].choices = [
                (Reabastecimiento.ESTADO_SOLICITADO, Reabastecimiento.ESTADO_SOLICITADO)
            ]
            self.fields['estado'].initial = Reabastecimiento.ESTADO_SOLICITADO # Set default to Solicitado
            self.fields['estado'].widget.attrs['disabled'] = True # Disable it to prevent modification


    class Meta:
        model = Reabastecimiento
        fields = ['proveedor', 'forma_pago', 'observaciones', 'estado']
        widgets = {
            'proveedor': forms.Select(attrs={'class': 'form-select'}),
            'forma_pago': forms.Select(attrs={'class': 'form-select'}),
            'observaciones': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'estado': forms.Select(attrs={'class': 'form-select'}),
        }


class ReabastecimientoDetalleForm(forms.ModelForm):
    class Meta:
        model = ReabastecimientoDetalle
        fields = ['producto', 'cantidad', 'costo_unitario', 'fecha_caducidad']
        widgets = {
            'producto': forms.Select(attrs={'class': 'form-select'}),
            'cantidad': forms.NumberInput(attrs={'class': 'form-control'}),
            'costo_unitario': forms.NumberInput(attrs={'class': 'form-control', 'step': '1'}),
            'fecha_caducidad': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
        }


# Un formset para múltiples líneas de detalle en el formulario de reabastecimiento
ReabastecimientoDetalleFormSet = inlineformset_factory(
    Reabastecimiento,
    ReabastecimientoDetalle,
    form=ReabastecimientoDetalleForm,
    extra=1,
    can_delete=True
)