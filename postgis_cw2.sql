--CREATE EXTENSION postgis;
SELECT * FROM public.popp;
-- 1.Wyznacz liczbę budynków położonych w odległości mniejszej niż 1000 m od głównych rzek.
-- Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.

SELECT COUNT(geom) AS Liczba_Budynkow FROM public.popp
WHERE ST_Distance(geom, (SELECT ST_Collect(geom) FROM public.rivers)) < 1000 AND f_codedesc = 'Building';

DROP TABLE IF EXISTS tableB;
CREATE TABLE tableB (LIKE popp);

INSERT INTO tableB
SELECT * FROM public.popp
WHERE ST_Distance(geom, (SELECT ST_Collect(geom) FROM public.rivers)) < 1000 AND f_codedesc = 'Building';

SELECT * FROM tableB;

-- 2.Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
-- geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

DROP TABLE IF EXISTS airportsNew;
CREATE TABLE airportsNew(name varchar(80), geom geometry, elev numeric);

INSERT INTO airportsNew
SELECT name, geom, elev FROM public.airports;

SELECT * FROM airportsNew;

-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód.

SELECT name, elev, ST_Y(geom) AS dlugosc_geo FROM airportsNew ORDER BY ST_X(geom) LIMIT 1; --najbardziej na zachód
SELECT name, elev, ST_Y(geom) AS dlugosc_geo FROM airportsNew ORDER BY ST_X(geom) DESC LIMIT 1; --najbardziej na wschód

-- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
-- środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
-- Wysokość n.p.m. przyjmij dowolną.
-- Uwaga: geodezyjny układ współrzędnych prostokątnych płaskich (x – oś pionowa, y – oś pozioma)

DELETE FROM airportsNew WHERE name = 'airportB';
INSERT INTO airportsNew (name, geom, elev)
VALUES
	('airportB', --nazwa Lotniska
	(SELECT * FROM ST_LineInterpolatePoint( --geometria lotniska (polowa drogi między skrajnymi lotniskami na dlugosci geograficznej)
		(SELECT * FROM ST_MakeLine(
			(SELECT geom AS dlugosc_geo FROM airportsNew ORDER BY ST_X(geom) LIMIT 1),
			(SELECT geom AS dlugosc_geo FROM airportsNew ORDER BY ST_X(geom) DESC LIMIT 1))), 0.5)),
	0); --wysokosc lotniska n.p.m.

SELECT * FROM airportsNew;

-- 3. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
-- linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT * FROM ST_Area( --Pole powierzchni obszar
    ST_Buffer( --Obszar to bufor do 1000 jednostek od linii
        (SELECT * FROM ST_ShortestLine( --Najkrótsza linia między dwoma obiektami
            (SELECT geom FROM lakes WHERE names = 'Iliamna Lake'),
            (SELECT geom FROM airports WHERE name = 'AMBLER'))), 
        1000));

-- 4. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
-- poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).

SELECT vegdesc, ST_Intersection(
	ST_Union(geom),
	(SELECT * FROM ST_Intersection(
		(SELECT ST_Union(geom) FROM swamp),
		(SELECT ST_Union(geom) FROM tundra))))
FROM trees GROUP BY vegdesc;
