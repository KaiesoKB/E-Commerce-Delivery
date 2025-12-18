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
HAVING total_orders.total_orders_per_state > 100
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC;
-- 14 states with over 100 total orders and over 10% late delivery rate -> AL, MA, PI, CE, SE, BA, RJ, TO, PA, ES, MS, PB, PE, RN
-- 3377/24669 total orders were late in these 14 states alone (44.01% of late orders came from these states)
-- SP had 2333/39368 total orders that were late (5.93% state wise) % (30.41% of late orders came from this state)

# Identifying how many cities there are are in each of the 15 highest late delivery rate states (and the late delivery rate in each) 
SELECT c.customer_state AS "Customer State", 
	COUNT(DISTINCT c.customer_city) AS "Number of cities in State",
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
WHERE c.customer_state IN ('AL', 'MA', 'PI', 'CE', 'SE', 'BA', 'RJ', 'TO', 'PA', 'ES', 'MS', 'PB', 'PE', 'RN', 'SP')
GROUP BY c.customer_state
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC; 
-- AL - 19, MA - 39, PI - 11, CE - 50, SE - 16, BA - 113, RJ - 98, TO - 14, PA - 30, ES - 47, MS - 19, PB - 20, PE - 48, RN - 20, SP - 252

# Identifying the ratio of orders in each city that are delivered late
WITH total_orders_state AS (
	SELECT c.customer_state AS customer_state, COUNT(o.order_id) AS total_orders_per_state
    FROM orders o 
    JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
    GROUP BY customer_state
)
SELECT c.customer_state AS "Customer state",
	c.customer_city AS "Customer City", 
	COUNT(lo.order_id) AS "Number of late delivered orders per City", 
    MAX(total_orders_city.total_orders_per_city) AS "Total Orders per City",
    MAX(tos.total_orders_per_state) AS "Total Orders per State",
    ROUND((COUNT(lo.order_id)/MAX(total_orders_city.total_orders_per_city)) * 100, 2) AS "Percent of late orders delivered to city",
    ROUND((COUNT(lo.order_id)/MAX(tos.total_orders_per_state)) * 100, 2) AS "Percent of all state orders delivered late to city"
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
) AS total_orders_city
	ON c.customer_city = total_orders_city.customer_city
LEFT JOIN total_orders_state tos
	ON c.customer_state = tos.customer_state
WHERE c.customer_state IN ('AL', 'MA', 'PI', 'CE', 'SE', 'BA', 'RJ', 'TO', 'PA', 'ES', 'MS', 'PB', 'PE', 'RN', 'SP')
GROUP BY c.customer_state, c.customer_city
HAVING MAX(total_orders_city.total_orders_per_city) > 100
	AND ROUND((COUNT(lo.order_id)/MAX(tos.total_orders_per_state)) * 100, 2) >= 5
ORDER BY ROUND((COUNT(lo.order_id)/MAX(total_orders_city.total_orders_per_city)) * 100, 2) DESC;
-- AL (maceio), MA (sao_luis), PI (teresina) and CE (fortaleza) -> extreme late orders rate both city level (Over 18%) and state level (over 8%) with decent orders volume present in these cities
-- RJ (rio_de_janeiro) -> lower late delivery rate both city level (11.96%) and state level (6.38%) but still accounts for ~10% (768 late orders) of all late deliveries
-- BA (salvador), SE (aracaju), TO (palmas), MS (campo_grande), PB (joao_pessoa) -> moderate late delivery rate both city level ~(12% -> 18%) and state levl ~(5% -> 7%)

# Identifying the most popular product categories ordered in these 15 highest late delivery rate states along with the frequency and severity of late deliveries of orders containing these products
WITH total_orders AS (
	SELECT c.customer_state AS customer_state, COUNT(o.order_id) AS total_orders_per_state
    FROM orders o 
    JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
    GROUP BY customer_state
)
SELECT c.customer_state AS "Customer state",
	p.product_category_name AS "Product category",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders containting product category delivered to customer state",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT oi.order_id)) * 100, 2) AS "Percent of orders containing product category delivered LATE to state",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delivered 7+ days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) / COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late deliveries to state that were 7+ days late (%)",
    COUNT(DISTINCT oi.order_id) AS "Total number of orders containing product cateogry delivered to customer state",
    ROUND((COUNT(DISTINCT oi.order_id) / t.total_orders_per_state) * 100, 2) AS "Percent of total orders containing product category delivered to state"
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN orders o
	ON oi.order_id = o.order_id
JOIN customers c
	ON o.customer_unique_id = c.customer_unique_id
JOIN total_orders t
	ON c.customer_state = t.customer_state
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
WHERE c.customer_state IN ('AL', 'MA', 'PI', 'CE', 'SE', 'BA', 'RJ', 'TO', 'PA', 'ES', 'MS', 'PB', 'PE', 'RN', 'SP')
GROUP BY c.customer_state, p.product_category_name, t.total_orders_per_state
HAVING (COUNT(DISTINCT oi.order_id) / t.total_orders_per_state) * 100 > 10
ORDER BY c.customer_state ASC, ROUND((COUNT(DISTINCT oi.order_id) / t.total_orders_per_state) * 100, 2) DESC;
-- The most popular product delivered to 10 of these states were health_beauty (all but BA, ES and MS) and (bed_bath_table -> only in RJ and SP)
-- These product categories were contained in over 10% of orders to each state and have over 10% late delivery rate to each state
-- health_beauty (AL, CE, MA, PA, PB, PE, PI, SE, TO) -> noticeable 30.00% late delivery in AL, 28.75% in MA, 20.83% in PI, 21.05% in SE, 24.14% in TO
-- CE, PA, PB, PE had between 10-20% late delivery for health_beauty products
-- RJ had 16.67% late delivery rate for orders containing bed_bath_table products with 11.17% of ordrers to RJ containing bed_bath_table products
-- Majority of orders containing these products were late by 7+ days (EXCEPT in RN: 0% of late orders containing health_beauty were delivered 7+ days late)

# Since majority of orders, containing the most popular product category, delivered to the above 15 states were late by 7+ days. Does the pattern follow through for all orders to these states
# regardless of product category 
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
WHERE c.customer_state IN ('AL', 'MA', 'PI', 'CE', 'SE', 'BA', 'RJ', 'TO', 'PA', 'ES', 'MS', 'PB', 'PE', 'RN', 'SP')
GROUP BY c.customer_state, total_orders.total_orders_per_state
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC;
-- A majority of orders of were late by 7+ days in the 15 states with the highest late delivery ratio
-- It isnt just a trend for the most popular product category ordered - IMPORTANT 
                         
                         
# Analyzing which customer state has the highest ON TIME delivery rate
SELECT c.customer_state AS "Customer State", 
	COUNT(DISTINCT o.order_id) AS "Number of on time deliveries", 
	total_orders.total_orders_per_state AS "Total number of orders in State",
    ROUND((COUNT(DISTINCT o.order_id)/total_orders.total_orders_per_state) * 100, 2) AS "On time delivery rate per state"
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
HAVING ROUND((COUNT(DISTINCT o.order_id)/total_orders.total_orders_per_state) * 100, 2) > 90
ORDER BY ROUND((COUNT(DISTINCT o.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC; 
-- 86090 on time deliveries
-- RO AC AM AP PR MG SP MT DF RS GO SC have higehst on time deliveries rates in their states (over 90%) -> 69056 total orders from these states