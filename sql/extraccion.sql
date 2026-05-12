-- **************************
-- Carga de Dimensión Cliente
-- **************************

INSERT INTO dw.dim_cliente (
	nombre,
	ciudad
)
SELECT DISTINCT
	COALESCE(rp.name, 'Cliente sin nombre') AS nombre,
	COALESCE(rp.city, 'Sin ciudad') AS ciudad
FROM public.res_partner rp
WHER rp.name IS NOT NULL;

-- ***************************
-- Cargar Dimensión Producto
-- ***************************

INSERT INTO dw.dim_producto (
	nombre,
	categoria
)
SELECT DISTINCT
	COALESCE(pt.name::TEXT, 'Producto sin nombre') AS nombre,
	COALESCE(pc.name::TEXT, 'Sin categoria') AS categoria
FROM public.product_template pt
LEFT JOIN public.product_category pc
	ON pt.categ_id = pc.id
WHERE pt.name IS NOT NULL;



-- **********************************************
-- Extracción + Transformación + Carga de Hechos
-- **********************************************
INSERT INTO dw.fact_ventas (
	id_cliente,
	id_producto,
	fecha,
	cantidad,
	precio,
	total
)
SELECT 
	c.id_cliente,
	p.id_producto,
	t.fecha,
	t.cantidad,
	t.precio,
	t.total
FROM (

	-- ********************************
	-- Extracción desde tablas del ERP
	-- ********************************
	SELECT 
		COALESCE(rp.name, 'Cliente sin nombre') AS cliente,
		COALESCE(pt.name, 'Producto sin nombre') AS producto,
		COALESCE(sol.product_uom_qty, 0) AS cantidad,
		COALESCE(sol.price_unit, 0) AS precio,
		COALESCE(sol.product_uom_qty, 0)
		* COALESCE(sol.price_unit, 0) AS total,
		DATE(so.date_order) AS fecha
	FROM public.sale_order_line sol
	JOIN public.sale_order so 
		ON sol.order_id = so.id
	JOIN public.res_partner rp 
		ON so.partner_id = rp.id
	JOIN public.product_product pp 
		ON sol.product_id = pp.id
	JOIN public.product_template pt 
		ON pp.product_tmpl_id = pt.id
	WHERE so.date_order IS NOT NULL
) t

-- relación con dimensiones

JOIN dw.dim_cliente c
	ON c.nombre = t.cliente

JOIN dw.dim_producto p
	ON p.nombre = t.producto;

-- ******************************
-- Comprobaciones del proceso ETL
-- ******************************

-- Comprobar clientes cargados
SELECT COUNT(*) AS total_clientes
FROM dw.dim_clientes;

-- Comprobar productos cargados
SELECT COUNT(*) AS total_productos
FROM dw.dim_producto;

-- Comprobar ventas
SELECT COUNT(*) AS total_ventas
FROM dw.fact_ventas;

-- Ver los primero registros de la tabla de hechos
SELECT *
FROM dw.fact_ventas
LIMIT 10;

-- Comprobar total global de ventas
SELECT SUM(total) AS importe_total_ventas
FROM dw.fact_ventas;

-- Comprobar posibles errores de carga
SELECT *
FROM dw.fact_ventas
WHERE total IS NULL
	OR cantidad < 0
	OR precio < 0;