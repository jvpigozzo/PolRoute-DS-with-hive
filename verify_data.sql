SELECT 'CRIME' AS table_name, COUNT(*) AS total_records FROM PolRouteDS.crime_data
UNION ALL
SELECT 'DISTRICT', COUNT(*) FROM PolRouteDS.district_data
UNION ALL
SELECT 'NEIGHBORHOOD', COUNT(*) FROM PolRouteDS.neighborhood_data
UNION ALL
SELECT 'SEGMENT', COUNT(*) FROM PolRouteDS.segment_data
UNION ALL
SELECT 'TIME', COUNT(*) FROM PolRouteDS.time_data
UNION ALL
SELECT 'VERTICE', COUNT(*) FROM PolRouteDS.vertice_data;

-- Sample data preview
SELECT 'CRIME - First 3 records:' AS info;
SELECT * FROM PolRouteDS.crime_data LIMIT 3;

SELECT 'DISTRICT - First 3 records:' AS info;
SELECT id, name, SUBSTR(geometry, 1, 50) FROM PolRouteDS.district_data LIMIT 3;

SELECT 'NEIGHBORHOOD - First 3 records:' AS info;
SELECT id, name, SUBSTR(geometry, 1, 50) FROM PolRouteDS.neighborhood_data LIMIT 3;

SELECT 'SEGMENT - First 3 records:' AS info;
SELECT id, SUBSTR(geometry, 1, 30), oneway, length, final_vertice_id, start_vertice_id FROM PolRouteDS.segment_data LIMIT 3;

SELECT 'TIME - First 3 records:' AS info;
SELECT * FROM PolRouteDS.time_data LIMIT 3;

SELECT 'VERTICE - First 3 records:' AS info;
SELECT * FROM PolRouteDS.vertice_data LIMIT 3;
