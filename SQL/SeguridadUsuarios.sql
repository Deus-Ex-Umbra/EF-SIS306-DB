-- 1. Crear ROL ADMINISTRADOR (DBA del Proyecto)
-- Tiene control total sobre las tablas y datos.
CREATE ROLE ROL_ADMIN_LIBRERIA;
GRANT ALL PRIVILEGES ON Cliente TO ROL_ADMIN_LIBRERIA;
GRANT ALL PRIVILEGES ON Pedido TO ROL_ADMIN_LIBRERIA;
GRANT ALL PRIVILEGES ON DetallePedido TO ROL_ADMIN_LIBRERIA;
GRANT ALL PRIVILEGES ON Libro TO ROL_ADMIN_LIBRERIA;
-- ... dar permisos al resto de tablas

-- 2. Crear ROL VENDEDOR (Operativo)
-- Puede registrar clientes, crear pedidos y consultar inventario. 
-- NO puede borrar historiales ni alterar configuraciones de sistema.
CREATE ROLE ROL_VENDEDOR;
GRANT SELECT, INSERT, UPDATE ON Cliente TO ROL_VENDEDOR;
GRANT SELECT, INSERT ON Ubicacion TO ROL_VENDEDOR;
GRANT SELECT, INSERT, UPDATE ON Pedido TO ROL_VENDEDOR;
GRANT SELECT, INSERT ON DetallePedido TO ROL_VENDEDOR;
GRANT SELECT ON v_catalogo_libros TO ROL_VENDEDOR;
GRANT EXECUTE ON sp_crear_pedido TO ROL_VENDEDOR;
GRANT EXECUTE ON sp_agregar_detalle_pedido TO ROL_VENDEDOR;

-- 3. Crear ROL AUDITOR (Solo Lectura)
-- Solo puede ver datos y reportes, no puede modificar nada.
CREATE ROLE ROL_AUDITOR;
GRANT SELECT ON v_reporte_general_ventas TO ROL_AUDITOR;
GRANT SELECT ON v_historial_precios TO ROL_AUDITOR;
GRANT SELECT ON HistoricoEstadoPedido TO ROL_AUDITOR;

-- EJEMPLO DE ASIGNACIÓN (Simulado):
-- CREATE USER JuanVendedor IDENTIFIED BY Password123;
-- GRANT CREATE SESSION TO JuanVendedor;
-- GRANT ROL_VENDEDOR TO JuanVendedor;