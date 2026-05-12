-- ********************************
-- LIMPIEZA TOTAL
-- ********************************

-- TRUNCATE elimina todos los registros de las tablas
-- RESTART IDENTITY reinicia los contadores de IDs automáticos
-- CASCADE elimina también las dependencias (claves foráneas)
TRUNCATE TABLE dw.dim_cliente RESTART IDENTITY CASCADE;

-- Eliminamos todos los productos existentes para empezar desde cero
TRUNCATE TABLE dw.dim_producto RESTART IDENTITY CASCADE;

-- Eliminamos todas las ventas existentes
-- Nota: fact_ventas no tiene CASCADE porque está al final de la cadena
TRUNCATE TABLE dw.fact_ventas RESTART IDENTITY;

-- ********************************
-- DIM_CLIENTE
-- ********************************

-- INSERT INTO selecciona los clientes únicos desde la tabla origen 'res_partner'
-- La tabla dim_cliente es nuestra dimensión, almacena descripciones del negocio
INSERT INTO dw.dim_cliente (nombre, ciudad, erp_partner_id)

-- SELECT extrae los datos transformándolos ligeramente
SELECT 
    -- Tomamos el nombre directamente del sistema origen
    rp.name AS nombre,
    
    -- COALESCE: si ciudad es NULL, usamos 'Sin ciudad' como valor por defecto
    -- Esto evita valores nulos en nuestra dimensión
    COALESCE(rp.city, 'Sin ciudad') AS ciudad,
    
    -- Guardamos el ID original del ERP como referencia (cliente natural)
    -- Esto nos permite conectar con la tabla de hechos después
    rp.id AS erp_partner_id
    
FROM public.res_partner rp

-- Filtramos: solo clientes que tienen nombre (evitamos registros vacíos)
WHERE rp.name IS NOT NULL

-- ORDER BY asegura un orden consistente en la inserción
-- No afecta la funcionalidad, solo la presentación
ORDER BY rp.id;

-- ********************************
-- DIM_PRODUCTO
-- ********************************

-- Cargamos la dimensión de productos desde las tablas de productos del ERP
INSERT INTO dw.dim_producto (nombre, categoria, erp_tmpl_id)

-- DISTINCT elimina duplicados por si un mismo template aparece varias veces
SELECT DISTINCT
    -- Nombre del producto desde la plantilla base
    pt.name AS nombre,
    
    -- Categoría: si no tiene, asignamos 'Sin categoría'
    -- LEFT JOIN permite que productos sin categoría también se carguen
    COALESCE(pc.name, 'Sin categoría') AS categoria,
    
    -- ID original de la plantilla para futuras relaciones
    pt.id AS erp_tmpl_id
    
FROM public.product_template pt

-- LEFT JOIN: trae TODOS los productos, tengan o no categoría
-- Si no hay categoría, pc.name será NULL (lo manejamos con COALESCE)
LEFT JOIN public.product_category pc ON pt.categ_id = pc.id

-- Solo productos con nombre definido
WHERE pt.name IS NOT NULL;

-- ********************************
-- FACT_VENTAS
-- ********************************

-- La tabla de hechos almacena los eventos de negocio (transacciones)
-- Cada fila representa una línea de venta individual
INSERT INTO dw.fact_ventas (id_cliente, id_producto, fecha, cantidad, precio, total)

SELECT 
    -- Buscamos el ID de la dimensión usando el ERP ID que guardamos antes
    c.id_cliente,
    
    -- Buscamos el ID del producto de la misma forma
    p.id_producto,
    
    -- Convertimos timestamp a solo fecha (importante para agrupar por día)
    DATE(so.date_order) AS fecha,
    
    -- Cantidad de unidades vendidas (viene de la línea de venta)
    sol.product_uom_qty AS cantidad,
    
    -- Precio unitario en el momento de la venta
    sol.price_unit AS precio,
    
    -- Calculamos el total: cantidad × precio unitario
    (sol.product_uom_qty * sol.price_unit) AS total
    
FROM public.sale_order_line sol

-- INNER JOIN con sale_order: necesitamos la fecha y el cliente
-- Solo incluimos líneas que tengan su cabecera de pedido
INNER JOIN public.sale_order so ON sol.order_id = so.id

-- INNER JOIN con dim_cliente: solo ventas de clientes que existen en nuestra dimensión
-- Usamos erp_partner_id como puente de conexión
INNER JOIN dw.dim_cliente c ON c.erp_partner_id = so.partner_id

-- INNER JOIN con dim_producto: solo productos que existen en nuestra dimensión
-- Conectamos por el ID de plantilla del ERP
INNER JOIN dw.dim_producto p ON p.erp_tmpl_id = sol.product_id

-- Filtros de calidad de datos:
WHERE so.date_order IS NOT NULL      -- Fecha válida
  AND sol.product_uom_qty > 0        -- Cantidad positiva (ventas reales)
  AND sol.price_unit IS NOT NULL;    -- Precio definido

-- ********************************
-- VERIFICACIÓN RÁPIDA
-- ********************************

-- UNION ALL combina los resultados de múltiples SELECT en una sola tabla
-- Esto nos da un resumen rápido de cuántos registros tiene cada tabla
SELECT 'Clientes' as Tabla, COUNT(*) as Total FROM dw.dim_cliente
UNION ALL
SELECT 'Productos', COUNT(*) FROM dw.dim_producto
UNION ALL
SELECT 'Ventas', COUNT(*) FROM dw.fact_ventas;

-- Ver una muestra de los datos cargados en la tabla de hechos
-- LIMIT 10 evita mostrar demasiadas filas en pantalla
SELECT * FROM dw.fact_ventas LIMIT 10;