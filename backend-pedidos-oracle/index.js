const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
// Cargar variables de entorno (asegúrate de tener dotenv instalado y requerido si usas .env)
require('dotenv').config(); 

const db = require('./db');
const controllers = require('./controllers');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// ==========================================
// RUTAS (Usar 'app' en lugar de 'router')
// ==========================================

// --- 1. CATÁLOGOS ---
app.get('/api/ciudades', controllers.getCiudades); 
app.get('/api/generos', controllers.getGeneros);   

// --- 2. CLIENTES Y UBICACIONES ---
app.post('/api/ubicaciones', controllers.createUbicacion);
app.get('/api/clientes', controllers.getClientes); // Corrección aplicada aquí
app.post('/api/clientes', controllers.createCliente);       
app.delete('/api/clientes/:id', controllers.deleteCliente);

// --- 3. LIBROS ---
app.get('/api/libros', controllers.getLibros);
app.post('/api/libros', controllers.createLibro); 
app.put('/api/libros/precio', controllers.updatePrecioLibro);
app.get('/api/libros/:id/precios', controllers.getHistorialPreciosLibro);

// --- 4. PEDIDOS ---
app.get('/api/pedidos', controllers.getPedidos); 
app.get('/api/pedidos/:id', controllers.getPedidoInfo); 
app.post('/api/pedidos', controllers.createPedido);
app.post('/api/pedidos/detalle', controllers.addDetallePedido);
app.put('/api/pedidos/estado', controllers.changeEstadoPedido); 

// --- 5. REPORTES ---
app.get('/api/reportes/ventas-ciudad', controllers.getReporteVentasCiudad);

// INICIO DEL SERVIDOR
async function startServer() {
    try {
        await db.initialize(); 
        app.listen(PORT, () => {
            console.log(`Servidor corriendo en http://localhost:${PORT}`);
        });
    } catch (err) {
        console.error('Error inicio:', err);
    }
}

startServer();