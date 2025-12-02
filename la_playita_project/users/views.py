from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.views import LoginView
from django.contrib.auth.decorators import login_required
from django.views.decorators.cache import never_cache
from django.contrib import messages
from django.db.models import Q
from django.core.paginator import Paginator
from .forms import VendedorRegistrationForm
from .models import Usuario, Rol
from .decorators import check_user_role


class CustomLoginView(LoginView):
    template_name = 'registration/login.html'

    def dispatch(self, request, *args, **kwargs):
        if self.request.user.is_authenticated:
            return redirect('dashboard')
        return super().dispatch(request, *args, **kwargs)


@never_cache
@login_required
def login_redirect_view(request):
    return redirect('dashboard')


def register_view(request):
    if request.method == 'POST':
        form = VendedorRegistrationForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, '¡Registro exitoso! Ahora puedes iniciar sesión.')
            return redirect('users:login')
    else:
        form = VendedorRegistrationForm()
    return render(request, 'registration/register.html', {'form': form})


@login_required
@check_user_role(allowed_roles=['Administrador'])
def listar_usuarios(request):
    """Vista para listar todos los usuarios con filtros"""
    usuarios = Usuario.objects.select_related('rol').all()
    
    # Filtros
    busqueda = request.GET.get('busqueda', '')
    rol_filtro = request.GET.get('rol', '')
    estado_filtro = request.GET.get('estado', '')
    
    if busqueda:
        usuarios = usuarios.filter(
            Q(first_name__icontains=busqueda) |
            Q(last_name__icontains=busqueda) |
            Q(username__icontains=busqueda) |
            Q(email__icontains=busqueda)
        )
    
    if rol_filtro:
        usuarios = usuarios.filter(rol_id=rol_filtro)
    
    if estado_filtro:
        usuarios = usuarios.filter(estado=estado_filtro)
    
    usuarios = usuarios.order_by('-date_joined')
    
    # Paginación
    paginator = Paginator(usuarios, 15)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    # Obtener roles para el filtro
    roles = Rol.objects.all()
    
    context = {
        'page_obj': page_obj,
        'roles': roles,
        'busqueda': busqueda,
        'rol_filtro': rol_filtro,
        'estado_filtro': estado_filtro,
    }
    
    return render(request, 'users/listar_usuarios.html', context)


@login_required
@check_user_role(allowed_roles=['Administrador'])
def crear_usuario(request):
    """Vista para crear un nuevo usuario"""
    if request.method == 'POST':
        form = VendedorRegistrationForm(request.POST)
        if form.is_valid():
            usuario = form.save()
            messages.success(request, f'Usuario {usuario.get_full_name()} creado exitosamente.')
            return redirect('users:listar_usuarios')
    else:
        form = VendedorRegistrationForm()
    
    return render(request, 'users/crear_usuario.html', {'form': form})


@login_required
@check_user_role(allowed_roles=['Administrador'])
def editar_usuario(request, usuario_id):
    """Vista para editar un usuario existente"""
    usuario = get_object_or_404(Usuario, id=usuario_id)
    
    if request.method == 'POST':
        # Actualizar datos básicos
        usuario.first_name = request.POST.get('first_name')
        usuario.last_name = request.POST.get('last_name')
        usuario.email = request.POST.get('email')
        usuario.telefono = request.POST.get('telefono', '')
        
        # Actualizar rol
        rol_id = request.POST.get('rol')
        if rol_id:
            usuario.rol_id = rol_id
        
        usuario.save()
        messages.success(request, f'Usuario {usuario.get_full_name()} actualizado exitosamente.')
        return redirect('users:listar_usuarios')
    
    roles = Rol.objects.all()
    context = {
        'usuario': usuario,
        'roles': roles,
    }
    
    return render(request, 'users/editar_usuario.html', context)


@login_required
@check_user_role(allowed_roles=['Administrador'])
def cambiar_estado_usuario(request, usuario_id):
    """Vista para activar/desactivar un usuario"""
    usuario = get_object_or_404(Usuario, id=usuario_id)
    
    if usuario.estado == 'activo':
        usuario.estado = 'inactivo'
        messages.success(request, f'Usuario {usuario.get_full_name()} desactivado.')
    else:
        usuario.estado = 'activo'
        messages.success(request, f'Usuario {usuario.get_full_name()} activado.')
    
    usuario.save()
    return redirect('users:listar_usuarios')


@login_required
@check_user_role(allowed_roles=['Administrador'])
def cambiar_contrasena_usuario(request, usuario_id):
    """Vista para cambiar la contraseña de un usuario"""
    usuario = get_object_or_404(Usuario, id=usuario_id)
    
    if request.method == 'POST':
        nueva_contrasena = request.POST.get('nueva_contrasena')
        confirmar_contrasena = request.POST.get('confirmar_contrasena')
        
        if nueva_contrasena and nueva_contrasena == confirmar_contrasena:
            usuario.set_password(nueva_contrasena)
            usuario.save()
            messages.success(request, f'Contraseña de {usuario.get_full_name()} actualizada exitosamente.')
            return redirect('users:listar_usuarios')
        else:
            messages.error(request, 'Las contraseñas no coinciden.')
    
    return render(request, 'users/cambiar_contrasena.html', {'usuario': usuario})
