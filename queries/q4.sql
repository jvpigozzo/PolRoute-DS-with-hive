SELECT
    cd.segment_id,
    SUM(cd.total_feminicide) AS total_feminicide,
    SUM(cd.total_homicide) AS total_homicide,
    SUM(cd.total_felony_murder) AS total_felony_murder,
    SUM(cd.total_bodily_harm) AS total_bodily_harm,
    SUM(cd.total_theft_cellphone) AS total_theft_cellphone,
    SUM(cd.total_armed_robbery_cellphone) AS total_armed_robbery_cellphone,
    SUM(cd.total_theft_auto) AS total_theft_auto,
    SUM(cd.total_armed_robbery_auto) AS total_armed_robbery_auto
FROM PolRouteDS.crime_data cd
JOIN PolRouteDS.time_data td ON cd.time_id = td.id
JOIN PolRouteDS.segment_data sd ON cd.segment_id = sd.id
WHERE td.year = 2012
  AND LOWER(sd.oneway) = 'yes'
GROUP BY cd.segment_id;
