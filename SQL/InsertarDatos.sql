SET SERVEROUTPUT ON;

DECLARE
    TYPE t_mapa_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_libros   t_mapa_ids;
    v_clientes t_mapa_ids;
    v_pedidos  t_mapa_ids;
    v_g_ficcion NUMBER; v_g_ciencia NUMBER; v_g_tecnologia NUMBER;
    v_g_historia NUMBER; v_g_arte NUMBER; v_g_negocios NUMBER;
    v_c_scz NUMBER; v_c_lpz NUMBER; v_c_cba NUMBER;
    v_id_ubicacion_temp NUMBER;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INICIANDO CARGA CONTROLADA DE DATOS ---');
    -- 1. OBTENER IDs DE CATÁLOGOS EXISTENTES
    -- (Asumimos que ejecutaste los INSERTS de catálogos básicos del paso anterior)
    SELECT id_genero INTO v_g_ficcion FROM CatGenero WHERE nombre_genero = 'Ficción';
    SELECT id_genero INTO v_g_ciencia FROM CatGenero WHERE nombre_genero = 'Ciencia';
    SELECT id_genero INTO v_g_tecnologia FROM CatGenero WHERE nombre_genero = 'Tecnología';
    SELECT id_genero INTO v_g_historia FROM CatGenero WHERE nombre_genero = 'Historia';
    SELECT id_genero INTO v_g_arte FROM CatGenero WHERE nombre_genero = 'Arte';
    SELECT id_genero INTO v_g_negocios FROM CatGenero WHERE nombre_genero = 'Negocios';

    SELECT id_ciudad INTO v_c_scz FROM CatCiudad WHERE nombre_ciudad = 'Santa Cruz';
    SELECT id_ciudad INTO v_c_lpz FROM CatCiudad WHERE nombre_ciudad = 'La Paz';
    SELECT id_ciudad INTO v_c_cba FROM CatCiudad WHERE nombre_ciudad = 'Cochabamba';

    -- =================================================================
    -- 2. INSERTAR 20 LIBROS (Datos Reales)
    -- =================================================================
    sp_insertar_libro(v_g_tecnologia, 'Robert C. Martin', 'Clean Code', 350.00, v_libros(1));
    sp_insertar_libro(v_g_tecnologia, 'Andrew Hunt', 'The Pragmatic Programmer', 320.50, v_libros(2));
    sp_insertar_libro(v_g_tecnologia, 'Thomas H. Cormen', 'Introduction to Algorithms', 500.00, v_libros(3));
    sp_insertar_libro(v_g_tecnologia, 'Erich Gamma', 'Design Patterns', 410.00, v_libros(4));
    
    -- Ficción
    sp_insertar_libro(v_g_ficcion, 'Frank Herbert', 'Dune', 150.00, v_libros(5));
    sp_insertar_libro(v_g_ficcion, 'George Orwell', '1984', 100.00, v_libros(6));
    sp_insertar_libro(v_g_ficcion, 'J.R.R. Tolkien', 'El Señor de los Anillos', 250.00, v_libros(7));
    sp_insertar_libro(v_g_ficcion, 'Isaac Asimov', 'Fundación', 180.00, v_libros(8));
    sp_insertar_libro(v_g_ficcion, 'Gabriel García Márquez', 'Cien Años de Soledad', 200.00, v_libros(9));
    
    -- Ciencia
    sp_insertar_libro(v_g_ciencia, 'Stephen Hawking', 'Breve Historia del Tiempo', 120.00, v_libros(10));
    sp_insertar_libro(v_g_ciencia, 'Carl Sagan', 'Cosmos', 190.00, v_libros(11));
    sp_insertar_libro(v_g_ciencia, 'Yuval Noah Harari', 'Sapiens', 210.00, v_libros(12));
    
    -- Negocios
    sp_insertar_libro(v_g_negocios, 'Robert Kiyosaki', 'Padre Rico, Padre Pobre', 90.00, v_libros(13));
    sp_insertar_libro(v_g_negocios, 'Eric Ries', 'The Lean Startup', 230.00, v_libros(14));
    sp_insertar_libro(v_g_negocios, 'Dale Carnegie', 'Cómo ganar amigos', 110.00, v_libros(15));
    
    -- Historia
    sp_insertar_libro(v_g_historia, 'Diana Uribe', 'Historia de las Civilizaciones', 260.00, v_libros(16));
    sp_insertar_libro(v_g_historia, 'Stefan Zweig', 'Momentos estelares', 140.00, v_libros(17));
    
    -- Arte
    sp_insertar_libro(v_g_arte, 'E.H. Gombrich', 'La Historia del Arte', 450.00, v_libros(18));
    sp_insertar_libro(v_g_arte, 'Van Gogh', 'Cartas a Theo', 130.00, v_libros(19));
    sp_insertar_libro(v_g_arte, 'Kandinsky', 'De lo espiritual en el arte', 115.00, v_libros(20));

    DBMS_OUTPUT.PUT_LINE('-> 20 Libros insertados.');

    -- =================================================================
    -- 3. INSERTAR 6 CLIENTES Y SUS UBICACIONES
    -- =================================================================

    -- Cliente 1: Santa Cruz
    sp_insertar_ubicacion(v_c_scz, 'Av. San Martin, Calle 4 Oeste #100', v_id_ubicacion_temp);
    sp_insertar_cliente('carlos.mamani@gmail.com', 'Carlos Mamani', v_id_ubicacion_temp, v_clientes(1));

    -- Cliente 2: Santa Cruz
    sp_insertar_ubicacion(v_c_scz, 'Barrio Sirari, Calle Los Claveles #50', v_id_ubicacion_temp);
    sp_insertar_cliente('ana.torres@hotmail.com', 'Ana Torres', v_id_ubicacion_temp, v_clientes(2));

    -- Cliente 3: La Paz
    sp_insertar_ubicacion(v_c_lpz, 'Zona Sopocachi, Edif. Azul Piso 3', v_id_ubicacion_temp);
    sp_insertar_cliente('luis.fernandez@yahoo.com', 'Luis Fernandez', v_id_ubicacion_temp, v_clientes(3));

    -- Cliente 4: La Paz
    sp_insertar_ubicacion(v_c_lpz, 'Av. Arce, frente al multicine', v_id_ubicacion_temp);
    sp_insertar_cliente('sofia.mendoza@gmail.com', 'Sofia Mendoza', v_id_ubicacion_temp, v_clientes(4));

    -- Cliente 5: Cochabamba
    sp_insertar_ubicacion(v_c_cba, 'Av. Pando, Recoleta #88', v_id_ubicacion_temp);
    sp_insertar_cliente('jorge.rojas@outlook.com', 'Jorge Rojas', v_id_ubicacion_temp, v_clientes(5));

    -- Cliente 6: Cochabamba
    sp_insertar_ubicacion(v_c_cba, 'Calle España, cerca a la Plaza', v_id_ubicacion_temp);
    sp_insertar_cliente('valeria.justiniano@gmail.com', 'Valeria Justiniano', v_id_ubicacion_temp, v_clientes(6));

    DBMS_OUTPUT.PUT_LINE('-> 6 Clientes insertados.');

    -- =================================================================
    -- 4. INSERTAR 12 PEDIDOS CON DETALLES Y CAMBIO DE ESTADO
    -- =================================================================

    -- PEDIDO 1 (Carlos - SCZ): Compra libros de Programación. Estado: ENTREGADO
    sp_crear_pedido(v_clientes(1), v_pedidos(1));
    sp_agregar_detalle_pedido(v_pedidos(1), v_libros(1), 1); -- Clean Code
    sp_agregar_detalle_pedido(v_pedidos(1), v_libros(2), 1); -- Pragmatic Programmer
    -- Flujo de estados
    sp_cambiar_estado_pedido(v_pedidos(1), 'Pagado', 'Transferencia QR');
    sp_cambiar_estado_pedido(v_pedidos(1), 'Enviado', 'Courier #123');
    sp_cambiar_estado_pedido(v_pedidos(1), 'Entregado', 'Recibido en portería');

    -- PEDIDO 2 (Carlos - SCZ): Compra Ficción. Estado: ENVIADO
    sp_crear_pedido(v_clientes(1), v_pedidos(2));
    sp_agregar_detalle_pedido(v_pedidos(2), v_libros(5), 1); -- Dune
    sp_cambiar_estado_pedido(v_pedidos(2), 'Pagado', 'T. Crédito');
    sp_cambiar_estado_pedido(v_pedidos(2), 'Enviado', 'Moto en camino');

    -- PEDIDO 3 (Ana - SCZ): Libros de Negocios. Estado: PENDIENTE
    sp_crear_pedido(v_clientes(2), v_pedidos(3));
    sp_agregar_detalle_pedido(v_pedidos(3), v_libros(13), 2); -- Padre Rico (2 copias)
    sp_agregar_detalle_pedido(v_pedidos(3), v_libros(14), 1); -- Lean Startup
    -- Se queda en pendiente

    -- PEDIDO 4 (Ana - SCZ): Historia. Estado: PAGADO
    sp_crear_pedido(v_clientes(2), v_pedidos(4));
    sp_agregar_detalle_pedido(v_pedidos(4), v_libros(16), 1);
    sp_cambiar_estado_pedido(v_pedidos(4), 'Pagado', 'Depósito Bancario');

    -- PEDIDO 5 (Luis - LPZ): Ciencia. Estado: ENTREGADO
    sp_crear_pedido(v_clientes(3), v_pedidos(5));
    sp_agregar_detalle_pedido(v_pedidos(5), v_libros(10), 1); -- Stephen Hawking
    sp_agregar_detalle_pedido(v_pedidos(5), v_libros(11), 1); -- Cosmos
    sp_cambiar_estado_pedido(v_pedidos(5), 'Pagado', 'QR');
    sp_cambiar_estado_pedido(v_pedidos(5), 'Enviado', 'Flota Bolivar');
    sp_cambiar_estado_pedido(v_pedidos(5), 'Entregado', 'Todo bien');

    -- PEDIDO 6 (Luis - LPZ): Arte. Estado: CANCELADO
    sp_crear_pedido(v_clientes(3), v_pedidos(6));
    sp_agregar_detalle_pedido(v_pedidos(6), v_libros(18), 1); -- Hist Arte
    sp_cambiar_estado_pedido(v_pedidos(6), 'Cancelado', 'Cliente se arrepintió');

    -- PEDIDO 7 (Sofia - LPZ): Mix. Estado: ENVIADO
    sp_crear_pedido(v_clientes(4), v_pedidos(7));
    sp_agregar_detalle_pedido(v_pedidos(7), v_libros(6), 1); -- 1984
    sp_agregar_detalle_pedido(v_pedidos(7), v_libros(12), 1); -- Sapiens
    sp_cambiar_estado_pedido(v_pedidos(7), 'Pagado', 'Web');
    sp_cambiar_estado_pedido(v_pedidos(7), 'Enviado', 'Despachado hoy');

    -- PEDIDO 8 (Sofia - LPZ): Solo uno. Estado: PENDIENTE
    sp_crear_pedido(v_clientes(4), v_pedidos(8));
    sp_agregar_detalle_pedido(v_pedidos(8), v_libros(20), 1); -- Kandinsky

    -- PEDIDO 9 (Jorge - CBA): Algoritmos. Estado: ENTREGADO
    sp_crear_pedido(v_clientes(5), v_pedidos(9));
    sp_agregar_detalle_pedido(v_pedidos(9), v_libros(3), 1); -- Algoritmos
    sp_cambiar_estado_pedido(v_pedidos(9), 'Pagado', 'Efectivo');
    sp_cambiar_estado_pedido(v_pedidos(9), 'Enviado', 'Courier');
    sp_cambiar_estado_pedido(v_pedidos(9), 'Entregado', 'Recibido personal');

    -- PEDIDO 10 (Jorge - CBA): Ficción. Estado: PENDIENTE
    sp_crear_pedido(v_clientes(5), v_pedidos(10));
    sp_agregar_detalle_pedido(v_pedidos(10), v_libros(7), 3); -- Señor Anillos (3 unidades!)

    -- PEDIDO 11 (Valeria - CBA): Varios. Estado: PAGADO
    sp_crear_pedido(v_clientes(6), v_pedidos(11));
    sp_agregar_detalle_pedido(v_pedidos(11), v_libros(9), 1); -- Cien años
    sp_agregar_detalle_pedido(v_pedidos(11), v_libros(19), 1); -- Van Gogh
    sp_cambiar_estado_pedido(v_pedidos(11), 'Pagado', 'QR Simple');

    -- PEDIDO 12 (Valeria - CBA): Último. Estado: ENTREGADO
    sp_crear_pedido(v_clientes(6), v_pedidos(12));
    sp_agregar_detalle_pedido(v_pedidos(12), v_libros(15), 2); -- Carnegie
    sp_cambiar_estado_pedido(v_pedidos(12), 'Pagado', 'Web');
    sp_cambiar_estado_pedido(v_pedidos(12), 'Enviado', 'Listo');
    sp_cambiar_estado_pedido(v_pedidos(12), 'Entregado', 'Finalizado');

    DBMS_OUTPUT.PUT_LINE('-> 12 Pedidos creados y estados actualizados.');

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('--- CARGA COMPLETA EXITOSA ---');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR FATAL: ' || SQLERRM);
END;
/