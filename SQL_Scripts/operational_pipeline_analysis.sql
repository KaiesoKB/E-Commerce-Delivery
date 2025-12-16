# OPERATIONAL PIPELINE BREAKDOWN
USE ecommerce_delivery;

# Identifying the average time taken at each operations from purchase -> pickup/delivery for non late orders
SELECT ROUND(AVG(od.apporval_time_mins), 2) AS "Average approval time for non late orders", -- -> 566.52 mins
	 ROUND(AVG(od.carrier_pickup_time_mins), 2) AS "Average pickup time for carriers for non late orders", -- 3780.93 mins
     ROUND(AVG(od.shipping_time_mins), 2) AS "Average shipping time for non late orders", -- 11390.85 mins
     ROUND(AVG(od.total_delivery_time_mins), 2) AS "Average delivery time for non late orders" -- 15738.23 mins
FROM orders_duration od
WHERE od.order_delay_time_mins = 0;

# Identifying the average time taken at each operations from purchase -> pickup/delivery for late orders
SELECT ROUND(AVG(od.apporval_time_mins), 2) AS "Average approval time for non late orders", -- -> 722.94 mins
	 ROUND(AVG(od.carrier_pickup_time_mins), 2) AS "Average pickup time for carriers for non late orders", -- 7667.39 mins
     ROUND(AVG(od.shipping_time_mins), 2) AS "Average shipping time for non late orders", -- 37018.56 mins
     ROUND(AVG(od.total_delivery_time_mins), 2) AS "Average delivery time for non late orders" -- 45408.84 mins
FROM orders_duration od
WHERE od.order_delay_time_mins > 0;
-- Late orders have higher average times across each stage in the operatonal pipeline 

# Identifying the range of times for each operation
SELECT MIN(od.apporval_time_mins) AS "Min order approval time",
	MAX(od.apporval_time_mins) AS "Max order approval time", -- 0 -> 44487
	MIN(od.carrier_pickup_time_mins) AS "Min order carrier pickup time",
    MAX(od.carrier_pickup_time_mins) AS "Maax order carrier pickup time", -- 0 -> 154157
	MIN(od.shipping_time_mins) AS "Min order shipping time",
    MAX(od.shipping_time_mins) AS "Max order shipping time", -- 0 -> 295475
	MIN(od.total_delivery_time_mins) AS "Min total delivery time",
    MAX(od.total_delivery_time_mins) AS "Max total delivery time" -- 768 -> 301865
FROM orders_duration od;

# Identifying if higher approval times lead to higher late delivery rates
SELECT 
	CASE 
		WHEN od.apporval_time_mins <= 200 THEN '0-200'
		WHEN od.apporval_time_mins <= 500 THEN '200-500'
		WHEN od.apporval_time_mins <= 800 THEN '500-800'
		WHEN od.apporval_time_mins <= 1200 THEN '800-1200'
		WHEN od.apporval_time_mins <= 1500 THEN '1200-1500'
        WHEN od.apporval_time_mins <= 2000 THEN '1500-2000'
		ELSE '2000+'
	END AS "approval time bucket",
    COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
    COUNT(od.order_id) AS "Total orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of orders that were late per approval time bucket"
FROM orders_duration od
GROUP BY 
	CASE 
		WHEN od.apporval_time_mins <= 200 THEN '0-200'
		WHEN od.apporval_time_mins <= 500 THEN '200-500'
		WHEN od.apporval_time_mins <= 800 THEN '500-800'
		WHEN od.apporval_time_mins <= 1200 THEN '800-1200'
		WHEN od.apporval_time_mins <= 1500 THEN '1200-1500'
		WHEN od.apporval_time_mins <= 2000 THEN '1500-2000'
		ELSE '2000+'
	END
ORDER BY ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) DESC;
-- 500 -> 800 has lowest late delivery rate (6.90%), 2000+ has highest late delivery rate (10.55%)
-- Extreme values of approval time tend to be linked to higher likelihood of late delivery. 
-- However approval time  by itself is not a reliable predictor of late deliveries across its full range
-- Most orders (65255) take between 0 -> 200 minutes for approval

# Identifying if higher carrier pickup times lead to higher late delivery rates
SELECT 
	CASE 
		WHEN od.carrier_pickup_time_mins <= 500 THEN '0-500'
		WHEN od.carrier_pickup_time_mins <= 1200 THEN '500-1200'
		WHEN od.carrier_pickup_time_mins <= 2500 THEN '1200-2500'
		WHEN od.carrier_pickup_time_mins <= 5000 THEN '2500-5000'
		WHEN od.carrier_pickup_time_mins <= 10000 THEN '5000-10000'
        WHEN od.carrier_pickup_time_mins <= 20000 THEN '10000-20000'
        WHEN od.carrier_pickup_time_mins <= 35000 THEN '20000-35000'
        WHEN od.carrier_pickup_time_mins <= 50000 THEN '35000-50000'
        WHEN od.carrier_pickup_time_mins <= 100000 THEN '50000-100000'
		ELSE '100000+'
	END AS "carrier pickup time bucket",
    COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
    COUNT(od.order_id) AS "Total orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of orders that were late per carrier pickup time bucket"
FROM orders_duration od
GROUP BY 
	CASE 
		WHEN od.carrier_pickup_time_mins <= 500 THEN '0-500'
		WHEN od.carrier_pickup_time_mins <= 1200 THEN '500-1200'
		WHEN od.carrier_pickup_time_mins <= 2500 THEN '1200-2500'
		WHEN od.carrier_pickup_time_mins <= 5000 THEN '2500-5000'
		WHEN od.carrier_pickup_time_mins <= 10000 THEN '5000-10000'
        WHEN od.carrier_pickup_time_mins <= 20000 THEN '10000-20000'
        WHEN od.carrier_pickup_time_mins <= 35000 THEN '20000-35000'
        WHEN od.carrier_pickup_time_mins <= 50000 THEN '35000-50000'
        WHEN od.carrier_pickup_time_mins <= 100000 THEN '50000-100000'
		ELSE '100000+'
	END
ORDER BY ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) DESC;
-- Late delivery likelihood is strongly correlated with carrier pickup time. Longer pickup delays significantly increase higher late delivery risk
-- Thousands orders up to 10000 mins carrier pickup time and even up to 35000 mins carrier pickup time contains large enough sample of data to support this
-- GENERATE GRAPH TO DEMONSTRATE THIS

# Identifying if higher shipping times lead to higher late delivery rates
