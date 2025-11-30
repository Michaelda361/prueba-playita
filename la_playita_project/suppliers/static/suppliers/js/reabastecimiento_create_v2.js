// Reabastecimiento Create Form - Versión Optimizada para Velocidad
// Cambios: Autocompletado inteligente, validación en vivo, cálculos automáticos

document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('reabastecimientoForm');
    const detalleTable = document.getElementById('detalleTable');
    const managementForm = document.querySelector('[name="reabastecimientodetalle_set-TOTAL_FORMS"]');
    const addRowBtn = document.getElementById('add-row-formset');
    const guardarBtn = document.getElementById('guardarReabastecimientoBtn');
    const cancelarBtn = document.getElementById('cancelarBtn');
    const proveedorSelect = document.getElementById('id_proveedor_select');
    
    const productos = JSON.parse(document.querySelector('script[data-productos]')?.textContent || '[]');
    const tasasIva = JSON.parse(document.querySelector('script[data-tasas-iva]')?.textContent || '[]');
    
    // Llenar los selects de IVA con los valores de la BD
    function populateIvaSelects() {
        document.querySelectorAll('.iva-select').forEach(select => {
            // Limpiar opciones existentes excepto la primera
            while (select.options.length > 1) {
                select.remove(1);
            }
            
            // Agregar opciones de tasas de IVA
            if (tasasIva && tasasIva.length > 0) {
                tasasIva.forEach(tasa => {
                    const option = document.createElement('option');
                    option.value = tasa.porcentaje;
                    option.textContent = `${tasa.porcentaje}%`;
                    select.appendChild(option);
                });
            } else {
                // Fallback si no hay datos
                const defaultTasas = [0, 5, 19];
                defaultTasas.forEach(tasa => {
                    const option = document.createElement('option');
                    option.value = tasa;
                    option.textContent = `${tasa}%`;
                    select.appendChild(option);
                });
            }
        });
    }
    
    // Llenar al cargar
    populateIvaSelects();

    // ============================================
    // 1. QUICK SUPPLIER BUTTONS
    // ============================================
    document.querySelectorAll('.quick-supplier-btn').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            const supplierId = this.dataset.supplierId;
            if (proveedorSelect) {
                proveedorSelect.value = supplierId;
                proveedorSelect.dispatchEvent(new Event('change', { bubbles: true }));
                this.classList.add('active');
            }
        });
    });

    // ============================================
    // 2. AGREGAR FILA
    // ============================================
    addRowBtn.addEventListener('click', addFormRow);

    function addFormRow() {
        const totalForms = parseInt(managementForm.value);
        const emptyForm = document.getElementById('empty-form-template').querySelector('tr');
        const newRow = emptyForm.cloneNode(true);
        
        newRow.classList.add('formset-row');
        newRow.id = `detalle-row-${totalForms}`;
        
        // Actualizar nombres de campos
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
        detalleTable.querySelector('tbody').appendChild(newRow);

        setTimeout(() => {
            newRow.style.transition = 'opacity 0.3s ease, background-color 0.5s ease';
            newRow.style.opacity = '1';
            setTimeout(() => newRow.style.backgroundColor = '', 1000);
        }, 10);

        managementForm.value = totalForms + 1;
        newRow.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        
        // Llenar el select de IVA de la nueva fila
        const ivaSelect = newRow.querySelector('.iva-select');
        if (ivaSelect) {
            if (tasasIva && tasasIva.length > 0) {
                tasasIva.forEach(tasa => {
                    const option = document.createElement('option');
                    option.value = tasa.porcentaje;
                    option.textContent = `${tasa.porcentaje}%`;
                    ivaSelect.appendChild(option);
                });
            } else {
                const defaultTasas = [0, 5, 19];
                defaultTasas.forEach(tasa => {
                    const option = document.createElement('option');
                    option.value = tasa;
                    option.textContent = `${tasa}%`;
                    ivaSelect.appendChild(option);
                });
            }
        }
        
        const firstInput = newRow.querySelector('input, select');
        if (firstInput) setTimeout(() => firstInput.focus(), 300);

        calculateTotals();
        validateForm();
        updateProductCount();
    }

    // ============================================
    // 3. ELIMINAR FILA
    // ============================================
    document.addEventListener('click', function(e) {
        if (e.target.closest('.delete-row-btn')) {
            e.preventDefault();
            const row = e.target.closest('tr.formset-row');
            if (row) {
                row.style.transition = 'opacity 0.3s ease';
                row.style.opacity = '0';
                setTimeout(() => {
                    row.remove();
                    updateProductCount();
                    calculateTotals();
                    validateForm();
                }, 300);
            }
        }
    });

    // ============================================
    // 4. SELECCIÓN DE PRODUCTO (AUTOCOMPLETADO)
    // ============================================
    document.addEventListener('change', function(e) {
        if (e.target.classList.contains('producto-select')) {
            handleProductSelection(e.target);
        }
    });

    function handleProductSelection(selectElement) {
        const productId = selectElement.value;
        const row = selectElement.closest('tr.formset-row');
        if (!row || !productId) return;

        const producto = productos.find(p => p.id == parseInt(productId));
        if (!producto) return;

        // Llenar costo unitario automáticamente
        const costoInput = row.querySelector('.costo-unitario-input');
        if (costoInput && producto.precio_unitario) {
            costoInput.value = producto.precio_unitario;
            costoInput.classList.add('is-valid');
            costoInput.classList.remove('is-invalid');
        }

        // Llenar IVA automáticamente desde el producto
        const ivaSelect = row.querySelector('.iva-select');
        const ivaValue = producto.tasa_iva__porcentaje || 0;
        
        if (ivaSelect) {
            ivaSelect.value = ivaValue;
            ivaSelect.classList.add('is-valid');
        }

        calculateTotals();
        validateField(selectElement);
    }

    // ============================================
    // 5. CÁLCULOS EN VIVO
    // ============================================
    document.addEventListener('input', function(e) {
        if (e.target.classList.contains('cantidad-input') || 
            e.target.classList.contains('costo-unitario-input')) {
            calculateTotals();
        }
    });

    // Recalcular cuando cambia el IVA manualmente
    document.addEventListener('change', function(e) {
        if (e.target.classList.contains('iva-select')) {
            calculateTotals();
        }
    });

    function calculateTotals() {
        let grandSubtotal = 0;
        let grandIva = 0;

        detalleTable.querySelectorAll('tbody tr.formset-row').forEach(row => {
            const cantidadInput = row.querySelector('.cantidad-input');
            const costoInput = row.querySelector('.costo-unitario-input');
            const ivaSelect = row.querySelector('.iva-select');
            const subtotalDisplay = row.querySelector('.subtotal-display');

            if (cantidadInput && costoInput && ivaSelect) {
                const cantidad = parseFloat(cantidadInput.value) || 0;
                const costo = parseFloat(costoInput.value) || 0;
                const ivaPorcentaje = parseFloat(ivaSelect.value) || 0;

                const subtotal = cantidad * costo;
                const iva = subtotal * (ivaPorcentaje / 100);
                const total = subtotal + iva;

                grandSubtotal += subtotal;
                grandIva += iva;

                if (subtotalDisplay) {
                    subtotalDisplay.textContent = formatCurrency(total);
                }
            }
        });

        const grandTotal = grandSubtotal + grandIva;
        document.getElementById('gran-subtotal').textContent = formatCurrency(grandSubtotal);
        document.getElementById('gran-iva').textContent = formatCurrency(grandIva);
        document.getElementById('gran-total').textContent = formatCurrency(grandTotal);
    }

    function formatCurrency(value) {
        return new Intl.NumberFormat('es-CO', {
            style: 'currency',
            currency: 'COP',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    // ============================================
    // 6. VALIDACIÓN EN VIVO
    // ============================================
    document.addEventListener('change', function(e) {
        if (e.target.classList.contains('producto-select') ||
            e.target.classList.contains('cantidad-input') ||
            e.target.classList.contains('costo-unitario-input') ||
            e.target.type === 'date') {
            validateField(e.target);
            validateForm();
        }
    });

    function validateField(field) {
        const row = field.closest('tr.formset-row');
        if (!row) return true;

        let isValid = true;

        if (field.classList.contains('producto-select')) {
            isValid = !!field.value;
        } else if (field.classList.contains('cantidad-input')) {
            const value = parseFloat(field.value);
            isValid = field.value && value > 0 && value <= 999999;
        } else if (field.classList.contains('costo-unitario-input')) {
            const value = parseFloat(field.value);
            isValid = field.value && value > 0 && value <= 999999999;
        } else if (field.type === 'date') {
            const today = new Date().toISOString().split('T')[0];
            isValid = field.value && field.value >= today;
        }

        field.classList.toggle('is-invalid', !isValid);
        field.classList.toggle('is-valid', isValid);

        return isValid;
    }

    function validateForm() {
        let isValid = true;

        if (!proveedorSelect || !proveedorSelect.value) {
            isValid = false;
            proveedorSelect?.classList.add('is-invalid');
        } else {
            proveedorSelect?.classList.remove('is-invalid');
        }

        const rows = detalleTable.querySelectorAll('tbody tr.formset-row');
        if (rows.length === 0) {
            isValid = false;
        }

        rows.forEach(row => {
            const producto = row.querySelector('.producto-select');
            const cantidad = row.querySelector('.cantidad-input');
            const costo = row.querySelector('.costo-unitario-input');
            const fecha = row.querySelector('[type="date"]');

            let rowValid = true;
            [producto, cantidad, costo, fecha].forEach(field => {
                if (field && !validateField(field)) {
                    rowValid = false;
                    isValid = false;
                }
            });

            row.classList.toggle('row-error', !rowValid);
            row.classList.toggle('row-valid', rowValid);
        });

        guardarBtn.disabled = !isValid;
        return isValid;
    }

    function updateProductCount() {
        const rows = detalleTable.querySelectorAll('tbody tr.formset-row');
        managementForm.value = rows.length;
        document.getElementById('product-count').textContent = rows.length;
    }

    // ============================================
    // 7. CANCELAR
    // ============================================
    cancelarBtn.addEventListener('click', function(e) {
        e.preventDefault();
        const hasData = detalleTable.querySelectorAll('tbody tr.formset-row').length > 0 ||
                       (proveedorSelect && proveedorSelect.value);

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
    });

    // ============================================
    // 8. ENVÍO DEL FORMULARIO
    // ============================================
    form.addEventListener('submit', function(e) {
        if (!validateForm()) {
            e.preventDefault();
            e.stopPropagation();
        } else {
            guardarBtn.disabled = true;
            guardarBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';
        }
    });

    // Inicializar
    validateForm();
    calculateTotals();
    updateProductCount();
});
