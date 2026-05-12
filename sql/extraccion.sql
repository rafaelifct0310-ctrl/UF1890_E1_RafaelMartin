-- ********************************
-- LIMPIEZA TOTAL
-- ********************************
TRUNCATE TABLE dw.dim_cliente RESTART IDENTITY CASCADE;
TRUNCATE TABLE dw.dim_producto RESTART IDENTITY CASCADE;
TRUNCATE TABLE dw.fact_ventas RESTART IDENTITY;

-- ********************************
-- DIM_CLIENTE
-- ********************************
INSERT INTO dw.dim_cliente (nombre, ciudad, erp_partner_id)
SELECT 
    rp.name AS nombre,
    COALESCE(rp.city, 'Sin ciudad') AS ciudad,
    rp.id AS erp_partner_id
FROM public.res_partner rp
WHERE rp.name IS NOT NULL
ORDER BY rp.id;

-- ********************************
-- DIM_PRODUCTO
-- ********************************
INSERT INTO dw.dim_producto (nombre, categoria, erp_tmpl_id)
SELECT DISTINCT
    pt.name AS nombre,
    COALESCE(pc.name, 'Sin categoría') AS categoria,
    pt.id AS erp_tmpl_id
FROM public.product_template pt
LEFT JOIN public.product_category pc ON pt.categ_id = pc.id
WHERE pt.name IS NOT NULL;

-- ********************************
-- FACT_VENTAS
-- ********************************
INSERT INTO dw.fact_ventas (id_cliente, id_producto, fecha, cantidad, precio, total)
SELECT 
    c.id_cliente,
    p.id_producto,
    DATE(so.date_order) AS fecha,
    sol.product_uom_qty AS cantidad,
    sol.price_unit AS precio,
    (sol.product_uom_qty * sol.price_unit) AS total
FROM public.sale_order_line sol
INNER JOIN public.sale_order so ON sol.order_id = so.id
INNER JOIN dw.dim_cliente c ON c.erp_partner_id = so.partner_id
INNER JOIN dw.dim_producto p ON p.erp_tmpl_id = sol.product_id
WHERE so.date_order IS NOT NULL
  AND sol.product_uom_qty > 0
  AND sol.price_unit IS NOT NULL;

-- ********************************
-- VERIFICACIÓN RÁPIDA
-- ********************************
SELECT 'Clientes' as Tabla, COUNT(*) as Total FROM dw.dim_cliente
UNION ALL
SELECT 'Productos', COUNT(*) FROM dw.dim_producto
UNION ALL
SELECT 'Ventas', COUNT(*) FROM dw.fact_ventas;

-- Ver muestra de fact_ventas
SELECT * FROM dw.fact_ventas LIMIT 10;