SET TIMING ON;
-- Esto hará que al final de cada ejecución te diga: "Transcurrido: 00:00:0X.XX"
-- Si la tabla ya existe, la borramos para empezar limpio
DROP TABLE VENTAS_SIN_NORM;

CREATE TABLE VENTAS_SIN_NORM (
    PEDIDO_ID NUMBER,
    INFO_CLIENTE VARCHAR2(400),    -- Contiene Nombre, Calle, Ciudad mezclados
    CORREO_CLIENTE VARCHAR2(100),
    TITULO_LIBRO VARCHAR2(400),    -- Múltiples libros separados por comas
    AUTOR_LIBRO VARCHAR2(400),
    GENERO_LIBRO VARCHAR2(200),
    PRECIO_LIBRO VARCHAR2(200),    -- Precios como texto "299.9, 100.0"
    CANTIDAD VARCHAR2(100),        -- Cantidades como texto "1, 2"
    FECHA_PEDIDO DATE,
    MONTO_TOTAL NUMBER,
    ESTADO_PAGO VARCHAR2(20)
);
INSERT INTO VENTAS_SIN_NORM VALUES (101, 'Juan Pérez, Calle Luna 123, CDMX', 'juan@email.com', 'SQL Básico, Modelado Datos', 'A. Brown, B. White', 'Técnico, Técnico', '299.9, 399.9', '2, 1', TO_DATE('10/01/2025','DD/MM/YYYY'), 999.7, 'Pagado');
INSERT INTO VENTAS_SIN_NORM VALUES (102, 'Ana López, Av. Sol 456, Miami', 'ana@email.com', 'Guía Python', 'C. Green', 'Técnico', '499.9', '1', TO_DATE('12/01/2025','DD/MM/YYYY'), 499.9, 'Pendiente');
INSERT INTO VENTAS_SIN_NORM VALUES (103, 'Luis Gómez, Calle Estrella 789, Bogotá', 'luis@email.com', 'SQL Avanzado, Big Data', 'D. Black, E. Blue', 'Técnico, Técnico', '349.9, 599.9', '1, 2', TO_DATE('15/01/2025','DD/MM/YYYY'), 1549.70, 'Pagado');
INSERT INTO VENTAS_SIN_NORM VALUES (104, 'María Ruiz, Av. Nube 101, CDMX', 'maria@email.com', 'Modelado Datos', 'B. White', 'Técnico', '399.9', '3', TO_DATE('18/01/2025','DD/MM/YYYY'), 1199.70, 'Pagado');
INSERT INTO VENTAS_SIN_NORM VALUES (105, 'Carlos Díaz, Calle Sol 202, Lima', 'carlos@email.com', 'Guía Python, Big Data', 'C. Green, E. Blue', 'Técnico, Técnico', '499.9, 599.9', '2, 1', TO_DATE('20/01/2025','DD/MM/YYYY'), 1599.70, 'Pendiente');
INSERT INTO VENTAS_SIN_NORM VALUES (106, 'Laura Vega, Av. Luna 303, Miami', 'laura@email.com', 'SQL Básico', 'A. Brown', 'Técnico', '299.9', '1', TO_DATE('22/01/2025','DD/MM/YYYY'), 299.9, 'Pagado');
INSERT INTO VENTAS_SIN_NORM VALUES (107, 'Pedro Mora, Calle Cielo 404, Bogotá', 'pedro@email.com', 'Big Data', 'E. Blue', 'Técnico', '599.9', '2', TO_DATE('25/01/2025','DD/MM/YYYY'), 1199.80, 'Pagado');
INSERT INTO VENTAS_SIN_NORM VALUES (108, 'Sofía Castro, Av. Sol 505, CDMX', 'sofia@email.com', 'SQL Avanzado, Guía Python', 'D. Black, C. Green', 'Técnico, Técnico', '349.9, 499.9', '1, 1', TO_DATE('28/01/2025','DD/MM/YYYY'), 849.8, 'Pendiente');
INSERT INTO VENTAS_SIN_NORM VALUES (109, 'Diego León, Calle Luna 606, Lima', 'diego@email.com', 'Modelado Datos', 'B. White', 'Técnico', '399.9', '2', TO_DATE('30/01/2025','DD/MM/YYYY'), 799.8, 'Pagado');
INSERT INTO VENTAS_SIN_NORM VALUES (110, 'Elena Cruz, Av. Estrella 707, Miami', 'elena@email.com', 'SQL Básico, Big Data', 'A. Brown, E. Blue', 'Técnico, Técnico', '299.9, 599.9', '1, 1', TO_DATE('01/02/2025','DD/MM/YYYY'), 899.8, 'Pagado');

COMMIT;
BEGIN
   -- Ejecutamos un ciclo para duplicar los datos 14 veces
   -- 10 filas * 2^14 = 163,840 filas aprox.
   FOR i IN 1..14 LOOP
      INSERT INTO VENTAS_SIN_NORM
      SELECT 
         PEDIDO_ID + (SELECT MAX(PEDIDO_ID) FROM VENTAS_SIN_NORM), -- Genera nuevo ID
         INFO_CLIENTE, 
         CORREO_CLIENTE, 
         TITULO_LIBRO, 
         AUTOR_LIBRO, 
         GENERO_LIBRO, 
         PRECIO_LIBRO, 
         CANTIDAD, 
         FECHA_PEDIDO, 
         MONTO_TOTAL, 
         ESTADO_PAGO
      FROM VENTAS_SIN_NORM;
      
      COMMIT; -- Guardamos cambios en cada vuelta
   END LOOP;
END;
/
SELECT COUNT(*) FROM VENTAS_SIN_NORM;
-- Debería ser un número cercano a 163,840.
-- TEST 1: BÚSQUEDA EN TEXTO NO ATÓMICO

SELECT COUNT(*) 
FROM VENTAS_SIN_NORM 
WHERE TITULO_LIBRO LIKE '%SQL Básico%';
