const db = require('./db');

const controllers = {
    // ==========================================
    // 1. CATALOGOS
    // ==========================================
    getCiudades: async (req, res) => {
        try {
            // Usa la vista v_lista_ciudades
            const result = await db.execute('SELECT * FROM v_lista_ciudades');
            res.json(result.rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    getGeneros: async (req, res) => {
        try {
            // Usa la vista v_lista_generos
            const result = await db.execute('SELECT * FROM v_lista_generos');
            res.json(result.rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    // ==========================================
    // 2. GESTIÓN DE CLIENTES Y UBICACIONES
    // ==========================================


    getClientes: async (req, res) => {
        try {
            // Consulta la vista recién creada
            const result = await db.execute('SELECT * FROM v_lista_clientes');
            console.log(result);
            
            // Oracle devuelve las filas en result.rows
            res.json(result.rows);
        } catch (err) { 
            console.error(err);
            res.status(500).json({ error: err.message }); 
        }
    },

    createUbicacion: async (req, res) => {
        const { id_ciudad, direccion } = req.body;
        try {
            const sql = `BEGIN sp_insertar_ubicacion(:p_id_ci, :p_dir, :p_id_out); END;`;
            const binds = {
                p_id_ci: id_ciudad,
                p_dir: direccion,
                p_id_out: { dir: db.oracledb.BIND_OUT, type: db.oracledb.NUMBER }
            };
            const result = await db.execute(sql, binds);
            res.json({ message: 'Ubicación creada', id_ubicacion: result.outBinds.p_id_out });
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    createCliente: async (req, res) => {
        const { correo, nombre, id_ubicacion } = req.body;
        try {
            const sql = `BEGIN sp_insertar_cliente(:p_cor, :p_nom, :p_id_ub, :p_id_out); END;`;
            const binds = {
                p_cor: correo,
                p_nom: nombre,
                p_id_ub: id_ubicacion,
                p_id_out: { dir: db.oracledb.BIND_OUT, type: db.oracledb.NUMBER }
            };
            const result = await db.execute(sql, binds);
            res.json({ message: 'Cliente creado', id_cliente: result.outBinds.p_id_out });
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    deleteCliente: async (req, res) => {
        const { id } = req.params;
        try {
            const sql = `BEGIN sp_eliminar_cliente(:p_id); END;`;
            await db.execute(sql, { p_id: id });
            res.json({ message: `Cliente ${id} eliminado correctamente` });
        } catch (err) { 
            // Manejo de errores ORA definidos en el SP
            if(err.message.includes('ORA-20011')) {
                res.status(400).json({ error: 'No se puede borrar: El cliente tiene pedidos.' });
            } else if (err.message.includes('ORA-20010')) {
                res.status(404).json({ error: 'Cliente no encontrado' });
            } else {
                res.status(500).json({ error: err.message }); 
            }
        }
    },

    // ==========================================
    // 3. GESTIÓN DE LIBROS Y PRECIOS
    // ==========================================

    createLibro: async (req, res) => {
        // CORRECCIÓN: Agregado 'titulo'
        const { id_genero, autor, titulo, precio } = req.body; 
        
        // Validación básica
        if (!titulo) return res.status(400).json({ error: 'El título es obligatorio' });

        try {
            // CORRECCIÓN: SQL actualizado con 5 parámetros para coincidir con el SP
            const sql = `BEGIN sp_insertar_libro(:p_id_gen, :p_aut, :p_tit, :p_pre, :p_id_out); END;`;
            const binds = {
                p_id_gen: id_genero,
                p_aut: autor,
                p_tit: titulo, // Nuevo bind
                p_pre: precio,
                p_id_out: { dir: db.oracledb.BIND_OUT, type: db.oracledb.NUMBER }
            };
            const result = await db.execute(sql, binds);
            res.json({ message: 'Libro creado', id_libro: result.outBinds.p_id_out });
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    updatePrecioLibro: async (req, res) => {
        const { id_libro, nuevo_precio } = req.body;
        try {
            const sql = `BEGIN sp_actualizar_precio_libro(:id, :pre); END;`;
            await db.execute(sql, { id: id_libro, pre: nuevo_precio });
            res.json({ message: 'Precio actualizado' });
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    getHistorialPreciosLibro: async (req, res) => {
        const { id } = req.params;
        try {
            // Usa la vista v_historial_precios
            const sql = `SELECT * FROM v_historial_precios WHERE id_libro = :id`;
            const result = await db.execute(sql, [id]);
            res.json(result.rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    getLibros: async (req, res) => {
    try {
        // Asegúrate de que NO haya un SELECT manual tipo "SELECT id, autor FROM..."
        // Debe usar la vista actualizada:
        const result = await db.execute('SELECT * FROM v_catalogo_libros');
        res.json(result.rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
},

    // ==========================================
    // 4. GESTIÓN DE PEDIDOS
    // ==========================================

    createPedido: async (req, res) => {
        const { id_cliente } = req.body;
        try {
            const sql = `BEGIN sp_crear_pedido(:p_cli, :p_id_out); END;`;
            const binds = {
                p_cli: id_cliente,
                p_id_out: { dir: db.oracledb.BIND_OUT, type: db.oracledb.NUMBER }
            };
            const result = await db.execute(sql, binds);
            res.json({ message: 'Pedido iniciado', id_pedido: result.outBinds.p_id_out });
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    addDetallePedido: async (req, res) => {
        const { id_pedido, id_libro, cantidad } = req.body;
        try {
            // El trigger trg_validar_detalle_pedido validará si el estado es 'Pendiente'
            const sql = `BEGIN sp_agregar_detalle_pedido(:pid, :lid, :cant); END;`;
            await db.execute(sql, { pid: id_pedido, lid: id_libro, cant: cantidad });
            res.json({ message: 'Item agregado' });
        } catch (err) { 
            if(err.message.includes('ORA-20009')) {
                res.status(400).json({ error: 'Solo se pueden agregar items a pedidos PENDIENTES.' });
            } else {
                res.status(500).json({ error: err.message }); 
            }
        }
    },

    changeEstadoPedido: async (req, res) => {
        // CORRECCIÓN: Agregado observaciones
        const { id_pedido, nuevo_estado, observaciones } = req.body;
        const obsFinal = observaciones || ''; // Manejo de opcional

        try {
            // CORRECCIÓN: Pasamos observaciones al SP
            const sql = `BEGIN sp_cambiar_estado_pedido(:pid, :est, :obs); END;`;
            await db.execute(sql, { pid: id_pedido, est: nuevo_estado, obs: obsFinal });
            res.json({ message: `Estado cambiado a ${nuevo_estado}` });
        } catch (err) { 
             if(err.message.includes('ORA-20008')) {
                res.status(400).json({ error: 'No se puede modificar un pedido finalizado.' });
            } else {
                res.status(500).json({ error: err.message });
            }
        }
    },

    getPedidos: async (req, res) => {
        try {
            // Usa la vista general v_pedidos_completo
            const result = await db.execute('SELECT * FROM v_pedidos_completo');
            res.json(result.rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    },

    // --- NUEVO: IMPLEMENTACIÓN DE CURSOR PARA INFO DETALLADA ---
    getPedidoInfo: async (req, res) => {
        const { id } = req.params;
        let connection;
        try {
            // Necesitamos acceder a la conexión raw para procesar el cursor
            connection = await db.oracledb.getConnection(); 

            const sql = `BEGIN sp_obtener_info_pedido(:p_id, :p_cursor); END;`;
            const binds = {
                p_id: id,
                p_cursor: { dir: db.oracledb.BIND_OUT, type: db.oracledb.CURSOR }
            };

            const result = await connection.execute(sql, binds);
            const resultSet = result.outBinds.p_cursor;

            // Convertimos el ResultSet (Cursor) a un array de JSON
            const rows = await resultSet.getRows(); 
            await resultSet.close(); // Importante cerrar el cursor

            if (rows.length === 0) {
                return res.status(404).json({ message: 'Pedido no encontrado o sin detalles' });
            }

            res.json(rows);

        } catch (err) {
            console.error(err);
            res.status(500).json({ error: err.message });
        } finally {
            if (connection) {
                try { await connection.close(); } catch (e) { console.error(e); }
            }
        }
    },

    getReporteVentasCiudad: async (req, res) => {
        try {
            const result = await db.execute('SELECT * FROM v_ventas_por_ciudad');
            res.json(result.rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    }
};

module.exports = controllers;