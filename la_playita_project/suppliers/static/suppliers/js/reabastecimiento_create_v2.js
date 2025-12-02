// Reabastecimiento Create Form - Versión Ultra Optimizada
// Mejoras: Búsqueda rápida, IVA automático, validación en vivo, copiar filas, predicción de stock

class ReabastecimientoForm {
    constructor() {
        this.form = document.getElementById('reabastecimientoForm');
        this.detalleTable = document.getElementById('detalleTable');
        this.managementForm = document.querySelector('[name="reabastecimientodetalle_set-TOTAL_FORMS"]');
        this.addRowBtn = document.getElementById('add-row-formset');
        this.guardarBtn = document.getElementById('guardarReabastecimientoBtn');
        this.cancelarBtn = document.getElementById('cancelarBtn');
        this.proveedorSelect = document.getElementById('id_proveedor_select');
        
        this.productos = JSON.parse(document.querySelector('script[data-productos]')?.textContent || '[]');
        this.tasasIva = JSON.parse(document.querySelector('script[data-tasas-iva]')?.textContent || '[]');
        this.productMap = new Map(this.productos.map(p => [p.id, p]));
        
        this.isSubmitting = false; // Flag para controlar el envío
        
        this.init();
    }

    init() {
        // Disable HTML5 validation to prevent "not focusable" errors
        this.form.setAttribute('novalidate', 'novalidate');
        
        this.initializeProveedorSelect();
        this.populateIvaSelects();
        this.setupEventListeners();
        this.validateForm();
        this.calculateTotals();
        this.updateProductCount();
        
        // Setup Tab navigation para filas existentes
        document.querySelectorAll('tr.formset-row').forEach(row => {
            this.setupRowTabNavigation(row);
        });
    }
    
    initializeProveedorSelect() {
        // NO usar Select2 para el proveedor, solo deshabilitar autocompletado nativo
        if (this.proveedorSelect) {
            this.proveedorSelect.setAttribute('autocomplete', 'off');
            this.proveedorSelect.setAttribute('autocomplete', 'new-password'); // Truco para deshabilitar autocompletado
        }
    }
    
    populateIvaSelects() {
        document.querySelectorAll('.iva-select').forEach(select => {
            // Solo poblar si el select solo tiene el placeholder (1 opción)
            if (select.options.length > 1) return;
            
            // Guardar el valor seleccionado si existe
            const selectedValue = select.value;
            
            // Usar this.tasasIva que viene del contexto de Django
            const tasas = this.tasasIva?.length > 0 ? this.tasasIva : [];
            
            tasas.forEach(tasa => {
                const option = document.createElement('option');
                option.value = tasa.id; // Usar el ID de la tasa como valor
                option.textContent = tasa.nombre; // Solo el nombre (ya incluye el porcentaje)
                option.dataset.porcentaje = tasa.porcentaje; // Guardar el porcentaje en un data attribute
                select.appendChild(option);
            });

            // Restaurar el valor seleccionado si aún es válido
            if (selectedValue) {
                select.value = selectedValue;
            }
        });
    }

    setupEventListeners() {
        // Permitir agregar productos SIN proveedor (validar solo al enviar)
        this.proveedorSelect.addEventListener('change', () => {
            this.validateForm();
        });

        // Quick supplier buttons
        document.querySelectorAll('.quick-supplier-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.proveedorSelect.value = btn.dataset.supplierId;
                this.proveedorSelect.dispatchEvent(new Event('change', { bubbles: true }));
                document.querySelectorAll('.quick-supplier-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
            });
        });

        // Add row button - SIN validación de proveedor
        this.addRowBtn.addEventListener('click', () => {
            this.addFormRow();
        });

        // Delete row buttons
        document.addEventListener('click', (e) => {
            if (e.target.closest('.delete-row-btn')) {
                e.preventDefault();
                const row = e.target.closest('tr.formset-row');
                if (row) this.deleteRow(row);
            }
        });

        // Copy row button (NEW)
        document.addEventListener('click', (e) => {
            if (e.target.closest('.copy-row-btn')) {
                e.preventDefault();
                const row = e.target.closest('tr.formset-row');
                if (row) this.copyRow(row);
            }
        });

        // Product selection with auto-fill
        document.addEventListener('change', (e) => {
            if (e.target.classList.contains('producto-select')) {
                this.handleProductSelection(e.target);
                this.updateProductCount(); // Actualizar contador al seleccionar producto
            }
        });

        // Live calculations
        document.addEventListener('input', (e) => {
            if (e.target.classList.contains('cantidad-input') || 
                e.target.classList.contains('costo-unitario-input')) {
                this.calculateTotals();
            }
        });

        document.addEventListener('change', (e) => {
            if (e.target.classList.contains('iva-select')) {
                // Validar que se haya seleccionado una opción
                if (e.target.value) {
                    e.target.classList.add('is-valid');
                    e.target.classList.remove('is-invalid');
                } else {
                    e.target.classList.add('is-invalid');
                    e.target.classList.remove('is-valid');
                }
                this.calculateTotals();
                this.validateForm();
            }
        });

        // Form validation
        document.addEventListener('change', (e) => {
            if (e.target.classList.contains('producto-select') ||
                e.target.classList.contains('cantidad-input') ||
                e.target.classList.contains('costo-unitario-input') ||
                e.target.type === 'date') {
                this.validateField(e.target);
                this.validateForm();
            }
        });

        // Cancel button
        this.cancelarBtn.addEventListener('click', (e) => this.handleCancel(e));
        
        // Guardar como borrador button
        const guardarBorradorBtn = document.getElementById('guardarBorradorBtn');
        if (guardarBorradorBtn) {
            guardarBorradorBtn.addEventListener('click', (e) => this.handleSaveDraft(e));
        }

        // Form submission - usar bind para mantener el contexto
        this.boundHandleSubmit = this.handleSubmit.bind(this);
        this.form.addEventListener('submit', this.boundHandleSubmit);
    }

    
    addFormRow() {
        const totalForms = parseInt(this.managementForm.value);
        const emptyForm = document.getElementById('empty-form-template').querySelector('tr');
        const newRow = emptyForm.cloneNode(true);
        
        newRow.classList.add('formset-row');
        newRow.id = `detalle-row-${totalForms}`;
        
        newRow.querySelectorAll('input, select').forEach(field => {
            const name = field.name;
            if (name) {
                field.name = name.replace(/__prefix__/g, totalForms);
                field.id = field.id ? field.id.replace(/__prefix__/g, totalForms) : '';
                field.value = '';
            }
        });

        newRow.style.opacity = '0';
        newRow.style.backgroundColor = '#fff3cd';
        this.detalleTable.querySelector('tbody').appendChild(newRow);

        setTimeout(() => {
            newRow.style.transition = 'opacity 0.3s ease, background-color 0.5s ease';
            newRow.style.opacity = '1';
            setTimeout(() => newRow.style.backgroundColor = '', 1000);
        }, 10);

        this.managementForm.value = totalForms + 1;
        newRow.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        
        // Poblar el select de IVA de la nueva fila
        this.populateIvaSelects();
        
        // Setup Tab navigation para la nueva fila
        this.setupRowTabNavigation(newRow);
        
        // Atajos de teclado para velocidad
        this.setupRowKeyboardShortcuts(newRow);
        
        const firstInput = newRow.querySelector('.producto-select');
        if (firstInput) setTimeout(() => firstInput.focus(), 300);

        this.calculateTotals();
        this.validateForm();
        this.updateProductCount();
    }

    setupRowTabNavigation(row) {
        const fields = row.querySelectorAll('.producto-select, .cantidad-input, .costo-unitario-input, .iva-select, [type="date"], .delete-row-btn, .copy-row-btn');
        
        fields.forEach((field, index) => {
            field.addEventListener('keydown', (e) => {
                if (e.key === 'Tab' && !e.shiftKey && index === fields.length - 1) {
                    e.preventDefault();
                    this.addFormRow();
                }
            });
        });
    }

    setupRowKeyboardShortcuts(row) {
        const cantidadInput = row.querySelector('.cantidad-input');
        const costoInput = row.querySelector('.costo-unitario-input');
        const deleteBtn = row.querySelector('.delete-row-btn');
        const copyBtn = row.querySelector('.copy-row-btn');

        // Ctrl+D: Duplicar fila
        row.addEventListener('keydown', (e) => {
            if (e.ctrlKey && e.key === 'd') {
                e.preventDefault();
                this.copyRow(row);
            }
        });

        // Ctrl+Backspace: Eliminar fila
        row.addEventListener('keydown', (e) => {
            if (e.ctrlKey && e.key === 'Backspace') {
                e.preventDefault();
                this.deleteRow(row);
            }
        });

        // Ctrl+Enter en cantidad: Ir a costo
        if (cantidadInput) {
            cantidadInput.addEventListener('keydown', (e) => {
                if (e.ctrlKey && e.key === 'Enter') {
                    e.preventDefault();
                    costoInput?.focus();
                }
            });
        }
    }

    deleteRow(row) {
        row.style.transition = 'opacity 0.3s ease';
        row.style.opacity = '0';
        setTimeout(() => {
            row.remove();
            this.updateProductCount();
            this.calculateTotals();
            this.validateForm();
        }, 300);
    }

    copyRow(sourceRow) {
        const totalForms = parseInt(this.managementForm.value);
        const newRow = sourceRow.cloneNode(true);
        
        newRow.id = `detalle-row-${totalForms}`;
        newRow.querySelectorAll('input, select').forEach(field => {
            const name = field.name;
            if (name) {
                field.name = name.replace(/\d+/g, totalForms);
                field.id = field.id ? field.id.replace(/\d+/g, totalForms) : '';
            }
        });

        newRow.style.opacity = '0';
        newRow.style.backgroundColor = '#d4edda';
        this.detalleTable.querySelector('tbody').appendChild(newRow);

        setTimeout(() => {
            newRow.style.transition = 'opacity 0.3s ease, background-color 0.5s ease';
            newRow.style.opacity = '1';
            setTimeout(() => newRow.style.backgroundColor = '', 1000);
        }, 10);

        this.managementForm.value = totalForms + 1;
        this.calculateTotals();
        this.validateForm();
        this.updateProductCount();
    }

    handleProductSelection(selectElement) {
        const productId = selectElement.value;
        const row = selectElement.closest('tr.formset-row');
        if (!row || !productId) return;

        const producto = this.productMap.get(parseInt(productId));
        if (!producto) return;

        // Auto-fill costo unitario
        const costoInput = row.querySelector('.costo-unitario-input');
        if (costoInput && producto.precio_unitario) {
            costoInput.value = producto.precio_unitario;
            costoInput.classList.add('is-valid');
            costoInput.classList.remove('is-invalid');
        }

        // NO auto-llenar IVA - dejar en "--" para que el usuario seleccione manualmente
        const ivaSelect = row.querySelector('.iva-select');
        
        if (ivaSelect) {
            // Resetear a la opción placeholder (--) 
            ivaSelect.value = '';
            ivaSelect.classList.remove('is-valid', 'is-invalid');
            
            // Opcional: Resaltar brevemente el campo IVA para que el usuario note que debe seleccionarlo
            ivaSelect.style.backgroundColor = '#fff3cd'; // Color amarillo suave
            setTimeout(() => {
                ivaSelect.style.backgroundColor = '';
            }, 1000);
        }

        // Sugerir cantidad basada en stock actual (si está disponible)
        const cantidadInput = row.querySelector('.cantidad-input');
        if (cantidadInput && producto.stock_actual !== undefined) {
            const suggestedQty = Math.max(10, Math.ceil(producto.stock_actual * 0.5));
            cantidadInput.placeholder = `Sugerido: ${suggestedQty}`;
            cantidadInput.setAttribute('data-suggested', suggestedQty);
            cantidadInput.setAttribute('title', `Stock actual: ${producto.stock_actual} | Sugerido: ${suggestedQty}`);
        }

        // Auto-focus cantidad para entrada rápida
        if (cantidadInput) {
            setTimeout(() => cantidadInput.focus(), 100);
        }

        this.calculateTotals();
        this.validateField(selectElement);
    }

    calculateTotals() {
        let grandSubtotal = 0;
        let grandIva = 0;

        this.detalleTable.querySelectorAll('tbody tr.formset-row').forEach((row, index) => {
            const cantidadInput = row.querySelector('.cantidad-input');
            const costoInput = row.querySelector('.costo-unitario-input');
            const ivaSelect = row.querySelector('.iva-select');
            const subtotalDisplay = row.querySelector('.subtotal-display');

            if (cantidadInput && costoInput && ivaSelect) {
                const cantidad = parseFloat(cantidadInput.value) || 0;
                const costo = parseFloat(costoInput.value) || 0;

                const selectedOption = ivaSelect.options[ivaSelect.selectedIndex];
                const ivaPorcentaje = selectedOption ? parseFloat(selectedOption.dataset.porcentaje) || 0 : 0;

                const subtotal = cantidad * costo;
                const iva = subtotal * (ivaPorcentaje / 100);
                const total = subtotal + iva;

                // Update hidden IVA field for form submission
                const ivaField = row.querySelector('input.iva-field');
                if (ivaField) {
                    ivaField.value = iva.toFixed(2);
                }

                grandSubtotal += subtotal;
                grandIva += iva;

                if (subtotalDisplay) {
                    subtotalDisplay.textContent = this.formatCurrency(total);
                }
            }
        });

        const grandTotal = grandSubtotal + grandIva;
        document.getElementById('gran-subtotal').textContent = this.formatCurrency(grandSubtotal);
        document.getElementById('gran-iva').textContent = this.formatCurrency(grandIva);
        document.getElementById('gran-total').textContent = this.formatCurrency(grandTotal);
        
        // Actualizar vista móvil
        this.syncMobileView();
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('es-CO', {
            style: 'currency',
            currency: 'COP',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    validateField(field) {
        const row = field.closest('tr.formset-row');
        if (!row) return true;

        let isValid = true;
        let errorMsg = '';
        let errorType = '';

        if (field.classList.contains('producto-select')) {
            isValid = !!field.value;
            if (isValid) {
                errorType = 'success';
            } else {
                errorMsg = 'Selecciona un producto';
                errorType = 'error';
            }
        } else if (field.classList.contains('cantidad-input')) {
            const value = parseFloat(field.value);
            if (!field.value) {
                isValid = false;
                errorMsg = 'Cantidad requerida';
                errorType = 'error';
            } else if (value <= 0) {
                isValid = false;
                errorMsg = 'Cantidad debe ser > 0';
                errorType = 'error';
            } else if (value > 999999) {
                isValid = false;
                errorMsg = 'Cantidad muy alta';
                errorType = 'warning';
            } else {
                errorType = 'success';
            }
        } else if (field.classList.contains('costo-unitario-input')) {
            const value = parseFloat(field.value);
            if (!field.value) {
                isValid = false;
                errorMsg = 'Costo requerido';
                errorType = 'error';
            } else if (value <= 0) {
                isValid = false;
                errorMsg = 'Costo debe ser > 0';
                errorType = 'error';
            } else if (value > 999999999) {
                isValid = false;
                errorMsg = 'Costo muy alto';
                errorType = 'warning';
            } else {
                errorType = 'success';
            }
        } else if (field.classList.contains('iva-select')) {
            // Validar que se haya seleccionado un IVA (no el placeholder)
            if (!field.value || field.value === '') {
                isValid = false;
                errorMsg = 'Selecciona un IVA';
                errorType = 'error';
            } else {
                errorType = 'success';
            }
        } else if (field.type === 'date') {
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const selectedDate = field.value ? new Date(field.value + 'T00:00:00') : null;
            
            if (!field.value) {
                isValid = false;
                errorMsg = 'Fecha requerida';
                errorType = 'error';
            } else {
                // Calcular días de diferencia desde HOY
                const diffDays = Math.ceil((selectedDate - today) / (1000 * 60 * 60 * 24));
                
                // Calcular fecha mínima (hoy + 5 días)
                const minDate = new Date(today);
                minDate.setDate(today.getDate() + 5);
                const minDateStr = minDate.toLocaleDateString('es-CO', { day: '2-digit', month: '2-digit', year: 'numeric' });
                
                // ERROR: Menos de 5 días de caducidad (no permitido)
                if (diffDays < 5) {
                    isValid = false;
                    errorMsg = `Mínimo 5 días de caducidad. Fecha mínima: ${minDateStr}`;
                    errorType = 'error';
                }
                // ADVERTENCIA: Entre 5 y 14 días (permitido pero con advertencia)
                else if (diffDays < 15) {
                    errorMsg = `⚠️ Caducidad cercana (${diffDays} días)`;
                    errorType = 'warning';
                } 
                // OK: 15 días o más
                else {
                    errorType = 'success';
                }
            }
        }

        field.classList.toggle('is-invalid', !isValid);
        field.classList.toggle('is-valid', isValid && errorType === 'success');
        field.classList.toggle('is-warning', errorType === 'warning');
        
        // Mostrar feedback visual en vivo con tooltip
        if (errorMsg) {
            field.setAttribute('data-error', errorMsg);
            field.setAttribute('title', errorMsg);
            // Agregar pequeño indicador visual debajo del campo
            this.showFieldError(field, errorMsg, errorType);
        } else {
            field.removeAttribute('data-error');
            field.removeAttribute('title');
            this.clearFieldError(field);
        }

        return isValid;
    }

    showFieldError(field, message, type) {
        // Primero limpiar cualquier error existente
        this.clearFieldError(field);
        
        // Crear nuevo elemento de error
        const errorEl = document.createElement('small');
        errorEl.className = `field-error-msg d-block mt-1 text-${type === 'error' ? 'danger' : 'warning'}`;
        errorEl.textContent = message;
        
        // Insertar después del campo
        field.parentNode.insertBefore(errorEl, field.nextSibling);
    }

    clearFieldError(field) {
        // Buscar y eliminar TODOS los mensajes de error después del campo
        let nextEl = field.nextElementSibling;
        while (nextEl && nextEl.classList.contains('field-error-msg')) {
            const toRemove = nextEl;
            nextEl = nextEl.nextElementSibling;
            toRemove.remove();
        }
    }

    validateForm() {
        let isValid = true;
        let validCount = 0;
        let totalChecks = 0;

        // Validar proveedor (requerido)
        if (!this.proveedorSelect || !this.proveedorSelect.value) {
            isValid = false;
            this.proveedorSelect?.classList.add('is-invalid');
        } else {
            this.proveedorSelect?.classList.remove('is-invalid');
            validCount++;
        }
        totalChecks++;

        const rows = this.detalleTable.querySelectorAll('tbody tr.formset-row');
        
        // Filtrar solo las filas que tienen un producto seleccionado
        const rowsWithProduct = Array.from(rows).filter(row => {
            const producto = row.querySelector('.producto-select');
            return producto && producto.value && producto.value !== '';
        });

        if (rowsWithProduct.length === 0) {
            isValid = false;
        } else {
            validCount += rowsWithProduct.length;
        }
        totalChecks += rowsWithProduct.length;

        let errorCount = 0;
        
        // Solo validar filas con producto seleccionado
        rowsWithProduct.forEach(row => {
            const producto = row.querySelector('.producto-select');
            const cantidad = row.querySelector('.cantidad-input');
            const costo = row.querySelector('.costo-unitario-input');
            const fecha = row.querySelector('[type="date"]');
            const iva = row.querySelector('.iva-select');

            let rowValid = true;
            [producto, cantidad, costo, iva, fecha].forEach(field => {
                if (field && !this.validateField(field)) {
                    rowValid = false;
                    isValid = false;
                    errorCount++;
                }
            });

            row.classList.toggle('row-error', !rowValid);
            row.classList.toggle('row-valid', rowValid);
        });

        // Limpiar validación de filas vacías (sin producto)
        rows.forEach(row => {
            const producto = row.querySelector('.producto-select');
            if (!producto || !producto.value || producto.value === '') {
                // Limpiar clases de validación
                row.classList.remove('row-error', 'row-valid');
                
                // Limpiar validación de todos los campos de la fila
                const fields = row.querySelectorAll('.producto-select, .cantidad-input, .costo-unitario-input, .iva-select, [type="date"]');
                fields.forEach(field => {
                    field.classList.remove('is-invalid', 'is-valid');
                    this.clearFieldError(field);
                });
            }
        });

        // Actualizar barra de validación
        const percentage = totalChecks > 0 ? Math.round(((totalChecks - errorCount) / totalChecks) * 100) : 0;
        const validationBar = document.getElementById('formValidationBar');
        if (validationBar) {
            validationBar.style.width = `${percentage}%`;
            validationBar.setAttribute('aria-valuenow', percentage);
            validationBar.className = `progress-bar ${percentage === 100 ? 'bg-success' : percentage > 50 ? 'bg-info' : 'bg-warning'}`;
        }

        this.guardarBtn.disabled = !isValid;
        return isValid;
    }

    updateProductCount() {
        // Solo contar filas visibles en el tbody principal (no el template oculto)
        const tbody = this.detalleTable.querySelector('tbody');
        const rows = tbody ? tbody.querySelectorAll('tr.formset-row') : [];
        this.managementForm.value = rows.length;
        
        // Contar solo filas con producto seleccionado (no filas vacías)
        let count = 0;
        rows.forEach(row => {
            const productoSelect = row.querySelector('.producto-select');
            if (productoSelect) {
                const value = productoSelect.value;
                const selectedIndex = productoSelect.selectedIndex;
                
                // Verificar que tenga un valor válido (no vacío y no el placeholder)
                if (value && value !== '' && selectedIndex > 0) {
                    count++;
                }
            }
        });
        
        const countElement = document.getElementById('product-count');
        if (countElement) {
            countElement.textContent = count;
        }
        this.syncMobileView();
    }
    
    syncMobileView() {
        // Sincronizar vista móvil con la tabla
        const mobileView = document.getElementById('mobileCardView');
        if (!mobileView) return;
        
        const rows = this.detalleTable.querySelectorAll('tbody tr.formset-row');
        let html = '';
        
        rows.forEach((row, index) => {
            const productoSelect = row.querySelector('.producto-select');
            const cantidadInput = row.querySelector('.cantidad-input');
            const costoInput = row.querySelector('.costo-unitario-input');
            const ivaSelect = row.querySelector('.iva-select');
            const fechaInput = row.querySelector('[type="date"]');
            const subtotalDisplay = row.querySelector('.subtotal-display');
            
            const productoNombre = productoSelect.options[productoSelect.selectedIndex]?.text || 'Seleccionar producto';
            const cantidad = cantidadInput.value || '0';
            const costo = costoInput.value || '0';
            const iva = ivaSelect.options[ivaSelect.selectedIndex]?.text || '--';
            const fecha = fechaInput.value || '';
            const subtotal = subtotalDisplay.textContent || '$0';
            
            html += `
                <div class="mobile-product-card" data-row-index="${index}">
                    <div class="card-header">
                        <strong>Producto ${index + 1}</strong>
                        <button type="button" class="btn btn-sm btn-outline-danger mobile-delete-btn" data-row-index="${index}">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                    <div class="form-group">
                        <label>Producto</label>
                        <div class="text-muted">${productoNombre}</div>
                    </div>
                    <div class="row">
                        <div class="col-6 form-group">
                            <label>Cantidad</label>
                            <div class="fw-bold">${cantidad}</div>
                        </div>
                        <div class="col-6 form-group">
                            <label>Costo Unit.</label>
                            <div class="fw-bold">$${parseFloat(costo || 0).toLocaleString('es-CO')}</div>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-6 form-group">
                            <label>IVA</label>
                            <div>${iva}</div>
                        </div>
                        <div class="col-6 form-group">
                            <label>Caducidad</label>
                            <div>${fecha || 'No especificada'}</div>
                        </div>
                    </div>
                    <div class="subtotal-badge">
                        Total: ${subtotal}
                    </div>
                </div>
            `;
        });
        
        if (rows.length === 0) {
            html = '<div class="text-center text-muted py-4">No hay productos agregados</div>';
        }
        
        mobileView.innerHTML = html;
        
        // Agregar event listeners para botones de eliminar en móvil
        mobileView.querySelectorAll('.mobile-delete-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const rowIndex = parseInt(btn.dataset.rowIndex);
                const tableRow = this.detalleTable.querySelectorAll('tbody tr.formset-row')[rowIndex];
                if (tableRow) this.deleteRow(tableRow);
            });
        });
    }

    updateAddRowButton() {
        const hasSupplier = !!this.proveedorSelect.value;
        this.addRowBtn.disabled = !hasSupplier;
        this.addRowBtn.title = hasSupplier ? 'Agregar producto (Tab al final)' : 'Selecciona un proveedor primero';
    }

    handleSaveDraft(e) {
        e.preventDefault();
        console.log('[BORRADOR] Iniciando guardado de borrador...');
        
        // Validar que al menos haya un proveedor
        if (!this.proveedorSelect.value) {
            console.log('[BORRADOR] Error: No hay proveedor seleccionado');
            Swal.fire({
                icon: 'warning',
                title: 'Proveedor requerido',
                text: 'Debes seleccionar un proveedor para guardar el borrador.',
                confirmButtonColor: '#0d6efd'
            });
            return;
        }
        
        const rows = this.detalleTable.querySelectorAll('tbody:not(#empty-form-template) tr.formset-row');
        console.log(`[BORRADOR] Filas encontradas: ${rows.length}`);
        
        // Cambiar el estado a borrador
        const estadoInput = this.form.querySelector('[name="estado"]');
        if (estadoInput) {
            estadoInput.value = 'borrador';
            console.log('[BORRADOR] Estado cambiado a: borrador');
        } else {
            console.error('[BORRADOR] No se encontró el campo de estado');
        }
        
        const guardarBtn = document.getElementById('guardarBorradorBtn');
        if (guardarBtn) {
            guardarBtn.disabled = true;
            guardarBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
        }
        
        console.log('[BORRADOR] Enviando formulario...');
        this.isSubmitting = true;
        
        // Remover el listener para evitar loop
        this.form.removeEventListener('submit', this.boundHandleSubmit);
        
        // Esperar 1.5 segundos para que el usuario vea el feedback visual
        setTimeout(() => {
            // Crear un input submit oculto y hacer clic en él
            const submitInput = document.createElement('input');
            submitInput.type = 'submit';
            submitInput.style.display = 'none';
            this.form.appendChild(submitInput);
            submitInput.click();
        }, 1500);
    }
    
    handleCancel(e) {
        e.preventDefault();
        const hasData = this.detalleTable.querySelectorAll('tbody tr.formset-row').length > 0 ||
                       (this.proveedorSelect && this.proveedorSelect.value);

        if (hasData && typeof Swal !== 'undefined') {
            Swal.fire({
                title: '¿Cancelar?',
                text: 'Se perderán todos los cambios.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc3545',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Sí, cancelar',
                cancelButtonText: 'Volver'
            }).then((result) => {
                if (result.isConfirmed) {
                    window.location.href = cancelUrl;
                }
            });
        } else {
            window.location.href = cancelUrl;
        }
    }

    handleSubmit(e) {
        // Si ya estamos enviando, permitir que continúe
        if (this.isSubmitting) {
            return true;
        }
        
        e.preventDefault();
        e.stopPropagation();
        
        if (!this.validateForm()) {
            // Encontrar primer error
            const firstError = this.form.querySelector('.is-invalid');
            if (firstError) {
                firstError.scrollIntoView({ behavior: 'smooth', block: 'center' });
                setTimeout(() => firstError.focus(), 300);
                this.showToast('Corrige los errores marcados en rojo', 'danger');
            }
            return false;
        }
        
        // Validación pasó, enviar el formulario
        this.guardarBtn.disabled = true;
        this.guardarBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Enviando...';
        
        // Marcar que estamos enviando
        this.isSubmitting = true;
        
        // Enviar el formulario de forma tradicional (no AJAX) para que Django maneje los mensajes
        // Remover el listener para evitar loop
        this.form.removeEventListener('submit', this.boundHandleSubmit);
        
        // Esperar 1.5 segundos para que el usuario vea el feedback visual
        setTimeout(() => {
            // Crear un input submit oculto y hacer clic en él
            const submitInput = document.createElement('input');
            submitInput.type = 'submit';
            submitInput.style.display = 'none';
            this.form.appendChild(submitInput);
            submitInput.click();
        }, 1500);
    }

    showToast(message, type = 'info') {
        const toastContainer = document.querySelector('.toast-container') || this.createToastContainer();
        const toastId = `toast-${Date.now()}`;
        
        const icons = {
            'success': 'fa-check-circle',
            'danger': 'fa-exclamation-circle',
            'warning': 'fa-exclamation-triangle',
            'info': 'fa-info-circle'
        };
        
        const toastHTML = `
            <div id="${toastId}" class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
                <div class="toast-header bg-${type} text-white">
                    <i class="fas ${icons[type]} me-2"></i>
                    <strong class="me-auto">${type.charAt(0).toUpperCase() + type.slice(1)}</strong>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast"></button>
                </div>
                <div class="toast-body">
                    ${message}
                </div>
            </div>
        `;
        
        toastContainer.insertAdjacentHTML('beforeend', toastHTML);
        const toastElement = document.getElementById(toastId);
        
        if (type !== 'danger') {
            setTimeout(() => {
                toastElement.classList.remove('show');
                setTimeout(() => toastElement.remove(), 300);
            }, 4000);
        }
    }

    createToastContainer() {
        let container = document.querySelector('.toast-container');
        if (!container) {
            container = document.createElement('div');
            container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
            container.style.zIndex = '9999';
            document.body.appendChild(container);
        }
        return container;
    }
}

// ============================================
// SMART PRODUCT SEARCH (AUTOCOMPLETADO)
// ============================================
class SmartProductSearch {
    constructor(productos) {
        this.productos = productos;
        this.setupSearchListeners();
    }

    setupSearchListeners() {
        // Ya no usamos Select2, solo select nativo
        // Los selects nativos funcionan mejor para este caso
    }
}

document.addEventListener('DOMContentLoaded', function() {
    const form = new ReabastecimientoForm();
    new SmartProductSearch(form.productos);
    
    // Exponer función global para importación desde Excel
    window.addProductosFromExcel = function(productos) {
        console.log('[EXCEL IMPORT] Agregando productos al formulario:', productos);
        
        // Limpiar TODAS las filas existentes antes de importar
        const tbody = form.detalleTable.querySelector('tbody');
        const existingRows = tbody.querySelectorAll('tr.formset-row');
        console.log('[EXCEL IMPORT] Limpiando todas las filas existentes:', existingRows.length);
        existingRows.forEach(row => {
            row.remove();
        });
        
        // Resetear el contador de formularios a 0
        form.managementForm.value = 0;
        console.log('[EXCEL IMPORT] Contador de formularios reseteado a 0');
        
        // Guardar referencia al template ANTES de empezar a clonar
        const template = document.getElementById('empty-form-template');
        if (!template) {
            console.error('[EXCEL IMPORT] No se encontró el template');
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'No se pudo encontrar el template del formulario',
                confirmButtonColor: '#dc3545'
            });
            return;
        }
        
        // Verificar que tenemos el tbody correcto de la tabla principal
        const mainTbody = form.detalleTable.querySelector('tbody');
        console.log('[EXCEL IMPORT] Tbody principal encontrado:', !!mainTbody);
        console.log('[EXCEL IMPORT] ID de la tabla:', form.detalleTable.id);
        
        const templateRow = template.querySelector('tr');
        if (!templateRow) {
            console.error('[EXCEL IMPORT] No se encontró el <tr> en el template');
            Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'El template del formulario está corrupto',
                confirmButtonColor: '#dc3545'
            });
            return;
        }
        
        // Guardar una copia del template para poder clonar múltiples veces
        const templateClone = templateRow.cloneNode(true);
        
        // Función para llenar una fila con datos
        const fillRow = (rowIndex, producto) => {
            return new Promise((resolve) => {
                console.log(`[EXCEL IMPORT] Procesando producto ${rowIndex + 1}:`, producto);
                
                // Clonar desde la copia guardada
                const newRow = templateClone.cloneNode(true);
                const totalForms = parseInt(form.managementForm.value);
                
                // Asegurar que la fila sea visible desde el inicio
                newRow.style.display = 'table-row';
                newRow.classList.remove('d-none');
                newRow.classList.add('formset-row');
                
                // Actualizar nombres e IDs
                newRow.querySelectorAll('input, select').forEach(field => {
                    const name = field.name;
                    if (name) {
                        field.name = name.replace(/__prefix__/g, totalForms);
                        field.id = field.id ? field.id.replace(/__prefix__/g, totalForms) : '';
                    }
                });
                
                // Agregar al DOM - Asegurarse de usar el tbody correcto (no el del template)
                const allTbodies = document.querySelectorAll('tbody');
                console.log(`[EXCEL IMPORT] Total de tbody encontrados: ${allTbodies.length}`);
                
                // El primer tbody es el de la tabla principal, el segundo es el del template oculto
                const tbody = form.detalleTable.querySelector('tbody:not(#empty-form-template)');
                if (!tbody) {
                    console.error('[EXCEL IMPORT] No se encontró el tbody de la tabla principal');
                    resolve();
                    return;
                }
                
                console.log(`[EXCEL IMPORT] Usando tbody:`, tbody.parentElement.id);
                tbody.appendChild(newRow);
                const newTotalForms = totalForms + 1;
                form.managementForm.value = newTotalForms;
                
                console.log(`[EXCEL IMPORT] Fila ${rowIndex + 1} creada y agregada al DOM`);
                console.log(`[EXCEL IMPORT] TOTAL_FORMS actualizado a: ${newTotalForms}`);
                console.log(`[EXCEL IMPORT] Fila visible:`, newRow.style.display, newRow.classList.contains('formset-row'));
                console.log(`[EXCEL IMPORT] Total filas en tbody principal:`, tbody.querySelectorAll('tr').length);
                
                // Verificar los nombres de los campos
                const productoField = newRow.querySelector('select[name*="producto"]');
                const cantidadField = newRow.querySelector('input[name*="cantidad"]');
                console.log(`[EXCEL IMPORT] Nombres de campos - Producto: ${productoField?.name}, Cantidad: ${cantidadField?.name}`);
                
                // Esperar un momento para que se renderice
                setTimeout(() => {
                    // Buscar campos en la nueva fila
                    const productoSelect = newRow.querySelector('select[name*="producto"]');
                    const cantidadInput = newRow.querySelector('input[name*="cantidad"]');
                    const costoInput = newRow.querySelector('input[name*="costo_unitario"]');
                    const ivaSelect = newRow.querySelector('select.iva-select');
                    const fechaInput = newRow.querySelector('input[name*="fecha_caducidad"]');
                    
                    console.log(`[EXCEL IMPORT] Campos encontrados:`, {
                        producto: !!productoSelect,
                        cantidad: !!cantidadInput,
                        costo: !!costoInput,
                        iva: !!ivaSelect,
                        fecha: !!fechaInput
                    });
                    
                    // Llenar producto - primero poblar opciones
                    if (productoSelect) {
                        // Limpiar opciones existentes
                        productoSelect.innerHTML = '<option value="">Seleccionar producto...</option>';
                        
                        // Agregar todas las opciones de productos
                        form.productos.forEach(p => {
                            const option = document.createElement('option');
                            option.value = p.id;
                            option.textContent = p.nombre;
                            productoSelect.appendChild(option);
                        });
                        
                        // Ahora seleccionar el producto
                        productoSelect.value = producto.producto_id;
                        console.log(`[EXCEL IMPORT] Producto seleccionado: ${producto.producto_id} (${producto.producto_nombre})`);
                        productoSelect.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                    
                    // Llenar cantidad
                    if (cantidadInput) {
                        cantidadInput.value = producto.cantidad;
                        console.log(`[EXCEL IMPORT] Cantidad: ${producto.cantidad}`);
                        cantidadInput.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                    
                    // Llenar costo
                    if (costoInput) {
                        costoInput.value = producto.costo_unitario;
                        console.log(`[EXCEL IMPORT] Costo: ${producto.costo_unitario}`);
                        costoInput.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                    
                    // Poblar IVA pero NO seleccionar automáticamente - dejar en "--"
                    if (ivaSelect) {
                        // Poblar opciones de IVA
                        form.populateIvaSelects();
                        
                        // NO auto-seleccionar el IVA - dejar en placeholder para que el usuario lo seleccione
                        ivaSelect.value = '';
                        console.log(`[EXCEL IMPORT] IVA dejado sin seleccionar (--) para que el usuario lo elija`);
                        
                        // Resaltar el campo para que el usuario note que debe seleccionarlo
                        ivaSelect.style.backgroundColor = '#fff3cd'; // Amarillo suave
                        setTimeout(() => {
                            ivaSelect.style.backgroundColor = '';
                        }, 1500);
                    }
                    
                    // Llenar fecha
                    if (fechaInput && producto.fecha_caducidad) {
                        fechaInput.value = producto.fecha_caducidad;
                        console.log(`[EXCEL IMPORT] Fecha: ${producto.fecha_caducidad}`);
                    }
                    
                    console.log(`[EXCEL IMPORT] Producto ${rowIndex + 1} completado`);
                    
                    // Forzar actualización visual y asegurar visibilidad
                    newRow.style.display = 'table-row';
                    newRow.style.visibility = 'visible';
                    newRow.classList.add('formset-row');
                    newRow.classList.remove('d-none');
                    
                    // Hacer scroll a la fila si es necesario
                    if (rowIndex === 0) {
                        newRow.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }
                    
                    // Esperar antes de resolver
                    setTimeout(() => {
                        resolve();
                    }, 200);
                }, 300);
            });
        };
        
        // Procesar productos secuencialmente
        const processProductos = async () => {
            for (let i = 0; i < productos.length; i++) {
                await fillRow(i, productos[i]);
            }
            
            // Actualizar totales al final
            setTimeout(() => {
                console.log('[EXCEL IMPORT] Actualizando totales y validación...');
                
                // Forzar recálculo de totales
                form.calculateTotals();
                form.updateProductCount();
                form.validateForm();
                
                // Poblar todos los selects de IVA
                form.populateIvaSelects();
                
                // Verificar que las filas sean visibles
                const rows = document.querySelectorAll('tr.formset-row');
                console.log(`[EXCEL IMPORT] Total de filas en el DOM: ${rows.length}`);
                
                rows.forEach((row, idx) => {
                    const productoSelect = row.querySelector('select[name*="producto"]');
                    const cantidadInput = row.querySelector('input[name*="cantidad"]');
                    console.log(`[EXCEL IMPORT] Fila ${idx}: Producto=${productoSelect?.value}, Cantidad=${cantidadInput?.value}`);
                    
                    // Asegurar visibilidad completa
                    row.style.display = 'table-row';
                    row.style.visibility = 'visible';
                    row.classList.add('formset-row');
                    row.classList.remove('d-none');
                });
                
                // Hacer scroll a la tabla de productos
                const productosSection = document.querySelector('.reab-section');
                if (productosSection) {
                    productosSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
                
                // Verificar el estado final del formset
                const finalTotalForms = form.managementForm.value;
                console.log(`[EXCEL IMPORT] ✓ Todos los productos agregados exitosamente`);
                console.log(`[EXCEL IMPORT] Estado final - TOTAL_FORMS: ${finalTotalForms}`);
                
                // Listar todos los campos del formset
                for (let i = 0; i < finalTotalForms; i++) {
                    const productoField = document.querySelector(`[name="reabastecimientodetalle_set-${i}-producto"]`);
                    const cantidadField = document.querySelector(`[name="reabastecimientodetalle_set-${i}-cantidad"]`);
                    console.log(`[EXCEL IMPORT] Formset ${i}: producto=${productoField?.value}, cantidad=${cantidadField?.value}`);
                }
            }, 500);
        };
        
        processProductos();
    };
});


// ============================================
// MODAL NUEVO PROVEEDOR
// ============================================
document.addEventListener('DOMContentLoaded', function() {
    const guardarProveedorBtn = document.getElementById('guardarProveedorBtn');
    const form = document.getElementById('nuevoProveedorForm');
    
    if (form) {
        // Validación en tiempo real
        const inputs = form.querySelectorAll('input, select');
        inputs.forEach(input => {
            input.addEventListener('blur', function() {
                validateField(this);
            });
            
            input.addEventListener('input', function() {
                if (this.classList.contains('is-invalid')) {
                    validateField(this);
                }
            });
        });
        
        // Validación específica para teléfono
        const telefonoInput = document.getElementById('telefonoEmpresa');
        if (telefonoInput) {
            telefonoInput.addEventListener('input', function() {
                // Permitir solo números, espacios, paréntesis, guiones y +
                this.value = this.value.replace(/[^0-9\s\(\)\-\+]/g, '');
            });
        }
        
        // Validación específica para documento
        const documentoInput = document.getElementById('documentoIdentificacionEmpresa');
        if (documentoInput) {
            documentoInput.addEventListener('input', function() {
                // Permitir números, guiones y espacios
                this.value = this.value.replace(/[^0-9\-\s]/g, '');
            });
        }
    }
    
    function validateField(field) {
        const value = field.value.trim();
        let isValid = true;
        
        // Validar campo requerido
        if (field.hasAttribute('required') && !value) {
            isValid = false;
        }
        
        // Validar email
        if (field.type === 'email' && value) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            isValid = emailRegex.test(value);
        }
        
        // Validar teléfono
        if (field.id === 'telefonoEmpresa' && value) {
            // Debe tener al menos 7 dígitos
            const digitsOnly = value.replace(/\D/g, '');
            isValid = digitsOnly.length >= 7;
        }
        
        // Validar documento
        if (field.id === 'documentoIdentificacionEmpresa' && value) {
            // Debe tener al menos 5 caracteres
            isValid = value.length >= 5;
        }
        
        // Aplicar clases de validación
        if (isValid) {
            field.classList.remove('is-invalid');
            field.classList.add('is-valid');
        } else {
            field.classList.remove('is-valid');
            field.classList.add('is-invalid');
        }
        
        return isValid;
    }
    
    function validateForm() {
        const inputs = form.querySelectorAll('input[required], select[required]');
        let isValid = true;
        
        inputs.forEach(input => {
            if (!validateField(input)) {
                isValid = false;
            }
        });
        
        return isValid;
    }
    
    if (guardarProveedorBtn) {
        guardarProveedorBtn.addEventListener('click', async function() {
            console.log('[PROVEEDOR] Guardando nuevo proveedor...');
            
            // Validar formulario
            if (!validateForm()) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Campos incompletos o inválidos',
                    text: 'Por favor revisa los campos marcados en rojo',
                    confirmButtonColor: '#0d6efd'
                });
                return;
            }
            
            // Obtener valores del formulario
            const tipoDocumento = document.getElementById('tipoDocumentoEmpresa').value;
            const documentoIdentificacion = document.getElementById('documentoIdentificacionEmpresa').value.trim();
            const nombreEmpresa = document.getElementById('nombreEmpresa').value.trim();
            const telefono = document.getElementById('telefonoEmpresa').value.trim();
            const correo = document.getElementById('correoEmpresa').value.trim();
            const direccion = document.getElementById('direccionEmpresa').value.trim();
            
            // Validación adicional
            if (!tipoDocumento) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Tipo de documento requerido',
                    text: 'Selecciona el tipo de documento',
                    confirmButtonColor: '#0d6efd'
                });
                return;
            }
            
            // Deshabilitar botón y mostrar loading
            const originalText = guardarProveedorBtn.innerHTML;
            guardarProveedorBtn.disabled = true;
            guardarProveedorBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
            
            try {
                const response = await fetch('/suppliers/proveedor/crear_ajax/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
                    },
                    body: JSON.stringify({
                        tipo_documento: tipoDocumento,
                        documento_identificacion: documentoIdentificacion,
                        nombre_empresa: nombreEmpresa,
                        telefono: telefono,
                        correo: correo,
                        direccion: direccion
                    })
                });
                
                const data = await response.json();
                
                if (!response.ok || data.error) {
                    throw new Error(data.error || 'Error al crear proveedor');
                }
                
                console.log('[PROVEEDOR] Proveedor creado:', data);
                
                // Agregar el nuevo proveedor al select
                const proveedorSelect = document.getElementById('id_proveedor_select');
                if (proveedorSelect) {
                    const option = document.createElement('option');
                    option.value = data.id;
                    option.textContent = data.nombre_empresa;
                    option.selected = true;
                    proveedorSelect.appendChild(option);
                    proveedorSelect.dispatchEvent(new Event('change'));
                }
                
                // Cerrar modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('nuevoProveedorModal'));
                if (modal) {
                    modal.hide();
                }
                
                // Limpiar formulario y validaciones
                form.reset();
                form.querySelectorAll('.is-valid, .is-invalid').forEach(el => {
                    el.classList.remove('is-valid', 'is-invalid');
                });
                
                // Mostrar mensaje de éxito
                Swal.fire({
                    icon: 'success',
                    title: '¡Proveedor creado!',
                    html: `
                        <div class="text-start">
                            <p class="mb-2"><strong>${data.nombre_empresa}</strong></p>
                            <p class="mb-0 text-muted">ha sido agregado exitosamente</p>
                        </div>
                    `,
                    timer: 2500,
                    timerProgressBar: true,
                    showConfirmButton: false
                });
                
            } catch (error) {
                console.error('[PROVEEDOR] Error:', error);
                Swal.fire({
                    icon: 'error',
                    title: 'Error al crear proveedor',
                    text: error.message,
                    confirmButtonColor: '#dc3545'
                });
            } finally {
                guardarProveedorBtn.disabled = false;
                guardarProveedorBtn.innerHTML = originalText;
            }
        });
    }
    
    // Limpiar validaciones al abrir el modal
    const modal = document.getElementById('nuevoProveedorModal');
    if (modal) {
        modal.addEventListener('show.bs.modal', function() {
            const form = document.getElementById('nuevoProveedorForm');
            if (form) {
                form.reset();
                form.querySelectorAll('.is-valid, .is-invalid').forEach(el => {
                    el.classList.remove('is-valid', 'is-invalid');
                });
            }
        });
    }
});


// ============================================
// MODAL NUEVO PRODUCTO
// ============================================
document.addEventListener('DOMContentLoaded', function() {
    const guardarProductoBtn = document.getElementById('guardarProductoBtn');
    const productoForm = document.getElementById('nuevoProductoForm');
    const categoriaSelect = document.getElementById('categoriaProducto');
    
    // Cargar categorías al abrir el modal
    const productoModal = document.getElementById('nuevoProductoModal');
    if (productoModal) {
        productoModal.addEventListener('show.bs.modal', async function() {
            await cargarCategorias();
            
            // Limpiar formulario
            if (productoForm) {
                productoForm.reset();
                productoForm.querySelectorAll('.is-valid, .is-invalid').forEach(el => {
                    el.classList.remove('is-valid', 'is-invalid');
                });
            }
        });
    }
    
    async function cargarCategorias() {
        if (!categoriaSelect) return;
        
        console.log('[PRODUCTO] Cargando categorías...');
        categoriaSelect.innerHTML = '<option value="">Cargando categorías...</option>';
        
        try {
            // Estrategia 1: Leer desde el script JSON en el template (categorias_json)
            const categoriasDataScript = document.getElementById('categoriasData');
            if (categoriasDataScript) {
                try {
                    const categoriasData = JSON.parse(categoriasDataScript.textContent);
                    if (categoriasData && categoriasData.length > 0) {
                        categoriaSelect.innerHTML = '<option value="">Seleccionar categoría...</option>';
                        categoriasData.forEach(cat => {
                            const option = document.createElement('option');
                            option.value = cat.id;
                            option.textContent = cat.nombre;
                            categoriaSelect.appendChild(option);
                        });
                        console.log('[PRODUCTO] ✓ Categorías cargadas desde backend:', categoriasData.length);
                        return;
                    }
                } catch (e) {
                    console.warn('[PRODUCTO] Error al parsear categorias_json:', e);
                }
            }
            
            // Estrategia 2: Extraer desde productos existentes en el select de productos
            const productoSelects = document.querySelectorAll('.producto-select');
            const categoriasMap = new Map();
            
            // Intentar extraer de los selects de productos que ya tienen opciones
            productoSelects.forEach(select => {
                select.querySelectorAll('option').forEach(option => {
                    const categoriaId = option.dataset.categoriaId;
                    const categoriaNombre = option.dataset.categoriaNombre;
                    if (categoriaId && categoriaNombre) {
                        categoriasMap.set(categoriaId, categoriaNombre);
                    }
                });
            });
            
            if (categoriasMap.size > 0) {
                categoriaSelect.innerHTML = '<option value="">Seleccionar categoría...</option>';
                categoriasMap.forEach((nombre, id) => {
                    const option = document.createElement('option');
                    option.value = id;
                    option.textContent = nombre;
                    categoriaSelect.appendChild(option);
                });
                
                console.log('[PRODUCTO] ✓ Categorías cargadas desde selects:', categoriasMap.size);
                return;
            }
            
            // Estrategia 3: Hacer petición AJAX al backend
            try {
                const response = await fetch('/inventory/categorias/list_ajax/');
                if (response.ok) {
                    const data = await response.json();
                    if (data.categorias && data.categorias.length > 0) {
                        categoriaSelect.innerHTML = '<option value="">Seleccionar categoría...</option>';
                        data.categorias.forEach(cat => {
                            const option = document.createElement('option');
                            option.value = cat.id;
                            option.textContent = cat.nombre;
                            categoriaSelect.appendChild(option);
                        });
                        console.log('[PRODUCTO] ✓ Categorías cargadas desde API:', data.categorias.length);
                        return;
                    }
                }
            } catch (e) {
                console.warn('[PRODUCTO] No se pudo cargar desde API:', e);
            }
            
            // Estrategia 4: Usar categorías comunes por defecto
            console.warn('[PRODUCTO] ⚠️ No se encontraron categorías, usando valores por defecto');
            
            // Cargar categorías comunes que probablemente existen
            categoriaSelect.innerHTML = `
                <option value="">Seleccionar categoría...</option>
                <option value="1">Bebidas</option>
                <option value="2">Alimentos</option>
                <option value="3">Snacks</option>
                <option value="4">Licores</option>
                <option value="5">Lácteos</option>
                <option value="6">Otros</option>
            `;
            
            console.log('[PRODUCTO] ℹ️ Categorías comunes cargadas. Si no encuentras la que necesitas, créala con el botón +');
            
        } catch (error) {
            console.error('[PRODUCTO] Error al cargar categorías:', error);
            categoriaSelect.innerHTML = `
                <option value="">Seleccionar categoría...</option>
                <option value="1">Bebidas</option>
                <option value="2">Alimentos</option>
                <option value="3">Otros</option>
            `;
        }
    }
    
    // Validación en tiempo real
    if (productoForm) {
        const inputs = productoForm.querySelectorAll('input, select, textarea');
        inputs.forEach(input => {
            input.addEventListener('blur', function() {
                validateProductField(this);
            });
            
            input.addEventListener('input', function() {
                if (this.classList.contains('is-invalid')) {
                    validateProductField(this);
                }
            });
        });
    }
    
    function validateProductField(field) {
        const value = field.value.trim();
        let isValid = true;
        
        // Validar campo requerido
        if (field.hasAttribute('required') && !value) {
            isValid = false;
        }
        
        // Validar precio
        if (field.id === 'precioProducto' && value) {
            const precio = parseFloat(value);
            isValid = precio > 0;
        }
        
        // Validar stock mínimo
        if (field.id === 'stockMinProducto' && value) {
            const stock = parseInt(value);
            isValid = stock >= 0;
        }
        
        // Aplicar clases de validación
        if (isValid) {
            field.classList.remove('is-invalid');
            field.classList.add('is-valid');
        } else {
            field.classList.remove('is-valid');
            field.classList.add('is-invalid');
        }
        
        return isValid;
    }
    
    function validateProductForm() {
        const inputs = productoForm.querySelectorAll('input[required], select[required]');
        let isValid = true;
        
        inputs.forEach(input => {
            if (!validateProductField(input)) {
                isValid = false;
            }
        });
        
        return isValid;
    }
    
    if (guardarProductoBtn) {
        guardarProductoBtn.addEventListener('click', async function() {
            console.log('[PRODUCTO] Guardando nuevo producto...');
            
            // Validar formulario
            if (!validateProductForm()) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Campos incompletos o inválidos',
                    text: 'Por favor revisa los campos marcados en rojo',
                    confirmButtonColor: '#0d6efd'
                });
                return;
            }
            
            // Obtener valores
            const nombre = document.getElementById('nombreProducto').value.trim();
            const categoriaId = document.getElementById('categoriaProducto').value;
            const precio = parseFloat(document.getElementById('precioProducto').value);
            const stockMin = parseInt(document.getElementById('stockMinProducto').value);
            const descripcion = document.getElementById('descripcionProducto').value.trim();
            
            if (!categoriaId) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Categoría requerida',
                    text: 'Selecciona una categoría para el producto',
                    confirmButtonColor: '#0d6efd'
                });
                return;
            }
            
            // Deshabilitar botón
            const originalText = guardarProductoBtn.innerHTML;
            guardarProductoBtn.disabled = true;
            guardarProductoBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
            
            try {
                const response = await fetch('/inventory/producto/crear/ajax/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
                    },
                    body: JSON.stringify({
                        nombre: nombre,
                        categoria: categoriaId,
                        precio_unitario: precio,
                        stock_minimo: stockMin,
                        descripcion: descripcion,
                        tasa_iva: getTasaIvaDefault()
                    })
                });
                
                const data = await response.json();
                
                if (!response.ok || data.error) {
                    throw new Error(data.error || 'Error al crear producto');
                }
                
                console.log('[PRODUCTO] Producto creado:', data);
                
                // Cerrar modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('nuevoProductoModal'));
                if (modal) {
                    modal.hide();
                }
                
                // Limpiar formulario
                productoForm.reset();
                productoForm.querySelectorAll('.is-valid, .is-invalid').forEach(el => {
                    el.classList.remove('is-valid', 'is-invalid');
                });
                
                // Mostrar mensaje de éxito
                Swal.fire({
                    icon: 'success',
                    title: '¡Producto creado!',
                    html: `
                        <div class="text-start">
                            <p class="mb-2"><strong>${data.nombre}</strong></p>
                            <p class="mb-0 text-muted">Precio: ${new Intl.NumberFormat('es-CO', {style: 'currency', currency: 'COP', minimumFractionDigits: 0}).format(precio)}</p>
                        </div>
                    `,
                    timer: 2500,
                    timerProgressBar: true,
                    showConfirmButton: false
                }).then(() => {
                    // Recargar página para actualizar lista de productos
                    location.reload();
                });
                
            } catch (error) {
                console.error('[PRODUCTO] Error:', error);
                Swal.fire({
                    icon: 'error',
                    title: 'Error al crear producto',
                    text: error.message,
                    confirmButtonColor: '#dc3545'
                });
            } finally {
                guardarProductoBtn.disabled = false;
                guardarProductoBtn.innerHTML = originalText;
            }
        });
    }
});


// ============================================
// MODAL NUEVA CATEGORÍA
// ============================================
document.addEventListener('DOMContentLoaded', function() {
    const guardarCategoriaBtn = document.getElementById('guardarCategoriaBtn');
    const categoriaForm = document.getElementById('nuevaCategoriaForm');
    const nombreCategoriaInput = document.getElementById('nombreCategoria');
    
    // Validación en tiempo real
    if (nombreCategoriaInput) {
        nombreCategoriaInput.addEventListener('input', function() {
            if (this.value.trim()) {
                this.classList.remove('is-invalid');
                this.classList.add('is-valid');
            } else {
                this.classList.remove('is-valid');
                this.classList.add('is-invalid');
            }
        });
    }
    
    // Manejar el botón de nueva categoría manualmente
    const btnNuevaCategoria = document.getElementById('btnNuevaCategoria');
    if (btnNuevaCategoria) {
        btnNuevaCategoria.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            // Limpiar formulario
            if (categoriaForm) {
                categoriaForm.reset();
            }
            if (nombreCategoriaInput) {
                nombreCategoriaInput.classList.remove('is-valid', 'is-invalid');
            }
            
            // Abrir modal de categoría sin cerrar el de producto
            const categoriaModal = document.getElementById('nuevaCategoriaModal');
            if (categoriaModal) {
                const modalInstance = new bootstrap.Modal(categoriaModal, {
                    backdrop: 'static',
                    keyboard: false
                });
                modalInstance.show();
                
                // Ajustar z-index para que esté encima del modal de producto
                setTimeout(() => {
                    categoriaModal.style.zIndex = '1060';
                    const backdrops = document.querySelectorAll('.modal-backdrop');
                    if (backdrops.length > 0) {
                        backdrops[backdrops.length - 1].style.zIndex = '1055';
                    }
                }, 50);
            }
        });
    }
    
    // Limpiar al abrir el modal
    const categoriaModal = document.getElementById('nuevaCategoriaModal');
    if (categoriaModal) {
        // Restaurar el modal de producto cuando se cierra el de categoría
        categoriaModal.addEventListener('hidden.bs.modal', function() {
            // Limpiar backdrops extra
            const backdrops = document.querySelectorAll('.modal-backdrop');
            if (backdrops.length > 1) {
                // Eliminar todos los backdrops excepto el primero
                for (let i = 1; i < backdrops.length; i++) {
                    backdrops[i].remove();
                }
            }
            
            const productoModal = document.getElementById('nuevoProductoModal');
            if (productoModal && productoModal.classList.contains('show')) {
                // Asegurar que el body tenga la clase modal-open
                document.body.classList.add('modal-open');
                
                // Asegurar que el modal de producto esté visible
                productoModal.style.zIndex = '1050';
                
                // Asegurar que el backdrop restante tenga el z-index correcto
                const remainingBackdrop = document.querySelector('.modal-backdrop');
                if (remainingBackdrop) {
                    remainingBackdrop.style.zIndex = '1040';
                }
                
                // Enfocar el select de categoría
                const categoriaSelect = document.getElementById('categoriaProducto');
                if (categoriaSelect) {
                    setTimeout(() => categoriaSelect.focus(), 100);
                }
            }
        });
    }
    
    if (guardarCategoriaBtn) {
        guardarCategoriaBtn.addEventListener('click', async function() {
            console.log('[CATEGORIA] Guardando nueva categoría...');
            
            const nombre = nombreCategoriaInput ? nombreCategoriaInput.value.trim() : '';
            
            if (!nombre) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Nombre requerido',
                    text: 'Ingresa el nombre de la categoría',
                    confirmButtonColor: '#0d6efd'
                });
                if (nombreCategoriaInput) {
                    nombreCategoriaInput.classList.add('is-invalid');
                    nombreCategoriaInput.focus();
                }
                return;
            }
            
            // Deshabilitar botón y mostrar loading
            const originalText = guardarCategoriaBtn.innerHTML;
            guardarCategoriaBtn.disabled = true;
            guardarCategoriaBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
            
            try {
                const response = await fetch('/inventory/categoria/crear/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRFToken': document.querySelector('[name=csrfmiddlewaretoken]').value
                    },
                    body: JSON.stringify({
                        nombre: nombre
                    })
                });
                
                const data = await response.json();
                
                if (!response.ok || data.error || data.errors) {
                    const errorMsg = data.error || (data.errors && data.errors.nombre ? data.errors.nombre.join(', ') : 'Error al crear categoría');
                    throw new Error(errorMsg);
                }
                
                console.log('[CATEGORIA] Categoría creada:', data);
                
                // Agregar la nueva categoría al select del modal de producto
                const categoriaSelect = document.getElementById('categoriaProducto');
                if (categoriaSelect) {
                    const option = document.createElement('option');
                    option.value = data.id;
                    option.textContent = data.nombre;
                    option.selected = true;
                    categoriaSelect.appendChild(option);
                    console.log('[CATEGORIA] Categoría agregada al select');
                }
                
                // Cerrar modal de categoría
                const modal = bootstrap.Modal.getInstance(categoriaModal);
                if (modal) {
                    modal.hide();
                }
                
                // Limpiar formulario
                if (categoriaForm) {
                    categoriaForm.reset();
                }
                if (nombreCategoriaInput) {
                    nombreCategoriaInput.classList.remove('is-valid', 'is-invalid');
                }
                
                // Mostrar toast discreto en lugar de SweetAlert
                showToastNotification(`✓ Categoría "${data.nombre}" creada`, 'success');
                
                // Asegurar que el modal de producto permanezca abierto y enfocado
                setTimeout(() => {
                    // Eliminar todos los backdrops excepto el del modal de producto
                    const backdrops = document.querySelectorAll('.modal-backdrop');
                    if (backdrops.length > 1) {
                        // Eliminar el último backdrop (del modal de categoría)
                        backdrops[backdrops.length - 1].remove();
                    }
                    
                    // Restaurar el body
                    document.body.classList.add('modal-open');
                    
                    const productoModal = document.getElementById('nuevoProductoModal');
                    if (productoModal && productoModal.classList.contains('show')) {
                        // Asegurar z-index correcto
                        productoModal.style.zIndex = '1050';
                        
                        // Enfocar el siguiente campo (precio)
                        const precioInput = document.getElementById('precioProducto');
                        if (precioInput) {
                            precioInput.focus();
                        }
                    }
                }, 300);
                
            } catch (error) {
                console.error('[CATEGORIA] Error:', error);
                Swal.fire({
                    icon: 'error',
                    title: 'Error al crear categoría',
                    text: error.message,
                    confirmButtonColor: '#dc3545'
                });
            } finally {
                guardarCategoriaBtn.disabled = false;
                guardarCategoriaBtn.innerHTML = originalText;
            }
        });
    }
});


// ============================================
// FUNCIÓN AUXILIAR PARA TOASTS
// ============================================
function showToastNotification(message, type = 'info') {
    const toastContainer = document.querySelector('.toast-container') || createToastContainer();
    const toastId = `toast-${Date.now()}`;
    
    const bgColors = {
        'success': 'bg-success',
        'danger': 'bg-danger',
        'warning': 'bg-warning',
        'info': 'bg-info'
    };
    
    const icons = {
        'success': 'fa-check-circle',
        'danger': 'fa-exclamation-circle',
        'warning': 'fa-exclamation-triangle',
        'info': 'fa-info-circle'
    };
    
    const toastHTML = `
        <div id="${toastId}" class="toast align-items-center text-white ${bgColors[type]} border-0" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="d-flex">
                <div class="toast-body">
                    <i class="fas ${icons[type]} me-2"></i>${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    `;
    
    toastContainer.insertAdjacentHTML('beforeend', toastHTML);
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement, { delay: 3000 });
    toast.show();
    
    // Eliminar después de ocultar
    toastElement.addEventListener('hidden.bs.toast', function() {
        toastElement.remove();
    });
}

function createToastContainer() {
    let container = document.querySelector('.toast-container');
    if (!container) {
        container = document.createElement('div');
        container.className = 'toast-container position-fixed top-0 end-0 p-3';
        container.style.zIndex = '9999';
        document.body.appendChild(container);
    }
    return container;
}


// ============================================
// FUNCIÓN AUXILIAR PARA OBTENER TASA IVA POR DEFECTO
// ============================================
function getTasaIvaDefault() {
    // Buscar en las tasas de IVA disponibles
    const tasasIvaScript = document.querySelector('script[data-tasas-iva]');
    if (tasasIvaScript) {
        try {
            const tasasIva = JSON.parse(tasasIvaScript.textContent);
            // Buscar la tasa del 19% (IVA General)
            const tasaGeneral = tasasIva.find(t => parseFloat(t.porcentaje) === 19);
            if (tasaGeneral) {
                return tasaGeneral.id;
            } else if (tasasIva.length > 0) {
                // Si no hay 19%, usar la primera disponible
                return tasasIva[0].id;
            }
        } catch (e) {
            console.warn('[PRODUCTO] Error al obtener tasa de IVA:', e);
        }
    }
    // Fallback: retornar null y dejar que el backend maneje el valor por defecto
    return null;
}
