-- DDL part of analysis
START transaction;
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE wpi_energy ADD date DATE AFTER mom_id;
UPDATE wpi_energy SET date = STR_TO_DATE(CONCAT('01-',RIGHT(mom_id,3),'-',LEFT(mom_id,4)),'%d-%M-%Y');

ALTER TABLE wpi_food ADD date DATE AFTER mom_id;
UPDATE wpi_food SET date = STR_TO_DATE(CONCAT('01-',RIGHT(mom_id,3),'-',LEFT(mom_id,4)),'%d-%M-%Y');

ALTER TABLE wpi_last_year_all_commodity_sql ADD date DATE AFTER mom_id;
UPDATE wpi_last_year_all_commodity_sql SET date = STR_TO_DATE(CONCAT('01-',RIGHT(mom_id,3),'-',LEFT(mom_id,4)),'%d-%M-%Y');

ALTER TABLE wpi_monthly_sql ADD date DATE AFTER mom_id;
UPDATE wpi_monthly_sql SET date = STR_TO_DATE(CONCAT('01-',RIGHT(mom_id,3),'-',LEFT(mom_id,4)),'%d-%M-%Y');
commit;

-- creating views for wpi subsets
-- 1. food
CREATE VIEW wpi_food_view AS
SELECT mom_id, date, commodity, weighted_index FROM wpi_comm 
WHERE 
LOWER(commodity) LIKE '%food%'
OR LOWER(commodity) LIKE '%sugar%'
OR LOWER(commodity) LIKE '%spice%';
-- 2. manufacturing
CREATE VIEW wpi_mfg_view AS
SELECT mom_id, date, commodity, weighted_index 
FROM wpi_comm 
WHERE LOWER(commodity) LIKE '%manufacturing%' OR LOWER(commodity) LIKE '%manufacture%';
-- 3. fuel, energy
CREATE VIEW wpi_energy_view AS 
SELECT mom_id, date, commodity, weighted_index FROM wpi_comm 
WHERE LOWER(commodity) LIKE '%fuel%' OR LOWER(commodity) LIKE '%power%'
OR LOWER(commodity) LIKE '%energy%'
OR LOWER(commodity) LIKE '%kerosene%'
OR LOWER(commodity) LIKE '%petroluem%'
OR LOWER(commodity) LIKE '%coal%'
OR LOWER(commodity) LIKE '%lignite%'
OR LOWER(commodity) LIKE '%bitumen%'
OR LOWER(commodity) LIKE '%electricity%'
OR LOWER(commodity) LIKE '%lpg%'
OR LOWER(commodity) LIKE '%natural gas%';

-- these will be subqueries to derive wpi for specific sub categories
-- wpi value of only mfg
SELECT 
mom_id,date, ROUND(AVG(weighted_index),2) AS wpi_mfg
FROM wpi_mfg_view
GROUP BY mom_id, date
ORDER BY date;
-- wpi value of only energy
SELECT 
mom_id,date, ROUND(AVG(weighted_index),2) AS wpi_energy
FROM wpi_energy_view
GROUP BY mom_id, date
ORDER BY date;
-- wpi value of only food
SELECT mom_id, date, ROUND(AVG(weighted_index),2) AS wpi_food
FROM wpi_food_view
GROUP BY mom_id, date
ORDER BY date;

-- full WPI
SELECT mom_id, wpi FROM wpi_monthly_sql;

