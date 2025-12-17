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
SELECT ROUND(AVG(od.apporval_time_mins), 2) AS "Average approval time for late orders", -- -> 722.94 mins
	 ROUND(AVG(od.carrier_pickup_time_mins), 2) AS "Average pickup time for carriers for late orders", -- 7667.39 mins
     ROUND(AVG(od.shipping_time_mins), 2) AS "Average shipping time for late orders", -- 37018.56 mins
     ROUND(AVG(od.total_delivery_time_mins), 2) AS "Average delivery time for late orders" -- 45408.84 mins
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
		WHEN od.carrier_pickup_time_mins <= 720 THEN '0-720' -- 1/2 day
		WHEN od.carrier_pickup_time_mins <= 1440 THEN '720-1440' -- 1 day
		WHEN od.carrier_pickup_time_mins <= 2880 THEN '1440-2880' -- 2 days
		WHEN od.carrier_pickup_time_mins <= 4320 THEN '2880-4320' -- 3 days
		WHEN od.carrier_pickup_time_mins <= 5760 THEN '4320-5760' -- 4 days
        WHEN od.carrier_pickup_time_mins <= 7200 THEN '5760-7200' -- 5 days
        WHEN od.carrier_pickup_time_mins <= 10080 THEN '7200-10080' -- 5-7 days
        WHEN od.carrier_pickup_time_mins <= 20160 THEN '10080-20160' -- 1-2 weeks
        WHEN od.carrier_pickup_time_mins <= 30240 THEN '20160-30240' -- 2-3 weeks
		ELSE '30240+' -- 3+ weeks
	END AS "carrier pickup time bucket",
    COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
    COUNT(od.order_id) AS "Total orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of orders that were late per carrier pickup time bucket"
FROM orders_duration od
GROUP BY 
	CASE 
		WHEN od.carrier_pickup_time_mins <= 720 THEN '0-720'
		WHEN od.carrier_pickup_time_mins <= 1440 THEN '720-1440'
		WHEN od.carrier_pickup_time_mins <= 2880 THEN '1440-2880'
		WHEN od.carrier_pickup_time_mins <= 4320 THEN '2880-4320'
		WHEN od.carrier_pickup_time_mins <= 5760 THEN '4320-5760'
        WHEN od.carrier_pickup_time_mins <= 7200 THEN '5760-7200'
        WHEN od.carrier_pickup_time_mins <= 10080 THEN '7200-10080'
        WHEN od.carrier_pickup_time_mins <= 20160 THEN '10080-20160'
        WHEN od.carrier_pickup_time_mins <= 30240 THEN '20160-30240'
		ELSE '30240+'
	END
ORDER BY ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) DESC;
-- Late delivery likelihood is strongly correlated with carrier pickup time. Longer pickup delays significantly increase higher late delivery risk
-- Thousands orders up to 30000 mins carrier pickup time contains large enough sample of data to support this
-- GENERATE GRAPH TO DEMONSTRATE THIS

# Identifying if higher shipping times lead to higher late delivery rates
SELECT 
	CASE 
		WHEN od.shipping_time_mins <= 720 THEN '0-720'
		WHEN od.shipping_time_mins <= 1440 THEN '720-1440'
		WHEN od.shipping_time_mins <= 2880 THEN '1440-2880'
		WHEN od.shipping_time_mins <= 4320 THEN '2880-4320'
		WHEN od.shipping_time_mins <= 5760 THEN '4320-5760'
        WHEN od.shipping_time_mins <= 7200 THEN '5760-7200'
        WHEN od.shipping_time_mins <= 10080 THEN '7200-10080'
        WHEN od.shipping_time_mins <= 20160 THEN '10080-20160'
        WHEN od.shipping_time_mins <= 30240 THEN '20160-30240'
		ELSE '30240+'
	END AS "shipping time bucket",
    COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
    COUNT(od.order_id) AS "Total orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of orders that were late per carrier pickup time bucket"
FROM orders_duration od
GROUP BY 
	CASE 
		WHEN od.shipping_time_mins <= 720 THEN '0-720'
		WHEN od.shipping_time_mins <= 1440 THEN '720-1440'
		WHEN od.shipping_time_mins <= 2880 THEN '1440-2880'
		WHEN od.shipping_time_mins <= 4320 THEN '2880-4320'
		WHEN od.shipping_time_mins <= 5760 THEN '4320-5760'
        WHEN od.shipping_time_mins <= 7200 THEN '5760-7200'
        WHEN od.shipping_time_mins <= 10080 THEN '7200-10080'
        WHEN od.shipping_time_mins <= 20160 THEN '10080-20160'
        WHEN od.shipping_time_mins <= 30240 THEN '20160-30240'
		ELSE '30240+'
	END
ORDER BY ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) DESC;
-- Shipping time doesnt indicate a direct linear relationship with late orders.
-- However the data does indicate that extreme shipping time values lead to late delivered orders
-- This suggests that shipping time is more of a failure-state indicator than a continiuous predictor


# Identfying the cause for the anomaly in <720 mins shipping time having high late delivery rate
SELECT o.order_delivered_customer_date,  o.order_estimated_delivery_date,
	ABS(TIMESTAMPDIFF(MINUTE, o.order_delivered_customer_date, o.order_estimated_delivery_date)) AS "delivered vs estimated delivery difference in minutes",
    od.carrier_pickup_time_mins 
FROM orders o
JOIN orders_duration od
	ON o.order_id = od.order_id
WHERE od.shipping_time_mins <= 720
	AND od.order_delay_time_mins > 0
ORDER BY od.carrier_pickup_time_mins ASC;
-- Late orders that had shipping time of <= 720 mins was late due to extremely higher carrier pickup times with the lowest carrier pickup time being 22748 mins


# Exploring possible combinations of carrier pickup time and shipping time that have high rates of late deliveries
SELECT COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
	COUNT(od.order_id) AS "Total number of orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of late orders"
FROM orders_duration od
WHERE od.carrier_pickup_time_mins >= 7200
	AND od.shipping_time_mins >= 20160;
-- 7200 minimum carrier pickup time + 20160 minimum shipping time -> 51.22% late deliveries 

SELECT COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
	COUNT(od.order_id) AS "Total number of orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of late orders"
FROM orders_duration od
WHERE od.carrier_pickup_time_mins >= 10080
	AND od.shipping_time_mins >= 20160;
-- 10080 minimum carrier pickup time + 20160 minimum shipping time -> 57.94% late deliveries 
-- Increasing carrier time -> increased late delivery rate

SELECT COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
	COUNT(od.order_id) AS "Total number of orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of late orders"
FROM orders_duration od
WHERE od.carrier_pickup_time_mins >= 7200
	AND od.shipping_time_mins >= 30240;
-- 7200 minimum carrier pickup time + 30240 minimum shipping time -> 77.90% late deliveries 
-- Increasing carrier time -> Signficant increase in late delivery time 

SELECT COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
	COUNT(od.order_id) AS "Total number of orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of late orders"
FROM orders_duration od
WHERE od.carrier_pickup_time_mins >= 10080
	AND od.shipping_time_mins >= 30240;
-- 10080 minimum carrier pickup time + 30240 minimum shipping time -> 80.80% late deliveries 
-- Combination of extreme carrier pickup time and extreme shipping time leads to extremely high late delivery rate


# Does decreasing carrier pickup time or shipping time significantly lower late delivery rate
SELECT COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
	COUNT(od.order_id) AS "Total number of orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of late orders"
FROM orders_duration od
WHERE od.carrier_pickup_time_mins <= 7200
	AND od.shipping_time_mins >= 20160;
-- 7200 maximum carrier pickup time + 20160 minimum shipping time -> 31.04% late deliveries

SELECT COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
	COUNT(od.order_id) AS "Total number of orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of late orders"
FROM orders_duration od
WHERE od.carrier_pickup_time_mins >= 7200
	AND od.shipping_time_mins <= 20160;
-- 7200 minimum carrier pickup time + 20160 maximum shipping time -> 9.33% late deliveries
-- Lower shipping time with high carrier pickup time signficantly decreases late delivery rate