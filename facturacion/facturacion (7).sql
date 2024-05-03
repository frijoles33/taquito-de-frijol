-- phpMyAdmin SQL Dump
-- version 5.0.4
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 20-03-2024 a las 16:29:33
-- Versión del servidor: 10.4.17-MariaDB
-- Versión de PHP: 7.3.27

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `facturacion`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_precio_producto` (`n_cantidad` INT, `n_precio` DECIMAL(10,2), `codigo` INT)  BEGIN
	DECLARE nueva_existencia int;
    DECLARE nuevo_total decimal(10,2);
    DECLARE nuevo_precio decimal(10,2);
    
    DECLARE cant_actual int;
    DECLARE pre_actual decimal(10,2);
    
    DECLARE actual_existencia int;
    DECLARE actual_precio decimal(10,2);
    
    SELECT precio,existencia INTO actual_precio,actual_existencia FROM producto WHERE codproducto = codigo;
    SET nueva_existencia = actual_existencia + n_cantidad;
    SET nuevo_total = (actual_existencia * actual_precio) + (n_cantidad * n_precio);
    SET nuevo_precio = nuevo_total / nueva_existencia;
    
    UPDATE producto SET existencia = nueva_existencia, precio = nuevo_precio WHERE codproducto = codigo;
    
    SELECT nueva_existencia,nuevo_precio;
    
  END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_detalle_temp` (`codigo` INT, `cantidad` INT, `token_user` VARCHAR(50))  BEGIN
		DECLARE precio_actual decimal(10,2);
		SELECT precio INTO precio_actual FROM producto WHERE codproducto=codigo;

		INSERT INTO detalle_temp(token_user,codproducto,cantidad,precio_venta) VALUES(token_user,codigo,cantidad,precio_actual);

		SELECT  tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp tmp
		INNER JOIN producto p
		ON tmp.codproducto=p.codproducto
		WHERE tmp.token_user=token_user;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `anular_factura` (IN `no_factura` INT)  BEGIN
	DECLARE existe_factura int;
	DECLARE registros int;
 	DECLARE a int;

	DECLARE cod_producto int;
	DECLARE cant_producto int;
	DECLARE existencia_actual int;
	DECLARE nueva_existencia int;

	SET existe_factura=(SELECT COUNT(*) FROM factura WHERE nofactura=no_factura and estatus=1);

	IF existe_factura >0 THEN
		CREATE TEMPORARY TABLE tbl_tmp(
			id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
			cod_prod BIGINT,
			cant_prod int);
			SET a=1;
			SET registros=(SELECT COUNT(*) FROM detallefactura WHERE nofactura = no_factura);

			IF registros >0 THEN
				INSERT INTO tbl_tmp(cod_prod,cant_prod) SELECT codproducto, cantidad FROM detallefactura WHERE nofactura=no_factura;
                        WHILE a<=registros DO
				SELECT cod_prod,cant_prod INTO cod_producto,cant_producto FROM tbl_tmp WHERE id=a;
				SELECT existencia INTO existencia_actual FROM producto WHERE codproducto=cod_producto;
  				SET nueva_existencia=existencia_actual+cant_producto;
				UPDATE producto SET existencia=nueva_existencia WHERE codproducto=cod_producto;
				SET a=a+1;
				
			END WHILE;

			UPDATE factura SET estatus=2 WHERE nofactura=no_factura;
			DROP TABLE tbl_tmp;
			SELECT * from factura WHERE nofactura=no_factura;

			END IF;	
	ELSE
		SELECT 0 factura;
	END IF;

	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `dataDashboard` ()  BEGIN
    
    	DECLARE usuarios int;
        DECLARE clientes int;
        DECLARE proveedores int;
        DECLARE productos int;
        DECLARE ventas int;
        
        SELECT COUNT(*) INTO usuarios FROM usuario WHERE estatus != 10;
         SELECT COUNT(*) INTO clientes FROM cliente WHERE estatus != 10;
          SELECT COUNT(*) INTO proveedores FROM proveedor WHERE estatus != 10;
           SELECT COUNT(*) INTO productos FROM producto WHERE estatus != 10;
            SELECT COUNT(*) INTO ventas FROM factura WHERE fecha> CURDATE() AND estatus != 10;
            
            SELECT usuarios,clientes,proveedores,productos,ventas;
            
            
        END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `del_detalle_temp` (`id_detalle` INT, `token` VARCHAR(50))  BEGIN
		DELETE FROM detalle_temp WHERE correlativo=id_detalle;

		SELECT tmp.correlativo, tmp.codproducto,p.descripcion,tmp.cantidad,tmp.precio_venta FROM detalle_temp tmp
		INNER JOIN producto p
		ON tmp.codproducto=p.codproducto
		WHERE tmp.token_user=token;
	END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `hola` ()  SELECT "WELCOME TO MySQL"$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `procesar_venta` (`cod_usuario` INT, `cod_cliente` INT, `token` VARCHAR(50))  BEGIN
        	DECLARE factura INT;
           
        	DECLARE registros INT;
            DECLARE total DECIMAL(10,2);
            
            DECLARE nueva_existencia int;
            DECLARE existencia_actual int;
            
            DECLARE tmp_cod_producto int;
            DECLARE tmp_cant_producto int;
            DECLARE a INT;
            SET a = 1;
            
            CREATE TEMPORARY TABLE tbl_tmp_tokenuser (
                	id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                	cod_prod BIGINT,
                	cant_prod int);
             SET registros = (SELECT COUNT(*) FROM detalle_temp WHERE token_user = token);
             
             IF registros > 0 THEN 
             	INSERT INTO tbl_tmp_tokenuser(cod_prod,cant_prod) SELECT codproducto,cantidad FROM detalle_temp WHERE token_user = token;
                
                INSERT INTO factura(usuario,codcliente) VALUES(cod_usuario,cod_cliente);
                SET factura = LAST_INSERT_ID();
                
                INSERT INTO detallefactura(nofactura,codproducto,cantidad,precio_venta) SELECT (factura) as nofactura, codproducto,cantidad,precio_venta 				FROM detalle_temp WHERE token_user = token; 
                
                WHILE a <= registros DO
                	SELECT cod_prod,cant_prod INTO tmp_cod_producto,tmp_cant_producto FROM tbl_tmp_tokenuser WHERE id = a;
                    SELECT existencia INTO existencia_actual FROM producto WHERE codproducto = tmp_cod_producto;
                    
                    SET nueva_existencia = existencia_actual - tmp_cant_producto;
                    UPDATE producto SET existencia = nueva_existencia WHERE codproducto = tmp_cod_producto;
                    
                    SET a=a+1;
                    
                
                END WHILE; 
                
                SET total = (SELECT SUM(cantidad * precio_venta) FROM detalle_temp WHERE token_user = token);
                UPDATE factura SET totalfactura = total WHERE nofactura = factura;
                DELETE FROM detalle_temp WHERE token_user = token;
                TRUNCATE TABLE tbl_tmp_tokenuser;
                SELECT * FROM factura WHERE nofactura = factura;
             
             ELSE
             SELECT 0;
             END IF;
	END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `idcliente` int(11) NOT NULL,
  `nit` int(11) DEFAULT NULL,
  `nombre` varchar(80) DEFAULT NULL,
  `telefono` int(11) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `dateadd` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`idcliente`, `nit`, `nombre`, `telefono`, `direccion`, `dateadd`, `usuario_id`, `estatus`) VALUES
(1, 12, 'Jacinto', 2147483647, 'Juarez #21', '2021-03-26 20:41:07', 1, 1),
(2, 987, 'Fidelito', 2147483647, 'Zaragoza 21 Tlax', '2021-03-27 00:01:41', 1, 1),
(3, 0, 'Elena Dorantes', 2147483647, 'AV. ADOLFO LOPEZ MATEOS 12', '2021-03-27 00:06:34', 2, 0),
(4, 7878, 'Cristina', 2147483647, 'AV. ADOLFO LOPEZ MATEOS 122222222222', '2021-03-27 00:11:30', 3, 1),
(5, 0, 'Ramiro', 2147483647, 'Zaragoza 21', '2021-03-27 00:29:50', 3, 1),
(6, 0, 'Ramiro', 2147483647, 'Zaragoza 21', '2021-03-27 01:14:56', 3, 1),
(7, 234, 'Andres', 2147483647, 'Juarez #21', '2021-03-27 01:23:39', 3, 1),
(8, 45678, 'Javier Hernandez', 2456356, 'Tetla', '2021-05-22 11:24:26', 1, 1),
(9, 6789, 'Fany Ocaña', 456677, 'Texantla', '2021-05-22 11:38:25', 1, 1),
(10, 5, 'Ruperto', 2147483647, 'apizaco', '2021-06-04 13:14:07', 1, 1),
(11, 345, '', 0, '', '2022-02-16 09:54:32', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion`
--

CREATE TABLE `configuracion` (
  `id` bigint(20) NOT NULL,
  `nit` varchar(20) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `razon_social` varchar(100) NOT NULL,
  `telefono` bigint(20) NOT NULL,
  `email` varchar(100) NOT NULL,
  `direccion` text NOT NULL,
  `iva` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `configuracion`
--

INSERT INTO `configuracion` (`id`, `nit`, `nombre`, `razon_social`, `telefono`, `email`, `direccion`, `iva`) VALUES
(1, '2345', 'PC Servicios', 'Xochipa', 241123456, 'jxochipa@info.com', 'strDir', '16.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detallefactura`
--

CREATE TABLE `detallefactura` (
  `correlativo` bigint(11) NOT NULL,
  `nofactura` bigint(11) DEFAULT NULL,
  `codproducto` int(11) DEFAULT NULL,
  `cantidad` int(11) DEFAULT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `detallefactura`
--

INSERT INTO `detallefactura` (`correlativo`, `nofactura`, `codproducto`, `cantidad`, `precio_venta`) VALUES
(1, 1, 1, 1, '1500.00'),
(2, 1, 1, 1, '1500.00'),
(4, 2, 1, 1, '1500.00'),
(5, 2, 1, 1, '1500.00'),
(7, 3, 1, 1, '1500.00'),
(8, 3, 1, 1, '1500.00'),
(10, 4, 1, 4, '1500.00'),
(11, 4, 1, 1, '1500.00'),
(13, 5, 1, 5, '1500.00'),
(14, 6, 1, 1, '1500.00'),
(15, 7, 1, 1, '1500.00'),
(16, 8, 1, 1, '1500.00'),
(17, 9, 1, 1, '1500.00'),
(18, 10, 1, 1, '1500.00'),
(19, 11, 1, 1, '1500.00'),
(20, 12, 1, 1, '1500.00'),
(21, 13, 1, 1, '1500.00'),
(22, 14, 1, 1, '1500.00'),
(23, 15, 1, 1, '1500.00'),
(24, 16, 1, 1, '1500.00'),
(25, 17, 1, 1, '1500.00'),
(26, 18, 1, 1, '1500.00'),
(27, 19, 1, 1, '1500.00'),
(28, 20, 1, 1, '1500.00'),
(29, 21, 1, 1, '1500.00'),
(30, 22, 1, 1, '1500.00'),
(31, 23, 1, 1, '1500.00'),
(32, 24, 1, 1, '1500.00'),
(33, 25, 1, 1, '1500.00'),
(34, 26, 1, 1, '1500.00'),
(35, 27, 1, 1, '1500.00'),
(36, 28, 1, 1, '1500.00'),
(37, 29, 1, 1, '1500.00'),
(38, 30, 1, 1, '1500.00'),
(39, 31, 1, 1, '1500.00'),
(40, 32, 1, 1, '1500.00'),
(41, 33, 1, 1, '1500.00'),
(42, 34, 1, 1, '1500.00'),
(43, 35, 1, 1, '1500.00'),
(44, 36, 1, 1, '1500.00'),
(45, 37, 1, 1, '1500.00'),
(46, 38, 1, 1, '1500.00'),
(47, 39, 1, 1, '1500.00'),
(48, 40, 1, 1, '1500.00'),
(49, 41, 1, 1, '1500.00'),
(50, 41, 1, 1, '1500.00'),
(52, 42, 1, 5, '1500.00'),
(53, 43, 1, 1, '1500.00'),
(54, 44, 1, 1, '1500.00'),
(55, 45, 1, 1, '1500.00'),
(56, 45, 1, 1, '1500.00'),
(57, 45, 1, 1, '1500.00'),
(58, 46, 6, 1, '9000.00'),
(59, 46, 6, 1, '9000.00'),
(60, 47, 1, 2, '1500.00'),
(61, 47, 1, 1, '1500.00'),
(62, 48, 1, 1, '1500.00'),
(63, 49, 1, 1, '1500.00'),
(64, 50, 1, 1, '1500.00'),
(65, 51, 1, 1, '1700.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_temp`
--

CREATE TABLE `detalle_temp` (
  `correlativo` int(11) NOT NULL,
  `token_user` varchar(50) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precio_venta` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `entradas`
--

CREATE TABLE `entradas` (
  `correlativo` int(11) NOT NULL,
  `codproducto` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `cantidad` int(11) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `usuario_id` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `entradas`
--

INSERT INTO `entradas` (`correlativo`, `codproducto`, `fecha`, `cantidad`, `precio`, `usuario_id`) VALUES
(1, 1, '2021-03-29 17:11:40', 100, '1500.00', 1),
(2, 4, '2021-03-30 00:11:54', 10, '12000.00', 1),
(3, 5, '2021-03-30 20:44:08', 10, '200.00', 1),
(4, 4, '2021-04-01 13:50:29', 10, '1100.00', 1),
(5, 4, '2021-04-01 13:51:28', 10, '1100.00', 1),
(6, 4, '2021-04-01 18:12:09', 10, '12000.00', 1),
(7, 4, '2021-04-01 18:16:38', 10, '1500.00', 1),
(8, 4, '2021-04-01 18:32:10', 5, '20000.00', 1),
(9, 4, '2021-04-01 18:45:41', 5, '20000.00', 1),
(10, 4, '2021-04-01 18:49:54', 5, '20000.00', 1),
(11, 4, '2021-04-01 18:50:11', 5, '20000.00', 1),
(12, 4, '2021-04-01 19:58:08', 5, '20000.00', 1),
(13, 6, '2021-06-16 19:59:21', 100, '9000.00', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `factura`
--

CREATE TABLE `factura` (
  `nofactura` bigint(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario` int(11) DEFAULT NULL,
  `codcliente` int(11) DEFAULT NULL,
  `totalfactura` decimal(10,2) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `factura`
--

INSERT INTO `factura` (`nofactura`, `fecha`, `usuario`, `codcliente`, `totalfactura`, `estatus`) VALUES
(1, '2021-05-25 14:46:36', 1, 7, '3000.00', 2),
(2, '2021-05-25 22:54:44', 1, 1, '3000.00', 1),
(3, '2021-05-25 22:58:56', 1, 9, '3000.00', 1),
(4, '2021-05-26 12:39:55', 1, 9, '7500.00', 1),
(5, '2021-05-26 12:42:46', 1, 9, '7500.00', 1),
(6, '2021-05-26 12:43:22', 1, 9, '1500.00', 1),
(7, '2021-05-26 12:49:02', 1, 9, '1500.00', 1),
(8, '2021-05-26 12:51:46', 1, 9, '1500.00', 1),
(9, '2021-05-26 13:02:01', 1, 9, '1500.00', 1),
(10, '2021-05-26 13:03:50', 1, 9, '1500.00', 1),
(11, '2021-05-26 13:07:36', 1, 9, '1500.00', 1),
(12, '2021-05-26 14:17:06', 1, 9, '1500.00', 1),
(13, '2021-05-26 14:17:23', 1, 9, '1500.00', 1),
(14, '2021-05-26 14:18:09', 1, 9, '1500.00', 1),
(15, '2021-05-26 14:21:57', 1, 9, '1500.00', 1),
(16, '2021-05-26 14:27:29', 1, 9, '1500.00', 1),
(17, '2021-05-26 15:53:10', 1, 9, '1500.00', 1),
(18, '2021-05-26 18:22:24', 1, 9, '1500.00', 1),
(19, '2021-05-26 18:24:38', 1, 9, '1500.00', 1),
(20, '2021-05-26 18:25:03', 1, 9, '1500.00', 1),
(21, '2021-05-26 18:28:37', 1, 9, '1500.00', 1),
(22, '2021-05-26 18:34:47', 1, 9, '1500.00', 1),
(23, '2021-05-26 18:35:25', 1, 1, '1500.00', 2),
(24, '2021-05-26 18:35:59', 1, 9, '1500.00', 2),
(25, '2021-05-26 18:36:25', 1, 9, '1500.00', 1),
(26, '2021-05-26 18:38:36', 1, 9, '1500.00', 1),
(27, '2021-05-26 18:39:52', 1, 9, '1500.00', 1),
(28, '2021-05-26 18:43:25', 1, 9, '1500.00', 2),
(29, '2021-05-26 18:48:42', 1, 9, '1500.00', 1),
(30, '2021-05-26 18:51:39', 1, 9, '1500.00', 2),
(31, '2021-05-26 18:53:08', 1, 9, '1500.00', 2),
(32, '2021-05-26 18:59:43', 1, 9, '1500.00', 2),
(33, '2021-05-26 19:00:45', 1, 9, '1500.00', 2),
(34, '2021-05-26 19:03:54', 1, 9, '1500.00', 2),
(35, '2021-05-26 19:06:26', 1, 9, '1500.00', 2),
(36, '2021-05-26 19:18:59', 1, 9, '1500.00', 2),
(37, '2021-05-26 19:19:46', 1, 9, '1500.00', 2),
(38, '2021-05-26 19:32:58', 1, 9, '1500.00', 2),
(39, '2021-05-26 19:35:32', 1, 9, '1500.00', 2),
(40, '2021-05-26 19:38:44', 1, 9, '1500.00', 1),
(41, '2021-05-29 15:19:10', 1, 1, '3000.00', 1),
(42, '2021-05-29 15:19:53', 1, 1, '7500.00', 2),
(43, '2021-05-29 17:43:12', 1, 1, '1500.00', 1),
(44, '2021-05-30 18:20:36', 1, 1, '1500.00', 2),
(45, '2021-06-16 19:27:53', 1, 8, '4500.00', 2),
(46, '2021-06-16 20:01:56', 1, 8, '18000.00', 2),
(47, '2021-11-09 14:48:54', 1, 1, '4500.00', 1),
(48, '2022-02-16 10:16:18', 1, 11, '1500.00', 1),
(49, '2022-02-22 13:12:38', 1, 1, '1500.00', 1),
(50, '2022-02-23 08:11:36', 1, 1, '1500.00', 1),
(51, '2022-05-16 12:30:33', 1, 1, '1700.00', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `codproducto` int(11) NOT NULL,
  `descripcion` varchar(100) DEFAULT NULL,
  `proveedor` int(11) DEFAULT NULL,
  `precio` decimal(10,2) DEFAULT NULL,
  `existencia` int(11) DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1,
  `foto` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`codproducto`, `descripcion`, `proveedor`, `precio`, `existencia`, `date_add`, `usuario_id`, `estatus`, `foto`) VALUES
(1, 'Monitor LCD', 11, '1700.00', 54, '2021-03-29 17:11:40', 1, 1, 'img_e4a4c1980c6bdcae5ffb9de3d63ba833.jpg'),
(4, 'Fuente 110', 11, '12390.00', 75, '2021-03-30 00:11:54', 1, 1, 'img_d01f8b158ab7f23abb12fe261f54a424.jpg'),
(5, 'Calculadora al22', 2, '30000.00', 10, '2021-03-30 20:44:08', 1, 1, 'img_producto.png'),
(6, ' Tv Sony', 8, '9000.00', 100, '2021-06-16 19:59:21', 1, 1, 'img_producto.png');

--
-- Disparadores `producto`
--
DELIMITER $$
CREATE TRIGGER `entradas_A_I` AFTER INSERT ON `producto` FOR EACH ROW BEGIN
	INSERT INTO entradas(codproducto, cantidad, precio, usuario_id)
	VALUES (new.codproducto, new.existencia, new.precio, new.usuario_id);
	END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedor`
--

CREATE TABLE `proveedor` (
  `codproveedor` int(11) NOT NULL,
  `proveedor` varchar(100) DEFAULT NULL,
  `contacto` varchar(100) DEFAULT NULL,
  `telefono` bigint(11) DEFAULT NULL,
  `direccion` text DEFAULT NULL,
  `date_add` datetime NOT NULL DEFAULT current_timestamp(),
  `usuario_id` int(11) NOT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `proveedor`
--

INSERT INTO `proveedor` (`codproveedor`, `proveedor`, `contacto`, `telefono`, `direccion`, `date_add`, `usuario_id`, `estatus`) VALUES
(1, 'BIC', 'Claudia Rosales', 123, 'Avenida las Americas', '2021-03-28 00:03:37', 1, 1),
(2, 'CASIO', 'Jorge Herrera', 565656565656, 'Calzada Las Flores', '2021-03-28 00:03:37', 1, 1),
(3, 'Omega', 'Julio Estrada', 982877489, 'Avenida Elena Zona 4, Guatemala', '2021-03-28 00:03:37', 1, 0),
(4, 'Dell Compani', 'Roberto Estrada', 2147483647, 'Guatemala, Guatemala', '2021-03-28 00:03:37', 1, 1),
(5, 'Olimpia S.A', 'Elena Franco Morales', 564535676, '5ta. Avenida Zona 4 Ciudad', '2021-03-28 00:03:37', 1, 1),
(6, 'Oster', 'Fernando Guerra', 78987678, 'Calzada La Paz, Guatemala', '2021-03-28 00:03:37', 1, 1),
(7, 'ACELTECSA S.A', 'Ruben PÃ©rez', 789879889, 'Colonia las Victorias', '2021-03-28 00:03:37', 1, 1),
(8, 'Sony', 'Julieta Contreras', 89476787, 'Antigua Guatemala', '2021-03-28 00:03:37', 1, 1),
(9, 'VAIO', 'Felix Arnoldo Rojas', 476378276, 'Avenida las Americas Zona 13', '2021-03-28 00:03:37', 1, 1),
(10, 'SUMAR', 'Oscar Maldonado', 788376787, 'Colonia San Jose, Zona 5 Guatemala', '2021-03-28 00:03:37', 1, 1),
(11, 'HP', 'Angel Cardona', 2147483647, '5ta. calle zona 4 Guatemala', '2021-03-28 00:03:37', 1, 1),
(12, 'Bic', 'Rosaura', 2411245874, 'Apizaco', '2021-03-28 01:01:26', 1, 1),
(13, 'Bimbo', 'Rene', 2411245874, 'Tetla', '2021-03-28 01:08:02', 2, 1),
(14, 'Bimbo', 'Rene', 2411245874, 'Tetla', '2021-03-28 13:37:35', 2, 1),
(15, 'ACER', 'Domitila', 1234, 'Mexico', '2021-03-29 21:28:46', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `idrol` int(11) NOT NULL,
  `rol` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`idrol`, `rol`) VALUES
(1, 'Administrador'),
(2, 'Supervisor'),
(3, 'Vendedor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `idusuario` int(11) NOT NULL,
  `nombre` varchar(50) DEFAULT NULL,
  `correo` varchar(30) DEFAULT NULL,
  `usuario` varchar(15) DEFAULT NULL,
  `clave` varchar(100) DEFAULT NULL,
  `rol` int(11) DEFAULT NULL,
  `estatus` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`idusuario`, `nombre`, `correo`, `usuario`, `clave`, `rol`, `estatus`) VALUES
(1, 'Responsable', 'res@hotmail.com', 'admin', '827ccb0eea8a706c4c34a16891f84e7b', 1, 1),
(2, 'Lizett', 'liz@gmail.com', 'lize', '202cb962ac59075b964b07152d234b70', 2, 1),
(3, 'Juanito', 'b@gmail.com', 'juanito', '202cb962ac59075b964b07152d234b70', 1, 1),
(4, 'Angelito', 'ange@gmail.com', 'angelitos', '202cb962ac59075b964b07152d234b70', 3, 1),
(5, 'Carlos', 'carlos@gmail.com', 'charlys', '250cf8b51c773f3f8dc8b4be867a9a02', 3, 1),
(6, 'Daniela', 'd@gmail.com', 'Dani', '202cb962ac59075b964b07152d234b70', 3, 1),
(7, 'Emelio', 'e@gmail.coe', 'eme', '202cb962ac59075b964b07152d234b70', 3, 1),
(8, 'Ruperto', 'ruper@hotmail.com', 'ruper', '827ccb0eea8a706c4c34a16891f84e7b', 3, 1);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`idcliente`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`),
  ADD KEY `nofactura` (`nofactura`);

--
-- Indices de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `nofactura` (`token_user`),
  ADD KEY `codproducto` (`codproducto`);

--
-- Indices de la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD PRIMARY KEY (`correlativo`),
  ADD KEY `codproducto` (`codproducto`);

--
-- Indices de la tabla `factura`
--
ALTER TABLE `factura`
  ADD PRIMARY KEY (`nofactura`),
  ADD KEY `usuario` (`usuario`),
  ADD KEY `codcliente` (`codcliente`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`codproducto`),
  ADD KEY `proveedor` (`proveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`codproveedor`),
  ADD KEY `usuario_id` (`usuario_id`);

--
-- Indices de la tabla `rol`
--
ALTER TABLE `rol`
  ADD PRIMARY KEY (`idrol`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`idusuario`),
  ADD KEY `rol` (`rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `idcliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  MODIFY `correlativo` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=66;

--
-- AUTO_INCREMENT de la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=86;

--
-- AUTO_INCREMENT de la tabla `entradas`
--
ALTER TABLE `entradas`
  MODIFY `correlativo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT de la tabla `factura`
--
ALTER TABLE `factura`
  MODIFY `nofactura` bigint(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `codproducto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `codproveedor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `rol`
--
ALTER TABLE `rol`
  MODIFY `idrol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `idusuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `cliente_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`);

--
-- Filtros para la tabla `detallefactura`
--
ALTER TABLE `detallefactura`
  ADD CONSTRAINT `detallefactura_ibfk_1` FOREIGN KEY (`nofactura`) REFERENCES `factura` (`nofactura`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detallefactura_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_temp`
--
ALTER TABLE `detalle_temp`
  ADD CONSTRAINT `detalle_temp_ibfk_2` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `entradas`
--
ALTER TABLE `entradas`
  ADD CONSTRAINT `entradas_ibfk_1` FOREIGN KEY (`codproducto`) REFERENCES `producto` (`codproducto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `factura`
--
ALTER TABLE `factura`
  ADD CONSTRAINT `factura_ibfk_1` FOREIGN KEY (`usuario`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `factura_ibfk_2` FOREIGN KEY (`codcliente`) REFERENCES `cliente` (`idcliente`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `producto_ibfk_1` FOREIGN KEY (`proveedor`) REFERENCES `proveedor` (`codproveedor`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `producto_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `proveedor`
--
ALTER TABLE `proveedor`
  ADD CONSTRAINT `proveedor_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`idusuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `usuario_ibfk_1` FOREIGN KEY (`rol`) REFERENCES `rol` (`idrol`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
