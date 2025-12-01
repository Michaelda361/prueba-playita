/**
 * Sistema de Carrito de Compras para el POS
 * Gestiona la lógica del carrito, búsqueda de productos y cálculos
 */

class CarritoPOS {
    constructor() {
        this.carrito = [];
        this.impuesto = 0.19; // 19%
        this.inicializar();
    }

    inicializar() {
        this.cargarCarritoDelLocalStorage();
        this.configurarEventos();
        this.actualizarVistaCarrito();
        this.actualizarTodosLosStocksVisuales(); // Actualizar stocks al cargar
    }

    configurarEventos() {
        // Búsqueda de productos
        const botonBusqueda = document.getElementById('product-search-button');
        const inputBusqueda = document.getElementById('product-search-input');

        if (botonBusqueda) {
            botonBusqueda.addEventListener('click', () => this.buscarProductos());
        }

        if (inputBusqueda) {
            inputBusqueda.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.buscarProductos();
                }
            });
        }

        // Botón de procesar venta
        const botonProcesar = document.querySelector('button.btn-success');
        if (botonProcesar && botonProcesar.textContent.includes('Procesar')) {
            botonProcesar.addEventListener('click', () => this.mostrarFormularioPago());
        }

        // Botón de cancelar venta
        const botonCancelar = document.querySelector('button.btn-outline-danger');
        if (botonCancelar && botonCancelar.textContent.includes('Cancelar')) {
            botonCancelar.addEventListener('click', () => this.vaciarCarrito());
        }
    }

    async buscarProductos() {
        const inputBusqueda = document.getElementById('product-search-input');
        const query = inputBusqueda.value.trim();

        if (!query) {
            this.cargarTodosLosProductos();
            return;
        }

        try {
            const response = await fetch(`/pos/api/buscar-productos/?q=${encodeURIComponent(query)}`);
            const datos = await response.json();

            if (datos.productos) {
                this.mostrarProductos(datos.productos);
            }
        } catch (error) {
            console.error('Error al buscar productos:', error);
            alert('Error al buscar productos');
        }
    }

    async cargarTodosLosProductos() {
        try {
            const inputBusqueda = document.getElementById('product-search-input');
            inputBusqueda.value = '';

            // Volver a la vista de categorías
            window.location.href = window.location.pathname;
        } catch (error) {
            console.error('Error al cargar productos:', error);
        }
    }

    mostrarProductos(productos) {
        const contenedorProductos = document.getElementById('product-list');
        contenedorProductos.innerHTML = '';

        if (productos.length === 0) {
            contenedorProductos.innerHTML = '<p class="col-12 text-center text-muted">No se encontraron productos</p>';
            return;
        }

        productos.forEach(producto => {
            const colDiv = document.createElement('div');
            colDiv.className = 'col';

            const cartaHTML = `
                <div class="card h-100 product-card">
                    <div class="card-body">
                        <h5 class="card-title">${this.escaparHTML(producto.nombre)}</h5>
                        <p class="card-text text-muted">${this.escaparHTML(producto.categoria)}</p>
                        ${producto.descripcion ? `<p class="card-text small">${this.escaparHTML(producto.descripcion)}</p>` : ''}
                        <p class="card-text fw-bold">$${this.formatearMoneda(producto.precio)}</p>
                        <p class="card-text small">
                            <span class="badge bg-info">Stock: ${producto.stock}</span>
                        </p>
                        <button class="btn btn-sm btn-primary agregar-producto-btn" data-producto-id="${producto.id}" data-nombre="${this.escaparHTML(producto.nombre)}" data-precio="${producto.precio}">
                            <i class="bi bi-plus-circle me-1"></i>Agregar
                        </button>
                    </div>
                </div>
            `;

            colDiv.innerHTML = cartaHTML;
            contenedorProductos.appendChild(colDiv);

            // Agregar evento al botón de agregar
            const btnAgregar = colDiv.querySelector('.agregar-producto-btn');
            btnAgregar.addEventListener('click', () => this.abrirModalProducto(producto.id));
        });
    }

    async abrirModalProducto(productoId) {
        try {
            const response = await fetch(`/pos/api/producto/${productoId}/`);
            const producto = await response.json();

            // Si hay un error al obtener el producto, mostrar notificación y salir.
            if (producto.error) {
                this.mostrarNotificacion('Error: ' + producto.error, 'danger');
                return;
            }

            // Validar si hay lotes disponibles.
            if (!producto.lotes || producto.lotes.length === 0) {
                this.mostrarNotificacion(`El producto "${this.escaparHTML(producto.nombre)}" no tiene lotes disponibles.`, 'warning');
                return;
            }

            // Filtrar lotes con stock disponible
            const lotesDisponibles = producto.lotes.filter(lote => lote.cantidad > 0);

            if (lotesDisponibles.length === 0) {
                this.mostrarNotificacion(`No hay stock disponible para "${this.escaparHTML(producto.nombre)}".`, 'danger');
                return;
            }

            // Mostrar modal para seleccionar lote y cantidad
            this.mostrarModalSeleccionLote(producto, lotesDisponibles);

        } catch (error) {
            console.error('Error al obtener producto:', error);
            this.mostrarNotificacion('Error al obtener detalles del producto.', 'danger');
        }
    }

    mostrarModalSeleccionLote(producto, lotes) {
        // Calcular stock total disponible
        const stockTotal = lotes.reduce((sum, lote) => sum + lote.cantidad, 0);

        const modalHTML = `
            <div class="modal fade" id="modalSeleccionLote" tabindex="-1">
                <div class="modal-dialog modal-dialog-centered">
                    <div class="modal-content">
                        <div class="modal-header bg-primary text-white">
                            <h5 class="modal-title">
                                <i class="bi bi-cart-plus me-2"></i>${this.escaparHTML(producto.nombre)}
                            </h5>
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="text-center mb-4">
                                <div class="display-6 text-primary mb-2">$${this.formatearMoneda(producto.precio)}</div>
                                <p class="text-muted mb-0">
                                    <i class="bi bi-box-seam me-1"></i>
                                    Disponible: <strong>${stockTotal}</strong> unidades
                                </p>
                            </div>
                            
                            <div class="mb-4">
                                <label for="input-cantidad" class="form-label fw-bold text-center d-block mb-3">
                                    ¿Cuántas unidades deseas agregar?
                                </label>
                                <div class="d-flex gap-2 mb-3">
                                    <button class="btn btn-outline-primary flex-fill" type="button" id="btn-cantidad-1">
                                        1
                                    </button>
                                    <button class="btn btn-outline-primary flex-fill" type="button" id="btn-cantidad-5">
                                        5
                                    </button>
                                    <button class="btn btn-outline-primary flex-fill" type="button" id="btn-cantidad-10">
                                        10
                                    </button>
                                    <button class="btn btn-outline-success flex-fill" type="button" id="btn-cantidad-max">
                                        <i class="bi bi-infinity"></i> Todo
                                    </button>
                                </div>
                                <div class="input-group input-group-lg">
                                    <button class="btn btn-outline-secondary" type="button" id="btn-decrementar">
                                        <i class="bi bi-dash-lg"></i>
                                    </button>
                                    <input type="number" id="input-cantidad" class="form-control text-center fw-bold fs-3" 
                                           value="1" min="1" max="${stockTotal}">
                                    <button class="btn btn-outline-secondary" type="button" id="btn-incrementar">
                                        <i class="bi bi-plus-lg"></i>
                                    </button>
                                </div>
                            </div>
                            
                            <div class="alert alert-success mb-0">
                                <div class="d-flex justify-content-between align-items-center">
                                    <span class="fw-bold">Subtotal:</span>
                                    <span class="fs-3 fw-bold">$<span id="subtotal-modal">${this.formatearMoneda(producto.precio)}</span></span>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                                Cancelar
                            </button>
                            <button type="button" class="btn btn-success btn-lg px-5" id="btn-agregar-carrito">
                                <i class="bi bi-cart-plus me-2"></i>Agregar
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Remover modal anterior si existe
        const modalAnterior = document.getElementById('modalSeleccionLote');
        if (modalAnterior) {
            modalAnterior.remove();
        }

        // Insertar nuevo modal
        document.body.insertAdjacentHTML('beforeend', modalHTML);

        // Referencias a elementos
        const inputCantidad = document.getElementById('input-cantidad');
        const subtotalModal = document.getElementById('subtotal-modal');
        const btnIncrementar = document.getElementById('btn-incrementar');
        const btnDecrementar = document.getElementById('btn-decrementar');
        const btnAgregar = document.getElementById('btn-agregar-carrito');
        const btnCantidad1 = document.getElementById('btn-cantidad-1');
        const btnCantidad5 = document.getElementById('btn-cantidad-5');
        const btnCantidad10 = document.getElementById('btn-cantidad-10');
        const btnCantidadMax = document.getElementById('btn-cantidad-max');

        const actualizarSubtotal = () => {
            const cantidad = parseInt(inputCantidad.value) || 1;
            const subtotal = producto.precio * cantidad;
            subtotalModal.textContent = this.formatearMoneda(subtotal);
        };

        const setCantidad = (valor) => {
            const max = parseInt(inputCantidad.max);
            const min = parseInt(inputCantidad.min);
            let nuevaCantidad = parseInt(valor);
            
            if (nuevaCantidad > max) nuevaCantidad = max;
            if (nuevaCantidad < min) nuevaCantidad = min;
            
            inputCantidad.value = nuevaCantidad;
            actualizarSubtotal();
        };

        // Eventos botones rápidos
        btnCantidad1.addEventListener('click', () => setCantidad(1));
        btnCantidad5.addEventListener('click', () => setCantidad(5));
        btnCantidad10.addEventListener('click', () => setCantidad(10));
        btnCantidadMax.addEventListener('click', () => setCantidad(stockTotal));

        // Eventos
        inputCantidad.addEventListener('input', () => {
            const max = parseInt(inputCantidad.max);
            const min = parseInt(inputCantidad.min);
            let valor = parseInt(inputCantidad.value);
            
            if (valor > max) inputCantidad.value = max;
            if (valor < min) inputCantidad.value = min;
            
            actualizarSubtotal();
        });

        btnIncrementar.addEventListener('click', () => {
            const max = parseInt(inputCantidad.max);
            const actual = parseInt(inputCantidad.value);
            if (actual < max) {
                inputCantidad.value = actual + 1;
                actualizarSubtotal();
            }
        });

        btnDecrementar.addEventListener('click', () => {
            const min = parseInt(inputCantidad.min);
            const actual = parseInt(inputCantidad.value);
            if (actual > min) {
                inputCantidad.value = actual - 1;
                actualizarSubtotal();
            }
        });

        btnAgregar.addEventListener('click', () => {
            const cantidadTotal = parseInt(inputCantidad.value);
            
            // Distribuir la cantidad entre los lotes disponibles (FIFO)
            this.agregarProductoMultiLote(producto, lotes, cantidadTotal);
            
            // Cerrar modal
            const modal = bootstrap.Modal.getInstance(document.getElementById('modalSeleccionLote'));
            modal.hide();
        });

        // Mostrar modal
        const modal = new bootstrap.Modal(document.getElementById('modalSeleccionLote'));
        modal.show();
    }

    /**
     * Agrega un producto al carrito distribuyendo la cantidad entre múltiples lotes (FIFO)
     */
    agregarProductoMultiLote(producto, lotes, cantidadTotal) {
        let cantidadRestante = cantidadTotal;
        let lotesUsados = 0;

        // Ordenar lotes por fecha de caducidad (FIFO - primero los que vencen antes)
        const lotesOrdenados = [...lotes].sort((a, b) => {
            if (a.fecha_caducidad === 'N/A') return 1;
            if (b.fecha_caducidad === 'N/A') return -1;
            return new Date(a.fecha_caducidad) - new Date(b.fecha_caducidad);
        });

        // Distribuir la cantidad entre los lotes
        for (const lote of lotesOrdenados) {
            if (cantidadRestante <= 0) break;

            const cantidadDeLote = Math.min(cantidadRestante, lote.cantidad);
            
            this.agregarAlCarrito(
                producto.id,
                producto.nombre,
                producto.precio,
                cantidadDeLote,
                lote.id,
                lote.cantidad
            );

            cantidadRestante -= cantidadDeLote;
            lotesUsados++;
        }

        // Mostrar notificación informativa
        if (lotesUsados > 1) {
            this.mostrarNotificacion(
                `${producto.nombre}: ${cantidadTotal} unidades agregadas usando ${lotesUsados} lotes`,
                'success'
            );
        }
    }

    agregarAlCarrito(productoId, nombre, precio, cantidad, loteId, maxStock) {
        // Verificar si el producto ya está en el carrito con el mismo lote
        const itemExistente = this.carrito.find(item => item.producto_id === productoId && item.lote_id === loteId);

        if (itemExistente) {
            // Actualizar el stock máximo con la información más reciente
            itemExistente.max_stock = maxStock;

            if (itemExistente.cantidad + cantidad > itemExistente.max_stock) {
                this.mostrarNotificacion(`No puedes agregar más. Stock máximo disponible: ${itemExistente.max_stock}`, 'warning');
                return;
            }
            itemExistente.cantidad += cantidad;
        } else {
            if (cantidad > maxStock) {
                this.mostrarNotificacion(`Stock insuficiente. Disponible: ${maxStock}`, 'warning');
                return;
            }
            this.carrito.push({
                producto_id: productoId,
                nombre: nombre,
                precio: parseFloat(precio),
                cantidad: cantidad,
                lote_id: loteId,
                max_stock: maxStock
            });
        }

        this.guardarCarritoEnLocalStorage();
        this.actualizarVistaCarrito();
        this.actualizarStockVisual(productoId); // Actualizar stock visual
        this.mostrarNotificacion(`${nombre} agregado al carrito`);
    }

    removerDelCarrito(index) {
        const item = this.carrito[index];
        const productoId = item.producto_id;
        
        this.carrito.splice(index, 1);
        this.guardarCarritoEnLocalStorage();
        this.actualizarVistaCarrito();
        this.actualizarStockVisual(productoId); // Actualizar stock visual
    }

    actualizarCantidadCarrito(index, nuevaCantidad) {
        nuevaCantidad = parseInt(nuevaCantidad);
        const item = this.carrito[index];
        const productoId = item.producto_id;

        if (nuevaCantidad <= 0) {
            this.removerDelCarrito(index);
            return;
        }

        if (item.max_stock && nuevaCantidad > item.max_stock) {
            this.mostrarNotificacion(`Solo hay ${item.max_stock} unidades disponibles de este lote.`, 'warning');
            nuevaCantidad = item.max_stock;
            // Forzar actualización visual del input si el usuario escribió un número mayor
            const input = document.querySelector(`input[data-index="${index}"]`);
            if (input) input.value = nuevaCantidad;
        }

        this.carrito[index].cantidad = nuevaCantidad;
        this.guardarCarritoEnLocalStorage();
        this.actualizarVistaCarrito();
        this.actualizarStockVisual(productoId); // Actualizar stock visual
    }

    actualizarVistaCarrito() {
        const contenedorItems = document.getElementById('cart-items');
        const subtotalSpan = document.getElementById('cart-subtotal');
        const impuestoSpan = document.getElementById('cart-tax');
        const totalSpan = document.getElementById('cart-total');

        contenedorItems.innerHTML = '';

        if (this.carrito.length === 0) {
            contenedorItems.innerHTML = '<tr><td colspan="4" class="text-center text-muted">El carrito está vacío</td></tr>';
            subtotalSpan.textContent = '$0.00';
            impuestoSpan.textContent = '$0.00';
            totalSpan.textContent = '$0.00';
            return;
        }

        let subtotal = 0;

        this.carrito.forEach((item, index) => {
            const subtotalItem = item.precio * item.cantidad;
            subtotal += subtotalItem;

            const fila = document.createElement('tr');
            fila.innerHTML = `
                <td>
                    <div>
                        <strong>${this.escaparHTML(item.nombre)}</strong>
                        <br>
                        <small class="text-muted">Lote ID: ${item.lote_id}</small>
                    </div>
                </td>
                <td class="text-end">
                    <input type="number" class="form-control form-control-sm" style="width: 70px;" value="${item.cantidad}" min="1" data-index="${index}">
                </td>
                <td class="text-end">
                    $${this.formatearMoneda(item.precio)} x ${item.cantidad} = <br>
                    <strong>$${this.formatearMoneda(subtotalItem)}</strong>
                </td>
                <td class="text-center">
                    <button class="btn btn-sm btn-outline-danger eliminar-btn" data-index="${index}" title="Eliminar">
                        <i class="bi bi-trash"></i>
                    </button>
                </td>
            `;

            contenedorItems.appendChild(fila);

            // Eventos
            const inputCantidad = fila.querySelector('input[type="number"]');
            inputCantidad.addEventListener('change', (e) => {
                this.actualizarCantidadCarrito(index, e.target.value);
            });

            const btnEliminar = fila.querySelector('.eliminar-btn');
            btnEliminar.addEventListener('click', () => {
                this.removerDelCarrito(index);
            });
        });

        // Calcular impuesto y total
        const impuesto = subtotal * this.impuesto;
        const total = subtotal + impuesto;

        subtotalSpan.textContent = `$${this.formatearMoneda(subtotal)}`;
        impuestoSpan.textContent = `$${this.formatearMoneda(impuesto)}`;
        totalSpan.textContent = `$${this.formatearMoneda(total)}`;
    }

    async mostrarFormularioPago() {
        if (this.carrito.length === 0) {
            alert('El carrito está vacío');
            return;
        }

        // Obtener el cliente seleccionado del selector principal
        const clienteSelectPrincipal = document.getElementById('cliente-select');
        const clienteSeleccionado = clienteSelectPrincipal ? clienteSelectPrincipal.value : '';
        
        console.log('Cliente seleccionado en el selector principal:', clienteSeleccionado);

        // Obtener clientes desde la API
        let clientesHTML = '<option value="">Consumidor Final</option>';

        try {
            console.log('Obteniendo clientes...');
            const response = await fetch('/pos/api/obtener-clientes/');
            console.log('Response status:', response.status);

            if (response.ok) {
                const data = await response.json();
                console.log('Datos recibidos:', data);

                if (data.success && data.clientes && data.clientes.length > 0) {
                    // Construir opciones de clientes
                    data.clientes.forEach(cliente => {
                        const selected = clienteSeleccionado && cliente.id == clienteSeleccionado ? 'selected' : '';
                        clientesHTML += `<option value="${cliente.id}" ${selected}>${this.escaparHTML(cliente.nombre)}</option>`;
                    });
                    console.log(`Se cargaron ${data.clientes.length} clientes`);
                }
            } else {
                console.error('Error en respuesta:', response.statusText);
            }
        } catch (error) {
            console.error('Error al obtener clientes:', error);
        }

        // Crear el modal con los clientes obtenidos
        const formularioHTML = `
            <div class="modal fade" id="modalPago" tabindex="-1">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Completar Venta</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <form id="form-pago">
                                <div class="mb-3">
                                    <label for="cliente-pago" class="form-label">Cliente (Opcional):</label>
                                    <select id="cliente-pago" class="form-control">
                                        ${clientesHTML}
                                    </select>
                                </div>

                                <div class="mb-3">
                                    <label for="metodo-pago" class="form-label">Método de Pago:</label>
                                    <select id="metodo-pago" class="form-control" required>
                                        <option value="">-- Seleccione --</option>
                                        <option value="efectivo">Efectivo</option>
                                        <option value="tarjeta_debito">Tarjeta Débito</option>
                                        <option value="tarjeta_credito">Tarjeta Crédito</option>
                                        <option value="transferencia">Transferencia</option>
                                        <option value="cheque">Cheque</option>
                                    </select>
                                </div>

                                <div class="mb-3">
                                    <label for="canal-venta" class="form-label">Canal de Venta:</label>
                                    <select id="canal-venta" class="form-control" required>
                                        <option value="">-- Seleccione --</option>
                                        <option value="mostrador">Mostrador</option>
                                        <option value="telefono">Teléfono</option>
                                        <option value="online">Online</option>
                                        <option value="delivery">Delivery</option>
                                    </select>
                                </div>

                                <div class="alert alert-info">
                                    <p><strong>Subtotal:</strong> $<span id="modal-subtotal">0.00</span></p>
                                    <p><strong>Impuestos (19%):</strong> $<span id="modal-impuesto">0.00</span></p>
                                    <p class="fs-5"><strong>Total a Pagar:</strong> $<span id="modal-total">0.00</span></p>
                                </div>
                            </form>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
                            <button type="button" class="btn btn-success" id="btn-confirmar-venta">
                                <i class="bi bi-check-circle me-1"></i>Confirmar Venta
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Remover modal anterior si existe
        const modalAnterior = document.getElementById('modalPago');
        if (modalAnterior) {
            modalAnterior.remove();
        }

        // Insertar nuevo modal
        document.body.insertAdjacentHTML('beforeend', formularioHTML);

        // Calcular y mostrar totales
        let subtotal = 0;
        this.carrito.forEach(item => {
            subtotal += item.precio * item.cantidad;
        });
        const impuesto = subtotal * this.impuesto;
        const total = subtotal + impuesto;

        document.getElementById('modal-subtotal').textContent = this.formatearMoneda(subtotal);
        document.getElementById('modal-impuesto').textContent = this.formatearMoneda(impuesto);
        document.getElementById('modal-total').textContent = this.formatearMoneda(total);

        // Mostrar modal
        const modal = new bootstrap.Modal(document.getElementById('modalPago'));

        // Agregar evento al botón de confirmar
        document.getElementById('btn-confirmar-venta').addEventListener('click', () => {
            this.confirmarVenta();
            modal.hide();
        });

        modal.show();
    }

    async confirmarVenta() {
        const clienteIdSeleccionado = document.getElementById('cliente-pago').value;
        // Si no se selecciona cliente, usar Consumidor Final (ID 1)
        const clienteId = clienteIdSeleccionado ? parseInt(clienteIdSeleccionado) : 1;
        const metodoPago = document.getElementById('metodo-pago').value;
        const canalVenta = document.getElementById('canal-venta').value;

        console.log('Cliente ID para la venta:', clienteId);

        // Validar que los campos requeridos estén completos
        if (!metodoPago || metodoPago.trim() === '') {
            alert('Por favor seleccione un Método de Pago');
            return;
        }
        if (!canalVenta || canalVenta.trim() === '') {
            alert('Por favor seleccione un Canal de Venta');
            return;
        }

        // Mostrar indicador de carga
        const btnConfirmar = document.getElementById('btn-confirmar-venta');
        const textoOriginal = btnConfirmar.innerHTML;
        btnConfirmar.disabled = true;
        btnConfirmar.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Procesando...';

        try {
            const response = await fetch('/pos/api/procesar-venta/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.obtenerCSRFToken(),
                },
                body: JSON.stringify({
                    cliente_id: clienteId,
                    metodo_pago: metodoPago,
                    canal_venta: canalVenta,
                    items: this.carrito
                })
            });

            const datos = await response.json();

            if (response.ok && datos.success) {
                let mensaje = datos.mensaje;
                if (datos.puntos_ganados && datos.puntos_ganados > 0) {
                    mensaje += ` ¡Has ganado ${datos.puntos_ganados.toFixed(2)} puntos!`;
                }
                this.mostrarNotificacion(mensaje, 'success');
                this.vaciarCarrito();
                this.redirigirAVentaDetalle(datos.venta_id);
            } else {
                alert('Error: ' + (datos.error || 'Error desconocido'));
            }
        } catch (error) {
            console.error('Error al procesar venta:', error);
            alert('Error al procesar la venta');
        } finally {
            btnConfirmar.disabled = false;
            btnConfirmar.innerHTML = textoOriginal;
        }
    }

    redirigirAVentaDetalle(ventaId) {
        setTimeout(() => {
            window.location.href = `/pos/venta/${ventaId}/`;
        }, 1500);
    }

    vaciarCarrito() {
        // Guardar IDs de productos antes de vaciar
        const productosIds = [...new Set(this.carrito.map(item => item.producto_id))];
        
        this.carrito = [];
        this.guardarCarritoEnLocalStorage();
        this.actualizarVistaCarrito();
        
        // Actualizar stock visual de todos los productos que estaban en el carrito
        productosIds.forEach(productoId => this.actualizarStockVisual(productoId));
    }

    /**
     * Actualiza todos los stocks visuales de productos que están en el carrito
     */
    actualizarTodosLosStocksVisuales() {
        // Obtener IDs únicos de productos en el carrito
        const productosIds = [...new Set(this.carrito.map(item => item.producto_id))];
        
        // Actualizar cada uno
        productosIds.forEach(productoId => this.actualizarStockVisual(productoId));
    }

    /**
     * Actualiza el stock visual mostrado en la tarjeta del producto
     * Calcula: Stock Real - Cantidad en Carrito = Stock Disponible
     */
    actualizarStockVisual(productoId) {
        // Buscar todos los items del producto en el carrito (puede haber múltiples lotes)
        const itemsEnCarrito = this.carrito.filter(item => item.producto_id === productoId);
        
        // Calcular cantidad total en carrito para este producto
        const cantidadEnCarrito = itemsEnCarrito.reduce((total, item) => total + item.cantidad, 0);
        
        // Buscar la tarjeta del producto en el DOM
        const btnProducto = document.querySelector(`button[data-producto-id="${productoId}"]`);
        if (!btnProducto) return;
        
        const tarjetaProducto = btnProducto.closest('.product-card');
        if (!tarjetaProducto) return;
        
        const badgeStock = tarjetaProducto.querySelector('.badge-stock');
        if (!badgeStock) return;
        
        // Obtener el stock real del atributo data o del texto actual
        let stockReal = parseInt(badgeStock.dataset.stockReal);
        
        // Si no existe el atributo, guardarlo la primera vez
        if (isNaN(stockReal)) {
            const textoStock = badgeStock.textContent.match(/\d+/);
            stockReal = textoStock ? parseInt(textoStock[0]) : 0;
            badgeStock.dataset.stockReal = stockReal;
        }
        
        // Calcular stock disponible
        const stockDisponible = stockReal - cantidadEnCarrito;
        
        // Actualizar el texto del badge
        if (cantidadEnCarrito > 0) {
            badgeStock.innerHTML = `Stock: ${stockDisponible} <small>(${cantidadEnCarrito} en carrito)</small>`;
            badgeStock.classList.remove('bg-info', 'bg-success');
            badgeStock.classList.add('bg-warning', 'text-dark');
        } else {
            badgeStock.textContent = `Stock: ${stockReal}`;
            badgeStock.classList.remove('bg-warning', 'text-dark');
            badgeStock.classList.add(stockReal <= 10 ? 'bg-warning text-dark' : 'bg-info');
        }
        
        // Deshabilitar botón si no hay stock disponible
        if (stockDisponible <= 0) {
            btnProducto.disabled = true;
            btnProducto.classList.add('disabled');
            btnProducto.innerHTML = '<i class="bi bi-x-circle"></i> Sin stock';
        } else {
            btnProducto.disabled = false;
            btnProducto.classList.remove('disabled');
            btnProducto.innerHTML = '<i class="bi bi-plus-circle"></i>';
        }
    }

    guardarCarritoEnLocalStorage() {
        localStorage.setItem('carrito_pos', JSON.stringify(this.carrito));
    }

    cargarCarritoDelLocalStorage() {
        const carritoGuardado = localStorage.getItem('carrito_pos');
        if (carritoGuardado) {
            try {
                this.carrito = JSON.parse(carritoGuardado);
            } catch (error) {
                this.carrito = [];
            }
        }
    }

    mostrarNotificacion(mensaje, tipo = 'info') {
        const alertaHTML = `
            <div class="alert alert-${tipo} alert-dismissible fade show position-fixed" style="top: 20px; right: 20px; z-index: 9999;" role="alert">
                ${mensaje}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', alertaHTML);

        const alerta = document.querySelector('.alert');
        setTimeout(() => {
            alerta.remove();
        }, 4000);
    }

    escaparHTML(texto) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return texto.replace(/[&<>"']/g, m => map[m]);
    }

    formatearMoneda(valor) {
        return parseFloat(valor).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    obtenerCSRFToken() {
        const name = 'csrftoken';
        let cookieValue = null;

        if (document.cookie && document.cookie !== '') {
            const cookies = document.cookie.split(';');
            for (let cookie of cookies) {
                cookie = cookie.trim();
                if (cookie.substring(0, name.length + 1) === (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }

        return cookieValue;
    }
}

// Inicializar el carrito cuando el documento esté listo
document.addEventListener('DOMContentLoaded', () => {
    window.carritoPOS = new CarritoPOS();
});
