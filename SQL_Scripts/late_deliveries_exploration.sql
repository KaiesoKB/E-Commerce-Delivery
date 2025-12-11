USE ecommerce_delivery;

SELECT COUNT(*) 
FROM orders_duration;
# 93763 orders recorded

SELECT COUNT(order_id)
FROM orders;
# Confirmed 93763 orders recorded

SELECT SUM(order_delay_time_mins > 0) AS "Number of Late deliveries"
FROM orders_duration;
# There are 7673 orders delivered late 

SELECT ROUND((SUM(order_delay_time_mins > 0)/COUNT(*)) * 100, 2) AS "Late deliveries rate(percent)"
FROM orders_duration;
# 8.18% of orders were delivered late

# Creating view to store records of all late delivered orders ONLY
DROP VIEW IF EXISTS late_orders;

CREATE VIEW late_orders AS
SELECT *,
	CASE
		WHEN od.order_delay_days = 0 THEN 'Some Hours'
        WHEN od.order_delay_days = 1 THEN '1 Day'
        WHEN od.order_delay_days = 2 THEN '2 Days'
        WHEN od.order_delay_days = 3 THEN '3 Days'
        WHEN od.order_delay_days BETWEEN 4 AND 6 THEN '4-6 Days'
        WHEN od.order_delay_days >= 7 THEN '7+ Days'
	END AS days_delivered_late_bucket
FROM orders_duration od
WHERE order_delay_time_mins > 0;

# Confirming the number of late orders match up
SELECT COUNT(*)
FROM late_orders;
# 7673

# Viewing the details of the late delivered orders
SELECT * 
FROM late_orders
ORDER BY order_delay_time_mins DESC;

SELECT COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END) AS "Number of late orders Some Hours late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END) AS "Number of late orders 1 Day late",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END) AS "Number of late orders 2 Days late",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END) AS "Number of late orders 3 Days late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END) AS "Number of late orders 4-6 Days late",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of late orders 7+ Days late",
	ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders Some Hours late",
	ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders 1 Day late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders 2 Days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders 3 Days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders 4-6 Days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders 7+ days late"
FROM late_orders lo;
-- Most late orders to least late orders:
-- 3642 took 7+ days (47.47%), 1368 took 4-6 days (17.83%), 1224 took 1 day (15.95%), 760 took 2 days (9.90%), 505 took 3 days (6.58%), 174 took some hours (2.27%)