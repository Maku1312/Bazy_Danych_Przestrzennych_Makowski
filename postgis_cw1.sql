-- CREATE EXTENSION postgis;

-- 0. Tworzenie tabel:

-- budynki
DROP TABLE buildings;
CREATE TABLE buildings(id INT, geometria GEOMETRY, nazwa VARCHAR(50), wysokosc INT);

-- drogi
DROP TABLE roads;
CREATE TABLE roads(id INT, geometria GEOMETRY, nazwa VARCHAR(50));

-- pktinfo
DROP TABLE pktinfo;
CREATE TABLE pktinfo(id INT, geometria GEOMETRY, nazwa VARCHAR(50), liczprac INT);

-- Wpisanie danych z zadania do tabel

INSERT INTO buildings(id, geometria, nazwa, wysokosc) VALUES
(1, ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))'), 'BuildingA', 5),
(2, ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))'), 'BuildingB', 4),
(3, ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))'), 'BuildingC', 4),
(4, ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))'), 'BuildingD', 2),
(5, ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))'), 'BuildingF', 2);

INSERT INTO roads(id, geometria, nazwa) VALUES
(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'), 'RoadX'),
(2, ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)'), 'RoadY');

INSERT INTO pktinfo(id, geometria, nazwa, liczprac) VALUES
(1, ST_GeomFromText('POINT(1 3.5)'), 'G', 0),
(2, ST_GeomFromText('POINT(5.5 1.5)'), 'H', 0),
(3, ST_GeomFromText('POINT(9.5 6)'), 'I', 0),
(4, ST_GeomFromText('POINT(6.5 6)'), 'J', 0),
(5, ST_GeomFromText('POINT(6 9.5)'), 'K', 0);

-- 1. Wyznacz całkowitą długość dróg w analizowanym mieście.

SELECT SUM(ST_Length(geometria)) AS total_length FROM roads;

-- 2. Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego BuildingA.

SELECT ST_Area(geometria) AS Area, ST_Perimeter(geometria) AS Perimeter FROM buildings WHERE nazwa = 'BuildingA';

-- 3. Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki.
-- Wyniki posortuj alfabetycznie.

SELECT nazwa, ST_Area(geometria) AS Area FROM buildings
ORDER BY nazwa;

-- 4. Wypisz nazwy i obwody 2 budynków o największej powierzchni.

SELECT nazwa, perimeter FROM 
(SELECT nazwa, ST_Area(geometria) AS Area, ST_Perimeter(geometria) AS Perimeter FROM buildings
ORDER BY Area DESC) buildings_subquery
LIMIT 2;

-- 5. Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.

SELECT * FROM ST_Distance((SELECT geometria FROM buildings WHERE nazwa = 'BuildingC'),
                          (SELECT geometria FROM pktinfo WHERE nazwa = 'G'));

-- 6. Wypisz pole powierzchni tej części budynku BuildingC,
-- która znajduje się w odległości większej niż 0.5 od budynku BuildingB.

SELECT * FROM ST_Area(ST_Difference((SELECT geometria FROM buildings WHERE nazwa = 'BuildingC'),
(SELECT * FROM ST_Buffer((SELECT geometria FROM buildings WHERE nazwa = 'BuildingB'), 0.5))));

-- 7. Wybierz te budynki, których centroid (ST_Centroid) znajduje się powyżej drogi RoadX.

SELECT nazwa FROM buildings
WHERE ST_Y(ST_Centroid(geometria)) >
(SELECT ST_Y(ST_PointN(geometria, 1)) FROM roads WHERE nazwa = 'RoadX');

-- 8. Oblicz pole powierzchni tych części budynku BuildingC i poligonu
-- o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch obiektów.

SELECT * FROM 
ST_Area(ST_Union(
    ST_Difference( --Tworzę różnicę poligonów: budynek C - część wspólna
        (SELECT geometria FROM buildings WHERE nazwa = 'BuildingC'), --Budynek C (odejmuję od niego część wspólną)
        (SELECT * FROM ST_Intersection( --Część wspólna poligonów
            (ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')),
            (SELECT geometria FROM buildings WHERE nazwa = 'BuildingC')))),
    ST_Difference( --Tworzę różnicę poligonów: nowy budynek - część wspólna
        (SELECT * FROM ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')), --Nowy poligon (odejmuję od niego część wspólną)
        (SELECT * FROM ST_Intersection( --Część wspólna poligonów
            (ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))')),
            (SELECT geometria FROM buildings WHERE nazwa = 'BuildingC'))))
    )); -- Pole = budynek C + nowy budynek - 2*(część wspólna)
	
SELECT * FROM
ST_Area(ST_SymDifference((SELECT geometria FROM buildings WHERE nazwa = 'BuildingC'), (ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))))