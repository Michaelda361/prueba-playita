"""
Tests para verificar que las ventas registren movimientos de inventario correctamente
"""
from django.test import TestCase, Client
from django.contrib.auth import get_user_model
from decimal import Decimal
import json

from pos.models import Venta, VentaDetalle, Pago
from inventory.models import Producto, Categoria, Lote, MovimientoInventario
from clients.models import Cliente
from users.models import Rol

Usuario = get_user_model()


class MovimientoInventarioVentaTest(TestCase):
    """Tests para verificar que las ventas registren movimientos de inventario"""
    
    def setUp(self):
        """Configurar datos de prueba"""
        # Crear rol
        self.rol_vendedor = Rol.objects.create(nombre='Vendedor')
        
        # Crear usuario
        self.usuario = Usuario.objects.create_user(
            username='12345678',
            password='testpass123',
            first_name='Test',
            last_name='User',
            email='test@test.com',
            rol=self.rol_vendedor
        )
        
        # Crear categoría
        self.categoria = Categoria.objects.create(nombre='Bebidas')
        
        # Crear producto
        self.producto = Producto.objects.create(
            nombre='Producto Test',
            precio_unitario=Decimal('10.00'),
            costo_promedio=Decimal('5.00'),
            stock_actual=100,
            stock_minimo=10,
            categoria=self.categoria
        )
        
        # Crear lote
        self.lote = Lote.objects.create(
            producto=self.producto,
            numero_lote='TEST-001',
            cantidad_disponible=100,
            costo_unitario_lote=Decimal('5.00'),
            fecha_caducidad='2026-12-31'
        )
        
        # Crear cliente
        self.cliente = Cliente.objects.create(
            nombres='Cliente',
            apellidos='Test',
            documento='87654321',
            telefono='1234567890',
            correo='cliente@test.com'
        )
        
        # Cliente para autenticación
        self.client = Client()
        self.client.login(username='12345678', password='testpass123')
    
    def test_venta_crea_movimiento_inventario(self):
        """Verificar que al procesar una venta se cree un movimiento de inventario"""
        # Datos de la venta
        venta_data = {
            'cliente_id': self.cliente.id,
            'metodo_pago': 'efectivo',
            'canal_venta': 'mostrador',
            'items': [
                {
                    'producto_id': self.producto.id,
                    'lote_id': self.lote.id,
                    'cantidad': 5,
                    'precio': '10.00'
                }
            ]
        }
        
        # Procesar venta
        response = self.client.post(
            '/pos/api/procesar-venta/',
            data=json.dumps(venta_data),
            content_type='application/json'
        )
        
        # Verificar respuesta exitosa
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertTrue(data['success'])
        
        venta_id = data['venta_id']
        
        # Verificar que se creó la venta
        venta = Venta.objects.get(id=venta_id)
        self.assertIsNotNone(venta)
        
        # Verificar que se creó el detalle
        detalle = VentaDetalle.objects.filter(venta=venta).first()
        self.assertIsNotNone(detalle)
        self.assertEqual(detalle.cantidad, 5)
        
        # ===== VERIFICACIÓN PRINCIPAL =====
        # Verificar que se creó el movimiento de inventario
        movimiento = MovimientoInventario.objects.filter(venta=venta).first()
        self.assertIsNotNone(movimiento, "No se creó el movimiento de inventario para la venta")
        
        # Verificar datos del movimiento
        self.assertEqual(movimiento.producto, self.producto)
        self.assertEqual(movimiento.lote, self.lote)
        self.assertEqual(movimiento.cantidad, -5)  # Negativo porque es salida
        self.assertEqual(movimiento.tipo_movimiento, 'salida')
        self.assertIn('Venta #', movimiento.descripcion)
        
        # Verificar que el lote se actualizó
        self.lote.refresh_from_db()
        self.assertEqual(self.lote.cantidad_disponible, 95)
    
    def test_venta_multiple_productos_crea_multiples_movimientos(self):
        """Verificar que una venta con múltiples productos cree múltiples movimientos"""
        # Crear segundo producto y lote
        producto2 = Producto.objects.create(
            nombre='Producto Test 2',
            precio_unitario=Decimal('15.00'),
            costo_promedio=Decimal('7.00'),
            stock_actual=50,
            stock_minimo=5,
            categoria=self.categoria
        )
        
        lote2 = Lote.objects.create(
            producto=producto2,
            numero_lote='TEST-002',
            cantidad_disponible=50,
            costo_unitario_lote=Decimal('7.00'),
            fecha_caducidad='2026-12-31'
        )
        
        # Datos de la venta con 2 productos
        venta_data = {
            'cliente_id': self.cliente.id,
            'metodo_pago': 'tarjeta_credito',
            'canal_venta': 'online',
            'items': [
                {
                    'producto_id': self.producto.id,
                    'lote_id': self.lote.id,
                    'cantidad': 3,
                    'precio': '10.00'
                },
                {
                    'producto_id': producto2.id,
                    'lote_id': lote2.id,
                    'cantidad': 2,
                    'precio': '15.00'
                }
            ]
        }
        
        # Procesar venta
        response = self.client.post(
            '/pos/api/procesar-venta/',
            data=json.dumps(venta_data),
            content_type='application/json'
        )
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        venta_id = data['venta_id']
        
        # Verificar que se crearon 2 movimientos
        movimientos = MovimientoInventario.objects.filter(venta_id=venta_id)
        self.assertEqual(movimientos.count(), 2, "Deben crearse 2 movimientos para 2 productos")
        
        # Verificar cada movimiento
        mov1 = movimientos.filter(producto=self.producto).first()
        self.assertIsNotNone(mov1)
        self.assertEqual(mov1.cantidad, -3)
        
        mov2 = movimientos.filter(producto=producto2).first()
        self.assertIsNotNone(mov2)
        self.assertEqual(mov2.cantidad, -2)
    
    def test_venta_fallida_no_crea_movimiento(self):
        """Verificar que si la venta falla, no se cree el movimiento"""
        # Intentar vender más de lo disponible
        venta_data = {
            'cliente_id': self.cliente.id,
            'metodo_pago': 'efectivo',
            'canal_venta': 'mostrador',
            'items': [
                {
                    'producto_id': self.producto.id,
                    'lote_id': self.lote.id,
                    'cantidad': 150,  # Más de lo disponible (100)
                    'precio': '10.00'
                }
            ]
        }
        
        # Contar movimientos antes
        movimientos_antes = MovimientoInventario.objects.count()
        
        # Intentar procesar venta (debe fallar)
        response = self.client.post(
            '/pos/api/procesar-venta/',
            data=json.dumps(venta_data),
            content_type='application/json'
        )
        
        # Verificar que falló
        self.assertEqual(response.status_code, 400)
        
        # Verificar que NO se creó ningún movimiento
        movimientos_despues = MovimientoInventario.objects.count()
        self.assertEqual(movimientos_antes, movimientos_despues, 
                        "No deben crearse movimientos si la venta falla")
        
        # Verificar que el lote no cambió
        self.lote.refresh_from_db()
        self.assertEqual(self.lote.cantidad_disponible, 100)
