--VISTAS
-- VISTA 1: Pedidos Completos
CREATE OR REPLACE VIEW v_pedidos_completo AS
SELECT p.id_pedido, p.fecha, c.nombre_completo, c.correo_electronico,
       cc.nombre_ciudad AS ciudad, u.direccion,
       ce.nombre_estado, p.fecha_ult_cambio,
       COUNT(dp.id_detalle) as items, SUM(dp.cantidad * dp.precio_unitario) as total
FROM Pedido p
JOIN Cliente c ON p.id_cliente = c.id_cliente
JOIN Ubicacion u ON c.id_ubicacion = u.id_ubicacion
JOIN CatCiudad cc ON u.id_ciudad = cc.id_ciudad  -- JOIN NUEVO
JOIN CatEstado ce ON p.id_estado_actual = ce.id_estado
LEFT JOIN DetallePedido dp ON p.id_pedido = dp.id_pedido
GROUP BY p.id_pedido, p.fecha, c.nombre_completo, c.correo_electronico, 
         cc.nombre_ciudad, u.direccion, ce.nombre_estado, p.fecha_ult_cambio;

-- VISTA 2: Catálogo de Libros (Con Género)

CREATE OR REPLACE VIEW v_catalogo_libros AS
SELECT 
    l.id_libro, 
    l.titulo,        -- <--- ESTE CAMPO ES EL IMPORTANTE
    cg.nombre_genero AS genero, 
    l.autor, 
    hp.precio
FROM Libro l
JOIN CatGenero cg ON l.id_genero = cg.id_genero 
JOIN HistoricoPrecio hp ON l.id_libro = hp.id_libro AND hp.vigente = '1';

-- VISTA 3: Ventas por Ciudad
CREATE OR REPLACE VIEW v_ventas_por_ciudad AS
SELECT cc.nombre_ciudad, COUNT(DISTINCT p.id_pedido) as pedidos, 
       SUM(dp.cantidad * dp.precio_unitario) as total_ventas
FROM CatCiudad cc
JOIN Ubicacion u ON cc.id_ciudad = u.id_ciudad
JOIN Cliente c ON u.id_ubicacion = c.id_ubicacion
JOIN Pedido p ON c.id_cliente = p.id_cliente
JOIN DetallePedido dp ON p.id_pedido = dp.id_pedido
GROUP BY cc.nombre_ciudad
ORDER BY total_ventas DESC;

-- VISTA 4 (Simple): Lista de Ciudades Disponibles 
CREATE OR REPLACE VIEW v_lista_ciudades AS SELECT * FROM CatCiudad ORDER BY nombre_ciudad;

-- VISTA 5 (Simple): Lista de Géneros Disponibles
CREATE OR REPLACE VIEW v_lista_generos AS SELECT * FROM CatGenero ORDER BY nombre_genero;

--VISTA 6: Lista de clientes
CREATE OR REPLACE VIEW v_lista_clientes AS
SELECT 
    c.id_cliente,
    c.nombre_completo AS nombre,
    c.correo_electronico AS correo,
    u.direccion,
    cc.nombre_ciudad,
    u.id_ciudad -- Útil si necesitamos pre-cargar el select de edición en el futuro
FROM Cliente c
JOIN Ubicacion u ON c.id_ubicacion = u.id_ubicacion
JOIN CatCiudad cc ON u.id_ciudad = cc.id_ciudad
ORDER BY c.id_cliente DESC;