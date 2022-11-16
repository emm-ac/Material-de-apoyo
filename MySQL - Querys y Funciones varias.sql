-- FUNCIÓN PARA CAMBIAR A MAYÚSCULA LA PRIMERA LETRA DE CADA PALABRA
SET GLOBAL log_bin_trust_function_creators = 1;
DROP FUNCTION IF EXISTS `UC_Words`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` FUNCTION `UC_Words`( str VARCHAR(255) ) RETURNS varchar(255) CHARSET utf8
BEGIN  
  DECLARE c CHAR(1);  
  DECLARE s VARCHAR(255);  
  DECLARE i INT DEFAULT 1;  
  DECLARE bool INT DEFAULT 1;  
  DECLARE punct CHAR(17) DEFAULT ' ()[]{},.-_!@;:?/';  
  SET s = LCASE( str );  
  WHILE i < LENGTH( str ) DO  
     BEGIN  
       SET c = SUBSTRING( s, i, 1 );  
       IF LOCATE( c, punct ) > 0 THEN  
        SET bool = 1;  
      ELSEIF bool=1 THEN  
        BEGIN  
          IF c >= 'a' AND c <= 'z' THEN  
             BEGIN  
               SET s = CONCAT(LEFT(s,i-1),UCASE(c),SUBSTRING(s,i+1));  
               SET bool = 0;  
             END;  
           ELSEIF c >= '0' AND c <= '9' THEN  
            SET bool = 0;  
          END IF;  
        END;  
      END IF;  
      SET i = i+1;  
    END;  
  END WHILE;  
  RETURN s;  
END$$
DELIMITER ;

SELECT UC_Words('alvaro nadie');

-- --------------------------------------------------------------------------------------------------------------------------------

-- CREAR UN CALENDARIO
DROP PROCEDURE IF EXISTS `Llenar_dimension_calendario`;
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `Llenar_dimension_calendario`(IN `startdate` DATE, IN `stopdate` DATE)
BEGIN
    DECLARE currentdate DATE;
    SET currentdate = startdate;
    WHILE currentdate < stopdate DO
        INSERT INTO calendario VALUES (
                        YEAR(currentdate)*10000+MONTH(currentdate)*100 + DAY(currentdate),
                        currentdate,
                        YEAR(currentdate),
                        MONTH(currentdate),
                        DAY(currentdate),
                        QUARTER(currentdate),
                        WEEKOFYEAR(currentdate),
                        DATE_FORMAT(currentdate,'%W'),
                        DATE_FORMAT(currentdate,'%M'));
        SET currentdate = ADDDATE(currentdate,INTERVAL 1 DAY);
    END WHILE;
END$$
DELIMITER ;

CALL Llenar_dimension_calendario('2015-01-01','2020-12-31');

-- --------------------------------------------------------------------------------------------------------------------------------

/*Importacion de las tablas*/
DROP TABLE IF EXISTS `gasto`;
CREATE TABLE IF NOT EXISTS `gasto` (
  	`IdGasto` 		INTEGER,
  	`IdSucursal` 	INTEGER,
  	`IdTipoGasto` 	INTEGER,
    `Fecha`			DATE,
  	`Monto` 		DECIMAL(10,2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Gasto.csv'
INTO TABLE `gasto` 
FIELDS TERMINATED BY ',' ENCLOSED BY '' ESCAPED BY '' 
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- --------------------------------------------------------------------------------------------------------------------------------

/*Se genera la dimension calendario*/
DROP TABLE IF EXISTS `calendario`;
CREATE TABLE calendario (
        id                      INTEGER PRIMARY KEY,  -- year*10000+month*100+day
        fecha                 	DATE NOT NULL,
        anio                    INTEGER NOT NULL,
        mes                   	INTEGER NOT NULL, -- 1 to 12
        dia                     INTEGER NOT NULL, -- 1 to 31
        trimestre               INTEGER NOT NULL, -- 1 to 4
        semana                  INTEGER NOT NULL, -- 1 to 52/53
        dia_nombre              VARCHAR(9) NOT NULL, -- 'Monday', 'Tuesday'...
        mes_nombre              VARCHAR(9) NOT NULL -- 'January', 'February'...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;


SELECT * FROM calendario;

-- --------------------------------------------------------------------------------------------------------------------------------

-- IMPORTAR ARCHIVO
  LOAD DATA INFILE 
'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\09_Venta X.csv'
INTO TABLE Venta
FIELDS TERMINATED BY ','
ENCLOSED BY ''
ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- --------------------------------------------------------------------------------------------------------------------------------

-- CREAR UNA BASE DE DATOS
CREATE DATABASE  IF NOT EXISTS `Modulo3`;
USE `Modulo3`;

-- --------------------------------------------------------------------------------------------------------------------------------

-- CREAR UNA TABLA
  DROP TABLE IF EXISTS Compra;
CREATE TABLE Compra (
  IdCompra INT,
  Fecha DATE,
  IdProducto INT,
  Cantidad INT,
  Precio DECIMAL(10,2),
  IdProveedor INT,
  PRIMARY KEY (IdCompra),
  FOREIGN KEY(IdProducto) REFERENCES Productos(IdProducto),
  FOREIGN KEY(IdProveedor) REFERENCES Proveedores(IdProveedor)
  );

-- --------------------------------------------------------------------------------------------------------------------------------

-- COMANDOS Y QUERYS VARIOS
SELECT Localidad FROM Localidad GROUP BY Localidad HAVING COUNT(*) > 1;		-- Para encontrar valores duplicados
SELECT * FROM Venta v JOIN Cliente c USING (IdCliente)		-- Otra función de JOIN sin usar ON.
SELECT REPLACE ('Hola Mundo','o','');		-- MUESTRA como quedaría un reemplazo
SELECT TRIM('    Hola Mundo    ');		-- Elimina los espacios en blanco
SELECT * FROM Venta WHERE Cantidad = 0;		-- Verifico cuales son igual a 0
SELECT IdCliente, COUNT(*) FROM Cliente GROUP BY IdCliente HAVING COUNT(*) > 1;		-- Cuenta los Id repetidos
SELECT DISTINCT Sucursal FROM Empleados
                UNION ALL
                SELECT DISTINCT Sucursal FROM Sucursales;		-- Consulta uniendo dos columnas de distintas tablas

ALTER TABLE Producto ADD Precio DECIMAL(10,2) NOT NULL AUTO_INCREMENT AFTER Detalle;		-- Agrega una nueva columna luego de otra
ALTER TABLE Venta CHANGE Precio Precio DECIMAL(10,2) NOT NULL DEFAULT '0';		-- Cambio tipo de dato a Decimal con Null iguales a cero
ALTER TABLE Sucursales DROP COLUMN Latitud;		-- Eliminar columna Latitud.
ALTER TABLE tabla CONVERT TO CHARACTER SET charset_name;		-- Cambiar tipo de codificación a una tabla
ALTER TABLE Venta ADD INDEX(IdProducto); 		-- Crear un index sobre una columna
ALTER TABLE Venta ADD UNIQUE INDEX(IdProducto); 		-- Crear un index sobre una columna (con índices únicos, los valores no se repiten)

UPDATE Venta SET Cantidad = REPLACE(Cantidad,'\r','');		-- Importante: sirve para eliminar los saltos de línea que impiden trabajar un campo
UPDATE Venta SET Precio = Null WHERE Precio = 0;		-- Cambio a Null los 0
UPDATE Proveedor SET Domilicio = 'Sin dato' WHERE TRIM(Domicilio) = '' OR ISNULL(Domicilio);
UPDATE Proveedores SET Direccion = CONCAT (UPPER(LEFT(Direccion,1)), LOWER(SUBSTRING(Direccion,2)));		-- Poner letra capital en la primera palabra
UPDATE Productos SET Precio = REPLACE(Precio,',','.');		-- Cambio las "comas" por un "punto"
UPDATE Sucursales SET Provincia = 'Córdoba' WHERE Provincia IN ('Cordoba','Cba','Crdoba');

CREATE TABLE tabla_nueva AS SELECT * FROM tabla_original;		-- Copiar una tabla en otra nueva (con sus datos)
CREATE TABLE tabla_nueva LIKE tabla_original		-- Crear una copia de una tabla
INSERT INTO tabla_nueva SELECT * FROM tabla_original;		-- Insertamos en una tabla el contenido de otra
DROP TABLE tabla		-- Elimina la tabla

INSERT INTO NombreTabla (PrimeraColumna,SegundaColumna,etc) VALUES (Dato1,Dato2,etc);
INSERT INTO Fact_venta SELECT IdVenta, Fecha, IdSucursal, idProducto, idCliente, Precio, Cantidad
FROM Venta WHERE YEAR(Fecha) = 2020;

CREATE INDEX IdProductoV ON Venta(IdProducto);
ALTER TABLE Venta ADD INDEX(IdProducto); 		-- Crear un index sobre una columna
DROP INDEX IdCliente ON Venta; 		-- Eliminar un índice

Set foreign_key_checks = 1; -- Con el cero desactiva las FOREIGN KEYS, y con el 1 las reactiva
TRUNCATE Personal;		-- Eliminar datos dentro de la columnaen
SET GLOBAL log_bin_trust_function_creators = 1;		-- CUANDO DA ERROR "DETERMINISTIC" AL CARGAR UNA FUNCIÓN
COLLATE utf8mb4_unicode_ci; -- Lo agregamos al final de una query para aclarar el tipo de codificación/caracter al buscar un VARCHAR.

SUM(IFNULL(v.Cantidad, 0)) AS Cantidad_productos		-- Sumamos los null. Primero el campo y luego el valor que les asignamos.

-- --------------------------------------------------------------------------------------------------------------------------------

SET @rango = '30'; -- Creando una variable y su utilización
SELECT *
FROM Clientes
WHERE Rango_Etario LIKE concat('%',@rango,'%') COLLATE utf8mb4_unicode_ci; -- Colattion cuando se usa variable o concat?????

-- --------------------------------------------------------------------------------------------------------------------------------

-- CREAR UNA VARIABLE CON UNA SUBQUERY
SELECT @varU:= COUNT(DISTINCT u.IdCliente) AS Ninguna_compra
FROM (SELECT IdCliente, COUNT(DISTINCT v.IdSucursal) AS vta 
	FROM Venta v
	WHERE YEAR(v.Fecha) = 2019
	GROUP BY v.IdCliente
	HAVING vta = 1) u;
    
-- --------------------------------------------------------------------------------------------------------------------------------

DROP FUNCTION valor_nominal;		-- Crear una función y su aplicación
DELIMITER $$
CREATE FUNCTION valor_nominal(margen_bruto DECIMAL(10,2), precio DECIMAL(15,3)) RETURNS DECIMAL(10,2) -- Asignamos un nombre, parámetros de la función y tipo de dato a retornar.
BEGIN
	DECLARE valorNominal DECIMAL(10,2); -- Declaramos las variables que van a operar en la función
	SET valorNominal = precio*(1+margen_bruto);  -- Definimos el script.
    RETURN valorNominal; -- Retornamos el valor de salida que debe coincidir con el tipo declarado en CREATE
END$$
DELIMITER ;

SELECT Concepto, valor_nominal(0.20, precio)
FROM Productos
WHERE IdTipo_Prod = 1;

-- --------------------------------------------------------------------------------------------------------------------------------

DROP PROCEDURE ventasporfecha;		-- Creando un procedimiento y su aplicación
DELIMITER $$
CREATE PROCEDURE ventasporfecha (IN fecha DATE)
BEGIN
SELECT v.Fecha, p.Concepto
FROM Productos p
JOIN venta v
ON (v.IdProducto = p.IdProducto)
WHERE v.fecha = Fecha;
END $$
DELIMITER ;

CALL ventasporfecha('2020-10-01');