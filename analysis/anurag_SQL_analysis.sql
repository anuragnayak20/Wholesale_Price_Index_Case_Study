CREATE DATABASE WPI;
USE WPI;

DESCRIBE cpi_data;
DESCRIBE wpi_food;
DESCRIBE wpi_energy;

SELECT c.sector, c.cpi, c.mom_id, w.wpi
FROM cpi_data c INNER JOIN wpi_food w ON w.mom_id = c.mom_id AND c.sector = 'Rural';