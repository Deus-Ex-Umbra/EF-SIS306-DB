-- 1. Crear Tablas 2FN
DROP TABLE DETALLE_2FN;
DROP TABLE PEDIDOS_2FN;

-- Tabla Cabecera (Datos que dependen solo del ID Pedido)
-- Aquí guardamos al cliente UNA sola vez por pedido.
CREATE TABLE PEDIDOS_2FN (
    PEDIDO_ID NUMBER PRIMARY KEY,
    CLIENTE VARCHAR2(100),
    FECHA_PEDIDO DATE,
    ESTADO_PAGO VARCHAR2(20)
);

-- Tabla Detalle (Datos que dependen del ID Pedido + Libro)
-- Aún usamos TEXTO para el libro (Título), porque en 2FN no necesariamente hemos creado un catálogo numérico externo.
CREATE TABLE DETALLE_2FN (
    PEDIDO_ID NUMBER REFERENCES PEDIDOS_2FN(PEDIDO_ID),
    TITULO_LIBRO VARCHAR2(100), 
    PRECIO_LIBRO NUMBER,
    CANTIDAD NUMBER
);

-- 2. Poblar Datos (Semilla)
-- Insertamos Cabeceras (Solo 1 por pedido)
INSERT INTO PEDIDOS_2FN VALUES (101, 'Juan Pérez', TO_DATE('10/01/2025','DD/MM/YYYY'), 'Pagado');
INSERT INTO PEDIDOS_2FN VALUES (102, 'Ana López', TO_DATE('12/01/2025','DD/MM/YYYY'), 'Pendiente');
INSERT INTO PEDIDOS_2FN VALUES (103, 'Luis Gómez', TO_DATE('15/01/2025','DD/MM/YYYY'), 'Pagado');
-- ... (puedes añadir el resto si quieres, pero con esto basta para la muestra)

-- Insertamos Detalles
INSERT INTO DETALLE_2FN VALUES (101, 'SQL Básico', 299.9, 2);
INSERT INTO DETALLE_2FN VALUES (101, 'Modelado Datos', 399.9, 1);
INSERT INTO DETALLE_2FN VALUES (102, 'Guía Python', 499.9, 1);
INSERT INTO DETALLE_2FN VALUES (103, 'SQL Avanzado', 349.9, 1);
INSERT INTO DETALLE_2FN VALUES (103, 'Big Data', 599.9, 2);

COMMIT;

-- 3. Generación Masiva para 2FN
-- Multiplicamos los detalles para llegar al volumen de 160k
BEGIN
   FOR i IN 1..15 LOOP
      INSERT INTO DETALLE_2FN
      SELECT 
         PEDIDO_ID, -- Mismo ID para simular carga, o podrías crear nuevos pedidos en cabecera
         TITULO_LIBRO, PRECIO_LIBRO, CANTIDAD
      FROM DETALLE_2FN;
      COMMIT;
   END LOOP;
END;
/

SET TIMING ON;
SELECT SUM(CANTIDAD * PRECIO_LIBRO) as TOTAL_VENTAS
FROM DETALLE_2FN 
WHERE TITULO_LIBRO = 'SQL Básico';

