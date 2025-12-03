# CUSTOMER GEOGRAPHY AND LATE DELIVERY ANALYSIS
USE ecommerce_delivery;

# Customer Overview
SELECT COUNT(DISTINCT customer_unique_id) AS "Number of unique customers",
	COUNT(DISTINCT customer_zip_code_prefix) AS "Number of customer zip code prefixes recorded",
	COUNT(DISTINCT customer_city) AS "Number of customer cities recorded",
    COUNT(DISTINCT customer_state) AS "Number of customer states recorded"
FROM customers;
-- Number of unique customers = 93763, Number of zip_code_prefixes = 14797, Number of customer cities = 4054, Number of customer states = 27

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
-- States with >10% late delivery rate from highest to lowest: AL(23.65%), MA, PI, SE, CE, BA, RJ, RR, TO, PA, ES, MS, PB, PE, RN
-- States with most order deliveries from highest to lowest:   SP, RJ, MG, RS, PR, SC, BA, DF, ES, GO, PE, CE, PA, MT, MA
-- States with >10% late delivery rate and highest deliveries: RJ, BA, ES, PE, CE, PA, MA

# Analyzing which customer state has the highest ON TIME delivery rate
SELECT c.customer_state AS "Customer State", 
	COUNT(o.order_id) AS "Number of on time deliveries", 
	total_orders.total_orders_per_state AS "Total number of orders in State",
    ROUND((COUNT(o.order_id)/total_orders.total_orders_per_state) * 100, 2) AS "On time delivery rate per state"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN orders_duration od
	ON o.order_id = od.order_id
JOIN (
	SELECT c.customer_state AS customer_state, COUNT(o.order_id) AS total_orders_per_state
    FROM orders o 
    JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
    GROUP BY customer_state
) AS total_orders
	ON c.customer_state = total_orders.customer_state
WHERE od.order_delay_time_mins = 0
GROUP BY c.customer_state
ORDER BY  ROUND((COUNT(o.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC; 
-- 86090 on time deliveries
-- RO AC AM AP PR MG SP MT DF RS GO SC have higehst on time deliveries rates in their states (over 90%)
-- SP MG RJ RS PR SC BA DF GO ES PE CE have the most on time deliveres (all over 1000)

# Identifying How severe the late deliveries are in the states with high late delivery frequency
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
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delivered 7+ days late",
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
WHERE c.customer_state IN ('AL', 'MA', 'PI', 'SE', 'CE', 'BA', 'RJ', 'RR', 'TO', 'PA', 'ES', 'MS', 'PB', 'PE', 'RN')
GROUP BY c.customer_state, total_orders.total_orders_per_state
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC;
-- A majority of orders of were late by 7+ days in the 15 states with the highest late delivery ratio
-- This needs further investigation!

# Lets ensure that most of the late delivered orders are really 7+ days delayed
SELECT days_delivered_late_bucket, COUNT(*) AS late_orders,
	ROUND((COUNT(*)/(SELECT COUNT(*) FROM late_orders)) * 100, 2) AS "Percent of late orders (%)"
FROM late_orders
GROUP BY days_delivered_late_bucket
ORDER BY ROUND((COUNT(*)/(SELECT COUNT(*) FROM late_orders)) * 100, 2) DESC;
-- 47.47% of late deliveries took 7+ days. -> CONFIRMED 

SELECT order_delay_days, COUNT(order_id) AS "Number of orders delivered late"
FROM late_orders
GROUP BY order_delay_days
ORDER BY order_delay_days;
-- There is a wide array of day delayed values that skew the bucket of 7+ days. However, realistically speaking, 7 Days itself is a significant and concerning delay for a delivery.
-- So the buckets will remain as is
-- From 7 days to 189 days late, the number of orders delivered late decreases (7 days = 423, 189 days = 1)
-- Orders delivered 1 day late was most frequent at 1224

# Now, can we identify any possible patterns that correlate towards the states have have alot of orders being delayed 7+ days
# possible products causing 7+ days delays
SELECT c.customer_state AS "customer state", 
	p.product_category_name AS "product category name", 
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delayed 7+ days in that product category",
    COUNT(CASE WHEN lo.order_delay_time_mins > 0 THEN 1 END) AS "Total number of orders delayed in that product category"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN late_orders lo
	ON o.order_id = lo.order_id
WHERE c.customer_state IN ('AL', 'MA', 'PI', 'SE', 'CE', 'BA', 'RJ', 'RR', 'TO', 'PA', 'ES', 'MS', 'PB', 'PE', 'RN') 
GROUP BY c.customer_state, p.product_category_name
HAVING 
	 COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) * 1.0
    / NULLIF(COUNT(CASE WHEN lo.order_delay_time_mins > 0 THEN 1 END), 0) >= 0.20
ORDER BY c.customer_state, COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) DESC;
-- This query returns the number of orders delivered late for each product category. 
-- It is filtered to only output the customer states + product category names where at least 20% of orders delivered late were 7+ days delayed.
-- There are 413 product categories in total that were delivered 7+ days late across the 15 states with the highest late delivery rates
-- There are 332 product categories in total where at least 20% of products were delivered 7+ days late across the 15 states with the highest late delivery rates

# Using the above query to identify the frequency of each product category in each state. I.e Identifying how many times each product categories with at least
# 20% of of products being delivered 7+ days late, appear in the top 15 states with highest late delivery rate
SELECT product_category_name as "product category name", COUNT(DISTINCT customer_state) AS "Number of states"
FROM (
	SELECT c.customer_state AS customer_state, 
		p.product_category_name AS product_category_name, 
		COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delayed 7+ days in that product category",
		COUNT(CASE WHEN lo.order_delay_time_mins > 0 THEN 1 END) AS "Total number of orders delayed in that product category"
	FROM customers c
	JOIN orders o
		ON c.customer_unique_id = o.customer_unique_id
	JOIN order_items oi
		ON o.order_id = oi.order_id
	JOIN products p
		ON oi.product_id = p.product_id
	JOIN late_orders lo
		ON o.order_id = lo.order_id
	WHERE c.customer_state IN ('AL', 'MA', 'PI', 'SE', 'CE', 'BA', 'RJ', 'RR', 'TO', 'PA', 'ES', 'MS', 'PB', 'PE', 'RN') 
	GROUP BY c.customer_state, p.product_category_name
	HAVING 
		 COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) * 1.0
		/ NULLIF(COUNT(CASE WHEN lo.order_delay_time_mins > 0 THEN 1 END), 0) >= 0.20
) AS product_category_frequency
GROUP BY product_category_name
ORDER BY COUNT(DISTINCT customer_state) DESC;
-- 'bed_bath_table' is delivered 7 or more days late, at least 20% of times across ALL (15) states with the highest late delivery rate
-- 'watches_gifts', 'health_beauty', 'garden_tools' -> 14 of the top 15 states 
-- 'electronics', 'sports_leisure', 'telephony', 'toys' -> 13 of the top 15 states
-- 'auto', 'baby', 'computers_accessories', furniture_decor' -> 12 of the top 15 states
-- 'perfumery', 'housewares' -> 11 of the top 15 states
-- 'fashion_bags_accessories', 'stationery' -> 10 of the top 15 states
-- 'cool_stuff', 'consoles_games', 'home_confort', 'office_furniture', 'pet_shop', 'audio', 'musical_instruments', 'luggage_accessories', 'fashion_shoes' -> between 5-9 of the top 15 states

# Identifying how many cities there are are in each state
SELECT c.customer_state AS "Customer State", COUNT(DISTINCT c.customer_city) AS "Number of cities in State",
	ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) AS "Late delivery rate per state" # Keeping late delivery rate makes referencing easier
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

# Identifying the proportion of orders in each city that are delivered late
SELECT c.customer_city AS "Customer City", 
	COUNT(lo.order_id) AS "Number of late delivered orders per City", 
    total_orders.total_orders_per_city AS "Total Orders per City",
    ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) AS "Late delivery rate per City",
    CASE 
		WHEN ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) BETWEEN 0 AND 5 THEN '<5%'
        WHEN ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) BETWEEN 5 AND 10 THEN '5-10%'
        WHEN ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) BETWEEN 10 AND 20 THEN '10-20%'
        WHEN ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) BETWEEN 20 and 50 THEN '20-50%'
        WHEN ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) BETWEEN 50 and 99 THEN '>50%'
        WHEN ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) > 99 THEN '100%'
	END AS Late_delivery_rlate_per_city_buckets
FROM customers c
JOIN orders o 
	ON c.customer_unique_id = o.customer_unique_id
JOIN late_orders lo
	ON o.order_id = lo.order_id
JOIN (
	SELECT c.customer_city AS customer_city, COUNT(o.order_id) AS total_orders_per_city
    FROM orders o 
    JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
    GROUP BY customer_city
) AS total_orders
	ON c.customer_city = total_orders.customer_city
GROUP BY c.customer_city
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_city) * 100, 2) DESC;
# 100% late deliveries cities: 126, >50%: 19, 20-50%: 328, 10-20%: 360, 5-10%: 313, <5%: 140