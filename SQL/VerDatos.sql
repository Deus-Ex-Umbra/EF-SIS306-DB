-- CLIENTES CON SUS UBICACIONES ---
SELECT c.id_cliente, c.nombre_completo, c.correo_electronico, 
       u.ciudad, u.direccion
FROM Cliente c
JOIN Ubicacion u ON c.id_ubicacion = u.id_ubicacion
ORDER BY c.id_cliente;

-- LIBROS CON PRECIO VIGENTE ---
SELECT l.id_libro, l.autor, l.genero, hp.precio AS precio_actual
FROM Libro l
JOIN HistoricoPrecio hp ON l.id_libro = hp.id_libro
WHERE hp.vigente = '1'
ORDER BY l.id_libro;

-- RESUMEN DE PEDIDOS ---
SELECT p.id_pedido, 
       c.nombre_completo AS cliente,
       TO_CHAR(p.fecha, 'DD/MM/YYYY HH24:MI:SS') AS fecha,
       ce.nombre_estado AS estado_actual,
       COUNT(dp.id_detalle) AS num_libros,
       SUM(dp.cantidad * dp.precio_unitario) AS total
FROM Pedido p
JOIN Cliente c ON p.id_cliente = c.id_cliente
JOIN CatEstado ce ON p.id_estado_actual = ce.id_estado
LEFT JOIN DetallePedido dp ON p.id_pedido = dp.id_pedido
GROUP BY p.id_pedido, c.nombre_completo, p.fecha, ce.nombre_estado
ORDER BY p.id_pedido;

-- HISTÓRICO DE ESTADOS ---
SELECT hep.id_pedido,
       ce.nombre_estado,
       TO_CHAR(hep.fecha_cambio, 'DD/MM/YYYY HH24:MI:SS') AS fecha,
       hep.observaciones
FROM HistoricoEstadoPedido hep
JOIN CatEstado ce ON hep.id_estado = ce.id_estado
ORDER BY hep.id_pedido, hep.fecha_cambio;

-- HISTÓRICO DE PRECIOS ---
SELECT hp.id_libro,
       l.autor,
       hp.precio,
       TO_CHAR(hp.fecha_inicio, 'DD/MM/YYYY HH24:MI:SS') AS vigente_desde,
       TO_CHAR(hp.fecha_fin, 'DD/MM/YYYY HH24:MI:SS') AS vigente_hasta,
       CASE WHEN hp.vigente = '1' THEN 'SÍ' ELSE 'NO' END AS vigente
FROM HistoricoPrecio hp
JOIN Libro l ON hp.id_libro = l.id_libro
ORDER BY hp.id_libro, hp.fecha_inicio;