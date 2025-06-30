SELECT
    SUM(cd.total_armed_robbery_cellphone) AS total_robbery_cellphone,
    SUM(cd.total_armed_robbery_auto) AS total_robbery_auto
FROM PolRouteDS.crime_data cd
JOIN PolRouteDS.time_data td ON cd.time_id = td.id
WHERE td.year = 2017;
