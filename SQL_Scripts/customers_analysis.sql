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

# Identifying How severe the late deliveries are in each state
SELECT c.customer_state,
	COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END) AS "Number of orders delivered some hours late", # SUM(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1  ELSE 0 END) AS "Number of orders delivered some hours late", --> This also works
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of late deliveries in state that were hours late (%)",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END) AS "Number of orders delivered 1 day late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of late deliveries in state that were 1 day late (%)",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END) AS "Number of orders delivered 2 days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of late deliveries in state that were 2 days late (%)",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END) AS "Number of orders delivered 3 days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of late deliveries in state that were 3 days late (%)",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END) AS "Number of orders delivered 4 to 6 dayx late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of late deliveries in state that were 4-6 days late (%)",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delivered 7 days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of late deliveries in state that were 7+ days late (%)"
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
# A majority of orders of were late by 7+ days in the 15 states with the highest late delivery ratio
# This is the same for the remaining 12 states, where the most late deliveries took 7+ days. 7+ days delay was either most prevalent or tied as the most prevalent.
# This needs further investigation

# Lets confirm if most of the late delivered orders are indeed 7+ days delayed
SELECT days_delivered_late_bucket, COUNT(*) AS late_orders,
	ROUND((COUNT(*)/(SELECT COUNT(*) FROM late_orders)) * 100, 2) AS "Percent of late orders (%)"
FROM late_orders
GROUP BY days_delivered_late_bucket
ORDER BY ROUND((COUNT(*)/(SELECT COUNT(*) FROM late_orders)) * 100, 2) DESC;
# 47.47% of late deliveries took 7+ days. 

SELECT order_delay_days, COUNT(order_id)
FROM late_orders
WHERE order_delay_days >= 7
GROUP BY order_delay_days
ORDER BY order_delay_days;
# There is a wide array of day delayed values that skew the bucket of 7+ days. However, realistically speaking, 7 Days itself is a significant and concerning delay for a delivery.
# So the buckets will remain as is

# Now, can we identify any possible patterns that correlate towards the states have have alot of orders being delayed 7+ days
# possible products causing 7+ days delays
SELECT c.customer_state AS "customer state", 
	p.product_category_name AS "product category name", 
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delayed 7+ days in that category",
    COUNT(CASE WHEN lo.order_delay_time_mins > 0 THEN 1 END) AS "Total number of orders delayed in that category"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN late_orders lo
	ON o.order_id = lo.order_id
GROUP BY c.customer_state, p.product_category_name
ORDER BY c.customer_state, COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) DESC;
# Recrete this query in python(sqlite) and save as a df there
# From there, a graph can be generated for far better observation and insights

# Repeat approach for customer cities (this will dig deeper to understand if there are specific cities that constantly receive late deliveries (especially 7+ days delays on deliveries)
