-- ÍNDICES DE RENDIMIENTO

CREATE INDEX idx_cliente_correo ON Cliente(correo_electronico);
CREATE INDEX idx_pedido_fecha ON Pedido(fecha);
CREATE INDEX idx_pedido_estado ON Pedido(id_estado_actual);
CREATE INDEX idx_detalle_pedido ON DetallePedido(id_pedido);
CREATE INDEX idx_hist_precio_libro ON HistoricoPrecio(id_libro);
CREATE INDEX idx_hist_precio_vig ON HistoricoPrecio(id_libro, vigente, fecha_inicio);
CREATE INDEX idx_hist_estado_pedido ON HistoricoEstadoPedido(id_pedido);
CREATE INDEX idx_hist_estado_fecha ON HistoricoEstadoPedido(id_pedido, fecha_cambio);


-- 3. PROCEDIMIENTOS ALMACENADOS

-- A. Procedimiento insertar Ubicación (Recibe ID Ciudad)
CREATE OR REPLACE PROCEDURE sp_insertar_ubicacion (
    p_id_ciudad     IN NUMBER,
    p_direccion     IN VARCHAR2,
    p_id_ubicacion  OUT NUMBER
) AS
BEGIN
    INSERT INTO Ubicacion (id_ciudad, direccion)
    VALUES (p_id_ciudad, p_direccion)
    RETURNING id_ubicacion INTO p_id_ubicacion;
    COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20001, SQLERRM);
END;
/

-- B. Procedimiento insertar Cliente
CREATE OR REPLACE PROCEDURE sp_insertar_cliente (
    p_correo_electronico IN VARCHAR2,
    p_nombre_completo    IN VARCHAR2,
    p_id_ubicacion       IN NUMBER,
    p_id_cliente         OUT NUMBER
) AS
BEGIN
    INSERT INTO Cliente (correo_electronico, nombre_completo, id_ubicacion)
    VALUES (p_correo_electronico, p_nombre_completo, p_id_ubicacion)
    RETURNING id_cliente INTO p_id_cliente;
    COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20002, SQLERRM);
END;
/

-- C. Procedimiento insertar Libro (Recibe ID Genero)
CREATE OR REPLACE PROCEDURE sp_insertar_libro (
    p_id_genero  IN NUMBER,
    p_autor      IN VARCHAR2,
    p_titulo     IN VARCHAR2, -- Nuevo parámetro
    p_precio     IN NUMBER,
    p_id_libro   OUT NUMBER
) AS
BEGIN
    -- Insertar libro incluyendo el Título
    INSERT INTO Libro (id_genero, autor, titulo)
    VALUES (p_id_genero, p_autor, p_titulo)
    RETURNING id_libro INTO p_id_libro;
    
    -- Insertar precio inicial
    INSERT INTO HistoricoPrecio (id_libro, precio, fecha_inicio, fecha_fin, vigente)
    VALUES (p_id_libro, p_precio, SYSDATE, NULL, '1');
    
    COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20003, SQLERRM);
END;
/

-- D. Procedimiento Actualizar Precio
CREATE OR REPLACE PROCEDURE sp_actualizar_precio_libro (
    p_id_libro     IN NUMBER,
    p_nuevo_precio IN NUMBER
) AS
BEGIN
    UPDATE HistoricoPrecio SET fecha_fin = SYSDATE, vigente = '0'
    WHERE id_libro = p_id_libro AND vigente = '1';
    
    INSERT INTO HistoricoPrecio (id_libro, precio, fecha_inicio, fecha_fin, vigente)
    VALUES (p_id_libro, p_nuevo_precio, SYSDATE, NULL, '1');
    COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20004, SQLERRM);
END;
/

-- E. Procedimiento Crear Pedido
CREATE OR REPLACE PROCEDURE sp_crear_pedido (
    p_id_cliente  IN NUMBER,
    p_id_pedido   OUT NUMBER
) AS
    v_id_estado_pendiente NUMBER;
BEGIN
    SELECT id_estado INTO v_id_estado_pendiente FROM CatEstado WHERE nombre_estado = 'Pendiente';
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual, fecha_ult_cambio)
    VALUES (p_id_cliente, SYSDATE, v_id_estado_pendiente, SYSDATE)
    RETURNING id_pedido INTO p_id_pedido;
    COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20005, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE sp_cambiar_estado_pedido (
    p_id_pedido   IN NUMBER,
    p_nombre_estado IN VARCHAR2,
    p_observaciones IN VARCHAR2
) AS
    v_id_nuevo_estado NUMBER;
BEGIN
    -- Obtener ID del estado basado en el nombre
    SELECT id_estado INTO v_id_nuevo_estado 
    FROM CatEstado 
    WHERE nombre_estado = p_nombre_estado;

    -- Actualizar el pedido (El trigger se encargará de guardar el histórico)
    UPDATE Pedido 
    SET id_estado_actual = v_id_nuevo_estado,
        fecha_ult_cambio = SYSDATE
    WHERE id_pedido = p_id_pedido;

    COMMIT;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20015, 'Estado no encontrado: ' || p_nombre_estado);
    WHEN OTHERS THEN 
        ROLLBACK; 
        RAISE_APPLICATION_ERROR(-20016, SQLERRM);
END;
/

-- F. Procedimiento Detalle Pedido
CREATE OR REPLACE PROCEDURE sp_agregar_detalle_pedido (
    p_id_pedido  IN NUMBER,
    p_id_libro   IN NUMBER,
    p_cantidad   IN NUMBER
) AS
    v_precio_actual NUMBER(12,2);
BEGIN
    SELECT precio INTO v_precio_actual FROM HistoricoPrecio WHERE id_libro = p_id_libro AND vigente = '1';
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario)
    VALUES (p_id_pedido, p_id_libro, p_cantidad, v_precio_actual);
    COMMIT;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20006, SQLERRM);
END;
/

-- 2. PROCEDIMIENTO PARA BORRAR CLIENTE
-- Nota: Solo borrará si el cliente no tiene pedidos (por integridad referencial)
CREATE OR REPLACE PROCEDURE sp_eliminar_cliente (
    p_id_cliente IN NUMBER
) AS
BEGIN
    DELETE FROM Cliente WHERE id_cliente = p_id_cliente;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Cliente no encontrado');
    END IF;

    COMMIT;
EXCEPTION 
    WHEN OTHERS THEN 
        ROLLBACK;
        -- Capturar error de llave foránea (Integridad)
        IF SQLCODE = -2292 THEN
            RAISE_APPLICATION_ERROR(-20011, 'No se puede borrar: El cliente tiene pedidos asociados.');
        ELSE
            RAISE_APPLICATION_ERROR(-20012, 'Error al eliminar cliente: ' || SQLERRM);
        END IF;
END;
/

CREATE OR REPLACE PROCEDURE sp_obtener_info_pedido (
    p_id_pedido IN NUMBER,
    p_cursor    OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT 
            -- 1. Información del Pedido y Estado
            p.id_pedido,
            p.fecha                 AS fecha_compra,
            ce.nombre_estado        AS estado_pedido,
            
            -- 2. Información del Cliente y Ubicación
            c.nombre_completo       AS cliente,
            c.correo_electronico,
            u.direccion             AS direccion_entrega,
            cc.nombre_ciudad        AS ciudad,
            
            -- 3. Detalle del Libro (Producto) - CORREGIDO
            l.id_libro,
            l.titulo                AS libro_titulo, -- Agregado
            l.autor                 AS libro_autor,
            cg.nombre_genero        AS genero,
            
            -- 4. Finanzas (Cálculos)
            dp.cantidad,
            dp.precio_unitario,
            (dp.cantidad * dp.precio_unitario) AS subtotal_item,
            
            -- 5. Monto Total del Pedido
            SUM(dp.cantidad * dp.precio_unitario) OVER (PARTITION BY p.id_pedido) AS monto_total_pedido

        FROM Pedido p
        JOIN Cliente c          ON p.id_cliente = c.id_cliente
        JOIN Ubicacion u        ON c.id_ubicacion = u.id_ubicacion
        JOIN CatCiudad cc       ON u.id_ciudad = cc.id_ciudad
        JOIN CatEstado ce       ON p.id_estado_actual = ce.id_estado
        JOIN DetallePedido dp   ON p.id_pedido = dp.id_pedido
        JOIN Libro l            ON dp.id_libro = l.id_libro
        JOIN CatGenero cg       ON l.id_genero = cg.id_genero
        
        WHERE p.id_pedido = p_id_pedido;
        
EXCEPTION
    WHEN OTHERS THEN
        IF p_cursor%ISOPEN THEN CLOSE p_cursor; END IF;
        RAISE_APPLICATION_ERROR(-20020, 'Error al obtener info del pedido: ' || SQLERRM);
END;
/

-- VISTA HISTORIAL DE PRECIOS (Necesaria para el reporte)
CREATE OR REPLACE VIEW v_historial_precios AS
SELECT 
    l.id_libro,
    l.titulo AS titulo_libro, -- Corregido: Usa la columna titulo real
    l.autor,                  -- Agregado: Es útil ver también el autor
    cg.nombre_genero,
    hp.precio,
    hp.fecha_inicio,
    hp.fecha_fin,
    CASE WHEN hp.vigente = '1' THEN 'VIGENTE' ELSE 'HISTÓRICO' END AS estado_precio
FROM Libro l
JOIN CatGenero cg ON l.id_genero = cg.id_genero
JOIN HistoricoPrecio hp ON l.id_libro = hp.id_libro
ORDER BY l.id_libro, hp.fecha_inicio DESC;

-- VISTA MAESTRA (Simulación de "Hoja de Cálculo" o Desnormalizada)
-- Esta vista reconstruye toda la información para reportes, equivalente a lo que tenías en SinFN.
CREATE OR REPLACE VIEW v_reporte_general_ventas AS
SELECT 
    p.id_pedido,
    c.nombre_completo AS cliente,
    c.correo_electronico,
    u.direccion || ', ' || cc.nombre_ciudad AS ubicacion_entrega,
    l.titulo AS libro,
    l.autor,
    cg.nombre_genero,
    dp.cantidad,
    dp.precio_unitario,
    (dp.cantidad * dp.precio_unitario) AS subtotal,
    p.fecha AS fecha_pedido,
    ce.nombre_estado AS estado
FROM Pedido p
JOIN Cliente c ON p.id_cliente = c.id_cliente
JOIN Ubicacion u ON c.id_ubicacion = u.id_ubicacion
JOIN CatCiudad cc ON u.id_ciudad = cc.id_ciudad
JOIN DetallePedido dp ON p.id_pedido = dp.id_pedido
JOIN Libro l ON dp.id_libro = l.id_libro
JOIN CatGenero cg ON l.id_genero = cg.id_genero
JOIN CatEstado ce ON p.id_estado_actual = ce.id_estado;

-- VISTA RESUMEN (Simulación 2FN - Cabeceras y Totales)
-- Muestra la información agrupada por pedido, útil para contabilidad.
CREATE OR REPLACE VIEW v_resumen_facturacion AS
SELECT 
    p.id_pedido,
    c.nombre_completo,
    p.fecha,
    COUNT(dp.id_libro) AS items_unicos,
    SUM(dp.cantidad) AS total_libros,
    SUM(dp.cantidad * dp.precio_unitario) AS monto_total_pedido,
    ce.nombre_estado
FROM Pedido p
JOIN Cliente c ON p.id_cliente = c.id_cliente
JOIN DetallePedido dp ON p.id_pedido = dp.id_pedido
JOIN CatEstado ce ON p.id_estado_actual = ce.id_estado
GROUP BY p.id_pedido, c.nombre_completo, p.fecha, ce.nombre_estado;

-- VISTA ANALÍTICA (KPIs de Negocio)
CREATE OR REPLACE VIEW v_kpi_rendimiento AS
SELECT 
    TO_CHAR(p.fecha, 'YYYY-MM') AS mes,
    cg.nombre_genero,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    SUM(dp.cantidad * dp.precio_unitario) AS ingresos_totales
FROM Pedido p
JOIN DetallePedido dp ON p.id_pedido = dp.id_pedido
JOIN Libro l ON dp.id_libro = l.id_libro
JOIN CatGenero cg ON l.id_genero = cg.id_genero
GROUP BY TO_CHAR(p.fecha, 'YYYY-MM'), cg.nombre_genero
ORDER BY mes DESC, ingresos_totales DESC;

-- 4. TRIGGERS (Lógica de negocio y logs)

CREATE OR REPLACE TRIGGER trg_pedido_insert_historico
AFTER INSERT ON Pedido FOR EACH ROW
BEGIN
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio, observaciones)
    VALUES (:NEW.id_pedido, :NEW.id_estado_actual, :NEW.fecha_ult_cambio, 'Estado inicial');
END;
/

CREATE OR REPLACE TRIGGER trg_pedido_update_historico
AFTER UPDATE OF id_estado_actual ON Pedido FOR EACH ROW
WHEN (NEW.id_estado_actual != OLD.id_estado_actual)
BEGIN
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio)
    VALUES (:NEW.id_pedido, :NEW.id_estado_actual, :NEW.fecha_ult_cambio);
END;
/

CREATE OR REPLACE TRIGGER trg_validar_estado_pedido
BEFORE UPDATE ON Pedido FOR EACH ROW
DECLARE v_nombre_estado VARCHAR2(50);
BEGIN
    SELECT nombre_estado INTO v_nombre_estado FROM CatEstado WHERE id_estado = :OLD.id_estado_actual;
    IF v_nombre_estado IN ('Entregado', 'Cancelado') THEN
        RAISE_APPLICATION_ERROR(-20008, 'Pedido finalizado, no se puede modificar.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_validar_detalle_pedido
BEFORE INSERT ON DetallePedido FOR EACH ROW
DECLARE v_nombre_estado VARCHAR2(50);
BEGIN
    SELECT ce.nombre_estado INTO v_nombre_estado FROM Pedido p 
    JOIN CatEstado ce ON p.id_estado_actual = ce.id_estado WHERE p.id_pedido = :NEW.id_pedido;
    IF v_nombre_estado != 'Pendiente' THEN
        RAISE_APPLICATION_ERROR(-20009, 'Solo se agregan items a pedidos Pendientes.');
    END IF;
END;
/

-- G. FUNCIONES
-- Funcion 1: Total gastado por cliente
CREATE OR REPLACE FUNCTION fn_total_gastado_cliente (
    p_id_cliente IN NUMBER
) RETURN NUMBER IS
    v_total NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(dp.cantidad * dp.precio_unitario), 0)
    INTO v_total
    FROM Pedido p
    JOIN DetallePedido dp ON p.id_pedido = dp.id_pedido
    JOIN CatEstado ce ON p.id_estado_actual = ce.id_estado
    WHERE p.id_cliente = p_id_cliente
    AND ce.nombre_estado IN ('Pagado', 'Enviado', 'Entregado'); -- Solo ventas reales
    
    RETURN v_total;
EXCEPTION 
    WHEN OTHERS THEN RETURN 0;
END;
/
-- Función 2: Obtener Precio Actual de un Libro (Para evitar subconsultas repetitivas)
CREATE OR REPLACE FUNCTION fn_obtener_precio_actual (
    p_id_libro IN NUMBER
) RETURN NUMBER IS
    v_precio NUMBER(12,2);
BEGIN
    SELECT precio INTO v_precio 
    FROM HistoricoPrecio 
    WHERE id_libro = p_id_libro AND vigente = '1';
    RETURN v_precio;
EXCEPTION 
    WHEN NO_DATA_FOUND THEN RETURN 0;
END;
/

-- Función 3: Calcular Ventas Totales por Género (Analítica)
CREATE OR REPLACE FUNCTION fn_ventas_por_genero (
    p_nombre_genero IN VARCHAR2
) RETURN NUMBER IS
    v_total NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(dp.cantidad * dp.precio_unitario), 0)
    INTO v_total
    FROM DetallePedido dp
    JOIN Libro l ON dp.id_libro = l.id_libro
    JOIN CatGenero cg ON l.id_genero = cg.id_genero
    WHERE cg.nombre_genero = p_nombre_genero;
    
    RETURN v_total;
END;
/

-- Función 4: Verificar Stock/Disponibilidad (Simulación de regla de negocio)
-- Retorna 1 si se puede vender (ej. menos de 50 unidades vendidas hoy), 0 si no.
CREATE OR REPLACE FUNCTION fn_verificar_limite_diario (
    p_id_libro IN NUMBER
) RETURN NUMBER IS
    v_cantidad_hoy NUMBER;
BEGIN
    SELECT NVL(SUM(dp.cantidad), 0) INTO v_cantidad_hoy
    FROM DetallePedido dp
    JOIN Pedido p ON dp.id_pedido = p.id_pedido
    WHERE dp.id_libro = p_id_libro
    AND TRUNC(p.fecha) = TRUNC(SYSDATE);
    
    IF v_cantidad_hoy >= 50 THEN
        RETURN 0; -- Límite diario alcanzado
    ELSE
        RETURN 1; -- Disponible
    END IF;
END;
/
