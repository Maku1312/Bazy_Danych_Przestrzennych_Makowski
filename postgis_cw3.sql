--1. Znajdź budynki, które zostały wybudowane lub wyremontowane na przestrzeni roku (zmiana pomiędzy 2018 a 2019).

SELECT COUNT(t1.*) FROM T2019_KAR_BUILDINGS AS t1, T2018_KAR_BUILDINGS AS t2
WHERE NOT t1.height = t2.height
--ST_Equals(t1.geom, t2.geom)
AND t1.gid = t2.gid;

--2. Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub wybudowanych budynków,
--    które znalezione zostały w zadaniu 1. Policz je wg ich kategorii.

SELECT *
FROM T2019_KAR_POI_TABLE AS t1
LEFT JOIN T2018_KAR_POI_TABLE AS t2 ON (t1.gid = t2.gid) --Dołączam do tabeli punktów 2019 tabelę 2018
WHERE t2.gid IS NULL --z warunkiem że t2.gid (czyli indeks punktu 2018) nie istnieje, czlyi jest nowy
AND ST_Distance( --oraz że odległość od obiektu jest mniejsza niż 500 metrów
        ST_SetSRID(t1.geom,4326)::geography, --Wybieram punkty 2019 jako pierwszy argument funkcji ST_Distance
        (SELECT ST_Collect(ST_SetSRID(t11.geom,4326))::geography --Wybieram wszystkie remontowane budynki jako multipoligon jako drugi argument funkcji ST_Distance
            FROM T2019_KAR_BUILDINGS AS t11, T2018_KAR_BUILDINGS AS t12 --Wybieram budynki z dwóch tablic (2018 i 2019), żeby dobrać te które były remontowane
            WHERE NOT t11.height = t12.height --Warunek remontu
            AND t11.gid = t12.gid)) < 500;

--3. Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
--    T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.

DROP TABLE IF EXISTS streets_reprojected;
CREATE TABLE streets_reprojected AS SELECT * FROM T2019_KAR_STREETS;
UPDATE streets_reprojected SET geom = ST_Transform(ST_SetSRID(geom, 4326), 3068);
SELECT * FROM streets_reprojected;

--4. Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
--    Użyj następujących współrzędnych:
--    X Y
--     8.36093 49.03174
--     8.39876 49.00644
--    Przyjmij układ współrzędnych GPS.

DROP TABLE IF EXISTS input_points;
CREATE TABLE input_points(id SMALLINT, geom geometry);
INSERT INTO input_points VALUES
	(0, ST_GeomFromText('POINT(8.36093 49.03174)'),
	(1, ST_GeomFromText('POINT(8.39876 49.00644)');


--5. Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie współrzędnych
--   DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText().

UPDATE input_points SET geom = ST_Transform(geom,3068);
SELECT id, ST_ASText(geom) FROM input_points;

--6. Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej
--   z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. Dokonaj
--   reprojekcji geometrii, aby była zgodna z resztą tabel.

SELECT * FROM T2019_KAR_STREET_NODE WHERE
    ST_DWithin(
        ST_SetSRID(geom, 4326)::geography,
        (SELECT ST_Transform(ST_MakeLine(geom),4326)::geography FROM input_points),
        200);

--7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się
--   w odległości 300 m od parków (LAND_USE_A).

SELECT COUNT(*) FROM T2019_KAR_POI_TABLE
WHERE type = 'Sporting Goods Store'
AND ST_DWithin(
    geom::geography,
    (SELECT ST_Collect(geom)::geography FROM T2019_KAR_LAND_USE_A WHERE type = 'Park (City/County)'),
    300);

--8. Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz
--   znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.

DROP TABLE IF EXISTS T2019_KAR_BRIDGES;
CREATE TABLE T2019_KAR_BRIDGES AS 
SELECT gid, ST_Intersection(geom, (SELECT ST_Collect(geom) FROM T2019_KAR_WATER_LINES)) FROM T2019_KAR_RAILWAYS;

SELECT * FROM T2019_KAR_BRIDGES;