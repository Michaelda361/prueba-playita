-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         12.0.2-MariaDB - mariadb.org binary distribution
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.11.0.7065
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Volcando estructura de base de datos para laplayita
DROP DATABASE IF EXISTS `laplayita`;
CREATE DATABASE IF NOT EXISTS `laplayita` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_uca1400_ai_ci */;
USE `laplayita`;

-- Volcando estructura para tabla laplayita.auth_group
DROP TABLE IF EXISTS `auth_group`;
CREATE TABLE IF NOT EXISTS `auth_group` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Volcando datos para la tabla laplayita.auth_group: ~0 rows (aproximadamente)

-- Volcando estructura para tabla laplayita.auth_group_permissions
DROP TABLE IF EXISTS `auth_group_permissions`;
CREATE TABLE IF NOT EXISTS `auth_group_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  `permission_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_group_permissions_group_id_permission_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  KEY `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Volcando datos para la tabla laplayita.auth_group_permissions: ~0 rows (aproximadamente)

-- Volcando estructura para tabla laplayita.auth_permission
DROP TABLE IF EXISTS `auth_permission`;
CREATE TABLE IF NOT EXISTS `auth_permission` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content_type_id` int(11) NOT NULL,
  `codename` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`),
  CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Volcando datos para la tabla laplayita.auth_permission: ~88 rows (aproximadamente)
INSERT INTO `auth_permission` (`id`, `name`, `content_type_id`, `codename`) VALUES
	(1, 'Can add permission', 1, 'add_permission'),
	(2, 'Can change permission', 1, 'change_permission'),
	(3, 'Can delete permission', 1, 'delete_permission'),
	(4, 'Can view permission', 1, 'view_permission'),
	(5, 'Can add group', 2, 'add_group'),
	(6, 'Can change group', 2, 'change_group'),
	(7, 'Can delete group', 2, 'delete_group'),
	(8, 'Can view group', 2, 'view_group'),
	(9, 'Can add content type', 3, 'add_contenttype'),
	(10, 'Can change content type', 3, 'change_contenttype'),
	(11, 'Can delete content type', 3, 'delete_contenttype'),
	(12, 'Can view content type', 3, 'view_contenttype'),
	(13, 'Can add session', 4, 'add_session'),
	(14, 'Can change session', 4, 'change_session'),
	(15, 'Can delete session', 4, 'delete_session'),
	(16, 'Can view session', 4, 'view_session'),
	(17, 'Can add rol', 5, 'add_rol'),
	(18, 'Can change rol', 5, 'change_rol'),
	(19, 'Can delete rol', 5, 'delete_rol'),
	(20, 'Can view rol', 5, 'view_rol'),
	(21, 'Can add usuario', 6, 'add_usuario'),
	(22, 'Can change usuario', 6, 'change_usuario'),
	(23, 'Can delete usuario', 6, 'delete_usuario'),
	(24, 'Can view usuario', 6, 'view_usuario'),
	(25, 'Can add log entry', 7, 'add_logentry'),
	(26, 'Can change log entry', 7, 'change_logentry'),
	(27, 'Can delete log entry', 7, 'delete_logentry'),
	(28, 'Can view log entry', 7, 'view_logentry'),
	(29, 'Can add categoria', 8, 'add_categoria'),
	(30, 'Can change categoria', 8, 'change_categoria'),
	(31, 'Can delete categoria', 8, 'delete_categoria'),
	(32, 'Can view categoria', 8, 'view_categoria'),
	(33, 'Can add lote', 9, 'add_lote'),
	(34, 'Can change lote', 9, 'change_lote'),
	(35, 'Can delete lote', 9, 'delete_lote'),
	(36, 'Can view lote', 9, 'view_lote'),
	(37, 'Can add movimiento inventario', 10, 'add_movimientoinventario'),
	(38, 'Can change movimiento inventario', 10, 'change_movimientoinventario'),
	(39, 'Can delete movimiento inventario', 10, 'delete_movimientoinventario'),
	(40, 'Can view movimiento inventario', 10, 'view_movimientoinventario'),
	(41, 'Can add producto', 11, 'add_producto'),
	(42, 'Can change producto', 11, 'change_producto'),
	(43, 'Can delete producto', 11, 'delete_producto'),
	(44, 'Can view producto', 11, 'view_producto'),
	(45, 'Can add pago', 12, 'add_pago'),
	(46, 'Can change pago', 12, 'change_pago'),
	(47, 'Can delete pago', 12, 'delete_pago'),
	(48, 'Can view pago', 12, 'view_pago'),
	(49, 'Can add pedido', 13, 'add_pedido'),
	(50, 'Can change pedido', 13, 'change_pedido'),
	(51, 'Can delete pedido', 13, 'delete_pedido'),
	(52, 'Can view pedido', 13, 'view_pedido'),
	(53, 'Can add pedido detalle', 14, 'add_pedidodetalle'),
	(54, 'Can change pedido detalle', 14, 'change_pedidodetalle'),
	(55, 'Can delete pedido detalle', 14, 'delete_pedidodetalle'),
	(56, 'Can view pedido detalle', 14, 'view_pedidodetalle'),
	(57, 'Can add venta', 15, 'add_venta'),
	(58, 'Can change venta', 15, 'change_venta'),
	(59, 'Can delete venta', 15, 'delete_venta'),
	(60, 'Can view venta', 15, 'view_venta'),
	(61, 'Can add venta detalle', 16, 'add_ventadetalle'),
	(62, 'Can change venta detalle', 16, 'change_ventadetalle'),
	(63, 'Can delete venta detalle', 16, 'delete_ventadetalle'),
	(64, 'Can view venta detalle', 16, 'view_ventadetalle'),
	(65, 'Can add pqrs', 17, 'add_pqrs'),
	(66, 'Can change pqrs', 17, 'change_pqrs'),
	(67, 'Can delete pqrs', 17, 'delete_pqrs'),
	(68, 'Can view pqrs', 17, 'view_pqrs'),
	(69, 'Can add pqrs historial', 18, 'add_pqrshistorial'),
	(70, 'Can change pqrs historial', 18, 'change_pqrshistorial'),
	(71, 'Can delete pqrs historial', 18, 'delete_pqrshistorial'),
	(72, 'Can view pqrs historial', 18, 'view_pqrshistorial'),
	(73, 'Can add proveedor', 19, 'add_proveedor'),
	(74, 'Can change proveedor', 19, 'change_proveedor'),
	(75, 'Can delete proveedor', 19, 'delete_proveedor'),
	(76, 'Can view proveedor', 19, 'view_proveedor'),
	(77, 'Can add reabastecimiento', 20, 'add_reabastecimiento'),
	(78, 'Can change reabastecimiento', 20, 'change_reabastecimiento'),
	(79, 'Can delete reabastecimiento', 20, 'delete_reabastecimiento'),
	(80, 'Can view reabastecimiento', 20, 'view_reabastecimiento'),
	(81, 'Can add reabastecimiento detalle', 21, 'add_reabastecimientodetalle'),
	(82, 'Can change reabastecimiento detalle', 21, 'change_reabastecimientodetalle'),
	(83, 'Can delete reabastecimiento detalle', 21, 'delete_reabastecimientodetalle'),
	(84, 'Can view reabastecimiento detalle', 21, 'view_reabastecimientodetalle'),
	(85, 'Can add Cliente', 22, 'add_cliente'),
	(86, 'Can change Cliente', 22, 'change_cliente'),
	(87, 'Can delete Cliente', 22, 'delete_cliente'),
	(88, 'Can view Cliente', 22, 'view_cliente');

-- Volcando estructura para tabla laplayita.categoria
DROP TABLE IF EXISTS `categoria`;
CREATE TABLE IF NOT EXISTS `categoria` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(25) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.categoria: ~5 rows (aproximadamente)
INSERT INTO `categoria` (`id`, `nombre`) VALUES
	(1, 'Lacteos'),
	(2, 'Quesos'),
	(3, 'Cerveza'),
	(4, 'Gaseosa'),
	(5, 'Dulces');

-- Volcando estructura para tabla laplayita.cliente
DROP TABLE IF EXISTS `cliente`;
CREATE TABLE IF NOT EXISTS `cliente` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `documento` varchar(20) NOT NULL,
  `nombres` varchar(50) NOT NULL,
  `apellidos` varchar(50) NOT NULL,
  `correo` varchar(60) NOT NULL,
  `telefono` varchar(25) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `documento` (`documento`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.cliente: ~2 rows (aproximadamente)
INSERT INTO `cliente` (`id`, `documento`, `nombres`, `apellidos`, `correo`, `telefono`) VALUES
	(1, '12345678', 'Pepito', 'Perez', 'pepito@gmail.com', '12342155124'),
	(2, '10001', 'Laura', 'Martinez', 'laura.m@gmail.com', '3124567890');

-- Volcando estructura para tabla laplayita.django_admin_log
DROP TABLE IF EXISTS `django_admin_log`;
CREATE TABLE IF NOT EXISTS `django_admin_log` (
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

-- Volcando datos para la tabla laplayita.django_admin_log: ~0 rows (aproximadamente)

-- Volcando estructura para tabla laplayita.django_content_type
DROP TABLE IF EXISTS `django_content_type`;
CREATE TABLE IF NOT EXISTS `django_content_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) NOT NULL,
  `model` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Volcando datos para la tabla laplayita.django_content_type: ~22 rows (aproximadamente)
INSERT INTO `django_content_type` (`id`, `app_label`, `model`) VALUES
	(1, 'auth', 'permission'),
	(2, 'auth', 'group'),
	(3, 'contenttypes', 'contenttype'),
	(4, 'sessions', 'session'),
	(5, 'users', 'rol'),
	(6, 'users', 'usuario'),
	(7, 'admin', 'logentry'),
	(8, 'inventory', 'categoria'),
	(9, 'inventory', 'lote'),
	(10, 'inventory', 'movimientoinventario'),
	(11, 'inventory', 'producto'),
	(12, 'pos', 'pago'),
	(13, 'pos', 'pedido'),
	(14, 'pos', 'pedidodetalle'),
	(15, 'pos', 'venta'),
	(16, 'pos', 'ventadetalle'),
	(17, 'pqrs', 'pqrs'),
	(18, 'pqrs', 'pqrshistorial'),
	(19, 'suppliers', 'proveedor'),
	(20, 'suppliers', 'reabastecimiento'),
	(21, 'suppliers', 'reabastecimientodetalle'),
	(22, 'clients', 'cliente');

-- Volcando estructura para tabla laplayita.django_migrations
DROP TABLE IF EXISTS `django_migrations`;
CREATE TABLE IF NOT EXISTS `django_migrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `app` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Volcando datos para la tabla laplayita.django_migrations: ~31 rows (aproximadamente)
INSERT INTO `django_migrations` (`id`, `app`, `name`, `applied`) VALUES
	(1, 'contenttypes', '0001_initial', '2025-11-19 01:51:29.183102'),
	(2, 'contenttypes', '0002_remove_content_type_name', '2025-11-19 01:51:29.235134'),
	(3, 'auth', '0001_initial', '2025-11-19 01:51:29.406066'),
	(4, 'auth', '0002_alter_permission_name_max_length', '2025-11-19 01:51:29.442857'),
	(5, 'auth', '0003_alter_user_email_max_length', '2025-11-19 01:51:29.448597'),
	(6, 'auth', '0004_alter_user_username_opts', '2025-11-19 01:51:29.453729'),
	(7, 'auth', '0005_alter_user_last_login_null', '2025-11-19 01:51:29.458824'),
	(8, 'auth', '0006_require_contenttypes_0002', '2025-11-19 01:51:29.461046'),
	(9, 'auth', '0007_alter_validators_add_error_messages', '2025-11-19 01:51:29.465838'),
	(10, 'auth', '0008_alter_user_username_max_length', '2025-11-19 01:51:29.470411'),
	(11, 'auth', '0009_alter_user_last_name_max_length', '2025-11-19 01:51:29.474934'),
	(12, 'auth', '0010_alter_group_name_max_length', '2025-11-19 01:51:29.498844'),
	(13, 'auth', '0011_update_proxy_permissions', '2025-11-19 01:51:29.503925'),
	(14, 'auth', '0012_alter_user_first_name_max_length', '2025-11-19 01:51:29.508934'),
	(15, 'sessions', '0001_initial', '2025-11-19 01:53:03.615302'),
	(16, 'users', '0001_initial', '2025-11-19 02:05:50.226802'),
	(17, 'suppliers', '0001_initial', '2025-11-19 02:07:00.029220'),
	(18, 'inventory', '0001_initial', '2025-11-19 02:07:24.792645'),
	(19, 'pos', '0001_initial', '2025-11-19 02:07:31.550654'),
	(20, 'core', '0001_initial', '2025-11-19 02:07:40.059590'),
	(21, 'pqrs', '0001_initial', '2025-11-19 02:07:54.810440'),
	(22, 'clients', '0001_initial', '2025-11-19 02:08:04.428007'),
	(23, 'admin', '0001_initial', '2025-11-19 02:13:44.480599'),
	(24, 'admin', '0002_logentry_remove_auto_add', '2025-11-19 02:13:44.486783'),
	(25, 'admin', '0003_logentry_add_action_flag_choices', '2025-11-19 02:13:44.493026'),
	(26, 'clients', '0002_initial', '2025-11-19 12:19:52.940673'),
	(27, 'inventory', '0002_initial', '2025-11-19 12:19:52.955620'),
	(28, 'pos', '0002_initial', '2025-11-19 12:19:52.962756'),
	(29, 'pqrs', '0002_initial', '2025-11-19 12:19:52.968056'),
	(30, 'suppliers', '0002_initial', '2025-11-19 12:19:52.973037'),
	(31, 'users', '0002_alter_rol_options_alter_usuario_is_superuser', '2025-11-19 12:19:52.988441'),
	(32, 'users', '0003_usuario_is_staff', '2025-11-19 13:11:08.531443'),
	(33, 'users', '0004_manual_add_is_superuser', '2025-11-19 13:14:21.160191');

-- Volcando estructura para tabla laplayita.django_session
DROP TABLE IF EXISTS `django_session`;
CREATE TABLE IF NOT EXISTS `django_session` (
  `session_key` varchar(40) NOT NULL,
  `session_data` longtext NOT NULL,
  `expire_date` datetime(6) NOT NULL,
  PRIMARY KEY (`session_key`),
  KEY `django_session_expire_date_a5c62663` (`expire_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Volcando datos para la tabla laplayita.django_session: ~0 rows (aproximadamente)
INSERT INTO `django_session` (`session_key`, `session_data`, `expire_date`) VALUES
	('8ynchq1evtb92l5f9rjq1u1pzaa7168v', '.eJxVjDsOAiEUAO9CbQjyx9LeM5AHjyerBpJltzLe3ZBsoe3MZN4swr7VuI-yxgXZhWl2-mUJ8rO0KfAB7d557m1bl8Rnwg87-K1jeV2P9m9QYdS5JZsdaY1ZmaCMCsI4KTBQkkGADMUGe1ZaeKnAF7KETtgEmrQr4JJnny_F9Ddd:1vLhE2:-cgsp0Yso0dZgftgjeO4Ynpd7X2B-GaCNlWZxxFEv7c', '2025-12-03 12:23:54.454513');

-- Volcando estructura para tabla laplayita.lote
DROP TABLE IF EXISTS `lote`;
CREATE TABLE IF NOT EXISTS `lote` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `reabastecimiento_detalle_id` int(11) DEFAULT NULL,
  `numero_lote` varchar(50) NOT NULL,
  `cantidad_disponible` int(11) unsigned NOT NULL,
  `costo_unitario_lote` decimal(12,2) NOT NULL,
  `fecha_caducidad` date NOT NULL,
  `fecha_entrada` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lote_producto_numero` (`producto_id`,`numero_lote`),
  KEY `fk_lote_producto` (`producto_id`),
  KEY `fk_lote_reabastecimiento_detalle` (`reabastecimiento_detalle_id`),
  CONSTRAINT `fk_lote_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_lote_reabastecimiento_detalle` FOREIGN KEY (`reabastecimiento_detalle_id`) REFERENCES `reabastecimiento_detalle` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.lote: ~8 rows (aproximadamente)
INSERT INTO `lote` (`id`, `producto_id`, `reabastecimiento_detalle_id`, `numero_lote`, `cantidad_disponible`, `costo_unitario_lote`, `fecha_caducidad`, `fecha_entrada`) VALUES
	(1, 1, 1, 'LCH-A1', 80, 2500.00, '2025-10-30', '2025-09-01 10:00:00'),
	(2, 2, 2, 'QSO-C3', 59, 7000.00, '2025-11-15', '2025-09-05 14:00:00'),
	(3, 7, 38, 'R36-P7-38', 42, 4500.00, '2025-12-31', '2025-11-05 11:38:47'),
	(4, 8, 39, 'R37-P8-39', 0, 2500.00, '2025-12-06', '2025-11-05 13:45:41'),
	(5, 7, 42, 'R40-P7-42', 199, 4500.00, '2026-01-15', '2025-11-06 23:06:20'),
	(6, 7, 40, 'R38-P7-40', 100, 4500.00, '2026-01-17', '2025-11-06 23:08:20'),
	(7, 1, 45, 'R45-P1-45', 5, 3800.00, '2026-01-10', '2025-11-12 22:46:31'),
	(10, 3, 55, 'R55-P3-55', 199, 3000.00, '2026-01-03', '2025-11-19 13:20:32');

-- Volcando estructura para tabla laplayita.movimiento_inventario
DROP TABLE IF EXISTS `movimiento_inventario`;
CREATE TABLE IF NOT EXISTS `movimiento_inventario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `producto_id` int(11) NOT NULL,
  `lote_id` int(11) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `tipo_movimiento` varchar(20) NOT NULL,
  `fecha_movimiento` datetime NOT NULL DEFAULT current_timestamp(),
  `descripcion` varchar(255) DEFAULT NULL,
  `venta_id` int(11) DEFAULT NULL,
  `reabastecimiento_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `producto_id` (`producto_id`),
  KEY `lote_id` (`lote_id`),
  KEY `venta_id` (`venta_id`),
  KEY `reabastecimiento_id` (`reabastecimiento_id`),
  CONSTRAINT `fk_movimiento_inventario_lote` FOREIGN KEY (`lote_id`) REFERENCES `lote` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movimiento_inventario_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_movimiento_inventario_reabastecimiento` FOREIGN KEY (`reabastecimiento_id`) REFERENCES `reabastecimiento` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_movimiento_inventario_venta` FOREIGN KEY (`venta_id`) REFERENCES `venta` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.movimiento_inventario: ~14 rows (aproximadamente)
INSERT INTO `movimiento_inventario` (`id`, `producto_id`, `lote_id`, `cantidad`, `tipo_movimiento`, `fecha_movimiento`, `descripcion`, `venta_id`, `reabastecimiento_id`) VALUES
	(1, 1, 1, 100, 'ENTRADA', '2025-10-10 22:48:22', 'Reabastecimiento inicial Lote A1', NULL, 1),
	(2, 2, 2, 60, 'ENTRADA', '2025-10-10 22:48:22', 'Reabastecimiento inicial Lote C3', NULL, 1),
	(3, 1, 1, -2, 'SALIDA', '2025-10-10 22:48:22', 'Venta ID 1', 1, NULL),
	(4, 2, 2, -1, 'SALIDA', '2025-10-10 22:48:22', 'Venta ID 2', 2, NULL),
	(5, 7, 3, 60, 'entrada', '2025-11-05 11:38:47', 'Entrada por reabastecimiento #36', NULL, 36),
	(6, 7, 3, -1, 'salida', '2025-11-05 12:40:34', 'Venta #6', 6, NULL),
	(7, 1, 1, -6, 'salida', '2025-11-05 12:44:58', 'Venta #7', 7, NULL),
	(8, 8, 4, 10, 'entrada', '2025-11-05 13:45:41', 'Entrada por reabastecimiento #37', NULL, 37),
	(9, 8, 4, -10, 'salida', '2025-11-05 13:48:30', 'Venta #8', 8, NULL),
	(10, 7, 3, -4, 'salida', '2025-11-06 22:52:29', 'Venta #9', 9, NULL),
	(11, 7, 5, 199, 'entrada', '2025-11-06 23:06:20', 'Entrada por reabastecimiento #40', NULL, 40),
	(12, 7, 6, 100, 'entrada', '2025-11-06 23:08:20', 'Entrada por reabastecimiento #38', NULL, 38),
	(13, 1, 7, 5, 'entrada', '2025-11-12 22:46:31', 'Entrada por reabastecimiento #45', NULL, 45),
	(16, 3, 10, 199, 'entrada', '2025-11-19 13:20:32', 'Entrada por reabastecimiento #55', NULL, 55);

-- Volcando estructura para tabla laplayita.pago
DROP TABLE IF EXISTS `pago`;
CREATE TABLE IF NOT EXISTS `pago` (
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.pago: ~9 rows (aproximadamente)
INSERT INTO `pago` (`id`, `venta_id`, `monto`, `metodo_pago`, `fecha_pago`, `estado`, `referencia_transaccion`) VALUES
	(1, 1, 7600.00, 'Efectivo', '2025-09-02 10:00:00', 'completado', NULL),
	(2, 2, 9500.00, 'Tarjeta', '2025-09-03 11:30:00', 'completado', NULL),
	(3, 3, 4500.00, 'Efectivo', '2025-11-05 12:24:54', 'completado', NULL),
	(4, 4, 54000.00, 'Efectivo', '2025-11-05 12:25:24', 'completado', NULL),
	(5, 5, 45600.00, 'Efectivo', '2025-11-05 12:25:41', 'completado', NULL),
	(6, 6, 4500.00, 'Efectivo', '2025-11-05 12:40:34', 'completado', NULL),
	(7, 7, 22800.00, 'Efectivo', '2025-11-05 12:44:58', 'completado', NULL),
	(8, 8, 25000.00, 'Efectivo', '2025-11-05 13:48:30', 'completado', NULL),
	(9, 9, 18000.00, 'Efectivo', '2025-11-06 22:52:29', 'completado', NULL);

-- Volcando estructura para tabla laplayita.pedido
DROP TABLE IF EXISTS `pedido`;
CREATE TABLE IF NOT EXISTS `pedido` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cliente_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `fecha_pedido` datetime NOT NULL DEFAULT current_timestamp(),
  `estado` varchar(20) NOT NULL DEFAULT 'pendiente' COMMENT 'Posibles estados: pendiente, en_proceso, completado, cancelado',
  `total_pedido` decimal(12,2) NOT NULL DEFAULT 0.00,
  `observaciones` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cliente_id` (`cliente_id`),
  KEY `usuario_id` (`usuario_id`),
  CONSTRAINT `fk_pedido_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `cliente` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pedido_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.pedido: ~0 rows (aproximadamente)

-- Volcando estructura para tabla laplayita.pedido_detalle
DROP TABLE IF EXISTS `pedido_detalle`;
CREATE TABLE IF NOT EXISTS `pedido_detalle` (
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

-- Volcando datos para la tabla laplayita.pedido_detalle: ~0 rows (aproximadamente)

-- Volcando estructura para tabla laplayita.pqrs
DROP TABLE IF EXISTS `pqrs`;
CREATE TABLE IF NOT EXISTS `pqrs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tipo` varchar(20) NOT NULL,
  `descripcion` text NOT NULL,
  `respuesta` text DEFAULT NULL,
  `estado` varchar(20) DEFAULT 'pendiente',
  `fecha_creacion` datetime NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `cliente_id` int(11) NOT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cliente_id` (`cliente_id`),
  KEY `usuario_id` (`usuario_id`),
  CONSTRAINT `fk_pqrs_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `cliente` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_pqrs_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.pqrs: ~0 rows (aproximadamente)
INSERT INTO `pqrs` (`id`, `tipo`, `descripcion`, `respuesta`, `estado`, `fecha_creacion`, `fecha_actualizacion`, `cliente_id`, `usuario_id`) VALUES
	(1, 'SUGERENCIA', 'Más productos saludables', NULL, 'en_proceso', '2025-07-01 10:00:00', NULL, 1, 2);

-- Volcando estructura para tabla laplayita.pqrs_historial
DROP TABLE IF EXISTS `pqrs_historial`;
CREATE TABLE IF NOT EXISTS `pqrs_historial` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pqrs_id` int(11) NOT NULL,
  `usuario_id` int(11) DEFAULT NULL,
  `estado_anterior` varchar(20) NOT NULL,
  `estado_nuevo` varchar(20) NOT NULL,
  `descripcion_cambio` text DEFAULT NULL,
  `fecha_cambio` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `pqrs_id` (`pqrs_id`),
  KEY `usuario_id` (`usuario_id`),
  CONSTRAINT `fk_pqrs_historial_pqrs` FOREIGN KEY (`pqrs_id`) REFERENCES `pqrs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pqrs_historial_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.pqrs_historial: ~0 rows (aproximadamente)
INSERT INTO `pqrs_historial` (`id`, `pqrs_id`, `usuario_id`, `estado_anterior`, `estado_nuevo`, `descripcion_cambio`, `fecha_cambio`) VALUES
	(1, 1, 2, 'pendiente', 'en_proceso', 'Se asigna el caso al administrador para evaluar la solicitud.', '2025-10-10 22:48:22');

-- Volcando estructura para tabla laplayita.producto
DROP TABLE IF EXISTS `producto`;
CREATE TABLE IF NOT EXISTS `producto` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(50) NOT NULL,
  `precio_unitario` decimal(12,2) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `stock_minimo` int(11) NOT NULL DEFAULT 10,
  `categoria_id` int(11) NOT NULL,
  `stock_actual` int(10) unsigned NOT NULL,
  `costo_promedio` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_producto_nombre` (`nombre`),
  KEY `categoria_id` (`categoria_id`),
  CONSTRAINT `fk_producto_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.producto: ~8 rows (aproximadamente)
INSERT INTO `producto` (`id`, `nombre`, `precio_unitario`, `descripcion`, `stock_minimo`, `categoria_id`, `stock_actual`, `costo_promedio`) VALUES
	(1, 'Leche Entera 1L', 3800.00, 'Leche pasteurizada', 10, 1, 80, 2500.00),
	(2, 'Queso Campesino 500g', 9500.00, 'Queso fresco de vaca', 5, 2, 59, 7000.00),
	(3, 'Yogurt', 3000.00, NULL, 10, 1, 199, 3000.00),
	(4, 'Manzana Postobon 1L', 4500.00, 'Sabor a manzana, 1L', 3, 4, 0, 0.00),
	(7, 'Cerveza Aguila', 4500.00, 'Tipo lager', 1, 3, 341, 4500.00),
	(8, 'Papas Fritas', 2500.00, 'Paquete de papas', 5, 5, 0, 0.00),
	(9, 'Poker', 3000.00, NULL, 10, 3, 0, 0.00),
	(10, 'Coronita', 5000.00, NULL, 5, 3, 370, 5000.00);

-- Volcando estructura para tabla laplayita.proveedor
DROP TABLE IF EXISTS `proveedor`;
CREATE TABLE IF NOT EXISTS `proveedor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nit` varchar(20) NOT NULL,
  `nombre_empresa` varchar(100) NOT NULL,
  `telefono` varchar(50) NOT NULL,
  `correo` varchar(50) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nit` (`nit`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.proveedor: ~4 rows (aproximadamente)
INSERT INTO `proveedor` (`id`, `nit`, `nombre_empresa`, `telefono`, `correo`, `direccion`) VALUES
	(1, '800.123.456-7', 'Proveedor de Lacteos S.A.', '123456789', 'contacto@lacteos.com', 'Calle Falsa 123'),
	(2, '890.903.635-1', 'Postobon S.A.', '3573612371', 'postobon@gmail.com', 'kra93 #32-13'),
	(3, '860.005.224-6', 'Bavaria S.A.', '2131456', 'lizarazojuanandres@gmail.com', 'cra105 #21-65'),
	(4, '800.22 margarita-9', 'Papas Margarita', '235156023', 'margaritas@gmail.com', 'cra100 #95-54');

-- Volcando estructura para tabla laplayita.reabastecimiento
DROP TABLE IF EXISTS `reabastecimiento`;
CREATE TABLE IF NOT EXISTS `reabastecimiento` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fecha` datetime NOT NULL,
  `costo_total` decimal(12,2) NOT NULL,
  `estado` varchar(20) NOT NULL DEFAULT 'solicitado' COMMENT 'Posibles: solicitado, cancelado, recibido',
  `forma_pago` varchar(25) DEFAULT 'Efectivo',
  `observaciones` text DEFAULT NULL,
  `proveedor_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `proveedor_id` (`proveedor_id`),
  CONSTRAINT `fk_reabastecimiento_proveedor` FOREIGN KEY (`proveedor_id`) REFERENCES `proveedor` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.reabastecimiento: ~11 rows (aproximadamente)
INSERT INTO `reabastecimiento` (`id`, `fecha`, `costo_total`, `estado`, `forma_pago`, `observaciones`, `proveedor_id`) VALUES
	(1, '2025-09-01 09:00:00', 670000.00, 'recibido', 'Efectivo', 'Reabastecimiento inicial', 1),
	(36, '2025-11-05 11:38:27', 270000.00, 'recibido', 'pse', '', 3),
	(37, '2025-11-05 13:45:25', 25000.00, 'recibido', 'pse', '', 4),
	(38, '2025-11-06 22:53:32', 450000.00, 'recibido', 'pse', '', 3),
	(40, '2025-11-06 22:54:41', 900000.00, 'recibido', 'pse', '', 3),
	(45, '2025-11-11 20:03:03', 19000.00, 'recibido', 'efectivo', '', 3),
	(46, '2025-11-13 23:34:09', 300000.00, 'solicitado', 'consignacion', '', 3),
	(55, '2025-11-19 13:20:16', 600000.00, 'recibido', 'pse', '', 3);

-- Volcando estructura para tabla laplayita.reabastecimiento_detalle
DROP TABLE IF EXISTS `reabastecimiento_detalle`;
CREATE TABLE IF NOT EXISTS `reabastecimiento_detalle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `reabastecimiento_id` int(11) NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `costo_unitario` decimal(12,2) NOT NULL,
  `fecha_caducidad` date DEFAULT NULL,
  `cantidad_recibida` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `reabastecimiento_id` (`reabastecimiento_id`),
  KEY `producto_id` (`producto_id`),
  CONSTRAINT `fk_reabastecimiento_detalle_reabastecimiento` FOREIGN KEY (`reabastecimiento_id`) REFERENCES `reabastecimiento` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `reabastecimiento_detalle_producto_id_63c5cefe_fk_producto_id` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=56 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.reabastecimiento_detalle: ~12 rows (aproximadamente)
INSERT INTO `reabastecimiento_detalle` (`id`, `reabastecimiento_id`, `producto_id`, `cantidad`, `costo_unitario`, `fecha_caducidad`, `cantidad_recibida`) VALUES
	(1, 1, 1, 100, 2500.00, NULL, 100),
	(2, 1, 2, 60, 7000.00, NULL, 60),
	(38, 36, 7, 60, 4500.00, '2025-12-31', 60),
	(39, 37, 8, 10, 2500.00, '2025-12-06', 10),
	(40, 38, 7, 100, 4500.00, '2026-01-17', 100),
	(42, 40, 7, 200, 4500.00, '2026-01-15', 199),
	(45, 45, 1, 5, 3800.00, '2026-01-10', 5),
	(46, 46, 9, 100, 3000.00, '2026-02-12', 0),
	(55, 55, 3, 200, 3000.00, '2026-01-03', 199);

-- Volcando estructura para tabla laplayita.rol
DROP TABLE IF EXISTS `rol`;
CREATE TABLE IF NOT EXISTS `rol` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(35) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nombre` (`nombre`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.rol: ~2 rows (aproximadamente)
INSERT INTO `rol` (`id`, `nombre`) VALUES
	(1, 'Administrador'),
	(2, 'Vendedor');

-- Volcando estructura para tabla laplayita.usuario
DROP TABLE IF EXISTS `usuario`;
CREATE TABLE IF NOT EXISTS `usuario` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.usuario: ~4 rows (aproximadamente)
INSERT INTO `usuario` (`id`, `documento`, `nombres`, `apellidos`, `correo`, `telefono`, `contrasena`, `estado`, `fecha_creacion`, `ultimo_login`, `rol_id`, `is_staff`, `is_superuser`) VALUES
	(1, '1014477103', 'Juan', 'Lizarazo', 'juan.vendedor@laplayita.com', '3105416287', 'hash_contrasena_vendedor', 'activo', '2025-10-10 22:48:22', NULL, 2, 0, 0),
	(2, '1234567', 'Admin', 'Principal', 'admin@laplayita.com', '32124551', 'hash_contrasena_admin', 'activo', '2025-10-10 22:48:22', '2025-11-09 07:03:56', 1, 0, 0),
	(4, '10000000', 'Laura', 'Gomez', 'laura.admin@laplayita.com', NULL, 'pbkdf2_sha256$1000000$5IUYpFqgilB2EvaR9GQJya$hH7HV5VkSrpqZSxNsg5r9+/o+2BQyzYwWbPiyTDV204=', 'activo', '2025-10-13 19:08:10', '2025-11-19 17:23:54', 1, 0, 0),
	(5, '1014477104', 'Juan Andres', 'Lizarazo Capera', 'lizarazojuanandres@gmail.com', '3105416287', 'pbkdf2_sha256$1000000$UFwj2ILaUlQL994XzKPWC9$KMJ5lGcAoz0n/JkjQsMt3/WVQ9ZH96GT9UowK868yaU=', 'activo', '2025-11-13 05:28:21', '2025-11-13 06:23:15', 2, 0, 0);

-- Volcando estructura para tabla laplayita.venta
DROP TABLE IF EXISTS `venta`;
CREATE TABLE IF NOT EXISTS `venta` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fecha_venta` datetime NOT NULL,
  `canal_venta` varchar(20) NOT NULL DEFAULT 'Tienda',
  `cliente_id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `pedido_id` int(11) DEFAULT NULL COMMENT 'Vincula la venta a un pedido original',
  `total_venta` decimal(12,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `cliente_id` (`cliente_id`),
  KEY `usuario_id` (`usuario_id`),
  KEY `pedido_id` (`pedido_id`),
  CONSTRAINT `fk_venta_cliente` FOREIGN KEY (`cliente_id`) REFERENCES `cliente` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.venta: ~9 rows (aproximadamente)
INSERT INTO `venta` (`id`, `fecha_venta`, `canal_venta`, `cliente_id`, `usuario_id`, `pedido_id`, `total_venta`) VALUES
	(1, '2025-09-02 10:00:00', 'Tienda', 1, 1, NULL, 7600.00),
	(2, '2025-09-03 11:30:00', 'Domicilio', 2, 1, NULL, 9500.00),
	(3, '2025-11-05 12:24:54', 'local', 1, 4, NULL, 4500.00),
	(4, '2025-11-05 12:25:24', 'local', 1, 4, NULL, 54000.00),
	(5, '2025-11-05 12:25:41', 'local', 2, 4, NULL, 45600.00),
	(6, '2025-11-05 12:40:34', 'local', 2, 4, NULL, 4500.00),
	(7, '2025-11-05 12:44:58', 'local', 1, 4, NULL, 22800.00),
	(8, '2025-11-05 13:48:30', 'local', 2, 4, NULL, 25000.00),
	(9, '2025-11-06 22:52:29', 'local', 2, 4, NULL, 18000.00);

-- Volcando estructura para tabla laplayita.venta_detalle
DROP TABLE IF EXISTS `venta_detalle`;
CREATE TABLE IF NOT EXISTS `venta_detalle` (
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Volcando datos para la tabla laplayita.venta_detalle: ~9 rows (aproximadamente)
INSERT INTO `venta_detalle` (`id`, `venta_id`, `producto_id`, `lote_id`, `cantidad`, `subtotal`) VALUES
	(1, 1, 1, 1, 2, 7600.00),
	(2, 2, 2, 2, 1, 9500.00),
	(3, 3, 7, 3, 1, 4500.00),
	(4, 4, 7, 3, 12, 54000.00),
	(5, 5, 1, 1, 12, 45600.00),
	(6, 6, 7, 3, 1, 4500.00),
	(7, 7, 1, 1, 6, 22800.00),
	(8, 8, 8, 4, 10, 25000.00),
	(9, 9, 7, 3, 4, 18000.00);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
