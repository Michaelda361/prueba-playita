/**
 * Sistema de Notificaciones para Mesas
 * Gestiona alertas y notificaciones en tiempo real para el sistema de mesas
 */

class NotificacionesMesas {
    constructor() {
        this.alertasActivas = new Map();
        this.tiempoLimiteOcupacion = 120; // 2 horas en minutos
        this.tiempoAlertaLarga = 90; // 1.5 horas en minutos
        this.intervalos = new Map();
        this.inicializar();
    }

    inicializar() {
        this.crearContenedorNotificaciones();
        this.iniciarMonitoreo();
        
        // Verificar permisos de notificaciones del navegador
        if ('Notification' in window && Notification.permission === 'default') {
            this.solicitarPermisoNotificaciones();
        }
    }

    crearContenedorNotificaciones() {
        if (document.getElementById('notificaciones-mesas')) return;

        const contenedor = document.createElement('div');
        contenedor.id = 'notificaciones-mesas';
        contenedor.className = 'position-fixed top-0 end-0 p-3';
        contenedor.style.zIndex = '9999';
        contenedor.style.maxWidth = '350px';
        
        document.body.appendChild(contenedor);
    }

    async solicitarPermisoNotificaciones() {
        try {
            const permission = await Notification.requestPermission();
            if (permission === 'granted') {
                this.mostrarNotificacion('Notificaciones activadas para el sistema de mesas', 'success');
            }
        } catch (error) {
            console.log('Notificaciones no soportadas en este navegador');
        }
    }

    iniciarMonitoreo() {
        // Verificar mesas cada 30 segundos
        setInterval(() => {
            this.verificarEstadoMesas();
        }, 30000);

        // Verificación inicial
        this.verificarEstadoMesas();
    }

    async verificarEstadoMesas() {
        try {
            const response = await fetch('/pos/api/mesas/');
            const data = await response.json();

            if (data.success) {
                this.procesarAlertas(data.mesas);
            }
        } catch (error) {
            console.error('Error al verificar estado de mesas:', error);
        }
    }

    procesarAlertas(mesas) {
        const ahora = new Date();
        
        mesas.forEach(mesa => {
            if (mesa.cuenta_abierta && mesa.fecha_apertura) {
                const tiempoApertura = new Date(mesa.fecha_apertura);
                const minutosOcupada = Math.floor((ahora - tiempoApertura) / (1000 * 60));

                // Alerta por tiempo prolongado
                if (minutosOcupada >= this.tiempoAlertaLarga && !this.alertasActivas.has(`tiempo_${mesa.id}`)) {
                    this.crearAlertaTiempo(mesa, minutosOcupada);
                }

                // Alerta crítica por tiempo excesivo
                if (minutosOcupada >= this.tiempoLimiteOcupacion && !this.alertasActivas.has(`critica_${mesa.id}`)) {
                    this.crearAlertaCritica(mesa, minutosOcupada);
                }

                // Alerta por cuenta alta
                if (mesa.total_cuenta > 100000 && !this.alertasActivas.has(`cuenta_alta_${mesa.id}`)) {
                    this.crearAlertaCuentaAlta(mesa);
                }
            } else {
                // Limpiar alertas si la mesa se cerró
                this.limpiarAlertasMesa(mesa.id);
            }
        });
    }

    crearAlertaTiempo(mesa, minutos) {
        const alertaId = `tiempo_${mesa.id}`;
        const horas = Math.floor(minutos / 60);
        const mins = minutos % 60;
        const tiempoTexto = horas > 0 ? `${horas}h ${mins}m` : `${mins}m`;

        const alerta = {
            id: alertaId,
            tipo: 'warning',
            titulo: `Mesa ${mesa.numero} - Tiempo Prolongado`,
            mensaje: `Ocupada por ${tiempoTexto}. Cliente: ${mesa.cliente ? mesa.cliente.nombre : 'Sin asignar'}`,
            acciones: [
                {
                    texto: 'Ver Cuenta',
                    clase: 'btn-info',
                    accion: () => this.verCuentaMesa(mesa.id)
                },
                {
                    texto: 'Cerrar Mesa',
                    clase: 'btn-warning',
                    accion: () => this.cerrarMesaRapida(mesa.id)
                }
            ],
            persistente: true
        };

        this.mostrarAlerta(alerta);
        this.alertasActivas.set(alertaId, alerta);

        // Notificación del navegador
        this.enviarNotificacionNavegador(
            `Mesa ${mesa.numero} ocupada por ${tiempoTexto}`,
            `Cliente: ${mesa.cliente ? mesa.cliente.nombre : 'Sin asignar'}`
        );
    }

    crearAlertaCritica(mesa, minutos) {
        const alertaId = `critica_${mesa.id}`;
        const horas = Math.floor(minutos / 60);
        const mins = minutos % 60;
        const tiempoTexto = horas > 0 ? `${horas}h ${mins}m` : `${mins}m`;

        const alerta = {
            id: alertaId,
            tipo: 'danger',
            titulo: `🚨 Mesa ${mesa.numero} - ATENCIÓN URGENTE`,
            mensaje: `Ocupada por ${tiempoTexto}. Total: $${mesa.total_cuenta.toFixed(2)}`,
            acciones: [
                {
                    texto: 'Cerrar Ahora',
                    clase: 'btn-danger',
                    accion: () => this.cerrarMesaUrgente(mesa.id)
                },
                {
                    texto: 'Ver Detalles',
                    clase: 'btn-outline-danger',
                    accion: () => this.verCuentaMesa(mesa.id)
                }
            ],
            persistente: true,
            sonido: true
        };

        this.mostrarAlerta(alerta);
        this.alertasActivas.set(alertaId, alerta);

        // Notificación crítica del navegador
        this.enviarNotificacionNavegador(
            `🚨 Mesa ${mesa.numero} - ATENCIÓN URGENTE`,
            `Ocupada por ${tiempoTexto} - Total: $${mesa.total_cuenta.toFixed(2)}`,
            true
        );

        // Reproducir sonido de alerta
        if (alerta.sonido) {
            this.reproducirSonidoAlerta();
        }
    }

    crearAlertaCuentaAlta(mesa) {
        const alertaId = `cuenta_alta_${mesa.id}`;

        const alerta = {
            id: alertaId,
            tipo: 'info',
            titulo: `💰 Mesa ${mesa.numero} - Cuenta Alta`,
            mensaje: `Total: $${mesa.total_cuenta.toFixed(2)}`,
            acciones: [
                {
                    texto: 'Ver Cuenta',
                    clase: 'btn-info',
                    accion: () => this.verCuentaMesa(mesa.id)
                }
            ],
            persistente: false,
            autoClose: 10000
        };

        this.mostrarAlerta(alerta);
        this.alertasActivas.set(alertaId, alerta);
    }

    mostrarAlerta(alerta) {
        const contenedor = document.getElementById('notificaciones-mesas');
        
        const alertaHTML = `
            <div class="alert alert-${alerta.tipo} alert-dismissible fade show shadow-lg mb-3" 
                 id="alerta-${alerta.id}" 
                 style="border-radius: 10px; border: none;">
                <div class="d-flex align-items-start">
                    <div class="flex-grow-1">
                        <h6 class="alert-heading mb-1 fw-bold">${alerta.titulo}</h6>
                        <p class="mb-2 small">${alerta.mensaje}</p>
                        ${alerta.acciones ? `
                            <div class="d-flex gap-2">
                                ${alerta.acciones.map(accion => `
                                    <button type="button" class="btn btn-sm ${accion.clase}" 
                                            onclick="window.notificacionesMesas.ejecutarAccion('${alerta.id}', ${alerta.acciones.indexOf(accion)})">
                                        ${accion.texto}
                                    </button>
                                `).join('')}
                            </div>
                        ` : ''}
                    </div>
                    <button type="button" class="btn-close btn-close-white ms-2" 
                            onclick="window.notificacionesMesas.cerrarAlerta('${alerta.id}')"></button>
                </div>
            </div>
        `;

        contenedor.insertAdjacentHTML('beforeend', alertaHTML);

        // Auto-cerrar si no es persistente
        if (!alerta.persistente) {
            setTimeout(() => {
                this.cerrarAlerta(alerta.id);
            }, alerta.autoClose || 5000);
        }

        // Animación de entrada
        const elemento = document.getElementById(`alerta-${alerta.id}`);
        if (elemento) {
            elemento.style.transform = 'translateX(100%)';
            elemento.style.transition = 'transform 0.3s ease-out';
            setTimeout(() => {
                elemento.style.transform = 'translateX(0)';
            }, 10);
        }
    }

    ejecutarAccion(alertaId, accionIndex) {
        const alerta = this.alertasActivas.get(alertaId);
        if (alerta && alerta.acciones && alerta.acciones[accionIndex]) {
            alerta.acciones[accionIndex].accion();
            this.cerrarAlerta(alertaId);
        }
    }

    cerrarAlerta(alertaId) {
        const elemento = document.getElementById(`alerta-${alertaId}`);
        if (elemento) {
            elemento.style.transform = 'translateX(100%)';
            setTimeout(() => {
                elemento.remove();
            }, 300);
        }
        this.alertasActivas.delete(alertaId);
    }

    limpiarAlertasMesa(mesaId) {
        const alertasAEliminar = [];
        
        this.alertasActivas.forEach((alerta, id) => {
            if (id.includes(`_${mesaId}`)) {
                alertasAEliminar.push(id);
            }
        });

        alertasAEliminar.forEach(id => {
            this.cerrarAlerta(id);
        });
    }

    enviarNotificacionNavegador(titulo, mensaje, urgente = false) {
        if ('Notification' in window && Notification.permission === 'granted') {
            const opciones = {
                body: mensaje,
                icon: '/static/pos/img/mesa-icon.png', // Agregar icono si existe
                badge: '/static/pos/img/badge-icon.png',
                tag: 'mesa-alerta',
                requireInteraction: urgente,
                silent: !urgente
            };

            const notificacion = new Notification(titulo, opciones);
            
            // Auto-cerrar después de 5 segundos si no es urgente
            if (!urgente) {
                setTimeout(() => {
                    notificacion.close();
                }, 5000);
            }

            // Enfocar ventana al hacer clic
            notificacion.onclick = () => {
                window.focus();
                notificacion.close();
            };
        }
    }

    reproducirSonidoAlerta() {
        // Crear sonido de alerta usando Web Audio API
        try {
            const audioContext = new (window.AudioContext || window.webkitAudioContext)();
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);

            oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
            oscillator.frequency.setValueAtTime(600, audioContext.currentTime + 0.1);
            oscillator.frequency.setValueAtTime(800, audioContext.currentTime + 0.2);

            gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);

            oscillator.start(audioContext.currentTime);
            oscillator.stop(audioContext.currentTime + 0.3);
        } catch (error) {
            console.log('No se pudo reproducir el sonido de alerta');
        }
    }

    // Métodos de acción para las alertas
    verCuentaMesa(mesaId) {
        if (window.gestionMesas) {
            window.gestionMesas.verCuenta(mesaId);
        }
    }

    cerrarMesaRapida(mesaId) {
        if (confirm('¿Desea cerrar esta mesa ahora?')) {
            if (window.gestionMesas) {
                window.gestionMesas.cerrarMesa(mesaId);
            }
        }
    }

    cerrarMesaUrgente(mesaId) {
        if (confirm('⚠️ ATENCIÓN: Esta mesa lleva mucho tiempo ocupada.\n¿Desea cerrarla inmediatamente?')) {
            if (window.gestionMesas) {
                window.gestionMesas.cerrarMesa(mesaId);
            }
        }
    }

    // Método para mostrar notificación simple
    mostrarNotificacion(mensaje, tipo = 'info', duracion = 4000) {
        const contenedor = document.getElementById('notificaciones-mesas');
        const id = 'notif_' + Date.now();
        
        const colores = {
            'success': 'alert-success',
            'error': 'alert-danger',
            'warning': 'alert-warning',
            'info': 'alert-info'
        };

        const iconos = {
            'success': 'bi-check-circle-fill',
            'error': 'bi-exclamation-triangle-fill',
            'warning': 'bi-exclamation-circle-fill',
            'info': 'bi-info-circle-fill'
        };

        const notifHTML = `
            <div class="alert ${colores[tipo]} alert-dismissible fade show shadow-sm mb-2" 
                 id="${id}" 
                 style="border-radius: 8px; border: none;">
                <i class="bi ${iconos[tipo]} me-2"></i>
                ${mensaje}
                <button type="button" class="btn-close" onclick="document.getElementById('${id}').remove()"></button>
            </div>
        `;

        contenedor.insertAdjacentHTML('beforeend', notifHTML);

        // Auto-cerrar
        setTimeout(() => {
            const elemento = document.getElementById(id);
            if (elemento) {
                elemento.remove();
            }
        }, duracion);
    }

    // Configuración de alertas
    configurarAlertas(config) {
        if (config.tiempoAlertaLarga) {
            this.tiempoAlertaLarga = config.tiempoAlertaLarga;
        }
        if (config.tiempoLimiteOcupacion) {
            this.tiempoLimiteOcupacion = config.tiempoLimiteOcupacion;
        }
    }

    // Obtener estadísticas de alertas
    obtenerEstadisticas() {
        return {
            alertasActivas: this.alertasActivas.size,
            tiposAlertas: Array.from(this.alertasActivas.values()).reduce((acc, alerta) => {
                acc[alerta.tipo] = (acc[alerta.tipo] || 0) + 1;
                return acc;
            }, {})
        };
    }
}

// Inicializar cuando el documento esté listo
document.addEventListener('DOMContentLoaded', () => {
    window.notificacionesMesas = new NotificacionesMesas();
});

// Exportar para uso en otros módulos
if (typeof module !== 'undefined' && module.exports) {
    module.exports = NotificacionesMesas;
}