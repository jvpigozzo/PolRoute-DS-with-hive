-- Create database
CREATE DATABASE IF NOT EXISTS PolRouteDS;

-- CRIME table
DROP TABLE IF EXISTS PolRouteDS.crime_data;
CREATE TABLE PolRouteDS.crime_data (
    id INT,
    total_feminicide INT,
    total_homicide INT,
    total_felony_murder INT,
    total_bodily_harm INT,
    total_theft_cellphone INT,
    total_armed_robbery_cellphone INT,
    total_theft_auto INT,
    total_armed_robbery_auto INT,
    segment_id INT,
    time_id INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE;

-- DISTRICT table
DROP TABLE IF EXISTS PolRouteDS.district_data;
CREATE TABLE PolRouteDS.district_data (
    id INT,
    name STRING,
    geometry STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE;

-- NEIGHBORHOOD table
DROP TABLE IF EXISTS PolRouteDS.neighborhood_data;
CREATE TABLE PolRouteDS.neighborhood_data (
    id INT,
    name STRING,
    geometry STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE;

-- SEGMENT table
DROP TABLE IF EXISTS PolRouteDS.segment_data;
CREATE TABLE PolRouteDS.segment_data (
    id INT,
    geometry STRING,
    oneway STRING,
    length DOUBLE,
    final_vertice_id INT,
    start_vertice_id INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE;

-- TIME table
DROP TABLE IF EXISTS PolRouteDS.time_data;
CREATE TABLE PolRouteDS.time_data (
    id INT,
    period STRING,
    day INT,
    month INT,
    year INT,
    weekday STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE;

-- VERTICE table
DROP TABLE IF EXISTS PolRouteDS.vertice_data;
CREATE TABLE PolRouteDS.vertice_data (
    id INT,
    label STRING,
    district_id INT,
    neighborhood_id INT,
    zone_id INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE;
