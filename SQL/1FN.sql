DROP TABLE VENTAS_1FN;

CREATE TABLE VENTAS_1FN (
    PEDIDO_ID NUMBER,
    CLIENTE VARCHAR2(100), -- Repetitivo
    TITULO_LIBRO VARCHAR2(100), -- Atómico pero texto repetido
    PRECIO_LIBRO NUMBER,   -- Ya es numérico (Avance)
    CANTIDAD NUMBER,       -- Ya es numérico (Avance)
    FECHA_PEDIDO DATE,
    MONTO_TOTAL NUMBER
);

-- Insertamos los datos "desglosados" (Atómicos)
-- Pedido 101 se convierte en 2 filas
INSERT INTO VENTAS_1FN VALUES (101, 'Juan Pérez', 'SQL Básico', 299.9, 2, TO_DATE('10/01/2025','DD/MM/YYYY'), 999.7);
INSERT INTO VENTAS_1FN VALUES (101, 'Juan Pérez', 'Modelado Datos', 399.9, 1, TO_DATE('10/01/2025','DD/MM/YYYY'), 999.7);
-- Pedido 102
INSERT INTO VENTAS_1FN VALUES (102, 'Ana López', 'Guía Python', 499.9, 1, TO_DATE('12/01/2025','DD/MM/YYYY'), 499.9);
-- Pedido 103 se convierte en 2 filas
INSERT INTO VENTAS_1FN VALUES (103, 'Luis Gómez', 'SQL Avanzado', 349.9, 1, TO_DATE('15/01/2025','DD/MM/YYYY'), 1549.70);
INSERT INTO VENTAS_1FN VALUES (103, 'Luis Gómez', 'Big Data', 599.9, 2, TO_DATE('15/01/2025','DD/MM/YYYY'), 1549.70);

COMMIT;

BEGIN
   FOR i IN 1..15 LOOP -- Una iteración más porque empezamos con menos filas base
      INSERT INTO VENTAS_1FN
      SELECT 
         PEDIDO_ID + (SELECT MAX(PEDIDO_ID) FROM VENTAS_1FN),
         CLIENTE, TITULO_LIBRO, PRECIO_LIBRO, CANTIDAD, FECHA_PEDIDO, MONTO_TOTAL
      FROM VENTAS_1FN;
      COMMIT;
   END LOOP;
END;
/

SET TIMING ON;
-- Consulta: Total de ingresos generados solo por el libro "SQL Básico"
SELECT SUM(CANTIDAD * PRECIO_LIBRO) as TOTAL_VENTAS
FROM VENTAS_1FN 
WHERE TITULO_LIBRO = 'SQL Básico';
