SELECT * FROM wpi_mfg_view;
SELECT * FROM wpi_food_view;
SELECT * FROM wpi_energy_view;

-- 4.2. mom growth of mfg, primary articles, fuel & power and whole wpi
-- of only mfg
WITH wpi_mfg_mom AS (
SELECT m.mom_id, m.wpi_mfg,
(m.wpi_mfg - LAG(m.wpi_mfg,1,NULL) OVER (ORDER BY m.date))*100/LAG(m.wpi_mfg,1,NULL) OVER (ORDER BY m.date) AS mom_growth
FROM
(SELECT 
mom_id,date, AVG(weighted_index) AS wpi_mfg
FROM wpi_mfg_view
GROUP BY mom_id, date) m
)
SELECT 
ROUND(MAX(mom_growth),2) AS max_mom_perc,
ROUND(MIN(mom_growth),2) AS min_mom_perc,
ROUND(stddev_samp(mom_growth),3) AS stddev_mom_growth,
COUNT(mom_growth) AS total_months,
(SELECT COUNT(mom_growth) FROM wpi_mfg_mom WHERE mom_growth > 0) AS inflation_months,
ROUND((SELECT COUNT(mom_growth) FROM wpi_mfg_mom WHERE mom_growth > 0)*100/COUNT(mom_growth),0) AS pos_mom_perc
FROM wpi_mfg_mom;

-- of only food
WITH wfm AS (
SELECT f.mom_id,f.wpi_foodstuff,
(f.wpi_foodstuff - LAG(f.wpi_foodstuff,1,NULL) OVER (ORDER BY f.date))*100/LAG(f.wpi_foodstuff,1,NULL) OVER (ORDER BY f.date) 
AS mom_growth
FROM
(SELECT mom_id, date, AVG(weighted_index) AS wpi_foodstuff FROM wpi_food_view GROUP BY mom_id, date) f
)
SELECT 
ROUND(MAX(wfm.mom_growth),2) AS max_inflation,
ROUND(MIN(wfm.mom_growth),2) AS min_inflation,
ROUND(STDDEV_SAMP(wfm.mom_growth),2) AS stdev_food_inflation,
COUNT(wfm.mom_growth) AS total_months,(SELECT COUNT(wfm.mom_growth) FROM wfm WHERE wfm.mom_growth > 0) AS inflation_months
FROM wfm;

-- energy only
WITH wem AS ( -- this cte give food mom calculation
SELECT e.mom_id,e.wpi_fuel,
(e.wpi_fuel - LAG(e.wpi_fuel,1,NULL) OVER (ORDER BY e.date))*100/LAG(e.wpi_fuel,1,NULL) OVER (ORDER BY e.date) 
AS mom_growth
FROM
(SELECT mom_id, date, AVG(weighted_index) AS wpi_fuel FROM wpi_energy_view GROUP BY mom_id, date) e -- get wpi of food only
) -- cte used as i can't use subquery in SELECT clause unless table already defined
SELECT 
ROUND(MAX(wem.mom_growth),2) AS max_inflation,
ROUND(MIN(wem.mom_growth),2) AS min_inflation,
ROUND(STDDEV_SAMP(wem.mom_growth),2) AS stdev_energy_inflation,
COUNT(wem.mom_growth) AS total_months,(SELECT COUNT(wem.mom_growth) FROM wem WHERE wem.mom_growth > 0) AS inflation_months
FROM wem;
-- full wpi mom peak
SELECT wm.mom_id, wm.mom_inflation
FROM
( -- wpi mom calculation subquery
SELECT 
mom_id, 
(wpi - LAG(wpi,1) OVER (ORDER BY date))*100/LAG(wpi,1) OVER (ORDER BY date) AS mom_inflation
FROM wpi_monthly_sql) wm
ORDER BY wm.mom_inflation DESC
LIMIT 1;

-- wpi yoy eda
SELECT wy.year, (wy.wpi - LAG(wy.wpi,1) OVER (ORDER BY wy.year))*100/LAG(wy.wpi,1) OVER (ORDER BY wy.year) AS yoy_perc
FROM
(SELECT YEAR(date) AS year, AVG(wpi) AS wpi FROM wpi_monthly_sql GROUP BY YEAR(date)) wy
;

-- 4.4 relationship between weights and correlation of commodities w.r.t. WPI
SELECT (SELECT COUNT(t1.commodity) FROM wpi_comm_info t1) AS total_commodities, 
COUNT(t2.commodity) AS high_correl_but_low_weight
FROM
(SELECT commodity, commodity_weight, correlation_coefficient
FROM wpi_comm_info
WHERE correlation_coefficient > commodity_weight) t2;

-- commodities with bias
SELECT commodity FROM wpi_comm_info WHERE commodity_weight > correlation_coefficient ORDER BY commodity_weight DESC;

-- 4.5 wpi and cpi linkage
WITH wpi_cpi_mom AS ( -- cte to get wpi inflation months link with cpi inflation months
SELECT wc.mom_id, 
ROUND((wc.wpi - LAG(wc.wpi,1) OVER (ORDER BY wc.date))*100/LAG(wc.wpi,1) OVER (ORDER BY wc.date),3) AS wpi,
ROUND((wc.cpi_r - LAG(wc.cpi_r,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_r,1) OVER (ORDER BY wc.date),3) AS cpi_r,
ROUND((wc.cpi_u - LAG(wc.cpi_u,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_u,1) OVER (ORDER BY wc.date),3) AS cpi_u,
ROUND((wc.cpi_ru - LAG(wc.cpi_ru,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_ru,1) OVER (ORDER BY wc.date),3) AS cpi_ru
FROM (
-- wpi + cpi merge
SELECT w.mom_id, w.date, w.wpi, cr.cpi AS cpi_r, cu.cpi AS cpi_u, cru.cpi AS cpi_ru
FROM wpi_monthly_sql w INNER JOIN cpi_data cr ON w.mom_id=cr.mom_id AND cr.Sector = 'Rural'
INNER JOIN cpi_data cu ON w.mom_id=cu.mom_id AND cu.Sector = 'Urban'
INNER JOIN cpi_data cru ON w.mom_id = cru.mom_id AND cru.Sector = 'Rural+Urban'
ORDER BY w.date) wc)
SELECT 
SUM(CASE WHEN wpi>0 THEN 1 ELSE 0 END) AS wpi_inflation_months,
SUM( CASE WHEN wpi > 0 AND cpi_r > 0 THEN 1 ELSE 0 END) AS wpi_cpi_r_infation_months,
SUM( CASE WHEN wpi > 0 AND cpi_u > 0 THEN 1 ELSE 0 END) AS wpi_cpi_u_inflation_months, 
SUM( CASE WHEN wpi > 0 AND cpi_ru > 0 THEN 1 ELSE 0 END) AS wpi_cpi_ru_inflation_months
FROM wpi_cpi_mom;

WITH wpi_cpi_mom AS ( -- cte to get wpi deflation months link with cpi deflation months
SELECT wc.mom_id, 
ROUND((wc.wpi - LAG(wc.wpi,1) OVER (ORDER BY wc.date))*100/LAG(wc.wpi,1) OVER (ORDER BY wc.date),3) AS wpi,
ROUND((wc.cpi_r - LAG(wc.cpi_r,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_r,1) OVER (ORDER BY wc.date),3) AS cpi_r,
ROUND((wc.cpi_u - LAG(wc.cpi_u,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_u,1) OVER (ORDER BY wc.date),3) AS cpi_u,
ROUND((wc.cpi_ru - LAG(wc.cpi_ru,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_ru,1) OVER (ORDER BY wc.date),3) AS cpi_ru
FROM (
-- wpi + cpi merge
SELECT w.mom_id, w.date, w.wpi, cr.cpi AS cpi_r, cu.cpi AS cpi_u, cru.cpi AS cpi_ru
FROM wpi_monthly_sql w INNER JOIN cpi_data cr ON w.mom_id=cr.mom_id AND cr.Sector = 'Rural'
INNER JOIN cpi_data cu ON w.mom_id=cu.mom_id AND cu.Sector = 'Urban'
INNER JOIN cpi_data cru ON w.mom_id = cru.mom_id AND cru.Sector = 'Rural+Urban'
ORDER BY w.date) wc)
SELECT 
SUM(CASE WHEN wpi< 0 THEN 1 ELSE 0 END) AS wpi_deflation_months,
SUM( CASE WHEN wpi < 0 AND cpi_r < 0 THEN 1 ELSE 0 END) AS wpi_cpi_r_deflation_months,
SUM( CASE WHEN wpi < 0 AND cpi_u < 0 THEN 1 ELSE 0 END) AS wpi_cpi_u_deflation_months, 
SUM( CASE WHEN wpi < 0 AND cpi_ru < 0 THEN 1 ELSE 0 END) AS wpi_cpi_ru_deflation_months
FROM wpi_cpi_mom;

WITH wpi_cpi_mom AS ( -- cte to get wpi and cpi extreme trends 
SELECT wc.mom_id, 
ROUND((wc.wpi - LAG(wc.wpi,1) OVER (ORDER BY wc.date))*100/LAG(wc.wpi,1) OVER (ORDER BY wc.date),3) AS wpi,
ROUND((wc.cpi_r - LAG(wc.cpi_r,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_r,1) OVER (ORDER BY wc.date),3) AS cpi_r,
ROUND((wc.cpi_u - LAG(wc.cpi_u,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_u,1) OVER (ORDER BY wc.date),3) AS cpi_u,
ROUND((wc.cpi_ru - LAG(wc.cpi_ru,1) OVER (ORDER BY wc.date))*100/LAG(wc.cpi_ru,1) OVER (ORDER BY wc.date),3) AS cpi_ru
FROM (
-- wpi + cpi merge
SELECT w.mom_id, w.date, w.wpi, cr.cpi AS cpi_r, cu.cpi AS cpi_u, cru.cpi AS cpi_ru
FROM wpi_monthly_sql w INNER JOIN cpi_data cr ON w.mom_id=cr.mom_id AND cr.Sector = 'Rural'
INNER JOIN cpi_data cu ON w.mom_id=cu.mom_id AND cu.Sector = 'Urban'
INNER JOIN cpi_data cru ON w.mom_id = cru.mom_id AND cru.Sector = 'Rural+Urban'
ORDER BY w.date) wc)
SELECT 
SUM(CASE WHEN cpi_ru IS NOT NULL THEN 1 ELSE 0 END)+1 AS cpi_recorded_months,
SUM(CASE WHEN cpi_ru < 2 THEN 1 ELSE 0 END) AS cpi_lower_limit_breach_months,
SUM(CASE WHEN cpi_ru < 2 AND wpi < 0 THEN 1 ELSE 0 END) AS wpi_deflation_cpi_below_2,
SUM(CASE WHEN cpi_ru > 6 THEN 1 ELSE 0 END) AS cpi_upper_limit_breach_months,
SUM(CASE WHEN cpi_ru > 6 AND wpi > 0 THEN 1 ELSE 0 END) AS wpi_inflation_cpi_above_6
FROM wpi_cpi_mom;