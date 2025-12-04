DROP TABLE DETALLE_PEDIDO_TEST;
DROP TABLE LIBRO_TEST;

-- Tabla Maestra de Libros (Pequeña, solo referencias únicas)
CREATE TABLE LIBRO_TEST (
    ID_LIBRO NUMBER PRIMARY KEY,
    TITULO VARCHAR2(100),
    PRECIO_ACTUAL NUMBER
);

-- Tabla Transaccional (Millones de filas, pero ligera: solo números)
CREATE TABLE DETALLE_PEDIDO_TEST (
    ID_PEDIDO NUMBER,
    ID_LIBRO NUMBER REFERENCES LIBRO_TEST(ID_LIBRO), -- Clave Foránea (Indexada automáticamente en muchos casos o manual)
    CANTIDAD NUMBER
);

-- Creamos un índice explícito en la FK para asegurar velocidad máxima
CREATE INDEX idx_detalle_libro ON DETALLE_PEDIDO_TEST(ID_LIBRO);

INSERT INTO LIBRO_TEST VALUES (1, 'SQL Básico', 299.9);
INSERT INTO LIBRO_TEST VALUES (2, 'Modelado Datos', 399.9);
INSERT INTO LIBRO_TEST VALUES (3, 'Guía Python', 499.9);
INSERT INTO LIBRO_TEST VALUES (4, 'SQL Avanzado', 349.9);
INSERT INTO LIBRO_TEST VALUES (5, 'Big Data', 599.9);
COMMIT;

-- Insertar semilla (equivalente a los datos anteriores)
INSERT INTO DETALLE_PEDIDO_TEST VALUES (101, 1, 2); -- SQL Básico
INSERT INTO DETALLE_PEDIDO_TEST VALUES (101, 2, 1);
INSERT INTO DETALLE_PEDIDO_TEST VALUES (102, 3, 1);
INSERT INTO DETALLE_PEDIDO_TEST VALUES (103, 4, 1);
INSERT INTO DETALLE_PEDIDO_TEST VALUES (103, 5, 2);
COMMIT;

-- Generación Masiva (Mismo volumen ~160k)
BEGIN
   FOR i IN 1..15 LOOP
      INSERT INTO DETALLE_PEDIDO_TEST
      SELECT 
         ID_PEDIDO + (SELECT MAX(ID_PEDIDO) FROM DETALLE_PEDIDO_TEST),
         ID_LIBRO, 
         CANTIDAD
      FROM DETALLE_PEDIDO_TEST;
      COMMIT;
   END LOOP;
END;
/

SET TIMING ON;
-- Oracle busca 'SQL Básico' en la tabla pequeña (5 filas) -> Obtiene ID=1
-- Luego va directo al índice de la tabla grande buscando el número 1.
SELECT SUM(d.CANTIDAD * l.PRECIO_ACTUAL) as TOTAL_VENTAS
FROM DETALLE_PEDIDO_TEST d
JOIN LIBRO_TEST l ON d.ID_LIBRO = l.ID_LIBRO
WHERE l.TITULO = 'SQL Básico';
