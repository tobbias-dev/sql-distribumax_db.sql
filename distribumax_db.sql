-- =====================================================================
-- DistribuMax S.A. - Sistema de Gestion de Inventario y Logistica
-- Script de creacion de base de datos, tablas, inserciones, consultas
-- y borrado de registros.
-- Autor: Tobias Uriel Barmaimon Molina
-- Materia: Seminario de Practica de Informatica - TP2
-- Universidad Siglo 21 - Profesor: Pablo A. Virgolini
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Creacion de la base de datos
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS distribumax_db;
CREATE DATABASE distribumax_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE distribumax_db;

-- ---------------------------------------------------------------------
-- 2. Creacion de tablas
-- ---------------------------------------------------------------------
CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre       VARCHAR(80)  NOT NULL UNIQUE,
    descripcion  VARCHAR(255)
);

CREATE TABLE productos (
    id_producto      INT AUTO_INCREMENT PRIMARY KEY,
    nombre           VARCHAR(120) NOT NULL,
    descripcion      VARCHAR(255),
    precio_unitario  DECIMAL(10,2) NOT NULL,
    id_categoria     INT NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

CREATE TABLE stock (
    id_stock      INT AUTO_INCREMENT PRIMARY KEY,
    id_producto   INT NOT NULL UNIQUE,
    cantidad      INT NOT NULL DEFAULT 0,
    stock_minimo  INT NOT NULL DEFAULT 0,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre     VARCHAR(120) NOT NULL,
    direccion  VARCHAR(255),
    telefono   VARCHAR(30),
    email      VARCHAR(120)
);

CREATE TABLE usuarios (
    id_usuario     INT AUTO_INCREMENT PRIMARY KEY,
    usuario        VARCHAR(40) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    nombre         VARCHAR(120) NOT NULL,
    rol            ENUM('ADMIN','VENDEDOR','OPERADOR','TRANSPORTISTA') NOT NULL
);

CREATE TABLE vehiculos (
    id_vehiculo INT AUTO_INCREMENT PRIMARY KEY,
    patente     VARCHAR(15) NOT NULL UNIQUE,
    capacidad   DECIMAL(10,2) NOT NULL,
    estado      VARCHAR(30) NOT NULL DEFAULT 'DISPONIBLE'
);

CREATE TABLE rutas_entrega (
    id_ruta          INT AUTO_INCREMENT PRIMARY KEY,
    fecha            DATE NOT NULL,
    estado           VARCHAR(30) NOT NULL DEFAULT 'PLANIFICADA',
    id_vehiculo      INT NOT NULL,
    id_transportista INT NOT NULL,
    FOREIGN KEY (id_vehiculo)      REFERENCES vehiculos(id_vehiculo),
    FOREIGN KEY (id_transportista) REFERENCES usuarios(id_usuario)
);

CREATE TABLE pedidos (
    id_pedido   INT AUTO_INCREMENT PRIMARY KEY,
    fecha       DATETIME NOT NULL,
    estado      ENUM('PENDIENTE','EN_PREPARACION','EN_TRANSITO',
                     'ENTREGADO','CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
    total       DECIMAL(12,2) NOT NULL DEFAULT 0,
    id_cliente  INT NOT NULL,
    id_ruta     INT NULL,
    id_vendedor INT NOT NULL,
    FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_ruta)     REFERENCES rutas_entrega(id_ruta),
    FOREIGN KEY (id_vendedor) REFERENCES usuarios(id_usuario)
);

CREATE TABLE detalle_pedido (
    id_detalle      INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido       INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido)   REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- ---------------------------------------------------------------------
-- 3. Insercion de datos de prueba
-- ---------------------------------------------------------------------
INSERT INTO categorias (nombre, descripcion) VALUES
  ('Almacen',  'Productos secos de almacen'),
  ('Bebidas',  'Bebidas con y sin alcohol'),
  ('Limpieza', 'Productos de limpieza e higiene');

INSERT INTO productos (nombre, descripcion, precio_unitario, id_categoria) VALUES
  ('Yerba 1kg',     'Yerba mate molida',     1500.00, 1),
  ('Aceite 1.5L',   'Aceite de girasol',     2800.00, 1),
  ('Gaseosa 2.25L', 'Gaseosa cola',          1800.00, 2),
  ('Lavandina 1L',  'Lavandina concentrada',  900.00, 3);

INSERT INTO stock (id_producto, cantidad, stock_minimo) VALUES
  (1, 85, 20),
  (2, 12, 20),
  (3, 60, 25),
  (4, 30, 10);

INSERT INTO clientes (nombre, direccion, telefono, email) VALUES
  ('Almacen El Sol',  'Av. Illia 123',  '2664-111111', 'elsol@mail.com'),
  ('Supermini Norte', 'Junin 456',      '2664-222222', 'norte@mail.com');

INSERT INTO usuarios (usuario, password_hash, nombre, rol) VALUES
  ('admin',    'hash_admin', 'Administrador General', 'ADMIN'),
  ('vendedor1','hash_vend1', 'Juan Perez',            'VENDEDOR'),
  ('chofer1',  'hash_chof1', 'Carlos Ruiz',           'TRANSPORTISTA');

INSERT INTO vehiculos (patente, capacidad, estado) VALUES
  ('AA123BB', 1500.00, 'DISPONIBLE'),
  ('CC456DD',  900.00, 'DISPONIBLE');

INSERT INTO pedidos (fecha, estado, total, id_cliente, id_vendedor) VALUES
  ('2026-05-15 10:30:00', 'PENDIENTE', 10100.00, 1, 2);

INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario) VALUES
  (1, 1, 3, 1500.00),
  (1, 2, 2, 2800.00);

-- ---------------------------------------------------------------------
-- 4. Consultas representativas
-- ---------------------------------------------------------------------

-- 4.1. Productos con stock por debajo del minimo (RF03)
SELECT p.id_producto, p.nombre, s.cantidad, s.stock_minimo
FROM productos p
JOIN stock s ON s.id_producto = p.id_producto
WHERE s.cantidad <= s.stock_minimo;

-- 4.2. Detalle completo de un pedido con cliente y subtotales
SELECT  c.nombre AS cliente,
        p.id_pedido,
        pr.nombre AS producto,
        d.cantidad,
        d.precio_unitario,
        (d.cantidad * d.precio_unitario) AS subtotal,
        p.estado,
        p.total
FROM pedidos p
JOIN clientes c        ON c.id_cliente   = p.id_cliente
JOIN detalle_pedido d  ON d.id_pedido    = p.id_pedido
JOIN productos pr      ON pr.id_producto = d.id_producto
WHERE p.id_pedido = 1;

-- 4.3. Reporte de ventas por categoria en un periodo (RF08)
SELECT cat.nombre AS categoria,
       SUM(d.cantidad * d.precio_unitario) AS total_vendido
FROM detalle_pedido d
JOIN productos pr   ON pr.id_producto  = d.id_producto
JOIN categorias cat ON cat.id_categoria = pr.id_categoria
JOIN pedidos p      ON p.id_pedido     = d.id_pedido
WHERE p.fecha BETWEEN '2026-05-01' AND '2026-05-31'
  AND p.estado <> 'CANCELADO'
GROUP BY cat.nombre
ORDER BY total_vendido DESC;

-- 4.4. Listado de pedidos pendientes con datos del cliente
SELECT p.id_pedido, p.fecha, p.estado, p.total, c.nombre
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
WHERE p.estado = 'PENDIENTE'
ORDER BY p.fecha ASC;

-- ---------------------------------------------------------------------
-- 5. Borrado de registros (respetando integridad referencial)
-- ---------------------------------------------------------------------
DELETE FROM detalle_pedido WHERE id_pedido = 1;
DELETE FROM pedidos        WHERE id_pedido = 1;

-- Verificacion
SELECT * FROM pedidos;
SELECT * FROM detalle_pedido;

-- =====================================================================
-- Fin del script
-- =====================================================================
