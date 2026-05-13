# UF1890 — Ejercicio 1: Data Warehouse con PostgreSQL

Proyecto de construcción de un Data Warehouse (DW) a partir de datos de un ERP basado en Odoo/PostgreSQL. Incluye la creación del esquema, las tablas dimensionales y de hechos, el proceso ETL completo y consultas de análisis.

---

## Origen de datos

Las tablas fuente se encuentran en el esquema `public` del ERP:

| Tabla fuente          | Descripción                              |
|-----------------------|------------------------------------------|
| `res_partner`         | Clientes y contactos                     |
| `sale_order`          | Cabeceras de pedidos de venta            |
| `sale_order_line`     | Líneas de detalle de cada pedido         |
| `product_product`     | Variantes de producto                    |
| `product_template`    | Plantillas base de producto              |
| `product_category`    | Categorías de producto                   |

---

## Estructura del Data Warehouse

El DW se aloja en el esquema `dw` con un modelo en estrella:

### Dimensiones

**`dw.dim_cliente`**
| Columna          | Tipo      | Descripción                        |
|------------------|-----------|------------------------------------|
| `id_cliente`     | SERIAL PK | Clave subrogada                    |
| `nombre`         | TEXT      | Nombre del cliente                 |
| `ciudad`         | TEXT      | Ciudad (por defecto: *Sin ciudad*) |
| `erp_partner_id` | INTEGER   | ID original en `res_partner`       |

**`dw.dim_producto`**
| Columna        | Tipo      | Descripción                              |
|----------------|-----------|------------------------------------------|
| `id_producto`  | SERIAL PK | Clave subrogada                          |
| `nombre`       | TEXT      | Nombre del producto                      |
| `categoria`    | TEXT      | Categoría (por defecto: *Sin categoría*) |
| `erp_tmpl_id`  | INTEGER   | ID original en `product_template`        |

### Tabla de hechos

**`dw.fact_ventas`**
| Columna      | Tipo    | Descripción                          |
|--------------|---------|--------------------------------------|
| `id_venta`   | SERIAL PK | Clave subrogada                    |
| `id_cliente` | INT     | FK → `dim_cliente`                   |
| `id_producto`| INT     | FK → `dim_producto`                  |
| `fecha`      | DATE    | Fecha del pedido                     |
| `cantidad`   | INT     | Unidades vendidas                    |
| `precio`     | NUMERIC | Precio unitario en el momento de venta |
| `total`      | NUMERIC | `cantidad × precio`                  |

---

## Proceso ETL

Los scripts SQL se ejecutan en el siguiente orden:

### 1. `crear_schema.sql`
Crea el esquema `dw` si no existe:
```sql
CREATE SCHEMA IF NOT EXISTS dw;
```

### 2. `crear_tablas.sql`
Crea las tres tablas del DW usando `IF NOT EXISTS` para evitar errores en ejecuciones repetidas.

### 3. `extraccion.sql`
Ejecuta el ciclo ETL completo:

1. **Limpieza** — `TRUNCATE` con `RESTART IDENTITY CASCADE` en las tres tablas para garantizar una carga limpia.
2. **Extracción y transformación de `dim_cliente`** — Selecciona clientes únicos desde `res_partner`, aplica `COALESCE` para sustituir ciudades nulas.
3. **Extracción y transformación de `dim_producto`** — Selecciona productos distintos desde `product_template` con `LEFT JOIN` a `product_category`, aplica `COALESCE` para categorías nulas.
4. **Carga de `fact_ventas`** — Cruza `sale_order_line` con `sale_order` y las dimensiones ya cargadas; calcula `total = cantidad × precio_unitario`. Filtra registros con fecha nula, cantidad ≤ 0 o precio nulo.
5. **Verificación** — Muestra el recuento de registros de cada tabla y una muestra de `fact_ventas`.

### 4. `consultas_analisis.sql`
Consultas de negocio sobre el DW:

```sql
-- Total de ventas por cliente
SELECT c.nombre, SUM(f.total) AS total_ventas
FROM dw.fact_ventas f
JOIN dw.dim_cliente c ON f.id_cliente = c.id_cliente
GROUP BY c.nombre;

-- Total de ventas por producto
SELECT p.nombre, SUM(f.total) AS total_ventas
FROM dw.fact_ventas f
JOIN dw.dim_producto p ON f.id_producto = p.id_producto
GROUP BY p.nombre;

-- Venta global
SELECT SUM(total) AS total_global FROM dw.fact_ventas;
```

---

## Estructura de archivos

```
UF1890_E1_RafaelMartin/
├── documentacion/
│   └── README.md
├── sql/
│   ├── crear_schema.sql      # Paso 1 — Crear esquema dw
│   ├── crear_tablas.sql      # Paso 2 — Crear tablas dimensionales y de hechos
│   ├── extraccion.sql        # Paso 3 — ETL completo (limpieza + carga)
│   └── consultas_analisis.sql # Paso 4 — Consultas de análisis
└── capturas/
```

---

## Requisitos

- PostgreSQL con acceso al esquema `public` del ERP (Odoo o compatible)
- Permisos de lectura sobre las tablas fuente
- Permisos de escritura en el esquema `dw`
