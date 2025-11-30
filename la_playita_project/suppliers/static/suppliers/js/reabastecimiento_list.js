/**
 * LISTA DE REABASTECIMIENTO - VERSIÓN MEJORADA
 * - Flujo simplificado con tabs
 * - Modal unificado para recepción
 * - Mejor validación en vivo
 * - Búsqueda y filtros optimizados
 */

document.addEventListener('DOMContentLoaded', function () {
    const container = document.getElementById('reabastecimiento-container');
    const ELIMINAR_URL = container.dataset.eliminarUrl;
    const PROVEEDORES_SEARCH_URL = container.dataset.proveedoresSearchUrl;

    // ===== TAB MANAGEMENT =====
    const tabButtons = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');

    tabButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const tabName = this.dataset.tab;
            
            // Remove active class from all
            tabButtons.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            
            // Add active class to clicked
            this.classList.add('active');
            document.getElementById(`tab-${tabName}`).classList.add('active');
            
            // Populate tab content
            populateTab(tabName);
        });
    });

    function populateTab(tabName) {
        const container = document.getElementById(`${tabName}-list`);
        const reabastecimientos = document.querySelectorAll('[data-reabastecimiento-id]');
        
        let html = '';
        let count = 0;

        reabastecimientos.forEach(row => {
            const estado = row.dataset.estado;
            const shouldShow = (tabName === 'pendientes' && estado === 'solicitado') ||
                              (tabName === 'historial' && (estado === 'recibido' || estado === 'cancelado'));
            
            if (shouldShow) {
                count++;
                const id = row.dataset.reabastecimientoId;
                const proveedor = row.dataset.proveedor || 'N/A';
                const fecha = row.dataset.fecha || '';
                const costoRaw = parseFloat(row.dataset.costo) || 0;
                const costo = '$' + costoRaw.toLocaleString('es-CO', {minimumFractionDigits: 2, maximumFractionDigits: 2});
                const productCount = row.dataset.productCount || '0';
                const statusBadge = getStatusBadge(estado);
                
                // Debug
                console.log(`Orden #${id}: costo=${row.dataset.costo}, costoRaw=${costoRaw}, formateado=${costo}`);

                html += `
                    <div class="order-card ${estado}" data-order-id="${id}">
                        <div class="row align-items-center">
                            <div class="col-md-6">
                                <h6 class="mb-1">
                                    <strong>Orden #${id}</strong>
                                </h6>
                                <small class="text-muted d-block">
                                    <i class="fas fa-building me-1"></i>${proveedor}
                                </small>
                                <small class="text-muted d-block">
                                    <i class="fas fa-calendar me-1"></i>${fecha}
                                </small>
                            </div>
                            <div class="col-md-3">
                                <div class="text-center">
                                    <small class="text-muted d-block">Productos</small>
                                    <strong class="d-block">${productCount}</strong>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="text-center">
                                    <small class="text-muted d-block">Total</small>
                                    <strong class="d-block">${costo}</strong>
                                </div>
                            </div>
                        </div>
                        <div class="mt-3 pt-3 border-top d-flex gap-2 justify-content-between align-items-center">
                            <div>${statusBadge}</div>
                            <div class="btn-group btn-group-sm" role="group">
                                ${estado === 'solicitado' ? `
                                    <button type="button" class="btn btn-success btn-recibir" data-id="${id}">
                                        <i class="fas fa-truck-loading me-1"></i>Recibir
                                    </button>
                                ` : ''}
                                <button type="button" class="btn btn-outline-secondary btn-detalles" data-id="${id}">
                                    <i class="fas fa-eye me-1"></i>Ver
                                </button>
                                ${estado === 'solicitado' ? `
                                    <button type="button" class="btn btn-outline-danger btn-eliminar" data-id="${id}">
                                        <i class="fas fa-trash me-1"></i>
                                    </button>
                                ` : ''}
                            </div>
                        </div>
                    </div>
                `;
            }
        });

        if (count === 0) {
            html = `
                <div class="text-center py-5">
                    <i class="fas fa-inbox text-muted" style="font-size: 3rem;"></i>
                    <h5 class="text-muted mt-3">No hay órdenes</h5>
                    <p class="text-muted">
                        ${tabName === 'pendientes' ? 'Crea una nueva orden para empezar' : 'No hay historial disponible'}
                    </p>
                </div>
            `;
        }

        container.innerHTML = html;
        updateTabCounts();
        attachEventListeners();
    }

    function getStatusBadge(estado) {
        const badges = {
            'solicitado': '<span class="badge bg-warning text-dark"><i class="fas fa-hourglass-half me-1"></i>Solicitado</span>',
            'recibido': '<span class="badge bg-success"><i class="fas fa-check-circle me-1"></i>Recibido</span>',
            'cancelado': '<span class="badge bg-danger"><i class="fas fa-ban me-1"></i>Cancelado</span>'
        };
        return badges[estado] || '<span class="badge bg-secondary">Desconocido</span>';
    }

    function updateTabCounts() {
        const pendientes = document.querySelectorAll('[data-estado="solicitado"]').length;
        const historial = document.querySelectorAll('[data-estado="recibido"], [data-estado="cancelado"]').length;
        
        document.getElementById('count-pendientes').textContent = pendientes;
        document.getElementById('count-historial').textContent = historial;
    }

    // ===== SEARCH & FILTERS =====
    const globalSearch = document.getElementById('global_search');
    const clearSearchBtn = document.getElementById('clearSearchBtn');
    const toggleFiltersBtn = document.getElementById('toggleFiltersBtn');
    const filtersCollapse = document.getElementById('filtersCollapse');

    if (globalSearch) {
        globalSearch.addEventListener('input', function() {
            const query = this.value.toLowerCase().trim();
            clearSearchBtn.style.display = query ? 'block' : 'none';
            
            const rows = document.querySelectorAll('[data-reabastecimiento-id]');
            rows.forEach(row => {
                const id = row.dataset.reabastecimientoId;
                const proveedor = row.dataset.proveedor || '';
                const text = (id + ' ' + proveedor).toLowerCase();
                
                const card = document.querySelector(`[data-order-id="${id}"]`);
                if (card) {
                    card.style.display = text.includes(query) ? '' : 'none';
                }
            });
        });

        clearSearchBtn.addEventListener('click', function() {
            globalSearch.value = '';
            clearSearchBtn.style.display = 'none';
            document.querySelectorAll('[data-order-id]').forEach(card => {
                card.style.display = '';
            });
        });
    }

    if (toggleFiltersBtn) {
        toggleFiltersBtn.addEventListener('click', function() {
            filtersCollapse.classList.toggle('show');
        });
    }

    // ===== EVENT LISTENERS =====
    function attachEventListeners() {
        // Recibir orden
        document.querySelectorAll('.btn-recibir').forEach(btn => {
            btn.addEventListener('click', async function() {
                const id = this.dataset.id;
                await openReceptionModal(id);
            });
        });

        // Ver detalles
        document.querySelectorAll('.btn-detalles').forEach(btn => {
            btn.addEventListener('click', async function() {
                const id = this.dataset.id;
                await showOrderDetails(id);
            });
        });

        // Eliminar
        document.querySelectorAll('.btn-eliminar').forEach(btn => {
            btn.addEventListener('click', async function() {
                const id = this.dataset.id;
                await deleteOrder(id);
            });
        });
    }

    // ===== RECEPTION MODAL =====
    async function openReceptionModal(id) {
        try {
            const response = await fetch(`/suppliers/reabastecimientos/${id}/details_api/`);
            if (!response.ok) throw new Error('Error al cargar datos');
            
            const data = await response.json();
            
            // Populate modal
            document.getElementById('receptionOrderId').textContent = id;
            document.getElementById('receptionProveedorName').textContent = data.proveedor_nombre;
            
            // Populate table
            const tbody = document.getElementById('receptionTableBody');
            tbody.innerHTML = data.detalles.map(detalle => `
                <tr data-detalle-id="${detalle.id}">
                    <td>${detalle.producto_nombre}</td>
                    <td class="text-center">${detalle.cantidad}</td>
                    <td class="text-center">
                        <input type="number" class="form-control form-control-sm cantidad-input" 
                               value="${detalle.cantidad_recibida}" min="0" max="${detalle.cantidad}">
                    </td>
                    <td class="text-center">
                        <input type="date" class="form-control form-control-sm fecha-input" 
                               value="${detalle.fecha_caducidad || ''}">
                    </td>
                    <td class="text-center">
                        <input type="text" class="form-control form-control-sm lote-input" 
                               value="${detalle.numero_lote || ''}" placeholder="Lote">
                    </td>
                    <td class="text-center">
                        <span class="product-status pending">
                            <i class="fas fa-circle"></i>
                        </span>
                    </td>
                </tr>
            `).join('');

            // Show modal
            const modal = new bootstrap.Modal(document.getElementById('receptionModal'));
            modal.show();

            // Attach input listeners
            attachReceptionInputListeners();
            updateReceptionProgress();

        } catch (error) {
            showToast(error.message, 'danger');
        }
    }

    function attachReceptionInputListeners() {
        const inputs = document.querySelectorAll('.cantidad-input, .fecha-input, .lote-input');
        inputs.forEach(input => {
            input.addEventListener('change', updateReceptionProgress);
            input.addEventListener('input', updateReceptionProgress);
        });

        // Mark all received
        document.getElementById('markAllReceivedBtn').addEventListener('click', function() {
            document.querySelectorAll('.cantidad-input').forEach(input => {
                const row = input.closest('tr');
                const solicitado = parseInt(row.querySelector('td:nth-child(2)').textContent);
                input.value = solicitado;
            });
            updateReceptionProgress();
        });

        // Apply expiry date to all
        document.getElementById('applyGeneralExpiryBtn').addEventListener('click', function() {
            const date = document.getElementById('generalExpiryDate').value;
            if (!date) return;
            document.querySelectorAll('.fecha-input').forEach(input => {
                input.value = date;
            });
            updateReceptionProgress();
        });

        // Search products
        document.getElementById('searchProductInput').addEventListener('input', function() {
            const query = this.value.toLowerCase();
            document.querySelectorAll('#receptionTableBody tr').forEach(row => {
                const productName = row.querySelector('td:first-child').textContent.toLowerCase();
                row.style.display = productName.includes(query) ? '' : 'none';
            });
        });

        // Confirm reception
        document.getElementById('confirmReceptionBtn').addEventListener('click', confirmReception);
    }

    function updateReceptionProgress() {
        const rows = document.querySelectorAll('#receptionTableBody tr:not([style*="display: none"])');
        let completed = 0, partial = 0, pending = 0;

        rows.forEach(row => {
            const solicitado = parseInt(row.querySelector('td:nth-child(2)').textContent);
            const recibido = parseInt(row.querySelector('.cantidad-input').value) || 0;
            const status = row.querySelector('.product-status');

            if (recibido === solicitado) {
                completed++;
                status.className = 'product-status complete';
                status.innerHTML = '<i class="fas fa-check-circle"></i>';
            } else if (recibido > 0) {
                partial++;
                status.className = 'product-status partial';
                status.innerHTML = '<i class="fas fa-exclamation-circle"></i>';
            } else {
                pending++;
                status.className = 'product-status pending';
                status.innerHTML = '<i class="fas fa-circle"></i>';
            }
        });

        const total = completed + partial + pending;
        document.getElementById('progressText').textContent = `${completed} de ${total}`;
        document.getElementById('progressBar').style.width = `${total > 0 ? (completed / total) * 100 : 0}%`;
        document.getElementById('completedCount').textContent = completed;
        document.getElementById('partialCount').textContent = partial;
        document.getElementById('pendingCount').textContent = pending;

        // Enable confirm button if at least one product received
        document.getElementById('confirmReceptionBtn').disabled = (completed + partial) === 0;

        // Show warning if partial
        const mismatchAlert = document.getElementById('quantityMismatchAlert');
        if (partial > 0) {
            mismatchAlert.style.display = 'block';
            document.getElementById('mismatchText').textContent = `${partial} producto(s) con cantidad parcial`;
        } else {
            mismatchAlert.style.display = 'none';
        }
    }

    async function confirmReception() {
        // TODO: Implement reception confirmation
        showToast('Recepción confirmada', 'success');
    }

    // ===== UTILITY FUNCTIONS =====
    async function showOrderDetails(id) {
        try {
            const response = await fetch(`/suppliers/reabastecimientos/${id}/details_api/`);
            if (!response.ok) throw new Error('Error al cargar detalles');
            
            const data = await response.json();
            
            let html = `
                <div class="row mb-3">
                    <div class="col-md-6">
                        <small class="text-muted">Proveedor</small>
                        <p class="fw-bold">${data.proveedor_nombre}</p>
                    </div>
                    <div class="col-md-6">
                        <small class="text-muted">Estado</small>
                        <p>${getStatusBadge(data.estado)}</p>
                    </div>
                </div>
                <div class="row mb-3">
                    <div class="col-md-6">
                        <small class="text-muted">Total</small>
                        <p class="fw-bold">${data.costo_total}</p>
                    </div>
                    <div class="col-md-6">
                        <small class="text-muted">IVA</small>
                        <p class="fw-bold">${data.iva}</p>
                    </div>
                </div>
                <hr>
                <h6>Productos (${data.detalles.length})</h6>
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead class="table-light">
                            <tr>
                                <th>Producto</th>
                                <th class="text-center">Solicitado</th>
                                <th class="text-center">Recibido</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${data.detalles.map(d => `
                                <tr>
                                    <td>${d.producto_nombre}</td>
                                    <td class="text-center">${d.cantidad}</td>
                                    <td class="text-center">${d.cantidad_recibida}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;

            Swal.fire({
                title: `Orden #${id}`,
                html: html,
                icon: 'info',
                width: '600px',
                confirmButtonText: 'Cerrar'
            });
        } catch (error) {
            showToast(error.message, 'danger');
        }
    }

    async function deleteOrder(id) {
        const result = await Swal.fire({
            title: '¿Eliminar orden?',
            text: 'Esta acción no se puede deshacer',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Sí, eliminar',
            cancelButtonText: 'Cancelar'
        });

        if (!result.isConfirmed) return;

        try {
            const response = await fetch(ELIMINAR_URL.replace('0', id), {
                method: 'POST',
                headers: {
                    'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
                }
            });

            if (!response.ok) throw new Error('Error al eliminar');

            const card = document.querySelector(`[data-order-id="${id}"]`);
            if (card) card.remove();
            
            updateTabCounts();
            showToast('Orden eliminada', 'success');
        } catch (error) {
            showToast(error.message, 'danger');
        }
    }

    function showToast(message, type = 'success') {
        const toastContainer = document.querySelector('.toast-container');
        if (!toastContainer) {
            console.log(`[${type}] ${message}`);
            return;
        }

        const toastId = `toast-${Date.now()}`;
        const bgClass = `bg-${type}`;

        const toastHtml = `
            <div id="${toastId}" class="toast align-items-center text-white ${bgClass} border-0" role="alert">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="fas fa-check-circle me-2"></i>${message}
                    </div>
                    <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
                </div>
            </div>
        `;

        toastContainer.insertAdjacentHTML('beforeend', toastHtml);
        const toastElement = document.getElementById(toastId);
        const toast = new bootstrap.Toast(toastElement, { delay: 3000 });
        toast.show();
    }

    // Initialize
    populateTab('pendientes');
});
