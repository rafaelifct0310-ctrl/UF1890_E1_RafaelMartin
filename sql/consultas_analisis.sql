-- Ventas por clientes
SELECT c.nombre, SUM(f.total) AS total_ventas
FROM dw.fact_ventas f
JOIN dw.dim_cliente c ON f.id_cliente = c.id_cliente
GROUP BY c.nombre;

-- Ventas por producto
SELECT p.nombre, SUM(f.total) AS total_ventas
FROM dw.fact_ventas f
JOIN dw.dim_producto p ON f.id_producto = p.id_producto
GROUP BY p.nombre;

-- Ventas totales
SELECT SUM(total) AS total_global
FROM dw.fact_ventas;