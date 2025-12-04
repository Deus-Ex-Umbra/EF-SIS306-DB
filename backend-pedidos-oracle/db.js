const oracledb = require('oracledb');
require('dotenv').config();

// Configuración opcional para modo Thin (si usas oracledb 6+)
// No requiere instalar el cliente instantáneo de Oracle en el SO.
try {
    oracledb.initOracleClient({ libDir: process.env.ORACLE_LIB_DIR }); 
} catch (err) {
    // Si falla o no se configura, intentará usar el modo Thin por defecto
    console.log('Iniciando en modo Thin o Default...');
}

const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECTION_STRING,
    poolMin: 2,
    poolMax: 10,
    poolIncrement: 2
};

async function initialize() {
    await oracledb.createPool(dbConfig);
    console.log('Conexión a Oracle Pool creada exitosamente.');
}

async function close() {
    await oracledb.getPool().close(0);
}

// Función genérica para ejecutar SQL
async function execute(sql, binds = [], opts = {}) {
    let connection;
    try {
        connection = await oracledb.getConnection();
        // Por defecto devolvemos objetos JSON en lugar de arrays
        opts.outFormat = oracledb.OUT_FORMAT_OBJECT;
        // AutoCommit está desactivado por defecto en oracledb, 
        // PERO tus procedimientos almacenados ya tienen "COMMIT;", 
        // así que para procedimientos no hace falta autoCommit: true.
        // Para SELECTs simples no afecta.
        
        const result = await connection.execute(sql, binds, opts);
        return result;
    } catch (err) {
        console.error("Error ejecutando SQL:", err);
        throw err;
    } finally {
        if (connection) {
            try {
                await connection.close();
            } catch (err) {
                console.error("Error cerrando conexión:", err);
            }
        }
    }
}

module.exports = { initialize, close, execute, oracledb };