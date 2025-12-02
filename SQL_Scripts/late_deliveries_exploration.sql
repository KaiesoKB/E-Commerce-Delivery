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