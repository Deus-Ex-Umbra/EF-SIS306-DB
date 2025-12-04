SET SERVEROUTPUT ON;

DECLARE
    -- Variables para capturar IDs
    v_id_ciudad     NUMBER;
    v_id_genero     NUMBER;
    v_id_estado_p   NUMBER; -- Pagado
    v_id_estado_pd  NUMBER; -- Pendiente
    v_id_cliente    NUMBER;
    v_id_ubicacion  NUMBER;
    v_id_pedido     NUMBER;
    
    -- Variables para IDs de Libros (Cache simple)
    v_libro_sql_bas NUMBER;
    v_libro_mod_dat NUMBER;
    v_libro_python  NUMBER;
    v_libro_sql_adv NUMBER;
    v_libro_bigdata NUMBER;

    -- Procedimiento Local: Gestionar Ciudad (Busca o Crea)
    PROCEDURE get_create_ciudad(p_nombre IN VARCHAR2, p_id OUT NUMBER) IS
    BEGIN
        SELECT id_ciudad INTO p_id FROM CatCiudad WHERE nombre_ciudad = p_nombre;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO CatCiudad (nombre_ciudad) VALUES (p_nombre) RETURNING id_ciudad INTO p_id;
    END;

    -- Procedimiento Local: Gestionar Libro y Precio (Busca o Crea)
    PROCEDURE get_create_libro(
        p_titulo IN VARCHAR2, p_autor IN VARCHAR2, p_precio IN NUMBER, p_id_genero IN NUMBER, p_id_out OUT NUMBER
    ) IS
    BEGIN
        SELECT id_libro INTO p_id_out FROM Libro WHERE titulo = p_titulo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Insertar Libro
            INSERT INTO Libro (id_genero, autor, titulo) 
            VALUES (p_id_genero, p_autor, p_titulo) 
            RETURNING id_libro INTO p_id_out;
            -- Insertar Precio Inicial
            INSERT INTO HistoricoPrecio (id_libro, precio, fecha_inicio, vigente)
            VALUES (p_id_out, p_precio, SYSDATE, '1');
    END;

    -- Procedimiento Local: Gestionar Cliente (Busca por correo o Crea con Ubicación)
    PROCEDURE get_create_cliente(
        p_correo IN VARCHAR2, p_nombre IN VARCHAR2, p_direccion IN VARCHAR2, p_id_ciudad IN NUMBER, p_id_out OUT NUMBER
    ) IS
        v_id_ubi_local NUMBER;
    BEGIN
        SELECT id_cliente INTO p_id_out FROM Cliente WHERE correo_electronico = p_correo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Crear Ubicación primero
            INSERT INTO Ubicacion (id_ciudad, direccion) 
            VALUES (p_id_ciudad, p_direccion) 
            RETURNING id_ubicacion INTO v_id_ubi_local;
            -- Crear Cliente
            INSERT INTO Cliente (correo_electronico, nombre_completo, id_ubicacion)
            VALUES (p_correo, p_nombre, v_id_ubi_local)
            RETURNING id_cliente INTO p_id_out;
    END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INICIANDO CARGA DE TABLA SOLICITADA ---');

    -- 1. PREPARAR CATÁLOGOS BÁSICOS (Estados y Género)
    -- Genero 'Técnico'
    BEGIN
        SELECT id_genero INTO v_id_genero FROM CatGenero WHERE nombre_genero = 'Técnico';
    EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO CatGenero (nombre_genero) VALUES ('Técnico') RETURNING id_genero INTO v_id_genero;
    END;

    -- Estados 'Pagado' y 'Pendiente'
    BEGIN
        SELECT id_estado INTO v_id_estado_p FROM CatEstado WHERE nombre_estado = 'Pagado';
    EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO CatEstado (nombre_estado, descripcion) VALUES ('Pagado', 'Pago confirmado') RETURNING id_estado INTO v_id_estado_p;
    END;

    BEGIN
        SELECT id_estado INTO v_id_estado_pd FROM CatEstado WHERE nombre_estado = 'Pendiente';
    EXCEPTION WHEN NO_DATA_FOUND THEN
        INSERT INTO CatEstado (nombre_estado, descripcion) VALUES ('Pendiente', 'Esperando pago') RETURNING id_estado INTO v_id_estado_pd;
    END;

    -- 2. PREPARAR LIBROS (Insertamos los 5 libros únicos de la tabla para tener sus IDs)
    get_create_libro('SQL Básico', 'A. Brown', 299.90, v_id_genero, v_libro_sql_bas);
    get_create_libro('Modelado Datos', 'B. White', 399.90, v_id_genero, v_libro_mod_dat);
    get_create_libro('Guía Python', 'C. Green', 499.90, v_id_genero, v_libro_python);
    get_create_libro('SQL Avanzado', 'D. Black', 349.90, v_id_genero, v_libro_sql_adv);
    get_create_libro('Big Data', 'E. Blue', 599.90, v_id_genero, v_libro_bigdata);

    DBMS_OUTPUT.PUT_LINE('-> Catálogos y Libros preparados.');

    -- 3. PROCESAMIENTO DE PEDIDOS (FILA POR FILA)

    -- ==============================================================================
    -- ID 101: Juan Pérez (CDMX) - 2 Libros - Pagado
    -- ==============================================================================
    get_create_ciudad('CDMX', v_id_ciudad);
    get_create_cliente('juan@email.com', 'Juan Pérez', 'Calle Luna 123', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('10/01/2025','DD/MM/YYYY'), v_id_estado_p) RETURNING id_pedido INTO v_id_pedido;
    
    -- Histórico Estado
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio, observaciones)
    VALUES (v_id_pedido, v_id_estado_p, TO_DATE('10/01/2025','DD/MM/YYYY'), 'Pedido Creado Pagado');
    
    -- Detalles (SQL Básico x2, Modelado x1)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_sql_bas, 2, 299.90);
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_mod_dat, 1, 399.90);

    -- ==============================================================================
    -- ID 102: Ana López (Miami) - 1 Libro - Pendiente
    -- ==============================================================================
    get_create_ciudad('Miami', v_id_ciudad);
    get_create_cliente('ana@email.com', 'Ana López', 'Av. Sol 456', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('12/01/2025','DD/MM/YYYY'), v_id_estado_pd) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_pd, TO_DATE('12/01/2025','DD/MM/YYYY'));
    
    -- Detalle (Guía Python x1)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_python, 1, 499.90);

    -- ==============================================================================
    -- ID 103: Luis Gómez (Bogotá) - 2 Libros - Pagado
    -- ==============================================================================
    get_create_ciudad('Bogotá', v_id_ciudad);
    get_create_cliente('luis@email.com', 'Luis Gómez', 'Calle Estrella 789', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('15/01/2025','DD/MM/YYYY'), v_id_estado_p) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_p, TO_DATE('15/01/2025','DD/MM/YYYY'));
    
    -- Detalles (SQL Avanzado x1, Big Data x2)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_sql_adv, 1, 349.90);
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_bigdata, 2, 599.90);

    -- ==============================================================================
    -- ID 104: María Ruiz (CDMX) - 1 Libro - Pagado
    -- ==============================================================================
    get_create_ciudad('CDMX', v_id_ciudad);
    get_create_cliente('maria@email.com', 'María Ruiz', 'Av. Nube 101', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('18/01/2025','DD/MM/YYYY'), v_id_estado_p) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_p, TO_DATE('18/01/2025','DD/MM/YYYY'));
    
    -- Detalle (Modelado Datos x3)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_mod_dat, 3, 399.90);

    -- ==============================================================================
    -- ID 105: Carlos Díaz (Lima) - 2 Libros - Pendiente
    -- ==============================================================================
    get_create_ciudad('Lima', v_id_ciudad);
    get_create_cliente('carlos@email.com', 'Carlos Díaz', 'Calle Sol 202', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('20/01/2025','DD/MM/YYYY'), v_id_estado_pd) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_pd, TO_DATE('20/01/2025','DD/MM/YYYY'));
    
    -- Detalles (Python x2, Big Data x1)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_python, 2, 499.90);
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_bigdata, 1, 599.90);

    -- ==============================================================================
    -- ID 106: Laura Vega (Miami) - 1 Libro - Pagado
    -- ==============================================================================
    get_create_ciudad('Miami', v_id_ciudad);
    get_create_cliente('laura@email.com', 'Laura Vega', 'Av. Luna 303', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('22/01/2025','DD/MM/YYYY'), v_id_estado_p) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_p, TO_DATE('22/01/2025','DD/MM/YYYY'));
    
    -- Detalle (SQL Básico x1)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_sql_bas, 1, 299.90);

    -- ==============================================================================
    -- ID 107: Pedro Mora (Bogotá) - 1 Libro - Pagado
    -- ==============================================================================
    get_create_ciudad('Bogotá', v_id_ciudad);
    get_create_cliente('pedro@email.com', 'Pedro Mora', 'Calle Cielo 404', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('25/01/2025','DD/MM/YYYY'), v_id_estado_p) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_p, TO_DATE('25/01/2025','DD/MM/YYYY'));
    
    -- Detalle (Big Data x2)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_bigdata, 2, 599.90);

    -- ==============================================================================
    -- ID 108: Sofía Castro (CDMX) - 2 Libros - Pendiente
    -- ==============================================================================
    get_create_ciudad('CDMX', v_id_ciudad);
    get_create_cliente('sofia@email.com', 'Sofía Castro', 'Av. Sol 505', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('28/01/2025','DD/MM/YYYY'), v_id_estado_pd) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_pd, TO_DATE('28/01/2025','DD/MM/YYYY'));
    
    -- Detalles (SQL Avanzado x1, Python x1)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_sql_adv, 1, 349.90);
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_python, 1, 499.90);

    -- ==============================================================================
    -- ID 109: Diego León (Lima) - 1 Libro - Pagado
    -- ==============================================================================
    get_create_ciudad('Lima', v_id_ciudad);
    get_create_cliente('diego@email.com', 'Diego León', 'Calle Luna 606', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('30/01/2025','DD/MM/YYYY'), v_id_estado_p) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_p, TO_DATE('30/01/2025','DD/MM/YYYY'));
    
    -- Detalle (Modelado Datos x2)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_mod_dat, 2, 399.90);

    -- ==============================================================================
    -- ID 110: Elena Cruz (Miami) - 2 Libros - Pagado
    -- ==============================================================================
    get_create_ciudad('Miami', v_id_ciudad);
    get_create_cliente('elena@email.com', 'Elena Cruz', 'Av. Estrella 707', v_id_ciudad, v_id_cliente);
    
    INSERT INTO Pedido (id_cliente, fecha, id_estado_actual) 
    VALUES (v_id_cliente, TO_DATE('01/02/2025','DD/MM/YYYY'), v_id_estado_p) RETURNING id_pedido INTO v_id_pedido;
    
    INSERT INTO HistoricoEstadoPedido (id_pedido, id_estado, fecha_cambio) VALUES (v_id_pedido, v_id_estado_p, TO_DATE('01/02/2025','DD/MM/YYYY'));
    
    -- Detalles (SQL Básico x1, Big Data x1)
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_sql_bas, 1, 299.90);
    INSERT INTO DetallePedido (id_pedido, id_libro, cantidad, precio_unitario) VALUES (v_id_pedido, v_libro_bigdata, 1, 599.90);

    DBMS_OUTPUT.PUT_LINE('-> 10 Pedidos (ID 101 a 110) insertados correctamente con sus detalles.');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('--- CARGA DE TABLA COMPLETADA EXITOSAMENTE ---');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR FATAL EN LA CARGA: ' || SQLERRM);
END;
/

