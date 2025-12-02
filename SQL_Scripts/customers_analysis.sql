# CUSTOMER GEOGRAPHY AND LATE DELIVERY ANALYSIS
USE ecommerce_delivery;

SELECT COUNT(DISTINCT customer_zip_code_prefix) AS "Number of customer zip code prefixes recorded",
	COUNT(DISTINCT customer_city) AS "Number of customer cities recorded",
    COUNT(DISTINCT customer_state) AS "Number of customer states recorded"
FROM customers;
# Number of zip_code_prefixes = 14797, Number of customer cities = 4054, Number of customer states = 27

# Analyzing which customer state has the highest late delivery rate
SELECT c.customer_state AS "Customer State", 
	COUNT(lo.order_id) AS "Number of late delivered orders", 
    total_orders.total_orders_per_state AS "Total Orders per state",
    ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) AS "Late delivery rate per state"
FROM customers c
JOIN orders o 
	ON c.customer_unique_id = o.customer_unique_id
JOIN late_orders lo
	ON o.order_id = lo.order_id
JOIN (
	SELECT c.customer_state AS customer_state, COUNT(o.order_id) AS total_orders_per_state
    FROM orders o 
    JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
    GROUP BY customer_state
) AS total_orders
	ON c.customer_state = total_orders.customer_state
GROUP BY c.customer_state
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC;
# States with >10% late delivery rate from highest to lowest: AL(23.65%), MA, PI, SE, CE, BA, RJ, RR, TO, PA, ES, MS, PB, PE, RN
# States with most order deliveries from highest to lowest:   SP, RJ, MG, RS, PR, SC, BA, DF, ES, GO, PE, CE, PA, MT, MA
# States with >10% late delivery rate and highest deliveries: RJ, BA, ES, PE, CE, PA, MA

SELECT c.customer_state,
	COUNT(lo.order_id) AS "Number of late delivered orders", 
    ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) AS "Late delivery rate per state",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END) AS "Number of orders delivered some hours late",
    # SUM(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1  ELSE 0 END) AS "Number of orders delivered some hours late", --> This also works
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END) AS "Number of orders delivered 1 day late",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END) AS "Number of orders delivered 2 days late",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END) AS "Number of orders delivered 3 days late",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END) AS "Number of orders delivered 4 to 6 dayx late",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delivered 7 days late"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN late_orders lo
	ON o.order_id = lo.order_id
JOIN (
	SELECT c.customer_state AS customer_state, COUNT(o.order_id) AS total_orders_per_state
    FROM orders o 
    JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
    GROUP BY customer_state
) AS total_orders
	ON c.customer_state = total_orders.customer_state
GROUP BY c.customer_state, total_orders.total_orders_per_state
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC;