DROP TABLE IF EXISTS obiekty;
CREATE TABLE obiekty (id SMALLINT, nazwa VARCHAR(50), geom geometry);
INSERT INTO obiekty
VALUES
    (1, 'obiekt1', ST_GeomFromEWKT(
                                    'COMPOUNDCURVE((0 1, 1 1),
                                    CIRCULARSTRING(1 1, 2 0, 3 1),
                                    CIRCULARSTRING(3 1, 4 2, 5 1),
                                    (5 1, 6 1))')),
    (2, 'obiekt2', ST_GeomFromEWKT('CURVEPOLYGON
										(COMPOUNDCURVE(
								        (10 6, 14 6), 
								        CIRCULARSTRING(14 6, 16 4, 14 2),
										CIRCULARSTRING(14 2, 12 0, 10 2),
								        (10 2, 10 6)),
								  CIRCULARSTRING(11 2,12 3,13 2,12 1,11 2))')),
    (3, 'obiekt3', ST_GeomFromText('POLYGON((7 15, 10 17, 12 13, 7 15))')),
    (4, 'obiekt4', ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)')),
    (5, 'obiekt5', ST_GeomFromText('MULTIPOINT(30 30 59, 38 32 234)')),
    (6, 'obiekt6', ST_Union(ST_GeomFromText('LINESTRING(1 1, 3 2)'), ST_GeomFromText('POINT(4 2)')));
	
-- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek,
-- który został utworzony wokół najkrótszej linii łączącej obiekt 3 i 4.

SELECT * FROM ST_Area(ST_Buffer(ST_ShortestLine((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'), (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')), 5));

-- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie?
-- Zapewnij te warunki.

UPDATE obiekty SET geom = ST_MakePolygon(ST_AddPoint(geom, ST_StartPoint(geom))) WHERE nazwa = 'obiekt4';

-- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty
VALUES (7, 'obiekt7', ST_Union((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'), (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')));

-- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek,
-- które zostały utworzone wokół obiektów nie zawierających łuków.

SELECT SUM(ST_Area(ST_Buffer(geom, 5))) FROM obiekty WHERE ST_HasArc(geom) = FALSE;