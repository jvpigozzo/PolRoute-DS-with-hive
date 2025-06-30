SELECT
    cd.segment_id,
    SUM(
        cd.total_feminicide + cd.total_homicide + cd.total_felony_murder +
        cd.total_bodily_harm + cd.total_theft_cellphone + cd.total_armed_robbery_cellphone +
        cd.total_theft_auto + cd.total_armed_robbery_auto
    ) AS total_crimes
FROM PolRouteDS.crime_data cd
JOIN PolRouteDS.time_data td ON cd.time_id = td.id
WHERE td.year = 2018
  AND LOWER(td.weekday) IN ('saturday', 'sunday')
GROUP BY cd.segment_id
ORDER BY total_crimes DESC;
