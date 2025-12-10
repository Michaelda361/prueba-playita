/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-12.0.2-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: laplayita
-- ------------------------------------------------------
-- Server version	12.0.2-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Current Database: `laplayita`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `laplayita` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;

USE `laplayita`;

--
-- Table structure for table `ajuste_inventario`
--

DROP TABLE IF EXISTS `ajuste_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ajuste_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad_sistema` int(11) NOT NULL COMMENT 'Stock seg??n sistema',
  `cantidad_fisica` int(11) NOT NULL COMMENT 'Stock seg??n conteo f??sico',
  `diferencia` int(11) NOT NULL COMMENT 'cantidad_fisica - cantidad_sistema',
  `motivo` enum('conteo_fisico','merma','robo','da??o','error_sistema','otro') NOT NULL,
  `descripcion` text DEFAULT NULL,
  `costo_ajuste` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT 'Impacto econ??mico',
  `usuario_ejecuta_id` bigint(20) NOT NULL COMMENT 'Quien hace el ajuste',
  `usuario_autoriza_id` bigint(20) DEFAULT NULL COMMENT 'Quien autoriza (si aplica)',
  `fecha_ajuste` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('pendiente','aprobado','rechazado','aplicado') NOT NULL DEFAULT 'pendiente',
  `observaciones` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_ajuste_producto` (`producto_id`),
  KEY `fk_ajuste_lote` (`lote_id`),
  KEY `fk_ajuste_ejecuta` (`usuario_ejecuta_id`),
  KEY `fk_ajuste_autoriza` (`usuario_autoriza_id`),
  KEY `idx_ajuste_fecha` (`fecha_ajuste`),
  KEY `idx_ajuste_estado` (`estado`),
  KEY `idx_ajuste_motivo` (`motivo`),
  CONSTRAINT `fk_ajuste_autoriza` FOREIGN KEY (`usuario_autoriza_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ajuste_ejecuta` FOREIGN KEY (`usuario_ejecuta_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `fk_ajuste_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_ajuste_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ajustes de inventario por diferencias f??sicas vs sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ajuste_inventario`
--

LOCK TABLES `ajuste_inventario` WRITE;
/*!40000 ALTER TABLE `ajuste_inventario` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `ajuste_inventario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `alerta_inventario`
--

DROP TABLE IF EXISTS `alerta_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `alerta_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `tipo_alerta` enum('stock_bajo','stock_critico','sin_stock','sobre_stock','proximo_vencer','vencido','rotacion_baja') NOT NULL,
  `prioridad` enum('baja','media','alta','critica') NOT NULL DEFAULT 'media',
  `titulo` varchar(255) NOT NULL,
  `mensaje` text NOT NULL,
  `valor_actual` varchar(100) DEFAULT NULL COMMENT 'Ej: Stock actual: 5',
  `valor_esperado` varchar(100) DEFAULT NULL COMMENT 'Ej: Stock m??nimo: 10',
  `fecha_generacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_vencimiento` datetime DEFAULT NULL COMMENT 'Cu??ndo expira la alerta',
  `estado` enum('activa','resuelta','ignorada','expirada') NOT NULL DEFAULT 'activa',
  `resuelta_por_id` bigint(20) DEFAULT NULL,
  `fecha_resolucion` datetime DEFAULT NULL,
  `notas_resolucion` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_alerta_producto` (`producto_id`),
  KEY `fk_alerta_lote` (`lote_id`),
  KEY `fk_alerta_resuelta_por` (`resuelta_por_id`),
  KEY `idx_alerta_tipo` (`tipo_alerta`),
  KEY `idx_alerta_prioridad` (`prioridad`),
  KEY `idx_alerta_estado` (`estado`),
  KEY `idx_alerta_fecha` (`fecha_generacion`),
  KEY `idx_alerta_prioridad_estado` (`prioridad`,`estado`,`fecha_generacion`),
  CONSTRAINT `fk_alerta_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alerta_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_alerta_resuelta_por` FOREIGN KEY (`resuelta_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Sistema de alertas autom??ticas de inventario';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alerta_inventario`
--

LOCK TABLES `alerta_inventario` WRITE;
/*!40000 ALTER TABLE `alerta_inventario` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `alerta_inventario` VALUES
(1,4,NULL,'sin_stock','critica','RUPTURA DE STOCK: Manzana Postobon 1L','El producto \"Manzana Postobon 1L\" no tiene stock disponible.','Stock actual: 0','Stock m??nimo: 3','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(2,8,NULL,'sin_stock','critica','RUPTURA DE STOCK: Papas Fritas','El producto \"Papas Fritas\" no tiene stock disponible.','Stock actual: 0','Stock m??nimo: 5','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(3,13,NULL,'sin_stock','critica','RUPTURA DE STOCK: Yogurt alpina','El producto \"Yogurt alpina\" no tiene stock disponible.','Stock actual: 0','Stock m??nimo: 12','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(4,14,NULL,'sin_stock','critica','RUPTURA DE STOCK: Cigarrillos MARLBORO Rojo cajetilla (20 und)','El producto \"Cigarrillos MARLBORO Rojo cajetilla (20 und)\" no tiene stock disponible.','Stock actual: 0','Stock m??nimo: 5','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(5,7,3,'proximo_vencer','media','Lote pr??ximo a vencer: Cerveza Aguila','El lote R36-P7-38 del producto \"Cerveza Aguila\" vence en 23 d??as.','Cantidad: 5 unidades','Vence: 31/12/2025','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(6,1,19,'proximo_vencer','media','Lote pr??ximo a vencer: Leche Entera 1L','El lote R61-P1-61 del producto \"Leche Entera 1L\" vence en 23 d??as.','Cantidad: 21 unidades','Vence: 31/12/2025','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(7,10,23,'proximo_vencer','media','Lote pr??ximo a vencer: Coronita','El lote R131-P10-120 del producto \"Coronita\" vence en 23 d??as.','Cantidad: 99 unidades','Vence: 31/12/2025','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(8,9,18,'proximo_vencer','media','Lote pr??ximo a vencer: Poker','El lote R60-P9-60 del producto \"Poker\" vence en 24 d??as.','Cantidad: 22 unidades','Vence: 01/01/2026','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(11,3,10,'proximo_vencer','media','Lote pr??ximo a vencer: Yogurt','El lote R55-P3-55 del producto \"Yogurt\" vence en 26 d??as.','Cantidad: 187 unidades','Vence: 03/01/2026','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(12,2,2,'vencido','critica','LOTE VENCIDO: Queso Campesino 500g','El lote QSO-C3 del producto \"Queso Campesino 500g\" est?? vencido y debe ser descartado.','Cantidad: 27 unidades','Venci??: 15/11/2025','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(13,11,14,'vencido','critica','LOTE VENCIDO: Aguila 330 ml','El lote R58-P11-58 del producto \"Aguila 330 ml\" est?? vencido y debe ser descartado.','Cantidad: 16 unidades','Venci??: 29/11/2025','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(14,12,15,'vencido','critica','LOTE VENCIDO: todo rico natural','El lote R59-P12-59 del producto \"todo rico natural\" est?? vencido y debe ser descartado.','Cantidad: 15 unidades','Venci??: 29/11/2025','2025-12-08 18:28:24',NULL,'activa',NULL,NULL,NULL),
(15,2,NULL,'sin_stock','critica','RUPTURA DE STOCK: Queso Campesino 500g','El producto \"Queso Campesino 500g\" no tiene stock disponible.','Stock actual: 0','Stock m??nimo: 5','2025-12-08 21:15:05',NULL,'activa',NULL,NULL,NULL),
(16,11,NULL,'sin_stock','critica','RUPTURA DE STOCK: Aguila 330 ml','El producto \"Aguila 330 ml\" no tiene stock disponible.','Stock actual: 0','Stock m??nimo: 2','2025-12-08 21:15:05',NULL,'activa',NULL,NULL,NULL),
(17,12,NULL,'sin_stock','critica','RUPTURA DE STOCK: todo rico natural','El producto \"todo rico natural\" no tiene stock disponible.','Stock actual: 0','Stock m??nimo: 2','2025-12-08 21:15:05',NULL,'activa',NULL,NULL,NULL);
/*!40000 ALTER TABLE `alerta_inventario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `auditoria_reabastecimiento`
--

DROP TABLE IF EXISTS `auditoria_reabastecimiento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auditoria_reabastecimiento` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `reabastecimiento_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) DEFAULT NULL,
  `accion` varchar(20) NOT NULL,
  `cantidad_anterior` int(11) DEFAULT NULL,
  `cantidad_nueva` int(11) DEFAULT NULL,
  `descripcion` longtext DEFAULT NULL,
  `fecha` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_reabastecimiento` (`reabastecimiento_id`),
  KEY `idx_fecha` (`fecha`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auditoria_reabastecimiento`
--

LOCK TABLES `auditoria_reabastecimiento` WRITE;
/*!40000 ALTER TABLE `auditoria_reabastecimiento` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `auditoria_reabastecimiento` VALUES
(1,61,2,'recibido',NULL,23,'Recepción completada: 1 productos recibidos','2025-11-29 23:55:48');
/*!40000 ALTER TABLE `auditoria_reabastecimiento` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `auth_group`
--

DROP TABLE IF EXISTS `auth_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group`
--

LOCK TABLES `auth_group` WRITE;
/*!40000 ALTER TABLE `auth_group` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `auth_group` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `auth_group_permissions`
--

DROP TABLE IF EXISTS `auth_group_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_group_permissions_group_id_permission_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  KEY `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group_permissions`
--

LOCK TABLES `auth_group_permissions` WRITE;
/*!40000 ALTER TABLE `auth_group_permissions` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `auth_group_permissions` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `auth_permission`
--

DROP TABLE IF EXISTS `auth_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_permission` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`),
  CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_permission`
--

LOCK TABLES `auth_permission` WRITE;
/*!40000 ALTER TABLE `auth_permission` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `auth_permission` VALUES
(1,'Can add permission',1,'add_permission'),
(2,'Can change permission',1,'change_permission'),
(3,'Can delete permission',1,'delete_permission'),
(4,'Can view permission',1,'view_permission'),
(5,'Can add group',2,'add_group'),
(6,'Can change group',2,'change_group'),
(7,'Can delete group',2,'delete_group'),
(8,'Can view group',2,'view_group'),
(9,'Can add content type',3,'add_contenttype'),
(10,'Can change content type',3,'change_contenttype'),
(11,'Can delete content type',3,'delete_contenttype'),
(12,'Can view content type',3,'view_contenttype'),
(13,'Can add session',4,'add_session'),
(14,'Can change session',4,'change_session'),
(15,'Can delete session',4,'delete_session'),
(16,'Can view session',4,'view_session'),
(17,'Can add rol',5,'add_rol'),
(18,'Can change rol',5,'change_rol'),
(19,'Can delete rol',5,'delete_rol'),
(20,'Can view rol',5,'view_rol'),
(21,'Can add usuario',6,'add_usuario'),
(22,'Can change usuario',6,'change_usuario'),
(23,'Can delete usuario',6,'delete_usuario'),
(24,'Can view usuario',6,'view_usuario'),
(25,'Can add log entry',7,'add_logentry'),
(26,'Can change log entry',7,'change_logentry'),
(27,'Can delete log entry',7,'delete_logentry'),
(28,'Can view log entry',7,'view_logentry'),
(29,'Can add categoria',8,'add_categoria'),
(30,'Can change categoria',8,'change_categoria'),
(31,'Can delete categoria',8,'delete_categoria'),
(32,'Can view categoria',8,'view_categoria'),
(33,'Can add lote',9,'add_lote'),
(34,'Can change lote',9,'change_lote'),
(35,'Can delete lote',9,'delete_lote'),
(36,'Can view lote',9,'view_lote'),
(37,'Can add movimiento inventario',10,'add_movimientoinventario'),
(38,'Can change movimiento inventario',10,'change_movimientoinventario'),
(39,'Can delete movimiento inventario',10,'delete_movimientoinventario'),
(40,'Can view movimiento inventario',10,'view_movimientoinventario'),
(41,'Can add producto',11,'add_producto'),
(42,'Can change producto',11,'change_producto'),
(43,'Can delete producto',11,'delete_producto'),
(44,'Can view producto',11,'view_producto'),
(45,'Can add pago',12,'add_pago'),
(46,'Can change pago',12,'change_pago'),
(47,'Can delete pago',12,'delete_pago'),
(48,'Can view pago',12,'view_pago'),
(49,'Can add pedido',13,'add_pedido'),
(50,'Can change pedido',13,'change_pedido'),
(51,'Can delete pedido',13,'delete_pedido'),
(52,'Can view pedido',13,'view_pedido'),
(53,'Can add pedido detalle',14,'add_pedidodetalle'),
(54,'Can change pedido detalle',14,'change_pedidodetalle'),
(55,'Can delete pedido detalle',14,'delete_pedidodetalle'),
(56,'Can view pedido detalle',14,'view_pedidodetalle'),
(57,'Can add venta',15,'add_venta'),
(58,'Can change venta',15,'change_venta'),
(59,'Can delete venta',15,'delete_venta'),
(60,'Can view venta',15,'view_venta'),
(61,'Can add venta detalle',16,'add_ventadetalle'),
(62,'Can change venta detalle',16,'change_ventadetalle'),
(63,'Can delete venta detalle',16,'delete_ventadetalle'),
(64,'Can view venta detalle',16,'view_ventadetalle'),
(65,'Can add pqrs',17,'add_pqrs'),
(66,'Can change pqrs',17,'change_pqrs'),
(67,'Can delete pqrs',17,'delete_pqrs'),
(68,'Can view pqrs',17,'view_pqrs'),
(69,'Can add pqrs historial',18,'add_pqrshistorial'),
(70,'Can change pqrs historial',18,'change_pqrshistorial'),
(71,'Can delete pqrs historial',18,'delete_pqrshistorial'),
(72,'Can view pqrs historial',18,'view_pqrshistorial'),
(73,'Can add proveedor',19,'add_proveedor'),
(74,'Can change proveedor',19,'change_proveedor'),
(75,'Can delete proveedor',19,'delete_proveedor'),
(76,'Can view proveedor',19,'view_proveedor'),
(77,'Can add reabastecimiento',20,'add_reabastecimiento'),
(78,'Can change reabastecimiento',20,'change_reabastecimiento'),
(79,'Can delete reabastecimiento',20,'delete_reabastecimiento'),
(80,'Can view reabastecimiento',20,'view_reabastecimiento'),
(81,'Can add reabastecimiento detalle',21,'add_reabastecimientodetalle'),
(82,'Can change reabastecimiento detalle',21,'change_reabastecimientodetalle'),
(83,'Can delete reabastecimiento detalle',21,'delete_reabastecimientodetalle'),
(84,'Can view reabastecimiento detalle',21,'view_reabastecimientodetalle'),
(85,'Can add Cliente',22,'add_cliente'),
(86,'Can change Cliente',22,'change_cliente'),
(87,'Can delete Cliente',22,'delete_cliente'),
(88,'Can view Cliente',22,'view_cliente'),
(89,'Can add pqrs evento',23,'add_pqrsevento'),
(90,'Can change pqrs evento',23,'change_pqrsevento'),
(91,'Can delete pqrs evento',23,'delete_pqrsevento'),
(92,'Can view pqrs evento',23,'view_pqrsevento'),
(93,'Can add producto canjeble',24,'add_productocanjeble'),
(94,'Can change producto canjeble',24,'change_productocanjeble'),
(95,'Can delete producto canjeble',24,'delete_productocanjeble'),
(96,'Can view producto canjeble',24,'view_productocanjeble'),
(97,'Can add canje producto',25,'add_canjeproducto'),
(98,'Can change canje producto',25,'change_canjeproducto'),
(99,'Can delete canje producto',25,'delete_canjeproducto'),
(100,'Can view canje producto',25,'view_canjeproducto'),
(101,'Can add puntos fidelizacion',26,'add_puntosfidelizacion'),
(102,'Can change puntos fidelizacion',26,'change_puntosfidelizacion'),
(103,'Can delete puntos fidelizacion',26,'delete_puntosfidelizacion'),
(104,'Can view puntos fidelizacion',26,'view_puntosfidelizacion'),
(105,'Can add auditoria reabastecimiento',27,'add_auditoriareabastecimiento'),
(106,'Can change auditoria reabastecimiento',27,'change_auditoriareabastecimiento'),
(107,'Can delete auditoria reabastecimiento',27,'delete_auditoriareabastecimiento'),
(108,'Can view auditoria reabastecimiento',27,'view_auditoriareabastecimiento'),
(109,'Can add tasa iva',28,'add_tasaiva'),
(110,'Can change tasa iva',28,'change_tasaiva'),
(111,'Can delete tasa iva',28,'delete_tasaiva'),
(112,'Can view tasa iva',28,'view_tasaiva'),
(113,'Can add mesa',29,'add_mesa'),
(114,'Can change mesa',29,'change_mesa'),
(115,'Can delete mesa',29,'delete_mesa'),
(116,'Can view mesa',29,'view_mesa'),
(117,'Can add item mesa',30,'add_itemmesa'),
(118,'Can change item mesa',30,'change_itemmesa'),
(119,'Can delete item mesa',30,'delete_itemmesa'),
(120,'Can view item mesa',30,'view_itemmesa');
/*!40000 ALTER TABLE `auth_permission` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `canje_producto`
--

DROP TABLE IF EXISTS `canje_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `canje_producto` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `puntos_gastados` decimal(10,2) NOT NULL,
  `fecha_canje` datetime(6) NOT NULL,
  `estado` varchar(20) NOT NULL,
  `fecha_entrega` datetime(6) DEFAULT NULL,
  `cliente_id` bigint(20) NOT NULL,
  `producto_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `canje_producto`
--

LOCK TABLES `canje_producto` WRITE;
/*!40000 ALTER TABLE `canje_producto` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `canje_producto` VALUES
(1,3.69,'2025-11-23 06:38:15.185869','completado',NULL,6,1),
(2,3.69,'2025-11-23 06:39:42.102779','completado',NULL,6,1),
(3,3.69,'2025-11-24 15:15:13.804939','completado',NULL,3,1);
/*!40000 ALTER TABLE `canje_producto` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `categoria`
--

DROP TABLE IF EXISTS `categoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `categoria` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(25) NOT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `imagen_url` varchar(255) DEFAULT NULL,
  `color_identificador` varchar(7) DEFAULT NULL,
  `icono` varchar(50) DEFAULT NULL,
  `orden` int(11) NOT NULL DEFAULT 0,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `creado_por_id` bigint(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_categoria_parent` (`parent_id`),
  KEY `idx_categoria_activo` (`activo`),
  KEY `fk_categoria_creado_por` (`creado_por_id`),
  CONSTRAINT `fk_categoria_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_categoria_parent` FOREIGN KEY (`parent_id`) REFERENCES `categoria` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categoria`
--

LOCK TABLES `categoria` WRITE;
/*!40000 ALTER TABLE `categoria` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `categoria` VALUES
(1,'Lacteos',NULL,NULL,NULL,NULL,NULL,0,1,NULL,'2025-12-08 18:23:34'),
(2,'Quesos',NULL,NULL,NULL,NULL,NULL,0,1,NULL,'2025-12-08 18:23:34'),
(3,'Cerveza',NULL,NULL,NULL,NULL,NULL,0,1,NULL,'2025-12-08 18:23:34'),
(4,'Gaseosa',NULL,NULL,NULL,NULL,NULL,0,1,NULL,'2025-12-08 18:23:34'),
(5,'Dulces',NULL,NULL,NULL,NULL,NULL,0,1,NULL,'2025-12-08 18:23:34'),
(6,'paquetes',NULL,NULL,NULL,NULL,NULL,0,1,NULL,'2025-12-08 18:23:34'),
(9,'Cigarillo',NULL,NULL,NULL,NULL,NULL,0,1,NULL,'2025-12-08 18:23:34');
/*!40000 ALTER TABLE `categoria` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `cliente`
--

DROP TABLE IF EXISTS `cliente`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cliente` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `documento` varchar(20) NOT NULL,
  `nombres` varchar(50) NOT NULL,
  `apellidos` varchar(50) NOT NULL,
  `correo` varchar(60) NOT NULL,
  `telefono` varchar(25) NOT NULL,
  `puntos_totales` decimal(10,2) DEFAULT 0.00,
  PRIMARY KEY (`id`),
  UNIQUE KEY `documento` (`documento`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cliente`
--

LOCK TABLES `cliente` WRITE;
/*!40000 ALTER TABLE `cliente` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `cliente` VALUES
(1,'12345678','Pepito','Perez','pepito@gmail.com','12342155124',0.00),
(2,'10001','Laura','Martinez','laura.m@gmail.com','3124567890',0.00),
(3,'213213','Michael David ','Ramirez','richardodito@gmail.com','3503372482',6.23),
(5,'2343422','Juan andres','Lizarazo','liza@gmail.com','35223234234',16.12),
(6,'ADMIN-4','Laura','Gomez','laura.admin@laplayita.com','0000000000',9992.62),
(7,'100038243432','cecilia','Rodriguez','liza@gmail.com','32423424',3.75),
(8,'21321321','alejandro','mendoza ','loqueseaxd@gmail.com','2342343243',0.29),
(9,'13123543','naomi','ramirez','naomi@gmail.com','135467613',0.42),
(10,'10138941','juan','lizarazo','lizarazojuanandres@gmail.com','21313123',0.00);
/*!40000 ALTER TABLE `cliente` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `configuracion_alerta`
--

DROP TABLE IF EXISTS `configuracion_alerta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuracion_alerta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo_alerta` enum('stock_bajo','stock_critico','sobre_stock','proximo_vencer','rotacion_baja') NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `umbral_valor` decimal(10,2) DEFAULT NULL COMMENT 'Valor num??rico del umbral',
  `umbral_porcentaje` decimal(5,2) DEFAULT NULL COMMENT 'Porcentaje del umbral',
  `dias_anticipacion` int(11) DEFAULT NULL COMMENT 'D??as de anticipaci??n para alertas de vencimiento',
  `descripcion` text DEFAULT NULL,
  `notificar_email` tinyint(1) NOT NULL DEFAULT 0,
  `notificar_dashboard` tinyint(1) NOT NULL DEFAULT 1,
  `usuarios_notificar` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Array de IDs de usuarios a notificar' CHECK (json_valid(`usuarios_notificar`)),
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_modificacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_config_tipo_alerta` (`tipo_alerta`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Configuraci??n de umbrales y comportamiento de alertas';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion_alerta`
--

LOCK TABLES `configuracion_alerta` WRITE;
/*!40000 ALTER TABLE `configuracion_alerta` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `configuracion_alerta` VALUES
(1,'stock_bajo',1,NULL,150.00,NULL,'Alerta cuando stock < stock_m??nimo ?? 1.5',0,1,NULL,'2025-12-08 18:23:44',NULL),
(2,'stock_critico',1,NULL,100.00,NULL,'Alerta cuando stock < stock_m??nimo',0,1,NULL,'2025-12-08 18:23:44',NULL),
(3,'sobre_stock',1,NULL,300.00,NULL,'Alerta cuando stock > stock_m??ximo',0,1,NULL,'2025-12-08 18:23:44',NULL),
(4,'proximo_vencer',1,NULL,NULL,30,'Alerta 30 d??as antes del vencimiento',0,1,NULL,'2025-12-08 18:23:44',NULL),
(5,'rotacion_baja',1,NULL,NULL,90,'Alerta si no hay ventas en 90 d??as',0,1,NULL,'2025-12-08 18:23:44',NULL);
/*!40000 ALTER TABLE `configuracion_alerta` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `conteo_fisico`
--

DROP TABLE IF EXISTS `conteo_fisico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `conteo_fisico` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `numero_conteo` varchar(50) NOT NULL COMMENT 'Ej: CF-2025-001',
  `tipo_conteo` enum('completo','parcial','ciclico','sorpresa') NOT NULL DEFAULT 'ciclico',
  `fecha_programada` date NOT NULL,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_finalizacion` datetime DEFAULT NULL,
  `estado` enum('programado','en_proceso','completado','cancelado','ajustado') NOT NULL DEFAULT 'programado',
  `ubicacion_id` int(11) DEFAULT NULL COMMENT 'Ubicación específica (si es parcial)',
  `categoria_id` int(11) DEFAULT NULL COMMENT 'Categoría específica (si es parcial)',
  `responsable_id` bigint(20) NOT NULL,
  `supervisor_id` bigint(20) DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  `total_productos` int(11) DEFAULT 0,
  `total_diferencias` int(11) DEFAULT 0,
  `valor_diferencias` decimal(12,2) DEFAULT 0.00,
  `creado_por_id` bigint(20) NOT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `numero_conteo` (`numero_conteo`),
  UNIQUE KEY `uq_numero_conteo` (`numero_conteo`),
  KEY `fk_conteo_ubicacion` (`ubicacion_id`),
  KEY `fk_conteo_categoria` (`categoria_id`),
  KEY `fk_conteo_responsable` (`responsable_id`),
  KEY `fk_conteo_supervisor` (`supervisor_id`),
  KEY `fk_conteo_creado_por` (`creado_por_id`),
  KEY `idx_conteo_estado` (`estado`),
  KEY `idx_conteo_fecha` (`fecha_programada`),
  CONSTRAINT `fk_conteo_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `fk_conteo_responsable` FOREIGN KEY (`responsable_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `fk_conteo_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_ubicacion` FOREIGN KEY (`ubicacion_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Conteos físicos de inventario';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conteo_fisico`
--

LOCK TABLES `conteo_fisico` WRITE;
/*!40000 ALTER TABLE `conteo_fisico` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `conteo_fisico` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `conteo_fisico_detalle`
--

DROP TABLE IF EXISTS `conteo_fisico_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `conteo_fisico_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conteo_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad_sistema` int(11) NOT NULL COMMENT 'Stock según sistema',
  `cantidad_contada` int(11) DEFAULT NULL COMMENT 'Stock según conteo físico',
  `diferencia` int(11) DEFAULT NULL COMMENT 'cantidad_contada - cantidad_sistema',
  `costo_unitario` decimal(12,2) NOT NULL,
  `valor_diferencia` decimal(12,2) DEFAULT 0.00,
  `estado` enum('pendiente','contado','verificado','ajustado') NOT NULL DEFAULT 'pendiente',
  `observaciones` text DEFAULT NULL,
  `contado_por_id` bigint(20) DEFAULT NULL,
  `fecha_conteo` datetime DEFAULT NULL,
  `verificado_por_id` bigint(20) DEFAULT NULL,
  `fecha_verificacion` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_conteo_detalle_conteo` (`conteo_id`),
  KEY `fk_conteo_detalle_producto` (`producto_id`),
  KEY `fk_conteo_detalle_lote` (`lote_id`),
  KEY `fk_conteo_detalle_contado_por` (`contado_por_id`),
  KEY `fk_conteo_detalle_verificado_por` (`verificado_por_id`),
  KEY `idx_conteo_detalle_estado` (`estado`),
  CONSTRAINT `fk_conteo_detalle_contado_por` FOREIGN KEY (`contado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_detalle_conteo` FOREIGN KEY (`conteo_id`) REFERENCES `conteo_fisico` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conteo_detalle_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_conteo_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_conteo_detalle_verificado_por` FOREIGN KEY (`verificado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Detalle de conteos físicos';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `conteo_fisico_detalle`
--

LOCK TABLES `conteo_fisico_detalle` WRITE;
/*!40000 ALTER TABLE `conteo_fisico_detalle` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `conteo_fisico_detalle` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `costo_historico`
--

DROP TABLE IF EXISTS `costo_historico`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `costo_historico` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `costo_anterior` decimal(12,2) NOT NULL,
  `costo_nuevo` decimal(12,2) NOT NULL,
  `diferencia` decimal(12,2) NOT NULL,
  `porcentaje_cambio` decimal(5,2) NOT NULL,
  `motivo` enum('reabastecimiento','ajuste_manual','inflacion','proveedor','otro') NOT NULL,
  `descripcion` text DEFAULT NULL,
  `reabastecimiento_id` int(11) DEFAULT NULL COMMENT 'Si fue por reabastecimiento',
  `usuario_id` bigint(20) DEFAULT NULL,
  `fecha_cambio` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_costo_historico_producto` (`producto_id`),
  KEY `fk_costo_historico_reabastecimiento` (`reabastecimiento_id`),
  KEY `fk_costo_historico_usuario` (`usuario_id`),
  KEY `idx_costo_historico_fecha` (`fecha_cambio`),
  CONSTRAINT `fk_costo_historico_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_costo_historico_reabastecimiento` FOREIGN KEY (`reabastecimiento_id`) REFERENCES `reabastecimiento` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_costo_historico_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historial de cambios de costo';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `costo_historico`
--

LOCK TABLES `costo_historico` WRITE;
/*!40000 ALTER TABLE `costo_historico` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `costo_historico` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `descarte_producto`
--

DROP TABLE IF EXISTS `descarte_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `descarte_producto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `motivo` enum('vencido','proximo_vencer','da??ado','contaminado','empaque_roto','calidad_baja','otro') NOT NULL,
  `descripcion` text DEFAULT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  `costo_total` decimal(12,2) NOT NULL,
  `usuario_ejecuta_id` bigint(20) NOT NULL,
  `usuario_autoriza_id` bigint(20) DEFAULT NULL,
  `fecha_descarte` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('pendiente','aprobado','rechazado','ejecutado') NOT NULL DEFAULT 'pendiente',
  `evidencia_url` varchar(255) DEFAULT NULL COMMENT 'Foto del producto descartado',
  PRIMARY KEY (`id`),
  KEY `fk_descarte_producto` (`producto_id`),
  KEY `fk_descarte_lote` (`lote_id`),
  KEY `fk_descarte_ejecuta` (`usuario_ejecuta_id`),
  KEY `fk_descarte_autoriza` (`usuario_autoriza_id`),
  KEY `idx_descarte_fecha` (`fecha_descarte`),
  KEY `idx_descarte_estado` (`estado`),
  KEY `idx_descarte_motivo` (`motivo`),
  CONSTRAINT `fk_descarte_autoriza` FOREIGN KEY (`usuario_autoriza_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_descarte_ejecuta` FOREIGN KEY (`usuario_ejecuta_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `fk_descarte_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_descarte_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro de productos descartados';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `descarte_producto`
--

LOCK TABLES `descarte_producto` WRITE;
/*!40000 ALTER TABLE `descarte_producto` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `descarte_producto` VALUES
(1,2,2,27,'vencido','Descarte automático - Vencido hace 23 días',7000.00,189000.00,2,2,'2025-12-09 02:04:30','ejecutado',NULL),
(2,2,2,27,'vencido','Descarte automático - Vencido hace 23 días',7000.00,189000.00,2,2,'2025-12-09 02:05:07','ejecutado',NULL),
(3,2,2,27,'vencido','Descarte automático - Vencido hace 23 días',7000.00,189000.00,2,2,'2025-12-09 02:05:47','ejecutado',NULL),
(4,2,2,27,'vencido','Descarte automático - Vencido hace 23 días',7000.00,189000.00,2,2,'2025-12-09 02:06:08','ejecutado',NULL),
(5,2,2,27,'vencido','Descarte automático - Vencido hace 23 días',7000.00,189000.00,2,2,'2025-12-09 02:07:53','ejecutado',NULL),
(6,11,14,16,'vencido','Descarte automático - Vencido hace 9 días',3000.00,48000.00,2,2,'2025-12-09 02:07:53','ejecutado',NULL),
(7,12,15,15,'vencido','Descarte automático - Vencido hace 9 días',3500.00,52500.00,2,2,'2025-12-09 02:07:53','ejecutado',NULL);
/*!40000 ALTER TABLE `descarte_producto` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `devolucion_proveedor`
--

DROP TABLE IF EXISTS `devolucion_proveedor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `devolucion_proveedor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reabastecimiento_id` int(11) NOT NULL,
  `proveedor_id` int(11) NOT NULL,
  `fecha_devolucion` datetime NOT NULL DEFAULT current_timestamp(),
  `motivo` enum('producto_defectuoso','producto_vencido','cantidad_incorrecta','producto_incorrecto','empaque_da??ado','otro') NOT NULL,
  `descripcion` text DEFAULT NULL,
  `costo_total` decimal(12,2) NOT NULL,
  `estado` enum('solicitada','aprobada','rechazada','completada') NOT NULL DEFAULT 'solicitada',
  `usuario_solicita_id` bigint(20) NOT NULL,
  `fecha_aprobacion` datetime DEFAULT NULL,
  `usuario_aprueba_id` bigint(20) DEFAULT NULL,
  `numero_guia` varchar(100) DEFAULT NULL COMMENT 'N??mero de gu??a de devoluci??n',
  PRIMARY KEY (`id`),
  KEY `fk_devolucion_reabastecimiento` (`reabastecimiento_id`),
  KEY `fk_devolucion_proveedor` (`proveedor_id`),
  KEY `fk_devolucion_solicita` (`usuario_solicita_id`),
  KEY `fk_devolucion_aprueba` (`usuario_aprueba_id`),
  KEY `idx_devolucion_fecha` (`fecha_devolucion`),
  KEY `idx_devolucion_estado` (`estado`),
  CONSTRAINT `fk_devolucion_aprueba` FOREIGN KEY (`usuario_aprueba_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_devolucion_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedor` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_devolucion_reabastecimiento` FOREIGN KEY (`reabastecimiento_id`) REFERENCES `reabastecimiento` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_devolucion_solicita` FOREIGN KEY (`usuario_solicita_id`) REFERENCES `usuario` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Devoluciones de mercanc??a a proveedores';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devolucion_proveedor`
--

LOCK TABLES `devolucion_proveedor` WRITE;
/*!40000 ALTER TABLE `devolucion_proveedor` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `devolucion_proveedor` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `devolucion_proveedor_detalle`
--

DROP TABLE IF EXISTS `devolucion_proveedor_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `devolucion_proveedor_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `devolucion_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  `motivo_especifico` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_devolucion_detalle_devolucion` (`devolucion_id`),
  KEY `fk_devolucion_detalle_producto` (`producto_id`),
  KEY `fk_devolucion_detalle_lote` (`lote_id`),
  CONSTRAINT `fk_devolucion_detalle_devolucion` FOREIGN KEY (`devolucion_id`) REFERENCES `devolucion_proveedor` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_devolucion_detalle_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_devolucion_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Detalle de productos en devoluciones a proveedores';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `devolucion_proveedor_detalle`
--

LOCK TABLES `devolucion_proveedor_detalle` WRITE;
/*!40000 ALTER TABLE `devolucion_proveedor_detalle` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `devolucion_proveedor_detalle` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `django_admin_log`
--

DROP TABLE IF EXISTS `django_admin_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_admin_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action_time` datetime(6) NOT NULL,
  `object_id` longtext DEFAULT NULL,
  `object_repr` varchar(200) NOT NULL,
  `action_flag` smallint(5) unsigned NOT NULL CHECK (`action_flag` >= 0),
  `change_message` longtext NOT NULL,
  `content_type_id` int(11) DEFAULT NULL,
  `user_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `django_admin_log_content_type_id_c4bce8eb_fk_django_co` (`content_type_id`),
  CONSTRAINT `django_admin_log_content_type_id_c4bce8eb_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_admin_log`
--

LOCK TABLES `django_admin_log` WRITE;
/*!40000 ALTER TABLE `django_admin_log` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `django_admin_log` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `django_content_type`
--

DROP TABLE IF EXISTS `django_content_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_content_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_content_type`
--

LOCK TABLES `django_content_type` WRITE;
/*!40000 ALTER TABLE `django_content_type` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `django_content_type` VALUES
(7,'admin','logentry'),
(2,'auth','group'),
(1,'auth','permission'),
(25,'clients','canjeproducto'),
(22,'clients','cliente'),
(24,'clients','productocanjeble'),
(26,'clients','puntosfidelizacion'),
(3,'contenttypes','contenttype'),
(8,'inventory','categoria'),
(9,'inventory','lote'),
(10,'inventory','movimientoinventario'),
(11,'inventory','producto'),
(28,'inventory','tasaiva'),
(30,'pos','itemmesa'),
(29,'pos','mesa'),
(12,'pos','pago'),
(13,'pos','pedido'),
(14,'pos','pedidodetalle'),
(15,'pos','venta'),
(16,'pos','ventadetalle'),
(17,'pqrs','pqrs'),
(23,'pqrs','pqrsevento'),
(18,'pqrs','pqrshistorial'),
(4,'sessions','session'),
(27,'suppliers','auditoriareabastecimiento'),
(19,'suppliers','proveedor'),
(20,'suppliers','reabastecimiento'),
(21,'suppliers','reabastecimientodetalle'),
(5,'users','rol'),
(6,'users','usuario');
/*!40000 ALTER TABLE `django_content_type` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `django_migrations`
--

DROP TABLE IF EXISTS `django_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_migrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `django_migrations` VALUES
(1,'contenttypes','0001_initial','2025-11-19 01:51:29.183102'),
(2,'contenttypes','0002_remove_content_type_name','2025-11-19 01:51:29.235134'),
(3,'auth','0001_initial','2025-11-19 01:51:29.406066'),
(4,'auth','0002_alter_permission_name_max_length','2025-11-19 01:51:29.442857'),
(5,'auth','0003_alter_user_email_max_length','2025-11-19 01:51:29.448597'),
(6,'auth','0004_alter_user_username_opts','2025-11-19 01:51:29.453729'),
(7,'auth','0005_alter_user_last_login_null','2025-11-19 01:51:29.458824'),
(8,'auth','0006_require_contenttypes_0002','2025-11-19 01:51:29.461046'),
(9,'auth','0007_alter_validators_add_error_messages','2025-11-19 01:51:29.465838'),
(10,'auth','0008_alter_user_username_max_length','2025-11-19 01:51:29.470411'),
(11,'auth','0009_alter_user_last_name_max_length','2025-11-19 01:51:29.474934'),
(12,'auth','0010_alter_group_name_max_length','2025-11-19 01:51:29.498844'),
(13,'auth','0011_update_proxy_permissions','2025-11-19 01:51:29.503925'),
(14,'auth','0012_alter_user_first_name_max_length','2025-11-19 01:51:29.508934'),
(15,'sessions','0001_initial','2025-11-19 01:53:03.615302'),
(16,'users','0001_initial','2025-11-19 02:05:50.226802'),
(17,'suppliers','0001_initial','2025-11-19 02:07:00.029220'),
(18,'inventory','0001_initial','2025-11-19 02:07:24.792645'),
(19,'pos','0001_initial','2025-11-19 02:07:31.550654'),
(20,'core','0001_initial','2025-11-19 02:07:40.059590'),
(21,'pqrs','0001_initial','2025-11-19 02:07:54.810440'),
(22,'clients','0001_initial','2025-11-19 02:08:04.428007'),
(23,'admin','0001_initial','2025-11-19 02:13:44.480599'),
(24,'admin','0002_logentry_remove_auto_add','2025-11-19 02:13:44.486783'),
(25,'admin','0003_logentry_add_action_flag_choices','2025-11-19 02:13:44.493026'),
(26,'clients','0002_initial','2025-11-19 12:19:52.940673'),
(27,'inventory','0002_initial','2025-11-19 12:19:52.955620'),
(28,'pos','0002_initial','2025-11-19 12:19:52.962756'),
(29,'pqrs','0002_initial','2025-11-19 12:19:52.968056'),
(30,'suppliers','0002_initial','2025-11-19 12:19:52.973037'),
(31,'users','0002_alter_rol_options_alter_usuario_is_superuser','2025-11-19 12:19:52.988441'),
(32,'users','0003_usuario_is_staff','2025-11-19 13:11:08.531443'),
(33,'users','0004_manual_add_is_superuser','2025-11-19 13:14:21.160191'),
(34,'pos','0003_fix_trigger_stock_update','2025-11-22 05:30:57.994689'),
(35,'clients','0003_add_loyalty_system','2025-11-22 05:53:08.157482'),
(36,'clients','0004_create_loyalty_tables','2025-11-22 06:24:07.640028'),
(37,'pqrs','0003_pqrsevento_delete_pqrshistorial_alter_pqrs_options_and_more','2025-11-24 01:50:15.942398'),
(38,'pqrs','0004_alter_pqrs_options_alter_pqrsevento_pqrs_and_more','2025-11-24 01:50:16.380649'),
(39,'users','0005_alter_usuario_id','2025-11-24 01:50:16.398830'),
(40,'clients','0005_productocanjeble_producto_inventario','2025-11-24 15:14:20.593254'),
(41,'users','0006_create_permission_tables','2025-11-24 15:14:30.251788'),
(42,'suppliers','0003_add_audit_fields','2025-11-29 21:38:40.718480'),
(43,'suppliers','0004_add_audit_and_lote','2025-11-29 21:52:46.180588'),
(44,'inventory','0003_tasaiva','2025-11-29 21:59:47.634431'),
(45,'suppliers','0005_auditoriareabastecimiento','2025-11-29 21:59:47.636875'),
(46,'pos','0004_mesa_itemmesa','2025-12-01 03:51:13.838767'),
(47,'pos','0005_itemmesa_anotacion','2025-12-01 03:51:33.642065');
/*!40000 ALTER TABLE `django_migrations` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `django_session`
--

DROP TABLE IF EXISTS `django_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_expire_date_a5c62663` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_session`
--

LOCK TABLES `django_session` WRITE;
/*!40000 ALTER TABLE `django_session` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `django_session` VALUES
('0ease78l1wxvtqn6kf2ow7pzv994a4jw','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vONeg:1Ntdn9iGektcfSHfIStjNW9vy3tCeiSLlPsexI7LsQ4','2025-11-26 22:36:30.643362'),
('14dx4u1hald1xi4rfisq596q90836ddt','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSnfX:lK3C2AJZHzgTftlssbNydafnstvTwQ5miDPCFho0eQs','2025-12-09 03:11:39.557154'),
('168v9zedcwtb983qn9p83t7rq1dwmrg2','.eJxVjLsOwjAMAP_FM4poEvLoyM43VLbjkAJKpKadEP-OKnWA9e50b5hwW8u0dVmmOcEIDk6_jJCfUneRHljvTXGr6zKT2hN12K5uLcnrerR_g4K9wAjZh0FH5kxeDJoYM12Ct2eNRrM2niSQsDjOQ_QU2AW2ZAVNziYGTPD5Avx4OOE:1vMgJK:2ISjvAyL9fNsmdeeaHsGl6SaEiZAwnEeTXJv6SLEjGk','2025-12-06 05:37:26.534237'),
('1819zifalcahqpcl4lei3odrlyc2g7sk','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vNkqV:ctoGKctU9Itni_fQAyQCvfLU4gJfUIZ_0h7r4Aub7lQ','2025-11-25 05:10:07.252966'),
('4trrzi4g22irkpl1etyimljfzooq3ijy','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vMPTJ:TjtJ8nwgay9XJdG1twYwR0z-7FHM1DObJsyMLcOl2Yo','2025-12-05 11:38:37.434948'),
('6bbvndspopyye0spt2fvrw2snw7zes9z','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vNhC2:1mu5GW3rhPA-nSSLvAtKnVCAJSqFj1-aMKN6KrsYodE','2025-11-25 01:16:06.815132'),
('76d2geff1mkrytu8o0hlmd3nxm51hptf','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vNUdN:XyFRmS_FayAp7-0f2Ewg0hHc7odnVGzRS0DwHNwFDLU','2025-12-08 11:21:29.226077'),
('7uy20k0zjobylaucwb7084nyhskj47wb','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vPAX3:d85aSxsiPjvUspyJFRJrNGynpyCN63z1ObWD7UL9rdQ','2025-11-29 02:47:53.446763'),
('85n6lsn3nvrv1b7k5m6prwnobxrcf34b','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vT5UX:IYxfP1WdxrUGP5BW5uhUoS5slX45GUNiQvHdNMs-YWk','2025-12-09 22:13:29.736613'),
('87yvcs2e7dj3eoo7c9592zhg4d404xsr','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSkAZ:tLBazVPMcVpcgmOtBsybqyF-BmNVCCvgSEb67EckK04','2025-12-08 23:27:27.890500'),
('8ynchq1evtb92l5f9rjq1u1pzaa7168v','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vLhE2:-cgsp0Yso0dZgftgjeO4Ynpd7X2B-GaCNlWZxxFEv7c','2025-12-03 12:23:54.454513'),
('9uz8sea8hry2pcn9frx7w3c4mh4wu3w2','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vPQcK:OopjG6ODSpg7goNBquTFUFNXTzzxMu2GhOzaz7lkwt4','2025-11-29 19:58:24.714172'),
('a1x5vko5f0j67vy80cvp05iplkzgfqqt','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vPBh4:hW0oiva_kXzOYLgmIw7gOh5RbRpf6zUpkt2CaFhi34I','2025-11-29 04:02:18.848624'),
('aq8a6avk2ivfj3mqhjkotrkeroioruj2','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vRGtC:WvoawsUNjOap63BdvyKrbTzpN-22LChQki6k28YvPxQ','2025-12-04 21:59:26.426767'),
('cwh0d4dmxcrk5rnjf1arstzcxje2oujt','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vS1E1:NaesLVQDfmrDXG68DRXBxyUujDZkhoLYlZUu526I6tY','2025-12-06 23:28:01.835241'),
('ed8wopbkvuauyh1hhjsqumapx2kmvwr6','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vOqCv:CcBlKAKd3vncrKZ7T5DEkenAWbucXIX0TfAbPVgJ3Wc','2025-11-28 05:05:45.070120'),
('fs7y2u1jijeiw55ki61gju63220snmjj','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSKnZ:ttmDZUkQ7bXddGIfOkQJhjJWixbaKVpzOPz9Z1LrPEM','2025-12-07 20:22:01.298463'),
('g73v0js40g9dtf69zfpvzx3mccvn861p','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSQEl:5GaJpbBCBuTmB7Ev8xe0Xmv47PddVBIt5lQGrNlJlkw','2025-12-08 02:10:27.192742'),
('gp4elbrcnjxugkpj88y7daru8a9genra','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vOjne:lrT2GR8WRCVywRlpw8Z4Qzb5XS14tqFfdSCmCSEbuUo','2025-11-27 22:15:14.412967'),
('in6w6e7vcc3n48tyh7gephu4kjyfmm28','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vN3JY:4VFhBYDSV9MkfUMwOockM_95M5st8m88HggWKzXq_fM','2025-12-07 06:11:12.249463'),
('kn7j9d2h8svvict9q33jq9e1ua01v8h4','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSMFM:-hODxp2UGF-9yrA2mB7MYxuwt6oQ3QonZ4oGg8vdkDM','2025-12-07 21:54:48.554308'),
('ky7k71vq5fclb2etxhpn83qg0ut5mj2b','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSkhb:a1vM7eOMM1zVP_ETP14YKz0Lt9ZN_s0QCvQC8mdrT7k','2025-12-09 00:01:35.052618'),
('m0hvgwjz4qfqjsyrh0qqvw5nprobxae9','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vQABA:DlX1XDmz7jgpi5fQH8Cv5pfT24D6Izrc7bvPFDQ_utM','2025-12-01 20:37:24.071498'),
('na5a7mz0edr5h31os1w4mxzkm3hdpsy3','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vPXY9:WWrBk0SaGFZQ5DvqqPlhi-PQSpgYeDJyaWeihC7HM4U','2025-11-30 03:22:33.087133'),
('nhavpnd5bjymv7vkn05zkyt94tqnn2w0','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vRffw:ZF0I9JRlRpBIHxLnEHuHYyF8HQNTVfFqsnGb_g95HrI','2025-12-06 00:27:24.087404'),
('nkjrcyqpxia388fgi8vfqzcz6vv810z6','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vQ2Ne:vEq5a6g6PaXMeL1Whn6ABR_Eftwnp8cEDEV6HaW5Ljo','2025-12-01 12:17:46.036334'),
('npi7w04qfqo00zm57xl0up92yvfk8s3s','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vOo71:4bOZTAIeyQQphpGhrS49L5SrpH8YKasfGWfbmFw293g','2025-11-28 02:51:31.484627'),
('ojy1o12h1hxmeut1881sznofgk6k59mg','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vNlde:mA2PaUpPW4ZgYc4NFwpu0McIcLPZQ-py2CMq8moJcUc','2025-11-25 06:00:54.926883'),
('othwhrom7878h4f71whzewnt5ejavox5','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vQJyL:fsNbrm-wgILsr-VvuwWtD7F2SGFOA2quc0hptuK2ROA','2025-12-02 07:04:49.746420'),
('ptgiumf1zjnplxbec66fkdi33y52ma4l','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vP39j:TbEXWXrRkKwDHRIlGecXDPJl4Y8gs3p2Lvz5LsB-w1Y','2025-11-28 18:55:19.054383'),
('qk4nln45l5zmkug2ytlaiqk3pjifggp9','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vS0OV:fYyUNwoQdaPq7pX7-aNSoHr-3u7Ehz2XIZfoh8DpW8c','2025-12-06 22:34:47.440458'),
('qtf2mfja7o9jskmvg5an5vy5fs5rmxjx','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vRFSG:prz2sJGZBp2mTXvqng7U4uSaRUEz2wgLKAJVduN6h1M','2025-12-04 20:27:32.742693'),
('r7kxyqjrl3ny8s9xw8nvbcrlzt2nmtga','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSNyj:faNWx-aOZFGRo8eQOb5ToKcoqkr42Ip5rr_3IGacXvM','2025-12-07 23:45:45.833160'),
('rn0dw5is671az2lxnga73t10i26uq7hd','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vPw50:GQPAKzGSI2VgIT0ItnRngPikdVBNo9U_Qe96BpErftw','2025-12-01 05:34:06.175268'),
('si4dhixeiquo78m4rfz83gfc2lzv0azt','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vOp5N:SgjsFs--W2iQJTKekn430Q1dUtDccgFuZ9avkIL7bok','2025-11-28 03:53:53.196394'),
('sovmak8j874du0vk7zbsv09ybolmqy1o','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vSlkT:BsY1r-ObBKPaazLLugSMmhn6akh4l8depEjHZu2bpXA','2025-12-09 01:08:37.675302'),
('ts2oiw4b15ei2bp1ax7llo8j6j1nt9ew','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vPUsS:uRPLrBA08U6uCUl5vlOjt_8ti58i_UUroUXYckubbJc','2025-11-30 00:31:20.582897'),
('uiut3hlpivu7wrxjsewakc4yfm0rtcmq','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vT6Td:gR_UYazf1Lb6F7mJ-cR4eqY4LVz2xU-UMpHaKknBA6I','2025-12-09 23:16:37.276781'),
('vgerxkbm0jp328vuujjys69p5c1s73yf','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vNe7d:Y2f8TY4qpdVaXr37NyjfWZe1p-m6NayuEeS5qPDsb4A','2025-11-24 21:59:21.961321'),
('vi5yxdtugyu9xt83w58qykpqlyzbb8r1','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vOOHp:a5m07DbUsocplnI4xDsTZacoRQFcr8glqSNmzBXG21Y','2025-11-26 23:16:57.423774'),
('vp9pys04aec4bsadqykjt2i6dslld2s1','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vOl9p:sjFKFVOZsIL2GOcx0xXM9kG6stHcIM7pKBzATfBRBlU','2025-11-27 23:42:13.529654'),
('w7vaikmjpfm17jqfzmeljxl518he9aez','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vPBXZ:Frg2ecjVM6uCgxt-vlqPN0CDBEejnZ6NxtwMq6Scd_M','2025-11-29 03:52:29.564041'),
('xl3v9tkv9pdx2ibivo0bcx5hiqzzfntw','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vQDN2:GazNDY8wh6lRIawGyW06Yqrsm9Ljz3DZf6__IY40XXg','2025-12-02 00:01:52.139139'),
('z40menxzwz7sx5ca77h24veyjg045obj','.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vS4uk:3-qI_85bgyd8NuXndhy8CsRiqjn3IXUxO6ngDMZq2Po','2025-12-07 03:24:22.695402');
/*!40000 ALTER TABLE `django_session` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `item_mesa`
--

DROP TABLE IF EXISTS `item_mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `item_mesa` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cantidad` int(10) unsigned NOT NULL CHECK (`cantidad` >= 0),
  `precio_unitario` decimal(12,2) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `fecha_agregado` datetime(6) NOT NULL,
  `facturado` tinyint(1) NOT NULL,
  `lote_id` bigint(20) NOT NULL,
  `producto_id` bigint(20) NOT NULL,
  `mesa_id` bigint(20) NOT NULL,
  `anotacion` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `item_mesa`
--

LOCK TABLES `item_mesa` WRITE;
/*!40000 ALTER TABLE `item_mesa` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `item_mesa` VALUES
(1,1,3000.00,3000.00,'2025-12-01 03:31:41.112642',1,10,3,1,NULL),
(2,1,3800.00,3800.00,'2025-12-01 03:32:09.775382',1,19,1,1,NULL),
(3,5,4500.00,22500.00,'2025-12-01 03:32:17.934640',1,3,7,1,NULL),
(4,1,3500.00,3500.00,'2025-12-01 03:41:33.778558',1,15,12,2,NULL),
(5,1,3500.00,3500.00,'2025-12-01 03:47:01.061139',1,15,12,1,NULL),
(6,1,3500.00,3500.00,'2025-12-01 03:53:45.711638',1,15,12,1,'comrpo'),
(7,1,3500.00,3500.00,'2025-12-01 03:58:18.717069',1,15,12,1,'lo pidio carlos 3'),
(8,1,3500.00,3500.00,'2025-12-01 04:02:46.283808',1,15,12,1,'lo pidio andres'),
(9,1,5000.00,5000.00,'2025-12-01 04:27:25.302039',1,20,10,1,''),
(10,1,3500.00,3500.00,'2025-12-01 04:35:43.913405',1,15,12,1,''),
(11,1,3500.00,3500.00,'2025-12-01 04:44:38.682092',1,15,12,1,''),
(12,1,3000.00,3000.00,'2025-12-01 04:48:46.626075',1,10,3,1,''),
(13,1,3500.00,3500.00,'2025-12-01 04:56:17.342770',1,15,12,9,''),
(14,3,5000.00,15000.00,'2025-12-01 05:00:11.363843',1,20,10,9,''),
(15,1,3500.00,3500.00,'2025-12-01 05:00:56.235226',1,15,12,9,''),
(16,1,3800.00,3800.00,'2025-12-01 05:02:58.596302',1,19,1,9,''),
(17,1,5000.00,5000.00,'2025-12-01 05:03:43.947843',1,20,10,9,''),
(18,14,3500.00,49000.00,'2025-12-01 11:26:16.400331',1,15,12,9,'los pidio juan');
/*!40000 ALTER TABLE `item_mesa` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `lote`
--

DROP TABLE IF EXISTS `lote`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `lote` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `reabastecimiento_detalle_id` int(11) DEFAULT NULL,
  `numero_lote` varchar(50) NOT NULL,
  `cantidad_disponible` int(11) unsigned NOT NULL,
  `costo_unitario_lote` decimal(12,2) NOT NULL,
  `fecha_caducidad` date NOT NULL,
  `fecha_entrada` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` enum('activo','agotado','vencido','descartado') NOT NULL DEFAULT 'activo',
  `ubicacion_fisica_id` int(11) DEFAULT NULL,
  `temperatura_almacenamiento` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lote_producto_numero` (`producto_id`,`numero_lote`),
  KEY `fk_lote_producto` (`producto_id`),
  KEY `fk_lote_reabastecimiento_detalle` (`reabastecimiento_detalle_id`),
  KEY `idx_lote_estado` (`estado`),
  KEY `idx_lote_fecha_caducidad` (`fecha_caducidad`),
  KEY `idx_lote_estado_cantidad` (`estado`,`cantidad_disponible`),
  KEY `idx_lote_fecha_caducidad_estado` (`fecha_caducidad`,`estado`),
  KEY `fk_lote_ubicacion_fisica` (`ubicacion_fisica_id`),
  CONSTRAINT `fk_lote_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_lote_reabastecimiento_detalle` FOREIGN KEY (`reabastecimiento_detalle_id`) REFERENCES `reabastecimiento_detalle` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_lote_ubicacion_fisica` FOREIGN KEY (`ubicacion_fisica_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_lote_cantidad_positiva` CHECK (`cantidad_disponible` >= 0),
  CONSTRAINT `chk_lote_fecha_valida` CHECK (`fecha_caducidad` >= `fecha_entrada`),
  CONSTRAINT `chk_lote_costo_positivo` CHECK (`costo_unitario_lote` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lote`
--

LOCK TABLES `lote` WRITE;
/*!40000 ALTER TABLE `lote` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `lote` VALUES
(1,1,1,'LCH-A1',0,2500.00,'2025-10-30','2025-09-01 10:00:00','activo',NULL,NULL),
(2,2,2,'QSO-C3',0,7000.00,'2025-11-15','2025-09-05 14:00:00','vencido',NULL,NULL),
(3,7,38,'R36-P7-38',0,4500.00,'2025-12-31','2025-11-05 11:38:47','agotado',NULL,NULL),
(4,8,39,'R37-P8-39',0,2500.00,'2025-12-06','2025-11-05 13:45:41','activo',NULL,NULL),
(5,7,42,'R40-P7-42',193,4500.00,'2026-01-15','2025-11-06 23:06:20','activo',NULL,NULL),
(6,7,40,'R38-P7-40',96,4500.00,'2026-01-17','2025-11-06 23:08:20','activo',NULL,NULL),
(7,1,45,'R45-P1-45',5,3800.00,'2026-01-10','2025-11-12 22:46:31','activo',NULL,NULL),
(10,3,55,'R55-P3-55',187,3000.00,'2026-01-03','2025-11-19 13:20:32','activo',NULL,NULL),
(14,11,58,'R58-P11-58',0,3000.00,'2025-11-29','2025-11-21 11:50:44','vencido',NULL,NULL),
(15,12,59,'R59-P12-59',0,3500.00,'2025-11-29','2025-11-21 12:10:34','vencido',NULL,NULL),
(17,9,46,'R46-P9-46',99,3000.00,'2026-02-12','2025-11-24 00:23:01','activo',NULL,NULL),
(18,9,60,'R60-P9-60',22,3000.00,'2026-01-01','2025-11-24 15:06:00','activo',NULL,NULL),
(19,1,61,'R61-P1-61',21,3800.00,'2025-12-31','2025-11-29 23:25:07','activo',NULL,NULL),
(20,10,80,'R80-P10-80',78,5000.00,'2026-01-01','2025-11-30 02:52:22','activo',NULL,NULL),
(23,10,120,'R131-P10-120',99,5000.00,'2025-12-31','2025-12-02 05:49:59','activo',NULL,NULL),
(24,9,121,'R131-P9-121',50,3000.00,'2026-01-01','2025-12-02 05:49:59','activo',NULL,NULL);
/*!40000 ALTER TABLE `lote` ENABLE KEYS */;
UNLOCK TABLES;
commit;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_lote_after_insert
AFTER INSERT ON lote
FOR EACH ROW
BEGIN
  UPDATE producto
    SET stock_actual = stock_actual + NEW.cantidad_disponible
    WHERE id = NEW.producto_id;

  CALL sp_recalcular_costo_promedio_por_producto(NEW.producto_id);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_lote_actualizar_estado
BEFORE UPDATE ON lote
FOR EACH ROW
BEGIN
    
    IF NEW.cantidad_disponible = 0 AND OLD.cantidad_disponible > 0 THEN
        SET NEW.estado = 'agotado';
    END IF;
    
    
    IF NEW.cantidad_disponible > 0 AND OLD.cantidad_disponible = 0 THEN
        SET NEW.estado = 'activo';
    END IF;
    
    
    IF NEW.fecha_caducidad < CURDATE() THEN
        SET NEW.estado = 'vencido';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_lote_after_update
            AFTER UPDATE ON lote
            FOR EACH ROW
            BEGIN
              DECLARE diff INT;
              SET diff = CAST(NEW.cantidad_disponible AS SIGNED) - CAST(OLD.cantidad_disponible AS SIGNED);
              IF diff <> 0 THEN
                UPDATE producto
                  SET stock_actual = stock_actual + diff
                  WHERE id = NEW.producto_id;
              END IF;

              IF NEW.producto_id <> OLD.producto_id THEN
                CALL sp_recalcular_costo_promedio_por_producto(OLD.producto_id);
                CALL sp_recalcular_costo_promedio_por_producto(NEW.producto_id);
              ELSE
                CALL sp_recalcular_costo_promedio_por_producto(NEW.producto_id);
              END IF;
            END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_lote_after_delete
AFTER DELETE ON lote
FOR EACH ROW
BEGIN
  UPDATE producto
    SET stock_actual = stock_actual - OLD.cantidad_disponible
    WHERE id = OLD.producto_id;

  CALL sp_recalcular_costo_promedio_por_producto(OLD.producto_id);
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `merma_esperada`
--

DROP TABLE IF EXISTS `merma_esperada`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `merma_esperada` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `categoria_id` int(11) NOT NULL,
  `porcentaje_merma` decimal(5,2) NOT NULL COMMENT 'Porcentaje esperado de merma',
  `motivo_principal` varchar(255) DEFAULT NULL,
  `descripcion` text DEFAULT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_vigencia_desde` date NOT NULL,
  `fecha_vigencia_hasta` date DEFAULT NULL,
  `creado_por_id` bigint(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_merma_categoria` (`categoria_id`),
  KEY `fk_merma_creado_por` (`creado_por_id`),
  KEY `idx_merma_vigencia` (`fecha_vigencia_desde`,`fecha_vigencia_hasta`),
  CONSTRAINT `fk_merma_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_merma_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Merma esperada por categoría';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `merma_esperada`
--

LOCK TABLES `merma_esperada` WRITE;
/*!40000 ALTER TABLE `merma_esperada` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `merma_esperada` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `mesa`
--

DROP TABLE IF EXISTS `mesa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mesa` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `numero` varchar(10) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `capacidad` int(10) unsigned NOT NULL CHECK (`capacidad` >= 0),
  `estado` varchar(20) NOT NULL,
  `activa` tinyint(1) NOT NULL,
  `cuenta_abierta` tinyint(1) NOT NULL,
  `total_cuenta` decimal(12,2) NOT NULL,
  `fecha_apertura` datetime(6) DEFAULT NULL,
  `cliente_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `numero` (`numero`),
  KEY `mesa_cliente_id_4fccd43b_fk_cliente_id` (`cliente_id`),
  CONSTRAINT `mesa_cliente_id_4fccd43b_fk_cliente_id` FOREIGN KEY (`cliente_id`) REFERENCES `cliente` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mesa`
--

LOCK TABLES `mesa` WRITE;
/*!40000 ALTER TABLE `mesa` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `mesa` VALUES
(1,'1','Mesa 1',4,'disponible',0,0,0.00,NULL,NULL),
(2,'2','Mesa 2',4,'disponible',0,0,0.00,NULL,NULL),
(3,'3','Mesa 3',6,'disponible',0,0,0.00,NULL,NULL),
(4,'4','Mesa 4',4,'disponible',0,0,0.00,NULL,NULL),
(5,'5','Mesa 5',2,'disponible',0,0,0.00,NULL,NULL),
(6,'6','Mesa 6',4,'disponible',0,0,0.00,NULL,NULL),
(7,'7','Mesa 7',6,'disponible',0,0,0.00,NULL,NULL),
(8,'8','Mesa 8',4,'disponible',0,0,0.00,NULL,NULL),
(9,'9','grupo afuera',4,'disponible',1,0,0.00,NULL,NULL);
/*!40000 ALTER TABLE `mesa` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `movimiento_inventario`
--

DROP TABLE IF EXISTS `movimiento_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `movimiento_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `costo_unitario` decimal(12,2) DEFAULT NULL,
  `tipo_movimiento` enum('ENTRADA','SALIDA','AJUSTE','DEVOLUCION','DESCARTE','TRANSFERENCIA') NOT NULL,
  `fecha_movimiento` datetime NOT NULL DEFAULT current_timestamp(),
  `descripcion` varchar(255) DEFAULT NULL,
  `documento_soporte` varchar(100) DEFAULT NULL,
  `ubicacion_origen_id` int(11) DEFAULT NULL,
  `ubicacion_destino_id` int(11) DEFAULT NULL,
  `usuario_id` bigint(20) DEFAULT NULL,
  `venta_id` int(11) DEFAULT NULL,
  `reabastecimiento_id` int(11) DEFAULT NULL,
  `transferencia_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `producto_id` (`producto_id`),
  KEY `lote_id` (`lote_id`),
  KEY `venta_id` (`venta_id`),
  KEY `reabastecimiento_id` (`reabastecimiento_id`),
  KEY `idx_movimiento_fecha` (`fecha_movimiento`),
  KEY `idx_movimiento_tipo` (`tipo_movimiento`),
  KEY `idx_movimiento_usuario` (`usuario_id`),
  KEY `fk_movimiento_ubicacion_origen` (`ubicacion_origen_id`),
  KEY `fk_movimiento_ubicacion_destino` (`ubicacion_destino_id`),
  KEY `fk_movimiento_transferencia` (`transferencia_id`),
  CONSTRAINT `fk_movimiento_inventario_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movimiento_inventario_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movimiento_inventario_reabastecimiento` FOREIGN KEY (`reabastecimiento_id`) REFERENCES `reabastecimiento` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movimiento_inventario_venta` FOREIGN KEY (`venta_id`) REFERENCES `venta` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movimiento_transferencia` FOREIGN KEY (`transferencia_id`) REFERENCES `transferencia_inventario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_movimiento_ubicacion_destino` FOREIGN KEY (`ubicacion_destino_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_movimiento_ubicacion_origen` FOREIGN KEY (`ubicacion_origen_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_movimiento_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `movimiento_inventario`
--

LOCK TABLES `movimiento_inventario` WRITE;
/*!40000 ALTER TABLE `movimiento_inventario` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `movimiento_inventario` VALUES
(1,1,1,100,NULL,'ENTRADA','2025-10-10 22:48:22','Reabastecimiento inicial Lote A1',NULL,NULL,NULL,NULL,NULL,1,NULL),
(2,2,2,60,NULL,'ENTRADA','2025-10-10 22:48:22','Reabastecimiento inicial Lote C3',NULL,NULL,NULL,NULL,NULL,1,NULL),
(3,1,1,-2,NULL,'SALIDA','2025-10-10 22:48:22','Venta ID 1',NULL,NULL,NULL,NULL,1,NULL,NULL),
(4,2,2,-1,NULL,'SALIDA','2025-10-10 22:48:22','Venta ID 2',NULL,NULL,NULL,NULL,2,NULL,NULL),
(5,7,3,60,NULL,'ENTRADA','2025-11-05 11:38:47','Entrada por reabastecimiento #36',NULL,NULL,NULL,NULL,NULL,36,NULL),
(6,7,3,-1,NULL,'SALIDA','2025-11-05 12:40:34','Venta #6',NULL,NULL,NULL,NULL,6,NULL,NULL),
(7,1,1,-6,NULL,'SALIDA','2025-11-05 12:44:58','Venta #7',NULL,NULL,NULL,NULL,7,NULL,NULL),
(8,8,4,10,NULL,'ENTRADA','2025-11-05 13:45:41','Entrada por reabastecimiento #37',NULL,NULL,NULL,NULL,NULL,37,NULL),
(9,8,4,-10,NULL,'SALIDA','2025-11-05 13:48:30','Venta #8',NULL,NULL,NULL,NULL,8,NULL,NULL),
(10,7,3,-4,NULL,'SALIDA','2025-11-06 22:52:29','Venta #9',NULL,NULL,NULL,NULL,9,NULL,NULL),
(11,7,5,199,NULL,'ENTRADA','2025-11-06 23:06:20','Entrada por reabastecimiento #40',NULL,NULL,NULL,NULL,NULL,40,NULL),
(12,7,6,100,NULL,'ENTRADA','2025-11-06 23:08:20','Entrada por reabastecimiento #38',NULL,NULL,NULL,NULL,NULL,38,NULL),
(13,1,7,5,NULL,'ENTRADA','2025-11-12 22:46:31','Entrada por reabastecimiento #45',NULL,NULL,NULL,NULL,NULL,45,NULL),
(16,3,10,199,NULL,'ENTRADA','2025-11-19 13:20:32','Entrada por reabastecimiento #55',NULL,NULL,NULL,NULL,NULL,55,NULL),
(18,11,14,55,NULL,'ENTRADA','2025-11-21 11:50:44','Entrada por reabastecimiento #58',NULL,NULL,NULL,NULL,NULL,58,NULL),
(19,12,15,43,NULL,'ENTRADA','2025-11-21 12:10:34','Entrada por reabastecimiento #59',NULL,NULL,NULL,NULL,NULL,59,NULL),
(20,9,17,99,NULL,'ENTRADA','2025-11-24 00:23:01','Entrada por reabastecimiento #46',NULL,NULL,NULL,NULL,NULL,46,NULL),
(21,9,18,22,NULL,'ENTRADA','2025-11-24 15:06:00','Entrada por reabastecimiento #60',NULL,NULL,NULL,NULL,NULL,60,NULL),
(22,7,NULL,-5,NULL,'SALIDA','2025-11-24 15:15:44','Asignación a producto canjeable: Cerveza Aguila',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(23,1,19,23,NULL,'ENTRADA','2025-11-29 23:25:07','Recepción de reabastecimiento #61',NULL,NULL,NULL,NULL,NULL,NULL,NULL),
(24,10,20,89,NULL,'ENTRADA','2025-11-30 02:52:22','Entrada por reabastecimiento #80',NULL,NULL,NULL,NULL,NULL,80,NULL),
(25,10,20,-1,NULL,'SALIDA','2025-12-01 01:44:30','Venta #29 - Coronita',NULL,NULL,NULL,NULL,29,NULL,NULL),
(26,2,2,-1,NULL,'SALIDA','2025-12-01 01:44:30','Venta #29 - Queso Campesino 500g',NULL,NULL,NULL,NULL,29,NULL,NULL),
(27,2,2,-2,NULL,'SALIDA','2025-12-01 02:18:16','Venta #30 - Queso Campesino 500g',NULL,NULL,NULL,NULL,30,NULL,NULL),
(28,10,20,-1,NULL,'SALIDA','2025-12-01 02:24:38','Venta #31 - Coronita',NULL,NULL,NULL,NULL,31,NULL,NULL),
(29,7,3,-4,NULL,'SALIDA','2025-12-01 02:54:10','Venta #32 - Cerveza Aguila',NULL,NULL,NULL,NULL,32,NULL,NULL),
(30,7,5,-4,NULL,'SALIDA','2025-12-01 02:54:10','Venta #32 - Cerveza Aguila',NULL,NULL,NULL,NULL,32,NULL,NULL),
(31,7,6,-4,NULL,'SALIDA','2025-12-01 02:54:10','Venta #32 - Cerveza Aguila',NULL,NULL,NULL,NULL,32,NULL,NULL),
(32,12,15,-1,NULL,'SALIDA','2025-12-01 02:54:42','Venta #33 - todo rico natural',NULL,NULL,NULL,NULL,33,NULL,NULL),
(33,10,20,-2,NULL,'SALIDA','2025-12-01 02:59:44','Venta #34 - Coronita',NULL,NULL,NULL,NULL,34,NULL,NULL),
(34,3,10,-10,NULL,'SALIDA','2025-12-01 02:59:44','Venta #34 - Yogurt',NULL,NULL,NULL,NULL,34,NULL,NULL),
(35,7,3,-10,NULL,'SALIDA','2025-12-01 03:01:04','Venta #35 - Cerveza Aguila',NULL,NULL,NULL,NULL,35,NULL,NULL),
(36,12,15,-1,NULL,'SALIDA','2025-12-01 03:41:57','Venta Mesa 2 - Venta #36',NULL,NULL,NULL,NULL,36,NULL,NULL),
(37,3,10,-1,NULL,'SALIDA','2025-12-01 03:45:44','Venta Mesa 1 - Venta #37',NULL,NULL,NULL,NULL,37,NULL,NULL),
(38,1,19,-1,NULL,'SALIDA','2025-12-01 03:45:44','Venta Mesa 1 - Venta #37',NULL,NULL,NULL,NULL,37,NULL,NULL),
(39,7,3,-5,NULL,'SALIDA','2025-12-01 03:45:44','Venta Mesa 1 - Venta #37',NULL,NULL,NULL,NULL,37,NULL,NULL),
(40,12,15,-1,NULL,'SALIDA','2025-12-01 03:57:45','Venta #38 - todo rico natural',NULL,NULL,NULL,NULL,38,NULL,NULL),
(41,12,15,-1,NULL,'SALIDA','2025-12-01 04:25:46','Venta Mesa 1 - Venta #39',NULL,NULL,NULL,NULL,39,NULL,NULL),
(42,12,15,-1,NULL,'SALIDA','2025-12-01 04:25:46','Venta Mesa 1 - Venta #39',NULL,NULL,NULL,NULL,39,NULL,NULL),
(43,12,15,-1,NULL,'SALIDA','2025-12-01 04:25:46','Venta Mesa 1 - Venta #39',NULL,NULL,NULL,NULL,39,NULL,NULL),
(44,12,15,-1,NULL,'SALIDA','2025-12-01 04:25:46','Venta Mesa 1 - Venta #39',NULL,NULL,NULL,NULL,39,NULL,NULL),
(45,10,20,-1,NULL,'SALIDA','2025-12-01 04:41:54','Venta Mesa 1 - Venta #40',NULL,NULL,NULL,NULL,40,NULL,NULL),
(46,12,15,-1,NULL,'SALIDA','2025-12-01 04:41:54','Venta Mesa 1 - Venta #40',NULL,NULL,NULL,NULL,40,NULL,NULL),
(47,12,15,-1,NULL,'SALIDA','2025-12-01 04:48:18','Venta Mesa 1 - Venta #41',NULL,NULL,NULL,NULL,41,NULL,NULL),
(48,3,10,-1,NULL,'SALIDA','2025-12-01 04:48:58','Venta Mesa 1 - Venta #42',NULL,NULL,NULL,NULL,42,NULL,NULL),
(49,10,20,-2,NULL,'SALIDA','2025-12-01 04:54:25','Venta #43 - Coronita',NULL,NULL,NULL,NULL,43,NULL,NULL),
(50,12,15,-1,NULL,'SALIDA','2025-12-01 04:56:31','Venta Mesa 9 - Venta #44',NULL,NULL,NULL,NULL,44,NULL,NULL),
(51,12,15,-1,NULL,'SALIDA','2025-12-01 04:56:52','Venta #45 - todo rico natural',NULL,NULL,NULL,NULL,45,NULL,NULL),
(52,12,15,-1,NULL,'SALIDA','2025-12-01 04:59:27','Venta #46 - todo rico natural',NULL,NULL,NULL,NULL,46,NULL,NULL),
(53,12,15,-1,NULL,'SALIDA','2025-12-01 04:59:48','Venta #47 - todo rico natural',NULL,NULL,NULL,NULL,47,NULL,NULL),
(54,10,20,-3,NULL,'SALIDA','2025-12-01 05:00:24','Venta Mesa 9 - Venta #48',NULL,NULL,NULL,NULL,48,NULL,NULL),
(55,12,15,-1,NULL,'SALIDA','2025-12-01 05:01:08','Venta Mesa 9 - Venta #49',NULL,NULL,NULL,NULL,49,NULL,NULL),
(56,1,19,-1,NULL,'SALIDA','2025-12-01 05:03:16','Venta Mesa 9 - Venta #50',NULL,NULL,NULL,NULL,50,NULL,NULL),
(57,10,20,-1,NULL,'SALIDA','2025-12-01 05:04:04','Venta Mesa 9 - Venta #51',NULL,NULL,NULL,NULL,51,NULL,NULL),
(58,12,15,-14,NULL,'SALIDA','2025-12-01 11:27:08','Venta Mesa 9 - Venta #52',NULL,NULL,NULL,NULL,52,NULL,NULL),
(59,2,2,-18,NULL,'SALIDA','2025-12-02 04:22:03','Venta #53 - Queso Campesino 500g',NULL,NULL,NULL,NULL,53,NULL,NULL),
(60,7,3,-5,NULL,'SALIDA','2025-12-02 04:22:03','Venta #53 - Cerveza Aguila',NULL,NULL,NULL,NULL,53,NULL,NULL),
(61,10,23,99,NULL,'ENTRADA','2025-12-02 05:49:59','Entrada por reabastecimiento #131',NULL,NULL,NULL,NULL,NULL,131,NULL),
(62,9,24,50,NULL,'ENTRADA','2025-12-02 05:49:59','Entrada por reabastecimiento #131',NULL,NULL,NULL,NULL,NULL,131,NULL),
(63,7,3,-5,NULL,'SALIDA','2025-12-09 01:26:16','Venta #54 - Cerveza Aguila',NULL,NULL,NULL,NULL,54,NULL,NULL),
(64,7,5,-2,NULL,'SALIDA','2025-12-09 01:26:16','Venta #54 - Cerveza Aguila',NULL,NULL,NULL,NULL,54,NULL,NULL),
(65,2,2,-27,7000.00,'DESCARTE','2025-12-09 02:04:30','Descarte automático lote vencido - QSO-C3',NULL,NULL,NULL,2,NULL,NULL,NULL),
(66,2,2,-27,7000.00,'DESCARTE','2025-12-09 02:05:07','Descarte automático lote vencido - QSO-C3',NULL,NULL,NULL,2,NULL,NULL,NULL),
(67,2,2,-27,7000.00,'DESCARTE','2025-12-09 02:05:47','Descarte automático lote vencido - QSO-C3',NULL,NULL,NULL,2,NULL,NULL,NULL),
(68,2,2,-27,7000.00,'DESCARTE','2025-12-09 02:06:08','Descarte automático lote vencido - QSO-C3',NULL,NULL,NULL,2,NULL,NULL,NULL),
(69,2,2,-27,7000.00,'DESCARTE','2025-12-09 02:07:53','Descarte automático lote vencido - QSO-C3',NULL,NULL,NULL,2,NULL,NULL,NULL),
(70,11,14,-16,3000.00,'DESCARTE','2025-12-09 02:07:53','Descarte automático lote vencido - R58-P11-58',NULL,NULL,NULL,2,NULL,NULL,NULL),
(71,12,15,-15,3500.00,'DESCARTE','2025-12-09 02:07:53','Descarte automático lote vencido - R59-P12-59',NULL,NULL,NULL,2,NULL,NULL,NULL);
/*!40000 ALTER TABLE `movimiento_inventario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pago`
--

DROP TABLE IF EXISTS `pago`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pago` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `venta_id` int(11) NOT NULL,
  `monto` decimal(12,2) NOT NULL,
  `metodo_pago` varchar(25) NOT NULL,
  `fecha_pago` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` varchar(20) NOT NULL DEFAULT 'completado' COMMENT 'Posibles: completado, fallido, reembolsado',
  `referencia_transaccion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `venta_id` (`venta_id`),
  CONSTRAINT `fk_pago_venta` FOREIGN KEY (`venta_id`) REFERENCES `venta` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pago`
--

LOCK TABLES `pago` WRITE;
/*!40000 ALTER TABLE `pago` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pago` VALUES
(1,1,7600.00,'Efectivo','2025-09-02 10:00:00','completado',NULL),
(2,2,9500.00,'Tarjeta','2025-09-03 11:30:00','completado',NULL),
(3,3,4500.00,'Efectivo','2025-11-05 12:24:54','completado',NULL),
(4,4,54000.00,'Efectivo','2025-11-05 12:25:24','completado',NULL),
(5,5,45600.00,'Efectivo','2025-11-05 12:25:41','completado',NULL),
(6,6,4500.00,'Efectivo','2025-11-05 12:40:34','completado',NULL),
(7,7,22800.00,'Efectivo','2025-11-05 12:44:58','completado',NULL),
(8,8,25000.00,'Efectivo','2025-11-05 13:48:30','completado',NULL),
(9,9,18000.00,'Efectivo','2025-11-06 22:52:29','completado',NULL),
(17,17,3800.00,'efectivo','2025-11-22 05:34:57','completado',NULL),
(18,18,3000.00,'efectivo','2025-11-22 05:40:24','completado',NULL),
(19,19,3000.00,'efectivo','2025-11-22 05:40:34','completado',NULL),
(20,20,3000.00,'efectivo','2025-11-22 05:40:34','completado',NULL),
(21,21,3000.00,'efectivo','2025-11-22 05:40:34','completado',NULL),
(22,22,304700.00,'efectivo','2025-11-22 06:15:41','completado',NULL),
(23,23,54000.00,'efectivo','2025-11-22 06:26:10','completado',NULL),
(24,24,54000.00,'efectivo','2025-11-22 06:27:01','completado',NULL),
(25,25,54000.00,'efectivo','2025-11-22 06:28:05','completado',NULL),
(26,26,304700.00,'efectivo','2025-11-22 06:32:54','completado',NULL),
(27,27,9500.00,'efectivo','2025-11-23 06:02:59','completado',NULL),
(28,28,95000.00,'efectivo','2025-11-23 06:05:55','completado',NULL),
(29,29,14500.00,'tarjeta_debito','2025-12-01 01:44:30','completado',NULL),
(30,30,19000.00,'tarjeta_debito','2025-12-01 02:18:16','completado',NULL),
(31,31,5000.00,'transferencia','2025-12-01 02:24:38','completado',NULL),
(32,32,54000.00,'tarjeta_debito','2025-12-01 02:54:10','completado',NULL),
(33,33,3500.00,'tarjeta_debito','2025-12-01 02:54:42','completado',NULL),
(34,34,40000.00,'tarjeta_debito','2025-12-01 02:59:44','completado',NULL),
(35,35,45000.00,'tarjeta_debito','2025-12-01 03:01:04','completado',NULL),
(36,36,3500.00,'efectivo','2025-12-01 03:41:57','completado',NULL),
(37,37,29300.00,'efectivo','2025-12-01 03:45:44','completado',NULL),
(38,38,3500.00,'efectivo','2025-12-01 03:57:45','completado',NULL),
(39,39,14000.00,'efectivo','2025-12-01 04:25:46','completado',NULL),
(40,40,8500.00,'efectivo','2025-12-01 04:41:54','completado',NULL),
(41,41,3500.00,'efectivo','2025-12-01 04:48:18','completado',NULL),
(42,42,3000.00,'efectivo','2025-12-01 04:48:58','completado',NULL),
(43,43,10000.00,'tarjeta_debito','2025-12-01 04:54:25','completado',NULL),
(44,44,3500.00,'efectivo','2025-12-01 04:56:31','completado',NULL),
(45,45,3500.00,'efectivo','2025-12-01 04:56:52','completado',NULL),
(46,46,3500.00,'efectivo','2025-12-01 04:59:27','completado',NULL),
(47,47,3500.00,'efectivo','2025-12-01 04:59:48','completado',NULL),
(48,48,15000.00,'efectivo','2025-12-01 05:00:24','completado',NULL),
(49,49,3500.00,'efectivo','2025-12-01 05:01:07','completado',NULL),
(50,50,3800.00,'efectivo','2025-12-01 05:03:16','completado',NULL),
(51,51,5000.00,'efectivo','2025-12-01 05:04:04','completado',NULL),
(52,52,49000.00,'tarjeta_credito','2025-12-01 11:27:08','completado',NULL),
(53,53,193500.00,'efectivo','2025-12-02 04:22:03','completado',NULL),
(54,54,31500.00,'efectivo','2025-12-09 01:26:16','completado',NULL);
/*!40000 ALTER TABLE `pago` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pedido`
--

DROP TABLE IF EXISTS `pedido`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cliente_id` bigint(20) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `fecha_pedido` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` varchar(20) NOT NULL DEFAULT 'pendiente' COMMENT 'Posibles estados: pendiente, en_proceso, completado, cancelado',
  `total_pedido` decimal(12,2) NOT NULL DEFAULT 0.00,
  `observaciones` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cliente_id` (`cliente_id`),
  KEY `usuario_id` (`usuario_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido`
--

LOCK TABLES `pedido` WRITE;
/*!40000 ALTER TABLE `pedido` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pedido` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pedido_detalle`
--

DROP TABLE IF EXISTS `pedido_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pedido_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL COMMENT 'Precio del producto en el momento del pedido',
  `subtotal` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `pedido_id` (`pedido_id`),
  KEY `producto_id` (`producto_id`),
  CONSTRAINT `fk_pedido_detalle_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pedido_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido_detalle`
--

LOCK TABLES `pedido_detalle` WRITE;
/*!40000 ALTER TABLE `pedido_detalle` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pedido_detalle` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs`
--

DROP TABLE IF EXISTS `pqrs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `numero_caso` varchar(20) NOT NULL,
  `tipo` varchar(20) NOT NULL,
  `categoria` varchar(50) NOT NULL DEFAULT 'general',
  `prioridad` varchar(20) NOT NULL DEFAULT 'media',
  `canal_origen` varchar(20) NOT NULL DEFAULT 'web',
  `descripcion` text NOT NULL,
  `estado` varchar(20) DEFAULT 'nuevo',
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `fecha_primera_respuesta` datetime DEFAULT NULL,
  `fecha_cierre` datetime DEFAULT NULL,
  `tiempo_resolucion_horas` int(11) DEFAULT NULL,
  `fecha_limite_sla` datetime DEFAULT NULL,
  `sla_vencido` tinyint(1) DEFAULT 0,
  `ultima_modificacion_por_id` bigint(20) DEFAULT NULL,
  `cliente_id` bigint(20) NOT NULL,
  `creado_por_id` bigint(20) NOT NULL,
  `asignado_a_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `numero_caso` (`numero_caso`),
  UNIQUE KEY `uq_numero_caso` (`numero_caso`),
  KEY `idx_estado` (`estado`),
  KEY `idx_prioridad` (`prioridad`),
  KEY `idx_cliente` (`cliente_id`),
  KEY `idx_creado_por` (`creado_por_id`),
  KEY `idx_asignado_a` (`asignado_a_id`),
  KEY `idx_estado_fecha` (`estado`,`fecha_creacion`),
  KEY `idx_canal` (`canal_origen`),
  KEY `fk_pqrs_ultima_modificacion` (`ultima_modificacion_por_id`),
  KEY `idx_sla_vencido` (`sla_vencido`),
  KEY `idx_fecha_limite_sla` (`fecha_limite_sla`),
  CONSTRAINT `fk_pqrs_asignado_a` FOREIGN KEY (`asignado_a_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_pqrs_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `cliente` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pqrs_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pqrs_ultima_modificacion` FOREIGN KEY (`ultima_modificacion_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs`
--

LOCK TABLES `pqrs` WRITE;
/*!40000 ALTER TABLE `pqrs` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pqrs` VALUES
(1,'PQRS-2025-0001','SUGERENCIA','general','media','web','Más productos saludables','en_proceso','2025-07-01 10:00:00','2025-12-04 16:28:03',NULL,NULL,NULL,'2025-07-06 10:00:00',1,NULL,1,2,2),
(10,'PQRS-2025-0010','peticion','general','urgente','web','prueba','cerrado','2025-12-07 19:36:46','2025-12-07 15:56:34','2025-12-07 15:27:07','2025-12-07 15:34:11',NULL,'2025-12-07 23:36:46',0,NULL,1,4,4);
/*!40000 ALTER TABLE `pqrs` ENABLE KEYS */;
UNLOCK TABLES;
commit;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER before_insert_pqrs
                BEFORE INSERT ON pqrs
                FOR EACH ROW
                BEGIN
                    DECLARE contador INT;
                    DECLARE anio INT;
                    
                    IF NEW.numero_caso IS NULL OR NEW.numero_caso = '' THEN
                        SET anio = YEAR(NOW());
                        SELECT COALESCE(MAX(CAST(SUBSTRING(numero_caso, -4) AS UNSIGNED)), 0) + 1 
                        INTO contador
                        FROM pqrs
                        WHERE numero_caso LIKE CONCAT('PQRS-', anio, '-%');
                        SET NEW.numero_caso = CONCAT('PQRS-', anio, '-', LPAD(contador, 4, '0'));
                    END IF;
                    
                    IF NEW.asignado_a_id IS NULL THEN
                        SET NEW.asignado_a_id = NEW.creado_por_id;
                    END IF;
                END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER before_update_pqrs
                BEFORE UPDATE ON pqrs
                FOR EACH ROW
                BEGIN
                    IF NEW.estado = 'cerrado' AND OLD.estado != 'cerrado' THEN
                        SET NEW.fecha_cierre = NOW();
                        SET NEW.tiempo_resolucion_horas = TIMESTAMPDIFF(HOUR, NEW.fecha_creacion, NOW());
                    END IF;
                    
                    IF NEW.fecha_primera_respuesta IS NULL AND OLD.estado = 'nuevo' AND NEW.estado != 'nuevo' THEN
                        SET NEW.fecha_primera_respuesta = NOW();
                    END IF;
                END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `pqrs_adjunto`
--

DROP TABLE IF EXISTS `pqrs_adjunto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_adjunto` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `pqrs_id` bigint(20) NOT NULL,
  `nombre_archivo` varchar(255) NOT NULL,
  `ruta_archivo` varchar(500) NOT NULL,
  `tipo_mime` varchar(100) NOT NULL,
  `tamano_bytes` bigint(20) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `subido_por_id` bigint(20) DEFAULT NULL,
  `fecha_subida` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_pqrs` (`pqrs_id`),
  KEY `idx_subido_por` (`subido_por_id`),
  CONSTRAINT `fk_adjunto_pqrs` FOREIGN KEY (`pqrs_id`) REFERENCES `pqrs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_adjunto_usuario` FOREIGN KEY (`subido_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_adjunto`
--

LOCK TABLES `pqrs_adjunto` WRITE;
/*!40000 ALTER TABLE `pqrs_adjunto` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pqrs_adjunto` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_backup`
--

DROP TABLE IF EXISTS `pqrs_backup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_backup` (
  `id` bigint(20) NOT NULL DEFAULT 0,
  `tipo` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `respuesta` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'pendiente',
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `cliente_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_backup`
--

LOCK TABLES `pqrs_backup` WRITE;
/*!40000 ALTER TABLE `pqrs_backup` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pqrs_backup` VALUES
(1,'SUGERENCIA','Más productos saludables',NULL,'en_proceso','2025-07-01 10:00:00',NULL,1,2),
(2,'peticion','Nuevo producto Amper de mango.','Se hara una solicitud de compra del producto solicitado','nuevo','2025-11-24 02:09:13','2025-11-24 02:22:25',5,4);
/*!40000 ALTER TABLE `pqrs_backup` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_calificacion`
--

DROP TABLE IF EXISTS `pqrs_calificacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_calificacion` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `pqrs_id` bigint(20) NOT NULL,
  `puntuacion` int(11) NOT NULL COMMENT '1=Muy malo, 2=Malo, 3=Regular, 4=Bueno, 5=Excelente',
  `comentario` text DEFAULT NULL,
  `fecha_calificacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pqrs_calificacion` (`pqrs_id`),
  CONSTRAINT `fk_calificacion_pqrs` FOREIGN KEY (`pqrs_id`) REFERENCES `pqrs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_puntuacion` CHECK (`puntuacion` >= 1 and `puntuacion` <= 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_calificacion`
--

LOCK TABLES `pqrs_calificacion` WRITE;
/*!40000 ALTER TABLE `pqrs_calificacion` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pqrs_calificacion` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_categoria_personalizada`
--

DROP TABLE IF EXISTS `pqrs_categoria_personalizada`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_categoria_personalizada` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `categoria_padre_id` int(11) DEFAULT NULL,
  `activa` tinyint(1) DEFAULT 1,
  `orden` int(11) DEFAULT 0,
  `icono` varchar(50) DEFAULT NULL,
  `color` varchar(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`),
  KEY `fk_categoria_padre` (`categoria_padre_id`),
  KEY `idx_categoria_activa` (`activa`),
  KEY `idx_categoria_orden` (`orden`),
  CONSTRAINT `fk_categoria_padre` FOREIGN KEY (`categoria_padre_id`) REFERENCES `pqrs_categoria_personalizada` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_categoria_personalizada`
--

LOCK TABLES `pqrs_categoria_personalizada` WRITE;
/*!40000 ALTER TABLE `pqrs_categoria_personalizada` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pqrs_categoria_personalizada` VALUES
(1,'Producto Defectuoso','Productos con defectos de fábrica o daños',NULL,1,1,'box-seam','#dc3545','2025-12-04 16:27:14'),
(2,'Entrega Tardía','Retrasos en la entrega de productos',NULL,1,2,'clock-history','#ffc107','2025-12-04 16:27:14'),
(3,'Atención al Cliente','Problemas con el servicio de atención',NULL,1,3,'headset','#0d6efd','2025-12-04 16:27:14'),
(4,'Precio Incorrecto','Discrepancias en precios o cobros',NULL,1,4,'currency-dollar','#fd7e14','2025-12-04 16:27:14'),
(5,'Producto Faltante','Productos no entregados o faltantes en pedido',NULL,1,5,'box-seam-fill','#dc3545','2025-12-04 16:27:14'),
(6,'Calidad del Producto','Problemas con la calidad o frescura',NULL,1,6,'star-half','#ffc107','2025-12-04 16:27:14'),
(7,'Solicitud de Cambio','Cambios o devoluciones de productos',NULL,1,7,'arrow-repeat','#0dcaf0','2025-12-04 16:27:14'),
(8,'Felicitación','Comentarios positivos y felicitaciones',NULL,1,8,'emoji-smile','#198754','2025-12-04 16:27:14'),
(9,'Sugerencia de Mejora','Ideas para mejorar el servicio',NULL,1,9,'lightbulb','#20c997','2025-12-04 16:27:14'),
(10,'Consulta General','Preguntas o consultas generales',NULL,1,10,'question-circle','#6c757d','2025-12-04 16:27:14');
/*!40000 ALTER TABLE `pqrs_categoria_personalizada` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_escalamiento`
--

DROP TABLE IF EXISTS `pqrs_escalamiento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_escalamiento` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `pqrs_id` bigint(20) NOT NULL,
  `escalado_por_id` bigint(20) DEFAULT NULL,
  `escalado_a_id` bigint(20) DEFAULT NULL,
  `motivo` text NOT NULL,
  `fecha_escalamiento` datetime NOT NULL DEFAULT current_timestamp(),
  `resuelto` tinyint(1) NOT NULL DEFAULT 0,
  `fecha_resolucion` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pqrs` (`pqrs_id`),
  KEY `idx_escalado_a` (`escalado_a_id`),
  KEY `idx_fecha` (`fecha_escalamiento`),
  KEY `fk_escalamiento_escalado_por` (`escalado_por_id`),
  CONSTRAINT `fk_escalamiento_escalado_a` FOREIGN KEY (`escalado_a_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_escalamiento_escalado_por` FOREIGN KEY (`escalado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_escalamiento_pqrs` FOREIGN KEY (`pqrs_id`) REFERENCES `pqrs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_escalamiento`
--

LOCK TABLES `pqrs_escalamiento` WRITE;
/*!40000 ALTER TABLE `pqrs_escalamiento` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pqrs_escalamiento` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_evento`
--

DROP TABLE IF EXISTS `pqrs_evento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_evento` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `pqrs_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) DEFAULT NULL,
  `tipo_evento` varchar(20) NOT NULL,
  `comentario` text DEFAULT NULL,
  `es_visible_cliente` tinyint(1) NOT NULL DEFAULT 1,
  `enviado_por_correo` tinyint(1) DEFAULT 0,
  `fecha_envio_correo` datetime DEFAULT NULL,
  `fecha_evento` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_pqrs` (`pqrs_id`),
  KEY `idx_fecha` (`fecha_evento`),
  KEY `idx_usuario` (`usuario_id`),
  CONSTRAINT `fk_evento_pqrs` FOREIGN KEY (`pqrs_id`) REFERENCES `pqrs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_evento_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_evento`
--

LOCK TABLES `pqrs_evento` WRITE;
/*!40000 ALTER TABLE `pqrs_evento` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pqrs_evento` VALUES
(24,10,4,'creacion','PQRS creado: Petición',1,0,NULL,'2025-12-07 19:36:46'),
(25,10,4,'nota','Caso reasignado de Juan Andres Lizarazo Capera (1014477104) a Juan Andres Lizarazo Capera (1014477104)',0,0,NULL,'2025-12-07 19:37:01'),
(26,10,4,'nota','Caso reasignado de Laura Gomez (10000000) a Laura Gomez (10000000)',0,0,NULL,'2025-12-07 19:37:12'),
(27,10,4,'estado','Cambio de estado: nuevo → en_proceso. Observación: prueba',0,0,NULL,'2025-12-07 20:27:07'),
(28,10,4,'estado','Cambio de estado: en_proceso → resuelto. Observación: prueba',0,0,NULL,'2025-12-07 20:33:45'),
(29,10,4,'estado','Cambio de estado: resuelto → cerrado. Observación: prueba cerrar',0,0,NULL,'2025-12-07 20:34:11');
/*!40000 ALTER TABLE `pqrs_evento` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_evento_backup`
--

DROP TABLE IF EXISTS `pqrs_evento_backup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_evento_backup` (
  `id` bigint(20) NOT NULL DEFAULT 0,
  `tipo_evento` varchar(20) NOT NULL,
  `comentario` longtext DEFAULT NULL,
  `fecha_evento` datetime(6) NOT NULL,
  `pqrs_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_evento_backup`
--

LOCK TABLES `pqrs_evento_backup` WRITE;
/*!40000 ALTER TABLE `pqrs_evento_backup` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pqrs_evento_backup` VALUES
(2,'respuesta','Se hara una solicitud de compra del producto solicitado','2025-11-24 02:12:38.651102',2,4),
(3,'respuesta','Se hara una solicitud de compra del producto solicitado','2025-11-24 02:12:49.195214',2,4),
(4,'respuesta','Se hara una solicitud de compra del producto solicitado','2025-11-24 02:22:25.937688',2,4);
/*!40000 ALTER TABLE `pqrs_evento_backup` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_notificacion`
--

DROP TABLE IF EXISTS `pqrs_notificacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_notificacion` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `pqrs_id` bigint(20) NOT NULL,
  `tipo` enum('email','push','sms','sistema') NOT NULL,
  `destinatario` varchar(255) NOT NULL,
  `asunto` varchar(255) DEFAULT NULL,
  `contenido` text NOT NULL,
  `enviado` tinyint(1) DEFAULT 0,
  `fecha_envio` datetime DEFAULT NULL,
  `error` text DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_notificacion_pqrs` (`pqrs_id`),
  KEY `idx_notificacion_enviado` (`enviado`),
  KEY `idx_notificacion_fecha` (`fecha_creacion`),
  CONSTRAINT `fk_notificacion_pqrs` FOREIGN KEY (`pqrs_id`) REFERENCES `pqrs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_notificacion`
--

LOCK TABLES `pqrs_notificacion` WRITE;
/*!40000 ALTER TABLE `pqrs_notificacion` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pqrs_notificacion` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_plantilla_respuesta`
--

DROP TABLE IF EXISTS `pqrs_plantilla_respuesta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_plantilla_respuesta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `tipo` varchar(20) DEFAULT NULL,
  `categoria` varchar(50) DEFAULT NULL,
  `contenido` text NOT NULL,
  `activa` tinyint(1) DEFAULT 1,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `creado_por_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_plantilla_creado_por` (`creado_por_id`),
  CONSTRAINT `fk_plantilla_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_plantilla_respuesta`
--

LOCK TABLES `pqrs_plantilla_respuesta` WRITE;
/*!40000 ALTER TABLE `pqrs_plantilla_respuesta` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pqrs_plantilla_respuesta` VALUES
(1,'Recepción de Petición','peticion','general','Estimado/a {{cliente_nombre}},\n\nHemos recibido su petición con número de caso {{numero_caso}}. Nuestro equipo está revisando su solicitud y le responderemos en un plazo máximo de {{sla_horas}} horas.\n\nGracias por su paciencia.\n\nAtentamente,\nEquipo La Playita',1,'2025-12-04 16:28:03',NULL,NULL),
(2,'Recepción de Queja','queja','general','Estimado/a {{cliente_nombre}},\n\nLamentamos los inconvenientes que ha experimentado. Hemos registrado su queja con el número {{numero_caso}} y estamos investigando el asunto con prioridad.\n\nNos pondremos en contacto con usted a la brevedad.\n\nDisculpe las molestias.\n\nAtentamente,\nEquipo La Playita',1,'2025-12-04 16:28:03',NULL,NULL),
(3,'Recepción de Reclamo - Producto','reclamo','producto','Estimado/a {{cliente_nombre}},\n\nHemos recibido su reclamo sobre el producto. Caso número: {{numero_caso}}.\n\nEstamos revisando su situación con prioridad y le daremos una solución en las próximas {{sla_horas}} horas.\n\nPor favor, conserve el producto y la factura para el proceso de cambio o devolución.\n\nGracias por su comprensión.\n\nAtentamente,\nEquipo La Playita',1,'2025-12-04 16:28:03',NULL,NULL),
(4,'Agradecimiento por Sugerencia','sugerencia','general','Estimado/a {{cliente_nombre}},\n\n¡Gracias por su sugerencia! Hemos registrado su idea con el número {{numero_caso}}.\n\nValoramos mucho su aporte y lo tendremos en cuenta para mejorar nuestros servicios.\n\nAtentamente,\nEquipo La Playita',1,'2025-12-04 16:28:03',NULL,NULL),
(5,'Caso Resuelto',NULL,NULL,'Estimado/a {{cliente_nombre}},\n\nNos complace informarle que su caso {{numero_caso}} ha sido resuelto.\n\nSolución aplicada: {{solucion}}\n\nSi tiene alguna duda adicional, no dude en contactarnos.\n\nAtentamente,\nEquipo La Playita',1,'2025-12-04 16:28:03',NULL,NULL);
/*!40000 ALTER TABLE `pqrs_plantilla_respuesta` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_sla`
--

DROP TABLE IF EXISTS `pqrs_sla`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_sla` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo` varchar(20) NOT NULL,
  `prioridad` varchar(20) NOT NULL,
  `horas_limite` int(11) NOT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tipo_prioridad` (`tipo`,`prioridad`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_sla`
--

LOCK TABLES `pqrs_sla` WRITE;
/*!40000 ALTER TABLE `pqrs_sla` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `pqrs_sla` VALUES
(1,'peticion','baja',72,1,'2025-12-04 16:27:13',NULL),
(2,'peticion','media',48,1,'2025-12-04 16:27:13',NULL),
(3,'peticion','alta',24,1,'2025-12-04 16:27:13',NULL),
(4,'peticion','urgente',4,1,'2025-12-04 16:27:13',NULL),
(5,'queja','baja',48,1,'2025-12-04 16:27:13',NULL),
(6,'queja','media',24,1,'2025-12-04 16:27:13',NULL),
(7,'queja','alta',12,1,'2025-12-04 16:27:13',NULL),
(8,'queja','urgente',2,1,'2025-12-04 16:27:13',NULL),
(9,'reclamo','baja',24,1,'2025-12-04 16:27:13',NULL),
(10,'reclamo','media',12,1,'2025-12-04 16:27:13',NULL),
(11,'reclamo','alta',6,1,'2025-12-04 16:27:13',NULL),
(12,'reclamo','urgente',1,1,'2025-12-04 16:27:13',NULL),
(13,'sugerencia','baja',168,1,'2025-12-04 16:27:13',NULL),
(14,'sugerencia','media',120,1,'2025-12-04 16:27:13',NULL),
(15,'sugerencia','alta',72,1,'2025-12-04 16:27:13',NULL),
(16,'sugerencia','urgente',24,1,'2025-12-04 16:27:13',NULL);
/*!40000 ALTER TABLE `pqrs_sla` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `pqrs_vista_guardada`
--

DROP TABLE IF EXISTS `pqrs_vista_guardada`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `pqrs_vista_guardada` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint(20) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `filtros` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`filtros`)),
  `es_publica` tinyint(1) DEFAULT 0,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_vista_usuario` (`usuario_id`),
  KEY `idx_vista_publica` (`es_publica`),
  CONSTRAINT `fk_vista_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pqrs_vista_guardada`
--

LOCK TABLES `pqrs_vista_guardada` WRITE;
/*!40000 ALTER TABLE `pqrs_vista_guardada` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `pqrs_vista_guardada` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `producto`
--

DROP TABLE IF EXISTS `producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `producto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `codigo_barras` varchar(50) DEFAULT NULL,
  `sku_alternativo` varchar(50) DEFAULT NULL,
  `unidad_medida` enum('unidad','caja','paquete','kg','litro','metro','otro') DEFAULT 'unidad',
  `peso` decimal(10,3) DEFAULT NULL,
  `volumen` decimal(10,3) DEFAULT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `imagen_url` varchar(255) DEFAULT NULL,
  `ubicacion` varchar(50) DEFAULT NULL COMMENT 'Ej: Pasillo A, Estante 3, Nivel 2',
  `ubicacion_fisica_id` int(11) DEFAULT NULL,
  `stock_minimo` int(11) NOT NULL DEFAULT 10,
  `stock_maximo` int(11) DEFAULT NULL,
  `categoria_id` int(11) NOT NULL,
  `stock_actual` int(10) unsigned NOT NULL,
  `dias_sin_movimiento` int(11) DEFAULT 0,
  `ultima_venta` datetime DEFAULT NULL,
  `estado` enum('activo','inactivo','descontinuado') NOT NULL DEFAULT 'activo',
  `costo_promedio` decimal(12,2) NOT NULL,
  `margen_objetivo` decimal(5,2) DEFAULT NULL,
  `tasa_iva_id` int(11) NOT NULL DEFAULT 1,
  `creado_por_id` bigint(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `modificado_por_id` bigint(20) DEFAULT NULL,
  `fecha_modificacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_producto_nombre` (`nombre`),
  UNIQUE KEY `uq_producto_codigo_barras` (`codigo_barras`),
  KEY `categoria_id` (`categoria_id`),
  KEY `fk_producto_tasa_iva` (`tasa_iva_id`),
  KEY `idx_producto_estado` (`estado`),
  KEY `fk_producto_creado_por` (`creado_por_id`),
  KEY `fk_producto_modificado_por` (`modificado_por_id`),
  KEY `idx_producto_stock_estado` (`stock_actual`,`estado`),
  KEY `fk_producto_ubicacion_fisica` (`ubicacion_fisica_id`),
  KEY `idx_producto_sku_alternativo` (`sku_alternativo`),
  KEY `idx_producto_dias_sin_movimiento` (`dias_sin_movimiento`),
  CONSTRAINT `fk_producto_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_producto_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_producto_modificado_por` FOREIGN KEY (`modificado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_producto_tasa_iva` FOREIGN KEY (`tasa_iva_id`) REFERENCES `tasa_iva` (`id`),
  CONSTRAINT `fk_producto_ubicacion_fisica` FOREIGN KEY (`ubicacion_fisica_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_stock_maximo` CHECK (`stock_maximo` is null or `stock_maximo` >= `stock_minimo`),
  CONSTRAINT `chk_producto_stock_positivo` CHECK (`stock_actual` >= 0),
  CONSTRAINT `chk_producto_stock_max_min` CHECK (`stock_maximo` is null or `stock_maximo` >= `stock_minimo`),
  CONSTRAINT `chk_producto_precio_positivo` CHECK (`precio_unitario` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `producto`
--

LOCK TABLES `producto` WRITE;
/*!40000 ALTER TABLE `producto` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `producto` VALUES
(1,'Leche Entera 1L',NULL,NULL,'unidad',NULL,NULL,3800.00,'Leche pasteurizada',NULL,NULL,7,10,NULL,1,26,0,NULL,'activo',3800.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(2,'Queso Campesino 500g',NULL,NULL,'unidad',NULL,NULL,9500.00,'Queso fresco de vaca',NULL,NULL,7,5,NULL,2,0,0,NULL,'activo',0.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(3,'Yogurt',NULL,NULL,'unidad',NULL,NULL,3000.00,NULL,NULL,NULL,7,10,NULL,1,187,0,NULL,'activo',3000.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(4,'Manzana Postobon 1L',NULL,NULL,'unidad',NULL,NULL,4500.00,'Sabor a manzana, 1L',NULL,NULL,5,3,NULL,4,0,0,NULL,'activo',0.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(7,'Cerveza Aguila',NULL,NULL,'unidad',NULL,NULL,4500.00,'Tipo lager',NULL,NULL,4,1,NULL,3,289,0,NULL,'activo',4500.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(8,'Papas Fritas',NULL,NULL,'unidad',NULL,NULL,2500.00,'Paquete de papas',NULL,NULL,3,5,NULL,5,0,0,NULL,'activo',0.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(9,'Poker',NULL,NULL,'unidad',NULL,NULL,3000.00,NULL,NULL,NULL,4,10,NULL,3,171,0,NULL,'activo',3000.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(10,'Coronita',NULL,NULL,'unidad',NULL,NULL,5000.00,NULL,NULL,NULL,3,5,NULL,3,177,0,NULL,'activo',5000.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(11,'Aguila 330 ml',NULL,NULL,'unidad',NULL,NULL,3000.00,'Cerveza Lager',NULL,NULL,3,2,NULL,3,0,0,NULL,'activo',0.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(12,'todo rico natural',NULL,NULL,'unidad',NULL,NULL,3500.00,'paquete de papas surtido',NULL,NULL,3,2,NULL,6,0,0,NULL,'activo',0.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(13,'Yogurt alpina',NULL,NULL,'unidad',NULL,NULL,2500.00,NULL,NULL,NULL,7,12,NULL,1,0,0,NULL,'activo',0.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32'),
(14,'Cigarrillos MARLBORO Rojo cajetilla (20 und)',NULL,NULL,'unidad',NULL,NULL,12000.00,NULL,NULL,NULL,5,5,NULL,9,0,0,NULL,'activo',0.00,NULL,1,NULL,'2025-12-08 18:23:34',NULL,'2025-12-09 22:42:32');
/*!40000 ALTER TABLE `producto` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `producto_canjeble`
--

DROP TABLE IF EXISTS `producto_canjeble`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `producto_canjeble` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `descripcion` longtext DEFAULT NULL,
  `puntos_requeridos` decimal(10,2) NOT NULL,
  `stock_disponible` int(10) unsigned NOT NULL CHECK (`stock_disponible` >= 0),
  `activo` tinyint(1) NOT NULL,
  `fecha_creacion` datetime(6) NOT NULL,
  `producto_inventario_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `producto_canjeble`
--

LOCK TABLES `producto_canjeble` WRITE;
/*!40000 ALTER TABLE `producto_canjeble` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `producto_canjeble` VALUES
(1,'taza la playita ','',3.69,4,1,'2025-11-22 06:14:44.582337',NULL),
(2,'desodorante ','',10.00,2,1,'2025-11-23 06:04:58.215270',NULL),
(3,'Cerveza Aguila','Tipo lager',3.00,5,1,'2025-11-24 15:15:44.228844',7);
/*!40000 ALTER TABLE `producto_canjeble` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `proveedor`
--

DROP TABLE IF EXISTS `proveedor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `documento_identificacion` varchar(20) DEFAULT NULL,
  `nombre_empresa` varchar(100) NOT NULL,
  `telefono` varchar(50) NOT NULL,
  `correo` varchar(50) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `tipo_documento` varchar(3) NOT NULL DEFAULT 'NIT',
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `creado_por_id` bigint(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `nit` (`documento_identificacion`),
  KEY `idx_proveedor_activo` (`activo`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedor`
--

LOCK TABLES `proveedor` WRITE;
/*!40000 ALTER TABLE `proveedor` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `proveedor` VALUES
(1,'800.123.456-7','Proveedor de Lacteos S.A.','123456789','contacto@lacteos.com','Calle Falsa 123','NIT',1,NULL,'2025-12-08 18:23:34'),
(2,'890.903.635-1','Postobon S.A.','3573612371','postobon@gmail.com','kra93 #32-13','NIT',1,NULL,'2025-12-08 18:23:34'),
(3,'860.005.224-6','Bavaria S.A.','2131456','lizarazojuanandres@gmail.com','cra105 #21-65','NIT',1,NULL,'2025-12-08 18:23:34'),
(4,'800.22 margarita-9','Papas Margarita','235156023','margaritas@gmail.com','cra100 #95-54','NIT',1,NULL,'2025-12-08 18:23:34'),
(5,'2032032','Fritolay','2342343243','fritolay@gmail.com','carrera 14 #12-32','NIT',1,NULL,'2025-12-08 18:23:34'),
(6,'800.236.541-9','Alimentos Rivera LTDA','315 902 1144','mrivera@alimentosrivera.com','Cl 23 # 18-44','NIT',1,NULL,'2025-12-08 18:23:34');
/*!40000 ALTER TABLE `proveedor` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `puntos_fidelizacion`
--

DROP TABLE IF EXISTS `puntos_fidelizacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `puntos_fidelizacion` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `tipo` varchar(20) NOT NULL,
  `puntos` decimal(10,2) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `fecha_transaccion` datetime(6) NOT NULL,
  `venta_id` int(11) DEFAULT NULL,
  `canje_id` bigint(20) DEFAULT NULL,
  `cliente_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `puntos_fidelizacion`
--

LOCK TABLES `puntos_fidelizacion` WRITE;
/*!40000 ALTER TABLE `puntos_fidelizacion` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `puntos_fidelizacion` VALUES
(1,'ganancia',0.79,'Compra de $9500 - Venta #27','2025-11-23 06:02:59.807102',27,NULL,3),
(2,'ganancia',7.92,'Compra de $95000 - Venta #28','2025-11-23 06:05:55.951945',28,NULL,3),
(3,'canje',-3.69,'Canje de taza la playita  (Web)','2025-11-23 06:38:15.186936',NULL,1,6),
(4,'canje',-3.69,'Canje de taza la playita  (Web)','2025-11-23 06:39:42.103931',NULL,2,6),
(5,'canje',-3.69,'Canje de taza la playita  (Web)','2025-11-24 15:15:13.806149',NULL,3,3),
(6,'ganancia',1.21,'Compra de $14500 - Venta #29','2025-12-01 01:44:30.715049',29,NULL,3),
(7,'ganancia',0.42,'Compra de $5000 - Venta #31','2025-12-01 02:24:38.294916',31,NULL,9),
(8,'ganancia',3.75,'Compra de $45000 - Venta #35','2025-12-01 03:01:04.057187',35,NULL,7),
(9,'ganancia',0.29,'Compra de $3500 - Venta #47','2025-12-01 04:59:48.042166',47,NULL,8),
(10,'ganancia',16.12,'Compra de $193500 - Venta #53','2025-12-02 04:22:03.159259',53,NULL,5);
/*!40000 ALTER TABLE `puntos_fidelizacion` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `reabastecimiento`
--

DROP TABLE IF EXISTS `reabastecimiento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `reabastecimiento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fecha` datetime NOT NULL,
  `fecha_estimada_entrega` date DEFAULT NULL,
  `orden_compra` varchar(100) DEFAULT NULL,
  `factura_proveedor` varchar(100) DEFAULT NULL,
  `tiempo_entrega_dias` int(11) DEFAULT NULL,
  `costo_total` decimal(12,2) NOT NULL,
  `estado` enum('borrador','solicitado','recibido','cancelado') DEFAULT 'solicitado',
  `forma_pago` varchar(25) DEFAULT 'Efectivo',
  `observaciones` text DEFAULT NULL,
  `proveedor_id` int(11) NOT NULL,
  `iva` decimal(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `proveedor_id` (`proveedor_id`),
  KEY `idx_reabastecimiento_orden_compra` (`orden_compra`),
  KEY `idx_reabastecimiento_factura` (`factura_proveedor`),
  CONSTRAINT `fk_reabastecimiento_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedor` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=133 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reabastecimiento`
--

LOCK TABLES `reabastecimiento` WRITE;
/*!40000 ALTER TABLE `reabastecimiento` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `reabastecimiento` VALUES
(1,'2025-09-01 09:00:00',NULL,NULL,NULL,NULL,670000.00,'recibido','Efectivo','Reabastecimiento inicial',1,0.00),
(36,'2025-11-05 11:38:27',NULL,NULL,NULL,NULL,270000.00,'recibido','pse','',3,0.00),
(37,'2025-11-05 13:45:25',NULL,NULL,NULL,NULL,25000.00,'recibido','pse','',4,0.00),
(38,'2025-11-06 22:53:32',NULL,NULL,NULL,NULL,450000.00,'recibido','pse','',3,0.00),
(40,'2025-11-06 22:54:41',NULL,NULL,NULL,NULL,900000.00,'recibido','pse','',3,0.00),
(45,'2025-11-11 20:03:03',NULL,NULL,NULL,NULL,19000.00,'recibido','efectivo','',3,0.00),
(46,'2025-11-13 23:34:09',NULL,NULL,NULL,NULL,297000.00,'recibido','consignacion','',3,0.00),
(55,'2025-11-19 13:20:16',NULL,NULL,NULL,NULL,600000.00,'recibido','pse','',3,0.00),
(58,'2025-11-21 11:50:36',NULL,NULL,NULL,NULL,165000.00,'recibido','efectivo','',3,0.00),
(59,'2025-11-21 12:09:50',NULL,NULL,NULL,NULL,150500.00,'recibido','efectivo','',5,0.00),
(60,'2025-11-24 15:05:34',NULL,NULL,NULL,NULL,69000.00,'recibido','pse','',3,0.00),
(61,'2025-11-24 15:16:31',NULL,NULL,NULL,NULL,87400.00,'recibido','tarjeta_credito','',4,0.00),
(62,'2025-11-29 23:36:59',NULL,NULL,NULL,NULL,300000.00,'solicitado','efectivo','',3,57000.00),
(63,'2025-11-29 23:59:37',NULL,NULL,NULL,NULL,150000.00,'solicitado','efectivo','',3,28500.00),
(64,'2025-11-30 01:30:34',NULL,NULL,NULL,NULL,243000.00,'solicitado','efectivo','',3,46170.00),
(75,'2025-11-30 02:11:21',NULL,NULL,NULL,NULL,192000.00,'solicitado','efectivo','',3,36480.00),
(78,'2025-11-30 02:21:40',NULL,NULL,NULL,NULL,450000.00,'solicitado','efectivo','',3,85500.00),
(80,'2025-11-30 02:36:17',NULL,NULL,NULL,NULL,450000.00,'recibido','efectivo','',3,85500.00),
(101,'2025-12-01 20:06:49',NULL,NULL,NULL,NULL,7500000.00,'solicitado','efectivo','',1,0.00),
(102,'2025-12-01 20:07:20',NULL,NULL,NULL,NULL,32500.00,'solicitado','efectivo','',1,0.00),
(103,'2025-12-01 20:46:12',NULL,NULL,NULL,NULL,105000.00,'solicitado','efectivo','',5,0.00),
(104,'2025-12-01 20:47:03',NULL,NULL,NULL,NULL,62500.00,'solicitado','efectivo','',5,0.00),
(105,'2025-12-01 21:09:53',NULL,NULL,NULL,NULL,350000.00,'solicitado','efectivo','',3,66500.00),
(113,'2025-12-02 02:50:33',NULL,NULL,NULL,NULL,650000.00,'solicitado','efectivo','',3,123500.00),
(114,'2025-12-02 04:14:13',NULL,NULL,NULL,NULL,96000.00,'solicitado','efectivo','',1,0.00),
(115,'2025-12-02 04:14:54',NULL,NULL,NULL,NULL,450000.00,'solicitado','efectivo','',3,0.00),
(121,'2025-12-02 04:29:54',NULL,NULL,NULL,NULL,5150000.00,'solicitado','efectivo','',3,0.00),
(122,'2025-12-02 04:40:59',NULL,NULL,NULL,NULL,650000.00,'solicitado','efectivo','',3,0.00),
(123,'2025-12-02 04:45:49',NULL,NULL,NULL,NULL,650000.00,'solicitado','efectivo','',3,0.00),
(124,'2025-12-02 04:47:04',NULL,NULL,NULL,NULL,217000.00,'solicitado','efectivo','',3,0.00),
(127,'2025-12-02 05:01:13',NULL,NULL,NULL,NULL,36000.00,'solicitado','efectivo','',3,1800.00),
(128,'2025-12-02 05:15:56',NULL,NULL,NULL,NULL,160000.00,'solicitado','efectivo','',3,30400.00),
(129,'2025-12-02 05:18:34',NULL,NULL,NULL,NULL,100000.00,'solicitado','efectivo','',1,19000.00),
(130,'2025-12-02 05:21:51',NULL,NULL,NULL,NULL,160000.00,'solicitado','efectivo','',3,30400.00),
(131,'2025-12-02 05:36:34',NULL,NULL,NULL,NULL,650000.00,'recibido','efectivo','',3,32500.00),
(132,'2025-12-09 02:34:58',NULL,NULL,NULL,NULL,360000.00,'solicitado','efectivo','',3,68400.00);
/*!40000 ALTER TABLE `reabastecimiento` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `reabastecimiento_detalle`
--

DROP TABLE IF EXISTS `reabastecimiento_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `reabastecimiento_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reabastecimiento_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  `fecha_caducidad` date DEFAULT NULL,
  `cantidad_recibida` int(11) NOT NULL,
  `iva` decimal(12,2) NOT NULL DEFAULT 0.00,
  `recibido_por_id` bigint(20) DEFAULT NULL,
  `fecha_recepcion` datetime DEFAULT NULL,
  `cantidad_anterior` int(11) DEFAULT 0,
  `numero_lote` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reabastecimiento_id` (`reabastecimiento_id`),
  KEY `producto_id` (`producto_id`),
  KEY `fk_recibido_por` (`recibido_por_id`),
  CONSTRAINT `fk_reabastecimiento_detalle_reabastecimiento` FOREIGN KEY (`reabastecimiento_id`) REFERENCES `reabastecimiento` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_recibido_por` FOREIGN KEY (`recibido_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `reabastecimiento_detalle_producto_id_63c5cefe_fk_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=123 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reabastecimiento_detalle`
--

LOCK TABLES `reabastecimiento_detalle` WRITE;
/*!40000 ALTER TABLE `reabastecimiento_detalle` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `reabastecimiento_detalle` VALUES
(1,1,1,100,2500.00,NULL,100,0.00,NULL,NULL,0,NULL),
(2,1,2,60,7000.00,NULL,60,0.00,NULL,NULL,0,NULL),
(38,36,7,60,4500.00,'2025-12-31',60,0.00,NULL,NULL,0,NULL),
(39,37,8,10,2500.00,'2025-12-06',10,0.00,NULL,NULL,0,NULL),
(40,38,7,100,4500.00,'2026-01-17',100,0.00,NULL,NULL,0,NULL),
(42,40,7,200,4500.00,'2026-01-15',199,0.00,NULL,NULL,0,NULL),
(45,45,1,5,3800.00,'2026-01-10',5,0.00,NULL,NULL,0,NULL),
(46,46,9,99,3000.00,'2026-02-12',99,0.00,NULL,NULL,0,NULL),
(55,55,3,200,3000.00,'2026-01-03',199,0.00,NULL,NULL,0,NULL),
(58,58,11,55,3000.00,'2025-11-29',55,0.00,NULL,NULL,0,NULL),
(59,59,12,43,3500.00,'2025-11-29',43,0.00,NULL,NULL,0,NULL),
(60,60,9,23,3000.00,'2026-01-01',22,0.00,NULL,NULL,0,NULL),
(61,61,1,23,3800.00,'2025-12-31',23,0.00,NULL,'2025-11-29 23:50:01',0,'R61-P1-61'),
(62,62,10,60,5000.00,'2026-01-24',0,0.00,NULL,NULL,0,NULL),
(63,63,10,30,5000.00,'2025-12-31',0,0.00,NULL,NULL,0,NULL),
(64,64,10,54,4500.00,'2026-01-06',0,0.00,NULL,NULL,0,NULL),
(75,75,9,64,3000.00,'2025-12-31',0,0.00,NULL,NULL,0,NULL),
(78,78,10,90,5000.00,'2026-01-08',0,0.00,NULL,NULL,0,NULL),
(80,80,10,90,5000.00,'2026-01-01',89,0.00,4,'2025-11-30 02:52:22',0,NULL),
(81,101,13,3000,2500.00,'2025-12-24',0,0.00,NULL,NULL,0,NULL),
(82,102,13,13,2500.00,'2025-12-31',0,0.00,NULL,NULL,0,NULL),
(83,103,12,30,3500.00,'2025-12-01',0,0.00,NULL,NULL,0,NULL),
(84,104,8,25,2500.00,'2025-12-01',0,0.00,NULL,NULL,0,NULL),
(85,105,10,70,5000.00,'2026-03-07',0,66500.00,NULL,NULL,0,NULL),
(95,113,10,100,5000.00,'2025-12-31',0,95000.00,NULL,NULL,0,NULL),
(96,113,9,50,3000.00,'2026-01-01',0,28500.00,NULL,NULL,0,NULL),
(97,114,11,32,3000.00,'2026-01-30',0,0.00,NULL,NULL,0,NULL),
(98,115,10,90,5000.00,'2026-01-01',0,0.00,NULL,NULL,0,NULL),
(106,121,10,1000,5000.00,'2025-12-31',0,0.00,NULL,NULL,0,NULL),
(107,121,9,50,3000.00,'2026-01-15',0,0.00,NULL,NULL,0,NULL),
(108,122,10,100,5000.00,'2025-12-31',0,0.00,NULL,NULL,0,NULL),
(109,122,9,50,3000.00,'2026-01-09',0,0.00,NULL,NULL,0,NULL),
(110,123,10,100,5000.00,'2025-12-31',0,0.00,NULL,NULL,0,NULL),
(111,123,9,50,3000.00,'2026-01-01',0,0.00,NULL,NULL,0,NULL),
(112,124,10,23,5000.00,'2026-02-06',0,0.00,NULL,NULL,0,NULL),
(113,124,9,34,3000.00,'2026-01-24',0,0.00,NULL,NULL,0,NULL),
(116,127,11,12,3000.00,'2026-02-02',0,1800.00,NULL,NULL,0,NULL),
(117,128,10,32,5000.00,'2026-01-08',0,0.00,NULL,NULL,0,NULL),
(118,129,10,20,5000.00,'2026-01-01',0,0.00,NULL,NULL,0,NULL),
(119,130,10,32,5000.00,'2026-01-30',0,0.00,NULL,NULL,0,NULL),
(120,131,10,100,5000.00,'2025-12-31',99,25000.00,4,'2025-12-02 05:49:59',0,NULL),
(121,131,9,50,3000.00,'2026-01-01',50,7500.00,4,'2025-12-02 05:49:59',0,NULL),
(122,132,14,30,12000.00,'2026-01-01',0,0.00,NULL,NULL,0,NULL);
/*!40000 ALTER TABLE `reabastecimiento_detalle` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `reserva_inventario`
--

DROP TABLE IF EXISTS `reserva_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `reserva_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `tipo_reserva` enum('venta','pedido','transferencia','otro') NOT NULL DEFAULT 'venta',
  `referencia_id` int(11) DEFAULT NULL COMMENT 'ID de venta, pedido, etc.',
  `referencia_tipo` varchar(50) DEFAULT NULL COMMENT 'Tipo de referencia',
  `fecha_reserva` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_expiracion` datetime DEFAULT NULL COMMENT 'Cuándo expira la reserva',
  `estado` enum('activa','liberada','consumida','expirada') NOT NULL DEFAULT 'activa',
  `usuario_reserva_id` bigint(20) NOT NULL,
  `fecha_liberacion` datetime DEFAULT NULL,
  `motivo_liberacion` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_reserva_producto` (`producto_id`),
  KEY `fk_reserva_lote` (`lote_id`),
  KEY `fk_reserva_usuario` (`usuario_reserva_id`),
  KEY `idx_reserva_estado` (`estado`),
  KEY `idx_reserva_fecha_expiracion` (`fecha_expiracion`),
  KEY `idx_reserva_referencia` (`referencia_tipo`,`referencia_id`),
  CONSTRAINT `fk_reserva_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_reserva_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reserva_usuario` FOREIGN KEY (`usuario_reserva_id`) REFERENCES `usuario` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Reservas de inventario (stock comprometido)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reserva_inventario`
--

LOCK TABLES `reserva_inventario` WRITE;
/*!40000 ALTER TABLE `reserva_inventario` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `reserva_inventario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `rol`
--

DROP TABLE IF EXISTS `rol`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rol` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(35) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rol`
--

LOCK TABLES `rol` WRITE;
/*!40000 ALTER TABLE `rol` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `rol` VALUES
(1,'Administrador'),
(2,'Vendedor');
/*!40000 ALTER TABLE `rol` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `rotacion_inventario`
--

DROP TABLE IF EXISTS `rotacion_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `rotacion_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `periodo` varchar(7) NOT NULL COMMENT 'Formato: YYYY-MM',
  `stock_inicial` int(11) NOT NULL,
  `stock_final` int(11) NOT NULL,
  `stock_promedio` decimal(12,2) NOT NULL,
  `cantidad_vendida` int(11) NOT NULL,
  `costo_mercancia_vendida` decimal(12,2) NOT NULL,
  `rotacion` decimal(10,2) NOT NULL COMMENT 'Veces que rota el inventario',
  `dias_inventario` decimal(10,2) NOT NULL COMMENT 'Días promedio en inventario',
  `clasificacion_abc` enum('A','B','C') DEFAULT NULL COMMENT 'Clasificación Pareto',
  `fecha_calculo` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rotacion_producto_periodo` (`producto_id`,`periodo`),
  KEY `fk_rotacion_producto` (`producto_id`),
  KEY `idx_rotacion_periodo` (`periodo`),
  KEY `idx_rotacion_clasificacion` (`clasificacion_abc`),
  CONSTRAINT `fk_rotacion_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Análisis de rotación de inventario';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rotacion_inventario`
--

LOCK TABLES `rotacion_inventario` WRITE;
/*!40000 ALTER TABLE `rotacion_inventario` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `rotacion_inventario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `tasa_iva`
--

DROP TABLE IF EXISTS `tasa_iva`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tasa_iva` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `porcentaje` decimal(5,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasa_iva`
--

LOCK TABLES `tasa_iva` WRITE;
/*!40000 ALTER TABLE `tasa_iva` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `tasa_iva` VALUES
(1,'IVA General 19%',19.00),
(2,'IVA Reducido 5%',5.00),
(3,'Exento 0%',0.00);
/*!40000 ALTER TABLE `tasa_iva` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `transferencia_inventario`
--

DROP TABLE IF EXISTS `transferencia_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `transferencia_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `numero_transferencia` varchar(50) NOT NULL COMMENT 'Ej: TRF-2025-001',
  `ubicacion_origen_id` int(11) NOT NULL,
  `ubicacion_destino_id` int(11) NOT NULL,
  `fecha_solicitud` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_envio` datetime DEFAULT NULL,
  `fecha_recepcion` datetime DEFAULT NULL,
  `estado` enum('solicitada','aprobada','en_transito','recibida','cancelada') NOT NULL DEFAULT 'solicitada',
  `motivo` enum('reubicacion','reabastecimiento_interno','optimizacion','otro') NOT NULL,
  `descripcion` text DEFAULT NULL,
  `usuario_solicita_id` bigint(20) NOT NULL,
  `usuario_aprueba_id` bigint(20) DEFAULT NULL,
  `usuario_envia_id` bigint(20) DEFAULT NULL,
  `usuario_recibe_id` bigint(20) DEFAULT NULL,
  `observaciones` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `numero_transferencia` (`numero_transferencia`),
  UNIQUE KEY `uq_numero_transferencia` (`numero_transferencia`),
  KEY `fk_transferencia_origen` (`ubicacion_origen_id`),
  KEY `fk_transferencia_destino` (`ubicacion_destino_id`),
  KEY `fk_transferencia_solicita` (`usuario_solicita_id`),
  KEY `fk_transferencia_aprueba` (`usuario_aprueba_id`),
  KEY `fk_transferencia_envia` (`usuario_envia_id`),
  KEY `fk_transferencia_recibe` (`usuario_recibe_id`),
  KEY `idx_transferencia_estado` (`estado`),
  KEY `idx_transferencia_fecha` (`fecha_solicitud`),
  CONSTRAINT `fk_transferencia_aprueba` FOREIGN KEY (`usuario_aprueba_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transferencia_destino` FOREIGN KEY (`ubicacion_destino_id`) REFERENCES `ubicacion_fisica` (`id`),
  CONSTRAINT `fk_transferencia_envia` FOREIGN KEY (`usuario_envia_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transferencia_origen` FOREIGN KEY (`ubicacion_origen_id`) REFERENCES `ubicacion_fisica` (`id`),
  CONSTRAINT `fk_transferencia_recibe` FOREIGN KEY (`usuario_recibe_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transferencia_solicita` FOREIGN KEY (`usuario_solicita_id`) REFERENCES `usuario` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Transferencias entre ubicaciones';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transferencia_inventario`
--

LOCK TABLES `transferencia_inventario` WRITE;
/*!40000 ALTER TABLE `transferencia_inventario` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `transferencia_inventario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `transferencia_inventario_detalle`
--

DROP TABLE IF EXISTS `transferencia_inventario_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `transferencia_inventario_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `transferencia_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad_solicitada` int(11) NOT NULL,
  `cantidad_enviada` int(11) DEFAULT NULL,
  `cantidad_recibida` int(11) DEFAULT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  `observaciones` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_transferencia_detalle_transferencia` (`transferencia_id`),
  KEY `fk_transferencia_detalle_producto` (`producto_id`),
  KEY `fk_transferencia_detalle_lote` (`lote_id`),
  CONSTRAINT `fk_transferencia_detalle_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transferencia_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_transferencia_detalle_transferencia` FOREIGN KEY (`transferencia_id`) REFERENCES `transferencia_inventario` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Detalle de transferencias';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transferencia_inventario_detalle`
--

LOCK TABLES `transferencia_inventario_detalle` WRITE;
/*!40000 ALTER TABLE `transferencia_inventario_detalle` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `transferencia_inventario_detalle` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `ubicacion_fisica`
--

DROP TABLE IF EXISTS `ubicacion_fisica`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ubicacion_fisica` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) NOT NULL COMMENT 'Ej: BOD-A-EST-3-NIV-2',
  `nombre` varchar(100) NOT NULL,
  `tipo` enum('bodega','pasillo','estante','nivel','zona') NOT NULL DEFAULT 'estante',
  `parent_id` int(11) DEFAULT NULL COMMENT 'Ubicación padre (jerárquico)',
  `capacidad_maxima` int(11) DEFAULT NULL COMMENT 'Capacidad en unidades',
  `capacidad_actual` int(11) DEFAULT 0 COMMENT 'Ocupación actual',
  `temperatura_min` decimal(5,2) DEFAULT NULL COMMENT 'Temperatura mínima (°C)',
  `temperatura_max` decimal(5,2) DEFAULT NULL COMMENT 'Temperatura máxima (°C)',
  `requiere_refrigeracion` tinyint(1) DEFAULT 0,
  `activo` tinyint(1) DEFAULT 1,
  `observaciones` text DEFAULT NULL,
  `creado_por_id` bigint(20) DEFAULT NULL,
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `codigo` (`codigo`),
  KEY `idx_ubicacion_codigo` (`codigo`),
  KEY `idx_ubicacion_tipo` (`tipo`),
  KEY `idx_ubicacion_parent` (`parent_id`),
  KEY `fk_ubicacion_creado_por` (`creado_por_id`),
  CONSTRAINT `fk_ubicacion_creado_por` FOREIGN KEY (`creado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ubicacion_parent` FOREIGN KEY (`parent_id`) REFERENCES `ubicacion_fisica` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Ubicaciones físicas en bodega/almacén';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ubicacion_fisica`
--

LOCK TABLES `ubicacion_fisica` WRITE;
/*!40000 ALTER TABLE `ubicacion_fisica` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `ubicacion_fisica` VALUES
(1,'BOD-A','Bodega Principal A','bodega',NULL,10000,0,NULL,NULL,0,1,NULL,NULL,'2025-12-09 22:38:42'),
(2,'BOD-A-PAS-1','Pasillo 1','pasillo',1,2000,0,NULL,NULL,0,1,NULL,NULL,'2025-12-09 22:38:42'),
(3,'BOD-A-PAS-1-EST-1','Estante 1','estante',2,500,0,NULL,NULL,0,1,NULL,NULL,'2025-12-09 22:38:42'),
(4,'BOD-A-PAS-1-EST-2','Estante 2','estante',2,500,0,NULL,NULL,0,1,NULL,NULL,'2025-12-09 22:38:42'),
(5,'BOD-A-PAS-1-EST-3','Estante 3','estante',2,500,0,NULL,NULL,0,1,NULL,NULL,'2025-12-09 22:38:42'),
(6,'BOD-B','Bodega Refrigerada B','bodega',NULL,5000,0,2.00,8.00,1,1,NULL,NULL,'2025-12-09 22:38:42'),
(7,'BOD-B-ZONA-1','Zona Refrigerada 1','zona',6,2000,0,2.00,8.00,1,1,NULL,NULL,'2025-12-09 22:38:42');
/*!40000 ALTER TABLE `ubicacion_fisica` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `usuario`
--

DROP TABLE IF EXISTS `usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuario` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `documento` varchar(20) NOT NULL,
  `nombres` varchar(50) NOT NULL,
  `apellidos` varchar(50) NOT NULL,
  `correo` varchar(60) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `contrasena` varchar(255) NOT NULL,
  `estado` varchar(20) NOT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp(),
  `ultimo_login` timestamp NULL DEFAULT NULL,
  `rol_id` int(11) NOT NULL,
  `is_staff` tinyint(1) NOT NULL,
  `is_superuser` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `documento` (`documento`),
  UNIQUE KEY `correo` (`correo`),
  KEY `rol_id` (`rol_id`),
  CONSTRAINT `fk_usuario_rol` FOREIGN KEY (`rol_id`) REFERENCES `rol` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario`
--

LOCK TABLES `usuario` WRITE;
/*!40000 ALTER TABLE `usuario` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `usuario` VALUES
(1,'1014477103','Juan','Lizarazo','juan.vendedor@laplayita.com','3105416287','hash_contrasena_vendedor','activo','2025-10-10 22:48:22',NULL,2,0,0),
(2,'1234567','Admin','Principal','admin@laplayita.com','32124551','hash_contrasena_admin','activo','2025-10-10 22:48:22','2025-11-09 07:03:56',1,0,0),
(4,'10000000','Laura','Gomez','laura.admin@laplayita.com',NULL,'pbkdf2_sha256$1000000$5IUYpFqgilB2EvaR9GQJya$hH7HV5VkSrpqZSxNsg5r9+/o+2BQyzYwWbPiyTDV204=','activo','2025-10-13 19:08:10','2025-12-10 03:44:08',1,0,0),
(5,'1014477104','Juan Andres','Lizarazo Capera','lizarazojuanandres@gmail.com','3105416287','pbkdf2_sha256$1000000$UFwj2ILaUlQL994XzKPWC9$KMJ5lGcAoz0n/JkjQsMt3/WVQ9ZH96GT9UowK868yaU=','activo','2025-11-13 05:28:21','2025-11-13 06:23:15',2,0,0),
(6,'1000','Test','Admin','test@admin.com',NULL,'pbkdf2_sha256$1000000$wQDpWFuo6WGjhOXadQOugV$GO7IdMPoLIASNGTmuZthpsgeg0W+QFFnFPa3Hqfupjs=','activo','2025-11-22 10:36:02','2025-11-22 10:37:26',1,1,1);
/*!40000 ALTER TABLE `usuario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `usuario_groups`
--

DROP TABLE IF EXISTS `usuario_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuario_groups` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint(20) NOT NULL,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario_groups_usuario_id_group_id` (`usuario_id`,`group_id`),
  KEY `usuario_groups_usuario_id` (`usuario_id`),
  KEY `usuario_groups_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario_groups`
--

LOCK TABLES `usuario_groups` WRITE;
/*!40000 ALTER TABLE `usuario_groups` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `usuario_groups` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `usuario_user_permissions`
--

DROP TABLE IF EXISTS `usuario_user_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuario_user_permissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint(20) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `usuario_user_permissions_usuario_id_permission_id` (`usuario_id`,`permission_id`),
  KEY `usuario_user_permissions_usuario_id` (`usuario_id`),
  KEY `usuario_user_permissions_permission_id` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario_user_permissions`
--

LOCK TABLES `usuario_user_permissions` WRITE;
/*!40000 ALTER TABLE `usuario_user_permissions` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `usuario_user_permissions` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Temporary table structure for view `v_pqrs_dashboard`
--

DROP TABLE IF EXISTS `v_pqrs_dashboard`;
/*!50001 DROP VIEW IF EXISTS `v_pqrs_dashboard`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v_pqrs_dashboard` AS SELECT
 1 AS `total_casos`,
  1 AS `casos_nuevos`,
  1 AS `casos_en_proceso`,
  1 AS `casos_resueltos`,
  1 AS `casos_cerrados`,
  1 AS `casos_sla_vencido`,
  1 AS `casos_urgentes_activos`,
  1 AS `tiempo_promedio_resolucion`,
  1 AS `clientes_unicos` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_productos_obsoletos`
--

DROP TABLE IF EXISTS `v_productos_obsoletos`;
/*!50001 DROP VIEW IF EXISTS `v_productos_obsoletos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v_productos_obsoletos` AS SELECT
 1 AS `id`,
  1 AS `nombre`,
  1 AS `categoria_id`,
  1 AS `categoria_nombre`,
  1 AS `stock_actual`,
  1 AS `costo_promedio`,
  1 AS `valor_inmovilizado`,
  1 AS `dias_sin_movimiento`,
  1 AS `ultima_venta`,
  1 AS `dias_desde_ultima_venta` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_resumen_alertas`
--

DROP TABLE IF EXISTS `v_resumen_alertas`;
/*!50001 DROP VIEW IF EXISTS `v_resumen_alertas`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v_resumen_alertas` AS SELECT
 1 AS `prioridad`,
  1 AS `tipo_alerta`,
  1 AS `total`,
  1 AS `activas`,
  1 AS `resueltas`,
  1 AS `ignoradas` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `v_stock_disponible`
--

DROP TABLE IF EXISTS `v_stock_disponible`;
/*!50001 DROP VIEW IF EXISTS `v_stock_disponible`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `v_stock_disponible` AS SELECT
 1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `stock_total`,
  1 AS `stock_reservado`,
  1 AS `stock_disponible`,
  1 AS `stock_minimo`,
  1 AS `stock_maximo` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `valorizacion_inventario`
--

DROP TABLE IF EXISTS `valorizacion_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `valorizacion_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `periodo` varchar(7) NOT NULL COMMENT 'Formato: YYYY-MM',
  `fecha_corte` date NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  `costo_promedio` decimal(12,2) NOT NULL,
  `valor_total` decimal(12,2) NOT NULL,
  `categoria_id` int(11) NOT NULL,
  `fecha_generacion` datetime NOT NULL DEFAULT current_timestamp(),
  `generado_por_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_valorizacion_periodo_producto` (`periodo`,`producto_id`),
  KEY `fk_valorizacion_producto` (`producto_id`),
  KEY `fk_valorizacion_categoria` (`categoria_id`),
  KEY `fk_valorizacion_generado_por` (`generado_por_id`),
  KEY `idx_valorizacion_periodo` (`periodo`),
  KEY `idx_valorizacion_fecha_corte` (`fecha_corte`),
  CONSTRAINT `fk_valorizacion_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_valorizacion_generado_por` FOREIGN KEY (`generado_por_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_valorizacion_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Valorizaci??n mensual del inventario para contabilidad';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `valorizacion_inventario`
--

LOCK TABLES `valorizacion_inventario` WRITE;
/*!40000 ALTER TABLE `valorizacion_inventario` DISABLE KEYS */;
set autocommit=0;
/*!40000 ALTER TABLE `valorizacion_inventario` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `venta`
--

DROP TABLE IF EXISTS `venta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `venta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fecha_venta` datetime NOT NULL,
  `canal_venta` varchar(20) NOT NULL DEFAULT 'Tienda',
  `cliente_id` bigint(20) NOT NULL,
  `usuario_id` bigint(20) NOT NULL,
  `pedido_id` int(11) DEFAULT NULL COMMENT 'Vincula la venta a un pedido original',
  `total_venta` decimal(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `cliente_id` (`cliente_id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `pedido_id` (`pedido_id`),
  CONSTRAINT `fk_venta_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `venta`
--

LOCK TABLES `venta` WRITE;
/*!40000 ALTER TABLE `venta` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `venta` VALUES
(1,'2025-09-02 10:00:00','Tienda',1,1,NULL,7600.00),
(2,'2025-09-03 11:30:00','Domicilio',2,1,NULL,9500.00),
(3,'2025-11-05 12:24:54','local',1,4,NULL,4500.00),
(4,'2025-11-05 12:25:24','local',1,4,NULL,54000.00),
(5,'2025-11-05 12:25:41','local',2,4,NULL,45600.00),
(6,'2025-11-05 12:40:34','local',2,4,NULL,4500.00),
(7,'2025-11-05 12:44:58','local',1,4,NULL,22800.00),
(8,'2025-11-05 13:48:30','local',2,4,NULL,25000.00),
(9,'2025-11-06 22:52:29','local',2,4,NULL,18000.00),
(17,'2025-11-22 05:34:57','mostrador',5,4,NULL,3800.00),
(18,'2025-11-22 05:40:24','mostrador',1,6,NULL,3000.00),
(19,'2025-11-22 05:40:34','mostrador',3,6,NULL,3000.00),
(20,'2025-11-22 05:40:34','mostrador',3,6,NULL,3000.00),
(21,'2025-11-22 05:40:34','mostrador',3,6,NULL,3000.00),
(22,'2025-11-22 06:15:41','mostrador',3,6,NULL,304700.00),
(23,'2025-11-22 06:26:10','mostrador',3,4,NULL,54000.00),
(24,'2025-11-22 06:27:01','mostrador',3,4,NULL,54000.00),
(25,'2025-11-22 06:28:05','mostrador',3,4,NULL,54000.00),
(26,'2025-11-22 06:32:54','mostrador',3,6,NULL,304700.00),
(27,'2025-11-23 06:02:59','mostrador',3,4,NULL,9500.00),
(28,'2025-11-23 06:05:55','mostrador',3,4,NULL,95000.00),
(29,'2025-12-01 01:44:30','telefono',3,4,NULL,14500.00),
(30,'2025-12-01 02:18:16','mostrador',1,4,NULL,19000.00),
(31,'2025-12-01 02:24:38','telefono',9,4,NULL,5000.00),
(32,'2025-12-01 02:54:10','telefono',1,4,NULL,54000.00),
(33,'2025-12-01 02:54:42','telefono',1,4,NULL,3500.00),
(34,'2025-12-01 02:59:44','mostrador',1,4,NULL,40000.00),
(35,'2025-12-01 03:01:04','telefono',7,4,NULL,45000.00),
(36,'2025-12-01 03:41:57','mostrador',1,4,NULL,3500.00),
(37,'2025-12-01 03:45:44','mostrador',1,4,NULL,29300.00),
(38,'2025-12-01 03:57:45','mostrador',1,4,NULL,3500.00),
(39,'2025-12-01 04:25:46','mostrador',1,4,NULL,14000.00),
(40,'2025-12-01 04:41:54','mostrador',1,4,NULL,8500.00),
(41,'2025-12-01 04:48:18','mostrador',1,4,NULL,3500.00),
(42,'2025-12-01 04:48:58','mostrador',1,4,NULL,3000.00),
(43,'2025-12-01 04:54:25','mostrador',1,4,NULL,10000.00),
(44,'2025-12-01 04:56:31','mostrador',1,4,NULL,3500.00),
(45,'2025-12-01 04:56:52','mostrador',1,4,NULL,3500.00),
(46,'2025-12-01 04:59:27','mostrador',1,4,NULL,3500.00),
(47,'2025-12-01 04:59:48','mostrador',8,4,NULL,3500.00),
(48,'2025-12-01 05:00:24','mostrador',1,4,NULL,15000.00),
(49,'2025-12-01 05:01:07','mostrador',1,4,NULL,3500.00),
(50,'2025-12-01 05:03:16','mostrador',8,4,NULL,3800.00),
(51,'2025-12-01 05:04:04','mostrador',3,4,NULL,5000.00),
(52,'2025-12-01 11:27:08','mostrador',3,4,NULL,49000.00),
(53,'2025-12-02 04:22:03','mostrador',5,4,NULL,193500.00),
(54,'2025-12-09 01:26:16','mostrador',1,4,NULL,31500.00);
/*!40000 ALTER TABLE `venta` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Table structure for table `venta_detalle`
--

DROP TABLE IF EXISTS `venta_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `venta_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `venta_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `venta_id` (`venta_id`),
  KEY `producto_id` (`producto_id`),
  KEY `lote_id` (`lote_id`),
  CONSTRAINT `fk_venta_detalle_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_detalle_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_detalle_venta` FOREIGN KEY (`venta_id`) REFERENCES `venta` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `venta_detalle`
--

LOCK TABLES `venta_detalle` WRITE;
/*!40000 ALTER TABLE `venta_detalle` DISABLE KEYS */;
set autocommit=0;
INSERT INTO `venta_detalle` VALUES
(1,1,1,1,2,7600.00),
(2,2,2,2,1,9500.00),
(3,3,7,3,1,4500.00),
(4,4,7,3,12,54000.00),
(5,5,1,1,12,45600.00),
(6,6,7,3,1,4500.00),
(7,7,1,1,6,22800.00),
(8,8,8,4,10,25000.00),
(9,9,7,3,4,18000.00),
(17,17,1,1,1,3800.00),
(18,18,11,14,1,3000.00),
(19,19,11,14,1,3000.00),
(20,20,11,14,1,3000.00),
(21,21,11,14,1,3000.00),
(22,22,1,1,79,300200.00),
(23,22,7,3,1,4500.00),
(24,23,7,3,12,54000.00),
(25,24,11,14,18,54000.00),
(26,25,11,14,18,54000.00),
(27,27,2,2,1,9500.00),
(28,28,2,2,10,95000.00),
(29,29,10,20,1,5000.00),
(30,29,2,2,1,9500.00),
(31,30,2,2,2,19000.00),
(32,31,10,20,1,5000.00),
(33,32,7,3,4,18000.00),
(34,32,7,5,4,18000.00),
(35,32,7,6,4,18000.00),
(36,33,12,15,1,3500.00),
(37,34,10,20,2,10000.00),
(38,34,3,10,10,30000.00),
(39,35,7,3,10,45000.00),
(40,36,12,15,1,3500.00),
(41,37,3,10,1,3000.00),
(42,37,1,19,1,3800.00),
(43,37,7,3,5,22500.00),
(44,38,12,15,1,3500.00),
(45,39,12,15,1,3500.00),
(46,39,12,15,1,3500.00),
(47,39,12,15,1,3500.00),
(48,39,12,15,1,3500.00),
(49,40,10,20,1,5000.00),
(50,40,12,15,1,3500.00),
(51,41,12,15,1,3500.00),
(52,42,3,10,1,3000.00),
(53,43,10,20,2,10000.00),
(54,44,12,15,1,3500.00),
(55,45,12,15,1,3500.00),
(56,46,12,15,1,3500.00),
(57,47,12,15,1,3500.00),
(58,48,10,20,3,15000.00),
(59,49,12,15,1,3500.00),
(60,50,1,19,1,3800.00),
(61,51,10,20,1,5000.00),
(62,52,12,15,14,49000.00),
(63,53,2,2,18,171000.00),
(64,53,7,3,5,22500.00),
(65,54,7,3,5,22500.00),
(66,54,7,5,2,9000.00);
/*!40000 ALTER TABLE `venta_detalle` ENABLE KEYS */;
UNLOCK TABLES;
commit;

--
-- Temporary table structure for view `vw_dashboard_inventario`
--

DROP TABLE IF EXISTS `vw_dashboard_inventario`;
/*!50001 DROP VIEW IF EXISTS `vw_dashboard_inventario`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_dashboard_inventario` AS SELECT
 1 AS `total_productos`,
  1 AS `productos_activos`,
  1 AS `unidades_totales`,
  1 AS `valor_total_inventario`,
  1 AS `productos_sin_stock`,
  1 AS `productos_stock_bajo`,
  1 AS `productos_sobre_stock`,
  1 AS `total_lotes_activos`,
  1 AS `lotes_vencidos`,
  1 AS `lotes_proximos_vencer`,
  1 AS `entradas_hoy`,
  1 AS `salidas_hoy`,
  1 AS `ordenes_pendientes`,
  1 AS `ordenes_hoy` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_historial_reabastecimientos`
--

DROP TABLE IF EXISTS `vw_historial_reabastecimientos`;
/*!50001 DROP VIEW IF EXISTS `vw_historial_reabastecimientos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_historial_reabastecimientos` AS SELECT
 1 AS `reabastecimiento_id`,
  1 AS `fecha`,
  1 AS `proveedor`,
  1 AS `proveedor_telefono`,
  1 AS `estado`,
  1 AS `forma_pago`,
  1 AS `costo_total`,
  1 AS `iva`,
  1 AS `total_con_iva`,
  1 AS `total_productos`,
  1 AS `total_unidades_solicitadas`,
  1 AS `total_unidades_recibidas`,
  1 AS `estado_recepcion`,
  1 AS `recibido_por`,
  1 AS `fecha_recepcion`,
  1 AS `observaciones` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_inventario_actual_producto`
--

DROP TABLE IF EXISTS `vw_inventario_actual_producto`;
/*!50001 DROP VIEW IF EXISTS `vw_inventario_actual_producto`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_inventario_actual_producto` AS SELECT
 1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `stock_actual`,
  1 AS `costo_promedio`,
  1 AS `stock_calculado_lotes`,
  1 AS `numero_lotes_activos` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_kardex_producto`
--

DROP TABLE IF EXISTS `vw_kardex_producto`;
/*!50001 DROP VIEW IF EXISTS `vw_kardex_producto`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_kardex_producto` AS SELECT
 1 AS `movimiento_id`,
  1 AS `fecha_movimiento`,
  1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `codigo_barras`,
  1 AS `categoria`,
  1 AS `numero_lote`,
  1 AS `fecha_caducidad`,
  1 AS `tipo_movimiento`,
  1 AS `cantidad`,
  1 AS `costo_unitario`,
  1 AS `valor_movimiento`,
  1 AS `descripcion`,
  1 AS `origen`,
  1 AS `usuario`,
  1 AS `saldo_cantidad`,
  1 AS `saldo_valor` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_lotes_activos`
--

DROP TABLE IF EXISTS `vw_lotes_activos`;
/*!50001 DROP VIEW IF EXISTS `vw_lotes_activos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_lotes_activos` AS SELECT
 1 AS `lote_id`,
  1 AS `numero_lote`,
  1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `codigo_barras`,
  1 AS `categoria`,
  1 AS `cantidad_disponible`,
  1 AS `costo_unitario_lote`,
  1 AS `valor_lote`,
  1 AS `fecha_entrada`,
  1 AS `fecha_caducidad`,
  1 AS `dias_hasta_vencer`,
  1 AS `estado_lote`,
  1 AS `estado_vencimiento`,
  1 AS `reabastecimiento_id`,
  1 AS `fecha_reabastecimiento`,
  1 AS `proveedor`,
  1 AS `alertas_activas` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_movimientos_recientes`
--

DROP TABLE IF EXISTS `vw_movimientos_recientes`;
/*!50001 DROP VIEW IF EXISTS `vw_movimientos_recientes`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_movimientos_recientes` AS SELECT
 1 AS `movimiento_id`,
  1 AS `fecha_movimiento`,
  1 AS `tipo_movimiento`,
  1 AS `cantidad`,
  1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `numero_lote`,
  1 AS `descripcion`,
  1 AS `venta_id`,
  1 AS `reabastecimiento_id` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_productos_alertas`
--

DROP TABLE IF EXISTS `vw_productos_alertas`;
/*!50001 DROP VIEW IF EXISTS `vw_productos_alertas`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_productos_alertas` AS SELECT
 1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `codigo_barras`,
  1 AS `categoria`,
  1 AS `stock_actual`,
  1 AS `stock_minimo`,
  1 AS `stock_maximo`,
  1 AS `costo_promedio`,
  1 AS `valor_inventario`,
  1 AS `estado_stock`,
  1 AS `prioridad`,
  1 AS `numero_lotes`,
  1 AS `proxima_fecha_vencimiento`,
  1 AS `dias_hasta_vencer`,
  1 AS `ultima_venta`,
  1 AS `ultima_compra`,
  1 AS `alertas_activas` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_productos_baja_rotacion`
--

DROP TABLE IF EXISTS `vw_productos_baja_rotacion`;
/*!50001 DROP VIEW IF EXISTS `vw_productos_baja_rotacion`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_productos_baja_rotacion` AS SELECT
 1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `codigo_barras`,
  1 AS `categoria`,
  1 AS `stock_actual`,
  1 AS `valor_inventario`,
  1 AS `ultimo_movimiento`,
  1 AS `dias_sin_movimiento`,
  1 AS `ventas_30_dias`,
  1 AS `ventas_90_dias` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_productos_mas_vendidos`
--

DROP TABLE IF EXISTS `vw_productos_mas_vendidos`;
/*!50001 DROP VIEW IF EXISTS `vw_productos_mas_vendidos`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_productos_mas_vendidos` AS SELECT
 1 AS `producto_id`,
  1 AS `producto_nombre`,
  1 AS `codigo_barras`,
  1 AS `categoria`,
  1 AS `stock_actual`,
  1 AS `precio_unitario`,
  1 AS `costo_promedio`,
  1 AS `ventas_7_dias`,
  1 AS `ventas_30_dias`,
  1 AS `ventas_90_dias`,
  1 AS `ingresos_30_dias`,
  1 AS `promedio_diario`,
  1 AS `ultima_venta` */;
SET character_set_client = @saved_cs_client;

--
-- Temporary table structure for view `vw_valorizacion_categoria`
--

DROP TABLE IF EXISTS `vw_valorizacion_categoria`;
/*!50001 DROP VIEW IF EXISTS `vw_valorizacion_categoria`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `vw_valorizacion_categoria` AS SELECT
 1 AS `categoria_id`,
  1 AS `categoria`,
  1 AS `total_productos`,
  1 AS `unidades_totales`,
  1 AS `valor_total`,
  1 AS `costo_promedio`,
  1 AS `porcentaje_valor`,
  1 AS `productos_stock_bajo`,
  1 AS `productos_sin_stock` */;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'laplayita'
--

--
-- Dumping routines for database 'laplayita'
--
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_dias_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_dias_inventario`(p_producto_id INT, p_dias_analisis INT) RETURNS decimal(10,2)
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE v_stock_actual INT;
    DECLARE v_ventas_periodo INT;
    DECLARE v_promedio_diario DECIMAL(10,2);
    DECLARE v_dias_inventario DECIMAL(10,2);
    
    
    SELECT stock_actual INTO v_stock_actual
    FROM producto
    WHERE id = p_producto_id;
    
    
    SELECT COALESCE(SUM(ABS(cantidad)), 0) INTO v_ventas_periodo
    FROM movimiento_inventario
    WHERE producto_id = p_producto_id
      AND tipo_movimiento = 'SALIDA'
      AND fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL p_dias_analisis DAY);
    
    
    IF v_ventas_periodo > 0 THEN
        SET v_promedio_diario = v_ventas_periodo / p_dias_analisis;
        SET v_dias_inventario = v_stock_actual / v_promedio_diario;
    ELSE
        SET v_dias_inventario = 999; 
    END IF;
    
    RETURN v_dias_inventario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_rotacion_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_rotacion_inventario`(p_producto_id INT, p_dias_analisis INT) RETURNS decimal(10,2)
    READS SQL DATA
    DETERMINISTIC
BEGIN
    DECLARE v_costo_promedio DECIMAL(12,2);
    DECLARE v_stock_actual INT;
    DECLARE v_costo_ventas DECIMAL(12,2);
    DECLARE v_inventario_promedio DECIMAL(12,2);
    DECLARE v_rotacion DECIMAL(10,2);
    
    
    SELECT costo_promedio, stock_actual 
    INTO v_costo_promedio, v_stock_actual
    FROM producto
    WHERE id = p_producto_id;
    
    
    SELECT COALESCE(SUM(ABS(cantidad) * costo_unitario), 0) INTO v_costo_ventas
    FROM movimiento_inventario
    WHERE producto_id = p_producto_id
      AND tipo_movimiento = 'SALIDA'
      AND fecha_movimiento >= DATE_SUB(CURDATE(), INTERVAL p_dias_analisis DAY);
    
    
    SET v_inventario_promedio = v_stock_actual * v_costo_promedio;
    
    
    IF v_inventario_promedio > 0 THEN
        SET v_rotacion = v_costo_ventas / v_inventario_promedio;
    ELSE
        SET v_rotacion = 0;
    END IF;
    
    RETURN v_rotacion;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_add_stock` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_add_stock`(
  IN p_reabastecimiento_detalle_id INT,
  IN p_producto_id INT,
  IN p_numero_lote VARCHAR(100),
  IN p_cantidad INT,
  IN p_costo_unitario DECIMAL(12,2),
  IN p_fecha_caducidad DATE,
  IN p_reabastecimiento_id INT,
  IN p_descripcion VARCHAR(255)
)
BEGIN
  DECLARE v_lote_id INT;

  START TRANSACTION;
    INSERT INTO lote (producto_id, reabastecimiento_detalle_id, numero_lote, cantidad_disponible, costo_unitario_lote, fecha_caducidad)
    VALUES (p_producto_id, p_reabastecimiento_detalle_id, p_numero_lote, p_cantidad, p_costo_unitario, p_fecha_caducidad);

    SET v_lote_id = LAST_INSERT_ID();

    INSERT INTO movimiento_inventario (producto_id, lote_id, cantidad, tipo_movimiento, descripcion, reabastecimiento_id)
    VALUES (p_producto_id, v_lote_id, p_cantidad, 'ENTRADA', p_descripcion, p_reabastecimiento_id);

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_aplicar_ajuste_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_aplicar_ajuste_inventario`(
    IN p_ajuste_id INT,
    IN p_usuario_autoriza_id BIGINT
)
BEGIN
    DECLARE v_producto_id INT;
    DECLARE v_lote_id INT;
    DECLARE v_diferencia INT;
    DECLARE v_descripcion TEXT;
    DECLARE v_estado VARCHAR(20);
    
    
    SELECT producto_id, lote_id, diferencia, descripcion, estado
    INTO v_producto_id, v_lote_id, v_diferencia, v_descripcion, v_estado
    FROM ajuste_inventario
    WHERE id = p_ajuste_id;
    
    
    IF v_estado != 'pendiente' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El ajuste ya fue procesado o no est?? pendiente';
    END IF;
    
    START TRANSACTION;
    
    
    IF v_lote_id IS NOT NULL THEN
        UPDATE lote 
        SET cantidad_disponible = cantidad_disponible + v_diferencia
        WHERE id = v_lote_id;
    END IF;
    
    
    INSERT INTO movimiento_inventario (
        producto_id, lote_id, cantidad, tipo_movimiento, 
        descripcion, usuario_id, costo_unitario
    )
    SELECT 
        v_producto_id,
        v_lote_id,
        v_diferencia,
        'AJUSTE',
        CONCAT('Ajuste de inventario #', p_ajuste_id, ': ', v_descripcion),
        p_usuario_autoriza_id,
        p.costo_promedio
    FROM producto p
    WHERE p.id = v_producto_id;
    
    
    UPDATE ajuste_inventario
    SET estado = 'aplicado',
        usuario_autoriza_id = p_usuario_autoriza_id
    WHERE id = p_ajuste_id;
    
    COMMIT;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_aplicar_descarte_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_aplicar_descarte_producto`(
    IN p_descarte_id INT,
    IN p_usuario_autoriza_id BIGINT
)
BEGIN
    DECLARE v_producto_id INT;
    DECLARE v_lote_id INT;
    DECLARE v_cantidad INT;
    DECLARE v_descripcion TEXT;
    DECLARE v_estado VARCHAR(20);
    DECLARE v_costo_unitario DECIMAL(12,2);
    
    
    SELECT producto_id, lote_id, cantidad, descripcion, estado, costo_unitario
    INTO v_producto_id, v_lote_id, v_cantidad, v_descripcion, v_estado, v_costo_unitario
    FROM descarte_producto
    WHERE id = p_descarte_id;
    
    
    IF v_estado != 'pendiente' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'El descarte ya fue procesado o no est?? pendiente';
    END IF;
    
    START TRANSACTION;
    
    
    IF v_lote_id IS NOT NULL THEN
        UPDATE lote 
        SET cantidad_disponible = cantidad_disponible - v_cantidad
        WHERE id = v_lote_id;
        
        
        UPDATE lote 
        SET estado = 'descartado'
        WHERE id = v_lote_id AND cantidad_disponible = 0;
    END IF;
    
    
    INSERT INTO movimiento_inventario (
        producto_id, lote_id, cantidad, tipo_movimiento, 
        descripcion, usuario_id, costo_unitario
    ) VALUES (
        v_producto_id,
        v_lote_id,
        -v_cantidad,
        'DESCARTE',
        CONCAT('Descarte #', p_descarte_id, ': ', v_descripcion),
        p_usuario_autoriza_id,
        v_costo_unitario
    );
    
    
    UPDATE descarte_producto
    SET estado = 'ejecutado',
        usuario_autoriza_id = p_usuario_autoriza_id
    WHERE id = p_descarte_id;
    
    
    UPDATE alerta_inventario
    SET estado = 'resuelta',
        resuelta_por_id = p_usuario_autoriza_id,
        fecha_resolucion = NOW(),
        notas_resolucion = CONCAT('Descarte aplicado #', p_descarte_id)
    WHERE lote_id = v_lote_id
      AND tipo_alerta IN ('vencido', 'proximo_vencer')
      AND estado = 'activa';
    
    COMMIT;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generar_alertas_inventario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_alertas_inventario`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_producto_id INT;
    DECLARE v_producto_nombre VARCHAR(50);
    DECLARE v_stock_actual INT;
    DECLARE v_stock_minimo INT;
    DECLARE v_stock_maximo INT;
    DECLARE v_lote_id INT;
    DECLARE v_numero_lote VARCHAR(50);
    DECLARE v_fecha_caducidad DATE;
    DECLARE v_cantidad_lote INT;
    DECLARE v_dias_vencer INT;
    
    
    DECLARE cur_stock_bajo CURSOR FOR
        SELECT p.id, p.nombre, p.stock_actual, p.stock_minimo
        FROM producto p
        WHERE p.estado = 'activo'
          AND p.stock_actual < (p.stock_minimo * 1.5)
          AND p.stock_actual > 0
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.producto_id = p.id
                AND a.tipo_alerta = 'stock_bajo'
                AND a.estado = 'activa'
          );
    
    
    DECLARE cur_sin_stock CURSOR FOR
        SELECT p.id, p.nombre, p.stock_actual, p.stock_minimo
        FROM producto p
        WHERE p.estado = 'activo'
          AND p.stock_actual = 0
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.producto_id = p.id
                AND a.tipo_alerta = 'sin_stock'
                AND a.estado = 'activa'
          );
    
    
    DECLARE cur_proximo_vencer CURSOR FOR
        SELECT l.id, l.numero_lote, l.producto_id, p.nombre, l.fecha_caducidad, l.cantidad_disponible,
               DATEDIFF(l.fecha_caducidad, CURDATE()) as dias_vencer
        FROM lote l
        INNER JOIN producto p ON l.producto_id = p.id
        WHERE l.estado = 'activo'
          AND l.cantidad_disponible > 0
          AND l.fecha_caducidad BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.lote_id = l.id
                AND a.tipo_alerta = 'proximo_vencer'
                AND a.estado = 'activa'
          );
    
    
    DECLARE cur_vencido CURSOR FOR
        SELECT l.id, l.numero_lote, l.producto_id, p.nombre, l.fecha_caducidad, l.cantidad_disponible
        FROM lote l
        INNER JOIN producto p ON l.producto_id = p.id
        WHERE l.estado IN ('activo', 'vencido')
          AND l.cantidad_disponible > 0
          AND l.fecha_caducidad < CURDATE()
          AND NOT EXISTS (
              SELECT 1 FROM alerta_inventario a
              WHERE a.lote_id = l.id
                AND a.tipo_alerta = 'vencido'
                AND a.estado = 'activa'
          );
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    
    OPEN cur_stock_bajo;
    read_loop_bajo: LOOP
        FETCH cur_stock_bajo INTO v_producto_id, v_producto_nombre, v_stock_actual, v_stock_minimo;
        IF done THEN
            LEAVE read_loop_bajo;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            'stock_bajo',
            IF(v_stock_actual < v_stock_minimo, 'alta', 'media'),
            CONCAT('Stock bajo: ', v_producto_nombre),
            CONCAT('El producto "', v_producto_nombre, '" tiene stock bajo y requiere reabastecimiento.'),
            CONCAT('Stock actual: ', v_stock_actual),
            CONCAT('Stock m??nimo: ', v_stock_minimo),
            'activa'
        );
    END LOOP;
    CLOSE cur_stock_bajo;
    
    
    SET done = FALSE;
    OPEN cur_sin_stock;
    read_loop_sin: LOOP
        FETCH cur_sin_stock INTO v_producto_id, v_producto_nombre, v_stock_actual, v_stock_minimo;
        IF done THEN
            LEAVE read_loop_sin;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            'sin_stock',
            'critica',
            CONCAT('RUPTURA DE STOCK: ', v_producto_nombre),
            CONCAT('El producto "', v_producto_nombre, '" no tiene stock disponible.'),
            'Stock actual: 0',
            CONCAT('Stock m??nimo: ', v_stock_minimo),
            'activa'
        );
    END LOOP;
    CLOSE cur_sin_stock;
    
    
    SET done = FALSE;
    OPEN cur_proximo_vencer;
    read_loop_vencer: LOOP
        FETCH cur_proximo_vencer INTO v_lote_id, v_numero_lote, v_producto_id, v_producto_nombre, 
                                       v_fecha_caducidad, v_cantidad_lote, v_dias_vencer;
        IF done THEN
            LEAVE read_loop_vencer;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, lote_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            v_lote_id,
            'proximo_vencer',
            IF(v_dias_vencer <= 7, 'alta', 'media'),
            CONCAT('Lote pr??ximo a vencer: ', v_producto_nombre),
            CONCAT('El lote ', v_numero_lote, ' del producto "', v_producto_nombre, 
                   '" vence en ', v_dias_vencer, ' d??as.'),
            CONCAT('Cantidad: ', v_cantidad_lote, ' unidades'),
            CONCAT('Vence: ', DATE_FORMAT(v_fecha_caducidad, '%d/%m/%Y')),
            'activa'
        );
    END LOOP;
    CLOSE cur_proximo_vencer;
    
    
    SET done = FALSE;
    OPEN cur_vencido;
    read_loop_vencido: LOOP
        FETCH cur_vencido INTO v_lote_id, v_numero_lote, v_producto_id, v_producto_nombre, 
                                v_fecha_caducidad, v_cantidad_lote;
        IF done THEN
            LEAVE read_loop_vencido;
        END IF;
        
        INSERT INTO alerta_inventario (
            producto_id, lote_id, tipo_alerta, prioridad, titulo, mensaje, 
            valor_actual, valor_esperado, estado
        ) VALUES (
            v_producto_id,
            v_lote_id,
            'vencido',
            'critica',
            CONCAT('LOTE VENCIDO: ', v_producto_nombre),
            CONCAT('El lote ', v_numero_lote, ' del producto "', v_producto_nombre, 
                   '" est?? vencido y debe ser descartado.'),
            CONCAT('Cantidad: ', v_cantidad_lote, ' unidades'),
            CONCAT('Venci??: ', DATE_FORMAT(v_fecha_caducidad, '%d/%m/%Y')),
            'activa'
        );
        
        
        UPDATE lote SET estado = 'vencido' WHERE id = v_lote_id;
    END LOOP;
    CLOSE cur_vencido;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generar_valorizacion_mensual` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generar_valorizacion_mensual`(
    IN p_periodo VARCHAR(7), 
    IN p_usuario_id BIGINT
)
BEGIN
    DECLARE v_fecha_corte DATE;
    
    
    SET v_fecha_corte = LAST_DAY(CONCAT(p_periodo, '-01'));
    
    
    DELETE FROM valorizacion_inventario WHERE periodo = p_periodo;
    
    
    INSERT INTO valorizacion_inventario (
        periodo, fecha_corte, producto_id, cantidad, costo_unitario, 
        costo_promedio, valor_total, categoria_id, generado_por_id
    )
    SELECT 
        p_periodo,
        v_fecha_corte,
        p.id,
        p.stock_actual,
        COALESCE(
            (SELECT l.costo_unitario_lote 
             FROM lote l 
             WHERE l.producto_id = p.id 
               AND l.cantidad_disponible > 0 
             ORDER BY l.fecha_entrada 
             LIMIT 1),
            p.costo_promedio
        ) as costo_unitario,
        p.costo_promedio,
        p.stock_actual * p.costo_promedio as valor_total,
        p.categoria_id,
        p_usuario_id
    FROM producto p
    WHERE p.estado = 'activo';
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_recalcular_costo_promedio_por_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_recalcular_costo_promedio_por_producto`(IN p_producto_id INT)
BEGIN
  DECLARE total_cantidad INT DEFAULT 0;
  DECLARE total_valor DECIMAL(18,4) DEFAULT 0.00;

  SELECT COALESCE(SUM(cantidad_disponible),0), COALESCE(SUM(cantidad_disponible * costo_unitario_lote),0)
  INTO total_cantidad, total_valor
  FROM lote
  WHERE producto_id = p_producto_id;

  IF total_cantidad = 0 THEN
    UPDATE producto SET costo_promedio = 0.00 WHERE id = p_producto_id;
  ELSE
    UPDATE producto SET costo_promedio = ROUND(total_valor / total_cantidad,2) WHERE id = p_producto_id;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_sell_stock` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_uca1400_ai_ci */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_sell_stock`(
  IN p_venta_id INT,
  IN p_producto_id INT,
  IN p_lote_id INT,
  IN p_cantidad INT,
  IN p_descripcion VARCHAR(255)
)
BEGIN
  DECLARE v_actual INT;

  START TRANSACTION;
    SELECT cantidad_disponible INTO v_actual FROM lote WHERE id = p_lote_id FOR UPDATE;
    IF v_actual IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Lote no existe';
    END IF;

    IF v_actual < p_cantidad THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente en lote';
    END IF;

    UPDATE lote SET cantidad_disponible = cantidad_disponible - p_cantidad WHERE id = p_lote_id;

    INSERT INTO movimiento_inventario (producto_id, lote_id, cantidad, tipo_movimiento, descripcion, venta_id)
    VALUES (p_producto_id, p_lote_id, -p_cantidad, 'SALIDA', p_descripcion, p_venta_id);

  COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `laplayita`
--

USE `laplayita`;

--
-- Final view structure for view `v_pqrs_dashboard`
--

/*!50001 DROP VIEW IF EXISTS `v_pqrs_dashboard`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_pqrs_dashboard` AS select count(0) AS `total_casos`,sum(case when `pqrs`.`estado` = 'nuevo' then 1 else 0 end) AS `casos_nuevos`,sum(case when `pqrs`.`estado` = 'en_proceso' then 1 else 0 end) AS `casos_en_proceso`,sum(case when `pqrs`.`estado` = 'resuelto' then 1 else 0 end) AS `casos_resueltos`,sum(case when `pqrs`.`estado` = 'cerrado' then 1 else 0 end) AS `casos_cerrados`,sum(case when `pqrs`.`sla_vencido` = 1 then 1 else 0 end) AS `casos_sla_vencido`,sum(case when `pqrs`.`prioridad` = 'urgente' and `pqrs`.`estado` not in ('cerrado','resuelto') then 1 else 0 end) AS `casos_urgentes_activos`,avg(`pqrs`.`tiempo_resolucion_horas`) AS `tiempo_promedio_resolucion`,count(distinct `pqrs`.`cliente_id`) AS `clientes_unicos` from `pqrs` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_productos_obsoletos`
--

/*!50001 DROP VIEW IF EXISTS `v_productos_obsoletos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_productos_obsoletos` AS select `p`.`id` AS `id`,`p`.`nombre` AS `nombre`,`p`.`categoria_id` AS `categoria_id`,`c`.`nombre` AS `categoria_nombre`,`p`.`stock_actual` AS `stock_actual`,`p`.`costo_promedio` AS `costo_promedio`,`p`.`stock_actual` * `p`.`costo_promedio` AS `valor_inmovilizado`,`p`.`dias_sin_movimiento` AS `dias_sin_movimiento`,`p`.`ultima_venta` AS `ultima_venta`,to_days(curdate()) - to_days(`p`.`ultima_venta`) AS `dias_desde_ultima_venta` from (`producto` `p` join `categoria` `c` on(`p`.`categoria_id` = `c`.`id`)) where `p`.`dias_sin_movimiento` > 90 and `p`.`stock_actual` > 0 and `p`.`estado` = 'activo' order by `p`.`dias_sin_movimiento` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_resumen_alertas`
--

/*!50001 DROP VIEW IF EXISTS `v_resumen_alertas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_resumen_alertas` AS select `alerta_inventario`.`prioridad` AS `prioridad`,`alerta_inventario`.`tipo_alerta` AS `tipo_alerta`,count(0) AS `total`,count(case when `alerta_inventario`.`estado` = 'activa' then 1 end) AS `activas`,count(case when `alerta_inventario`.`estado` = 'resuelta' then 1 end) AS `resueltas`,count(case when `alerta_inventario`.`estado` = 'ignorada' then 1 end) AS `ignoradas` from `alerta_inventario` where `alerta_inventario`.`fecha_generacion` >= curdate() - interval 30 day group by `alerta_inventario`.`prioridad`,`alerta_inventario`.`tipo_alerta` order by field(`alerta_inventario`.`prioridad`,'critica','alta','media','baja'),count(0) desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_stock_disponible`
--

/*!50001 DROP VIEW IF EXISTS `v_stock_disponible`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_stock_disponible` AS select `p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`p`.`stock_actual` AS `stock_total`,coalesce(sum(case when `r`.`estado` = 'activa' then `r`.`cantidad` else 0 end),0) AS `stock_reservado`,`p`.`stock_actual` - coalesce(sum(case when `r`.`estado` = 'activa' then `r`.`cantidad` else 0 end),0) AS `stock_disponible`,`p`.`stock_minimo` AS `stock_minimo`,`p`.`stock_maximo` AS `stock_maximo` from (`producto` `p` left join `reserva_inventario` `r` on(`p`.`id` = `r`.`producto_id` and `r`.`estado` = 'activa')) group by `p`.`id` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_dashboard_inventario`
--

/*!50001 DROP VIEW IF EXISTS `vw_dashboard_inventario`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_dashboard_inventario` AS select count(distinct `p`.`id`) AS `total_productos`,count(distinct case when `p`.`estado` = 'activo' then `p`.`id` end) AS `productos_activos`,sum(`p`.`stock_actual`) AS `unidades_totales`,sum(`p`.`stock_actual` * `p`.`costo_promedio`) AS `valor_total_inventario`,count(distinct case when `p`.`stock_actual` = 0 and `p`.`estado` = 'activo' then `p`.`id` end) AS `productos_sin_stock`,count(distinct case when `p`.`stock_actual` < `p`.`stock_minimo` and `p`.`estado` = 'activo' then `p`.`id` end) AS `productos_stock_bajo`,count(distinct case when `p`.`stock_maximo` is not null and `p`.`stock_actual` > `p`.`stock_maximo` then `p`.`id` end) AS `productos_sobre_stock`,count(distinct `l`.`id`) AS `total_lotes_activos`,count(distinct case when `l`.`fecha_caducidad` < curdate() then `l`.`id` end) AS `lotes_vencidos`,count(distinct case when `l`.`fecha_caducidad` between curdate() and curdate() + interval 30 day then `l`.`id` end) AS `lotes_proximos_vencer`,(select count(0) from `movimiento_inventario` where cast(`movimiento_inventario`.`fecha_movimiento` as date) = curdate() and `movimiento_inventario`.`tipo_movimiento` = 'ENTRADA') AS `entradas_hoy`,(select count(0) from `movimiento_inventario` where cast(`movimiento_inventario`.`fecha_movimiento` as date) = curdate() and `movimiento_inventario`.`tipo_movimiento` = 'SALIDA') AS `salidas_hoy`,(select count(0) from `reabastecimiento` where `reabastecimiento`.`estado` = 'solicitado') AS `ordenes_pendientes`,(select count(0) from `reabastecimiento` where cast(`reabastecimiento`.`fecha` as date) = curdate()) AS `ordenes_hoy` from (`producto` `p` left join `lote` `l` on(`p`.`id` = `l`.`producto_id` and `l`.`estado` = 'activo')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_historial_reabastecimientos`
--

/*!50001 DROP VIEW IF EXISTS `vw_historial_reabastecimientos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_historial_reabastecimientos` AS select `r`.`id` AS `reabastecimiento_id`,`r`.`fecha` AS `fecha`,`pr`.`nombre_empresa` AS `proveedor`,`pr`.`telefono` AS `proveedor_telefono`,`r`.`estado` AS `estado`,`r`.`forma_pago` AS `forma_pago`,`r`.`costo_total` AS `costo_total`,`r`.`iva` AS `iva`,`r`.`costo_total` + `r`.`iva` AS `total_con_iva`,count(distinct `rd`.`producto_id`) AS `total_productos`,sum(`rd`.`cantidad`) AS `total_unidades_solicitadas`,sum(`rd`.`cantidad_recibida`) AS `total_unidades_recibidas`,case when `r`.`estado` = 'recibido' then 'Completo' when `r`.`estado` = 'solicitado' then 'Pendiente' when `r`.`estado` = 'cancelado' then 'Cancelado' else `r`.`estado` end AS `estado_recepcion`,group_concat(distinct concat(`u`.`nombres`,' ',`u`.`apellidos`) separator ', ') AS `recibido_por`,max(`rd`.`fecha_recepcion`) AS `fecha_recepcion`,`r`.`observaciones` AS `observaciones` from (((`reabastecimiento` `r` join `proveedor` `pr` on(`r`.`proveedor_id` = `pr`.`id`)) left join `reabastecimiento_detalle` `rd` on(`r`.`id` = `rd`.`reabastecimiento_id`)) left join `usuario` `u` on(`rd`.`recibido_por_id` = `u`.`id`)) group by `r`.`id`,`r`.`fecha`,`pr`.`nombre_empresa`,`pr`.`telefono`,`r`.`estado`,`r`.`forma_pago`,`r`.`costo_total`,`r`.`iva`,`r`.`observaciones` order by `r`.`fecha` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_inventario_actual_producto`
--

/*!50001 DROP VIEW IF EXISTS `vw_inventario_actual_producto`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_inventario_actual_producto` AS select `p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`p`.`stock_actual` AS `stock_actual`,`p`.`costo_promedio` AS `costo_promedio`,coalesce(sum(`l`.`cantidad_disponible`),0) AS `stock_calculado_lotes`,count(`l`.`id`) AS `numero_lotes_activos` from (`producto` `p` left join `lote` `l` on(`p`.`id` = `l`.`producto_id`)) group by `p`.`id`,`p`.`nombre`,`p`.`stock_actual`,`p`.`costo_promedio` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_kardex_producto`
--

/*!50001 DROP VIEW IF EXISTS `vw_kardex_producto`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_kardex_producto` AS select `mi`.`id` AS `movimiento_id`,`mi`.`fecha_movimiento` AS `fecha_movimiento`,`p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`p`.`codigo_barras` AS `codigo_barras`,`c`.`nombre` AS `categoria`,`l`.`numero_lote` AS `numero_lote`,`l`.`fecha_caducidad` AS `fecha_caducidad`,`mi`.`tipo_movimiento` AS `tipo_movimiento`,`mi`.`cantidad` AS `cantidad`,`mi`.`costo_unitario` AS `costo_unitario`,abs(`mi`.`cantidad` * coalesce(`mi`.`costo_unitario`,`p`.`costo_promedio`)) AS `valor_movimiento`,`mi`.`descripcion` AS `descripcion`,case when `mi`.`venta_id` is not null then concat('Venta #',`mi`.`venta_id`) when `mi`.`reabastecimiento_id` is not null then concat('Reabastecimiento #',`mi`.`reabastecimiento_id`) else 'Ajuste manual' end AS `origen`,concat(`u`.`nombres`,' ',`u`.`apellidos`) AS `usuario`,NULL AS `saldo_cantidad`,NULL AS `saldo_valor` from ((((`movimiento_inventario` `mi` join `producto` `p` on(`mi`.`producto_id` = `p`.`id`)) join `categoria` `c` on(`p`.`categoria_id` = `c`.`id`)) left join `lote` `l` on(`mi`.`lote_id` = `l`.`id`)) left join `usuario` `u` on(`mi`.`usuario_id` = `u`.`id`)) order by `mi`.`producto_id`,`mi`.`fecha_movimiento`,`mi`.`id` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_lotes_activos`
--

/*!50001 DROP VIEW IF EXISTS `vw_lotes_activos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_lotes_activos` AS select `l`.`id` AS `lote_id`,`l`.`numero_lote` AS `numero_lote`,`p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`p`.`codigo_barras` AS `codigo_barras`,`c`.`nombre` AS `categoria`,`l`.`cantidad_disponible` AS `cantidad_disponible`,`l`.`costo_unitario_lote` AS `costo_unitario_lote`,`l`.`cantidad_disponible` * `l`.`costo_unitario_lote` AS `valor_lote`,`l`.`fecha_entrada` AS `fecha_entrada`,`l`.`fecha_caducidad` AS `fecha_caducidad`,to_days(`l`.`fecha_caducidad`) - to_days(curdate()) AS `dias_hasta_vencer`,`l`.`estado` AS `estado_lote`,case when `l`.`fecha_caducidad` < curdate() then 'VENCIDO' when to_days(`l`.`fecha_caducidad`) - to_days(curdate()) <= 7 then 'CRITICO' when to_days(`l`.`fecha_caducidad`) - to_days(curdate()) <= 30 then 'PROXIMO' else 'NORMAL' end AS `estado_vencimiento`,`r`.`id` AS `reabastecimiento_id`,`r`.`fecha` AS `fecha_reabastecimiento`,`pr`.`nombre_empresa` AS `proveedor`,(select count(0) from `alerta_inventario` where `alerta_inventario`.`lote_id` = `l`.`id` and `alerta_inventario`.`estado` = 'activa') AS `alertas_activas` from (((((`lote` `l` join `producto` `p` on(`l`.`producto_id` = `p`.`id`)) join `categoria` `c` on(`p`.`categoria_id` = `c`.`id`)) left join `reabastecimiento_detalle` `rd` on(`l`.`reabastecimiento_detalle_id` = `rd`.`id`)) left join `reabastecimiento` `r` on(`rd`.`reabastecimiento_id` = `r`.`id`)) left join `proveedor` `pr` on(`r`.`proveedor_id` = `pr`.`id`)) where `l`.`cantidad_disponible` > 0 order by case when `l`.`fecha_caducidad` < curdate() then 1 when to_days(`l`.`fecha_caducidad`) - to_days(curdate()) <= 7 then 2 when to_days(`l`.`fecha_caducidad`) - to_days(curdate()) <= 30 then 3 else 4 end,`l`.`fecha_caducidad` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_movimientos_recientes`
--

/*!50001 DROP VIEW IF EXISTS `vw_movimientos_recientes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_movimientos_recientes` AS select `mi`.`id` AS `movimiento_id`,`mi`.`fecha_movimiento` AS `fecha_movimiento`,`mi`.`tipo_movimiento` AS `tipo_movimiento`,`mi`.`cantidad` AS `cantidad`,`p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`l`.`numero_lote` AS `numero_lote`,`mi`.`descripcion` AS `descripcion`,`mi`.`venta_id` AS `venta_id`,`mi`.`reabastecimiento_id` AS `reabastecimiento_id` from ((`movimiento_inventario` `mi` join `producto` `p` on(`mi`.`producto_id` = `p`.`id`)) left join `lote` `l` on(`mi`.`lote_id` = `l`.`id`)) order by `mi`.`fecha_movimiento` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_productos_alertas`
--

/*!50001 DROP VIEW IF EXISTS `vw_productos_alertas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_productos_alertas` AS select `p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`p`.`codigo_barras` AS `codigo_barras`,`c`.`nombre` AS `categoria`,`p`.`stock_actual` AS `stock_actual`,`p`.`stock_minimo` AS `stock_minimo`,`p`.`stock_maximo` AS `stock_maximo`,`p`.`costo_promedio` AS `costo_promedio`,`p`.`stock_actual` * `p`.`costo_promedio` AS `valor_inventario`,case when `p`.`stock_actual` = 0 then 'SIN_STOCK' when `p`.`stock_actual` < `p`.`stock_minimo` then 'STOCK_CRITICO' when `p`.`stock_actual` < `p`.`stock_minimo` * 1.5 then 'STOCK_BAJO' when `p`.`stock_maximo` is not null and `p`.`stock_actual` > `p`.`stock_maximo` then 'SOBRE_STOCK' else 'NORMAL' end AS `estado_stock`,case when `p`.`stock_actual` = 0 then 'CRITICA' when `p`.`stock_actual` < `p`.`stock_minimo` then 'ALTA' when `p`.`stock_actual` < `p`.`stock_minimo` * 1.5 then 'MEDIA' else 'BAJA' end AS `prioridad`,count(distinct `l`.`id`) AS `numero_lotes`,min(`l`.`fecha_caducidad`) AS `proxima_fecha_vencimiento`,to_days(min(`l`.`fecha_caducidad`)) - to_days(curdate()) AS `dias_hasta_vencer`,(select max(`movimiento_inventario`.`fecha_movimiento`) from `movimiento_inventario` where `movimiento_inventario`.`producto_id` = `p`.`id` and `movimiento_inventario`.`tipo_movimiento` = 'SALIDA') AS `ultima_venta`,(select max(`movimiento_inventario`.`fecha_movimiento`) from `movimiento_inventario` where `movimiento_inventario`.`producto_id` = `p`.`id` and `movimiento_inventario`.`tipo_movimiento` = 'ENTRADA') AS `ultima_compra`,(select count(0) from `alerta_inventario` where `alerta_inventario`.`producto_id` = `p`.`id` and `alerta_inventario`.`estado` = 'activa') AS `alertas_activas` from ((`producto` `p` join `categoria` `c` on(`p`.`categoria_id` = `c`.`id`)) left join `lote` `l` on(`p`.`id` = `l`.`producto_id` and `l`.`estado` = 'activo' and `l`.`cantidad_disponible` > 0)) where `p`.`estado` = 'activo' group by `p`.`id`,`p`.`nombre`,`p`.`codigo_barras`,`c`.`nombre`,`p`.`stock_actual`,`p`.`stock_minimo`,`p`.`stock_maximo`,`p`.`costo_promedio` having `estado_stock` <> 'NORMAL' or `dias_hasta_vencer` <= 30 order by case `prioridad` when 'CRITICA' then 1 when 'ALTA' then 2 when 'MEDIA' then 3 else 4 end,to_days(min(`l`.`fecha_caducidad`)) - to_days(curdate()) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_productos_baja_rotacion`
--

/*!50001 DROP VIEW IF EXISTS `vw_productos_baja_rotacion`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_productos_baja_rotacion` AS select `p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`p`.`codigo_barras` AS `codigo_barras`,`c`.`nombre` AS `categoria`,`p`.`stock_actual` AS `stock_actual`,`p`.`stock_actual` * `p`.`costo_promedio` AS `valor_inventario`,max(`mi`.`fecha_movimiento`) AS `ultimo_movimiento`,to_days(curdate()) - to_days(max(`mi`.`fecha_movimiento`)) AS `dias_sin_movimiento`,coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 30 day then abs(`mi`.`cantidad`) end),0) AS `ventas_30_dias`,coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 90 day then abs(`mi`.`cantidad`) end),0) AS `ventas_90_dias` from ((`producto` `p` join `categoria` `c` on(`p`.`categoria_id` = `c`.`id`)) left join `movimiento_inventario` `mi` on(`p`.`id` = `mi`.`producto_id`)) where `p`.`estado` = 'activo' and `p`.`stock_actual` > 0 group by `p`.`id`,`p`.`nombre`,`p`.`codigo_barras`,`c`.`nombre`,`p`.`stock_actual`,`p`.`costo_promedio` having `dias_sin_movimiento` > 60 or `ventas_90_dias` = 0 order by to_days(curdate()) - to_days(max(`mi`.`fecha_movimiento`)) desc,`p`.`stock_actual` * `p`.`costo_promedio` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_productos_mas_vendidos`
--

/*!50001 DROP VIEW IF EXISTS `vw_productos_mas_vendidos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_productos_mas_vendidos` AS select `p`.`id` AS `producto_id`,`p`.`nombre` AS `producto_nombre`,`p`.`codigo_barras` AS `codigo_barras`,`c`.`nombre` AS `categoria`,`p`.`stock_actual` AS `stock_actual`,`p`.`precio_unitario` AS `precio_unitario`,`p`.`costo_promedio` AS `costo_promedio`,coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 7 day then abs(`mi`.`cantidad`) else 0 end),0) AS `ventas_7_dias`,coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 30 day then abs(`mi`.`cantidad`) else 0 end),0) AS `ventas_30_dias`,coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 90 day then abs(`mi`.`cantidad`) else 0 end),0) AS `ventas_90_dias`,coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 30 day then abs(`mi`.`cantidad`) * `p`.`precio_unitario` else 0 end),0) AS `ingresos_30_dias`,coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 30 day then abs(`mi`.`cantidad`) else 0 end),0) / 30 AS `promedio_diario`,max(case when `mi`.`tipo_movimiento` = 'SALIDA' then `mi`.`fecha_movimiento` end) AS `ultima_venta` from ((`producto` `p` join `categoria` `c` on(`p`.`categoria_id` = `c`.`id`)) left join `movimiento_inventario` `mi` on(`p`.`id` = `mi`.`producto_id`)) where `p`.`estado` = 'activo' group by `p`.`id`,`p`.`nombre`,`p`.`codigo_barras`,`c`.`nombre`,`p`.`stock_actual`,`p`.`precio_unitario`,`p`.`costo_promedio` having `ventas_30_dias` > 0 order by coalesce(sum(case when `mi`.`tipo_movimiento` = 'SALIDA' and `mi`.`fecha_movimiento` >= curdate() - interval 30 day then abs(`mi`.`cantidad`) else 0 end),0) desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_valorizacion_categoria`
--

/*!50001 DROP VIEW IF EXISTS `vw_valorizacion_categoria`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_valorizacion_categoria` AS select `c`.`id` AS `categoria_id`,`c`.`nombre` AS `categoria`,count(distinct `p`.`id`) AS `total_productos`,sum(`p`.`stock_actual`) AS `unidades_totales`,sum(`p`.`stock_actual` * `p`.`costo_promedio`) AS `valor_total`,avg(`p`.`costo_promedio`) AS `costo_promedio`,round(sum(`p`.`stock_actual` * `p`.`costo_promedio`) / (select sum(`producto`.`stock_actual` * `producto`.`costo_promedio`) from `producto` where `producto`.`estado` = 'activo') * 100,2) AS `porcentaje_valor`,count(distinct case when `p`.`stock_actual` < `p`.`stock_minimo` then `p`.`id` end) AS `productos_stock_bajo`,count(distinct case when `p`.`stock_actual` = 0 then `p`.`id` end) AS `productos_sin_stock` from (`categoria` `c` join `producto` `p` on(`c`.`id` = `p`.`categoria_id`)) where `p`.`estado` = 'activo' group by `c`.`id`,`c`.`nombre` order by sum(`p`.`stock_actual` * `p`.`costo_promedio`) desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2025-12-09 17:46:45
