SELECT *FROM cpi_data LIMIT 1;
SELECT * FROM wpi_commodity_info LIMIT 1;
SELECT * FROM wpi_energy LIMIT 2;
SELECT * FROM wpi_food LIMIT 1;
SELECT * FROM wpi_last_year_all_commodity_sql LIMIT 1;
SELECT * FROM wpi_monthly_sql LIMIT 1;

ALTER TABLE wpi_last_year_all_commodity RENAME TO wpi_last_year_all_commodity_sql; 


SELECT commodity, ROUND(AVG(weighted_index),2) AS avg_price_index 
FROM wpi_last_year_all_commodity_sql WHERE commodity LIKE '%manufacturing%'
GROUP BY commodity
UNION
SELECT commodity, ROUND(AVG(weighted_index),2) AS avg_price_index 
FROM wpi_last_year_all_commodity_sql WHERE commodity LIKE '%MANUFACTURING%'
GROUP BY commodity
UNION
SELECT commodity, ROUND(AVG(weighted_index),2) AS avg_price_index 
FROM wpi_last_year_all_commodity_sql WHERE commodity LIKE '%MANUFACTURE%'
GROUP BY commodity
ORDER BY avg_price_index DESC;

SELECT mom_id,commodity,
MAX(weighted_index) OVER (PARTITION BY commodity) AS max_price,
MIN(weighted_index) OVER (PARTITION BY commodity) AS min_price,
MAX(weighted_index) OVER (PARTITION BY commodity) - MIN(weighted_index) OVER (PARTITION BY commodity) AS volatility
FROM wpi_last_year_all_commodity_sql;

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