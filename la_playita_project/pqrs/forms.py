from django import forms
from .models import Pqrs


class PqrsForm(forms.ModelForm):
    class Meta:
        model = Pqrs
        fields = ['tipo', 'descripcion']
        widgets = {
            'tipo': forms.Select(attrs={'class': 'form-select'}),
            'descripcion': forms.Textarea(attrs={'class': 'form-control', 'rows': 5}),
        }


class PqrsUpdateForm(forms.ModelForm):
    observacion_estado = forms.CharField(
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
        label="Observación para el cambio de estado",
        required=False
    )
    nota_interna = forms.CharField(
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
        label="Añadir nota interna",
        required=False
    )

    class Meta:
        model = Pqrs
        fields = ['respuesta']
        widgets = {
            'respuesta': forms.Textarea(attrs={'class': 'form-control', 'rows': 5}),
        }