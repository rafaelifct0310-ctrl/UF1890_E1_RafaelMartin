CREATE TABLE IF NOT EXISTS dw.dim_cliente (
	id_cliente SERIAL PRIMARY KEY,
	nombre TEXT,
	ciudad TEXT,
	erp_partner_id INTEGER
);

CREATE TABLE IF NOT EXISTS dw.dim_producto (
	id_producto SERIAL PRIMARY KEY,
	nombre TEXT,
	categoria TEXT,
	erp_tmpl_id    INTEGER
);

CREATE TABLE IF NOT EXISTS dw.fact_ventas (
	id_venta SERIAL PRIMARY KEY,
	id_cliente INT,
	id_producto INT,
	fecha DATE,
	cantidad INT,
	precio NUMERIC,
	total NUMERIC
)
