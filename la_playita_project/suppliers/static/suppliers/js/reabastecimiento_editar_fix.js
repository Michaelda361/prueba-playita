// Fix para inicialización de IVA en editar
document.addEventListener('DOMContentLoaded', function() {
    setTimeout(() => {
        document.querySelectorAll('.iva-select').forEach(select => {
            const tasaIvaId = select.getAttribute('data-tasa-iva-id');
            if (tasaIvaId && select.value === '') {
                select.value = tasaIvaId;
                select.dispatchEvent(new Event('change', { bubbles: true }));
                console.log('[FIX] IVA inicializado correctamente:', tasaIvaId);
            }
        });
    }, 500);
});
