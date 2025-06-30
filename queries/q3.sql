SELECT
    SUM(cd.total_armed_robbery_cellphone) AS total_robbery_cellphone,
    SUM(cd.total_armed_robbery_auto) AS total_robbery_auto
FROM PolRouteDS.crime_data cd
JOIN PolRouteDS.time_data td ON cd.time_id = td.id
JOIN PolRouteDS.segment_data sd ON cd.segment_id = sd.id
JOIN PolRouteDS.vertice_data vd ON sd.start_vertice_id = vd.id
JOIN PolRouteDS.neighborhood_data nd ON vd.neighborhood_id = nd.id
WHERE td.year = 2015
  AND nd.name = 'SANTA EFIGÊNIA';
