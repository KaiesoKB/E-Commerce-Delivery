# ROUTE OPERATIONS ANALYSIS
USE ecommerce_delivery;

# Identifying which customer states that SP is selling too, with high volumes of orders
WITH total_orders_seller_state AS (
	SELECT s.seller_state AS seller_state, COUNT(DISTINCT oi.order_id) AS total_orders_per_seller_state
    FROM sellers s
	JOIN order_items oi	
		ON s.seller_id = oi.seller_id
	GROUP BY seller_state
)
SELECT 
    s.seller_state AS "Seller state",
    c.customer_state AS "Customer State",
    COUNT(DISTINCT lo.order_id) AS "Late deliveries made from seller state to customer state",
    COUNT(DISTINCT o.order_id) AS "Total orders made through route",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Percent of deliveries in route that were late",
	ROUND((COUNT(DISTINCT lo.order_id) / toss.total_orders_per_seller_state) * 100, 2) AS "Percent of total deliveries in state that were late to specific customer route"
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_unique_id = c.customer_unique_id
JOIN total_orders_seller_state toss
	ON s.seller_state = toss.seller_state
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id
WHERE s.seller_state IN ('SP')
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) > 1000
	OR ROUND((COUNT(DISTINCT lo.order_id) / MAX(toss.total_orders_per_seller_state)) * 100, 2) >= 1 
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / MAX(toss.total_orders_per_seller_state)) * 100, 2) >= 1 DESC,
	ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- 61492/66688 of total orders and 5157/5882 total late orders are delivered to these 11 customer states -> RJ(15.56%), BA(14.94%), ES(14.03%), SC(10.90%), PE(10.86%), GO(9.14%)
																										 -- DF(8.44%) , RS(7.75%), MG(6.42%), SP(6.24%), PR(5.43%)
-- Routes SP -> RJ (1242/7982), SP -> SP (1871/29967) contribute most to the entire late delivery rate from this seller state (1.86% and 2.81% respectively)
-- NOTE SP seller state has late delivery rate of 8.82%
-- Routes SP -> BA (14.94%), ES (14.03%), SC (10.90%), PE (10.86%) -> late delivery rate at route level

# Routes SP -> RJ and SP -> SP were identified as problematic for the entire system. Identifying any patterns in product categories among these routes
WITH total_late_orders_route AS (
	SELECT s.seller_state AS seller_state, c.customer_state AS customer_state, COUNT(DISTINCT lo.order_id) AS total_late_orders_per_route
    FROM sellers s
	JOIN order_items oi	
		ON s.seller_id = oi.seller_id
	JOIN late_orders lo
		ON oi.order_id = lo.order_id
	JOIN orders o
		ON lo.order_id = o.order_id
	JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
	GROUP BY seller_state, customer_state
)
SELECT s.seller_state AS "Seller State",
	c.customer_state AS "Customer State",
	p.product_category_name AS "Product category",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders contianing product category",
    COUNT(DISTINCT o.order_id) AS "Total number of orders containing product category",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Late delivery rate of orders containing product category in route",
    ROUND((COUNT(DISTINCT lo.order_id) / tlor.total_late_orders_per_route) * 100, 2) AS "Percent of total deliveries in route containing certain produts that were late"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN sellers s 
	ON oi.seller_id = s.seller_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN total_late_orders_route tlor
	ON s.seller_state = tlor.seller_state
	AND c.customer_state = tlor.customer_state
LEFT JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE (s.seller_state, c.customer_state) IN (('SP', 'RJ'), ('SP', 'SP'))
GROUP BY s.seller_state, c.customer_state, p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100 
	AND ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) >= 5
ORDER BY c.customer_state, ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) DESC;
-- Route SP -> RJ: bed_bath_table, watches_gifts, sports_leisure, furniture_decor, health_beauty, garden_tools -> these 6 categories alone account for ~50% of all late orders in route
-- Route SP -> SP: bed_bath_table, health_beauty, housewares, sports_leisure, furniture_decor, watches_gifts, auto -> These 7 categories alone account for 52.37% of all late orders in route
-- Common categories in both routes: bed_bath_table(SP->RJ: 16.91% | SP->SP: 10.15%),  watches_gifts(SP->RJ: 8.37% | SP->SP: 5.77%), sports_leisure(SP->RJ: 7.41% | SP->SP: 7.27%)
								  -- furniture_decor(SP->RJ: 7.09% | SP->SP: 6.63%), health_beauty(SP->RJ: 5.56% | SP->SP: 10.05%)
-- product categories contribution to late delivery are spread out more evenly in SP -> SP. 
-- Lateness is more related to volume of orders and congestion in SP -> SP
-- IMPORTANT OBSERVATIONS IN THIS QUERY -> VISUALIZATION NEEDED

# Identifying possible difference in approval times of product category: bed_bath_table vs other products that cause the higher late delivery rate in routes SP->RJ and SP->SP
WITH total_late_orders_route AS (
	SELECT s.seller_state AS seller_state, c.customer_state AS customer_state, COUNT(DISTINCT lo.order_id) AS total_late_orders_per_route
    FROM sellers s
	JOIN order_items oi	
		ON s.seller_id = oi.seller_id
	JOIN late_orders lo
		ON oi.order_id = lo.order_id
	JOIN orders o
		ON lo.order_id = o.order_id
	JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
	GROUP BY seller_state, customer_state
)
SELECT s.seller_state AS "Seller State",
	c.customer_state AS "Customer State",
	p.product_category_name AS "Product category",
    ROUND(AVG(od.apporval_time_mins), 2) AS "Average approval time of late orders containing bed_bath_table in route",
    ROUND(AVG(od.carrier_pickup_time_mins), 2) AS "Average carrier pickup time of orders containing bed_bath_table in route",
    ROUND(AVG(od.shipping_time_mins), 2) AS "Average shipping time of orders containing bed_bath_table in route"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN orders_duration od
	ON o.order_id = od.order_id
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN sellers s 
	ON oi.seller_id = s.seller_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN total_late_orders_route tlor
	ON s.seller_state = tlor.seller_state
	AND c.customer_state = tlor.customer_state
LEFT JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE (s.seller_state, c.customer_state) IN (('SP', 'RJ'), ('SP', 'SP')) 
GROUP BY s.seller_state, c.customer_state, p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100 
	AND ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) >= 5
ORDER BY c.customer_state, ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) DESC;
-- bed_bath_table does not exhibit anomalously high approval, pickup, or shipping times compared to other high-volume categories on the same routes.

# Now analyzing routes with high late delivery rate at route level -> i.e the routes themselves have high late delivery rates (SP -> BA, ES, SC, PE)
# Identifying any patterns in product categories among these routes
WITH total_late_orders_route AS (
	SELECT s.seller_state AS seller_state, c.customer_state AS customer_state, COUNT(DISTINCT lo.order_id) AS total_late_orders_per_route
    FROM sellers s
	JOIN order_items oi	
		ON s.seller_id = oi.seller_id
	JOIN late_orders lo
		ON oi.order_id = lo.order_id
	JOIN orders o
		ON lo.order_id = o.order_id
	JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
	GROUP BY seller_state, customer_state
)
SELECT s.seller_state AS "Seller State",
	c.customer_state AS "Customer State",
	p.product_category_name AS "Product category",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders contianing product category",
    COUNT(DISTINCT o.order_id) AS "Total number of orders containing product category",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Late delivery rate of orders containing product category in route",
    ROUND((COUNT(DISTINCT lo.order_id) / tlor.total_late_orders_per_route) * 100, 2) AS "Percent of total deliveries in route that were late"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN sellers s 
	ON oi.seller_id = s.seller_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN total_late_orders_route tlor
	ON s.seller_state = tlor.seller_state
	AND c.customer_state = tlor.customer_state
LEFT JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE (s.seller_state, c.customer_state) IN (('SP', 'BA'), ('SP', 'ES'), ('SP', 'SC'), ('SP', 'PE'))
GROUP BY s.seller_state, c.customer_state, p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100 
	AND ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) >= 10
ORDER BY c.customer_state, ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) DESC;
-- SP -> BA: health_beauty (43/233 late orders) -> 18.45% route & product level late delivery rate and 12.76% route level late delivery rate
-- SP -> ES: bed_bath_table (34/186 late orders) -> 18.28% route & product level late delivery rate and 16.83% route level late delivery rate
-- SP -> PE: health_beauty (18/131 late orders) -> 13.74% route & product level late delivery rate and 15.00% route level late delivery rate
-- SP -> PE: watches_gifts (12/110 late orders) -> 10.91% route & product level late delivery rate and 10.00% route level late delivery rate
-- SP -> SC: furniture_decor (31/191 late orders) -> 16.23% route & product level late delivery rate and 12.60% route level late delivery rate
-- SP -> SC: bed_bath_table (30/211 late orders) -> 14.22% route & product level late delivery rate and 12.20% route level late delivery rate
-- VISUALIZATION VERY SUITABLE FOR THIS QUERY 


# Identifying routes high volumes of orders and high late delivery rate stemming from seller states not including SP
WITH total_orders_seller_state AS (
	SELECT s.seller_state AS seller_state, COUNT(DISTINCT oi.order_id) AS total_orders_per_seller_state
    FROM sellers s
	JOIN order_items oi	
		ON s.seller_id = oi.seller_id
	GROUP BY seller_state
)
SELECT 
    s.seller_state AS "Seller state",
    c.customer_state AS "Customer State",
    COUNT(DISTINCT lo.order_id) AS "Late deliveries made through route",
    COUNT(DISTINCT o.order_id) AS "Total orders made through route",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Percent of deliveries in route that were late",
    toss.total_orders_per_seller_state AS "Total orders sold in seller State",
    ROUND((COUNT(DISTINCT lo.order_id) / toss.total_orders_per_seller_state) * 100, 2) AS "Percent of all orders delivered from seller state that was late"
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_unique_id = c.customer_unique_id
JOIN total_orders_seller_state toss
	ON s.seller_state = toss.seller_state
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id
WHERE s.seller_state NOT IN ('SP')
GROUP BY s.seller_state, c.customer_state
HAVING (COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10)
    OR (COUNT(DISTINCT o.order_id) >= 100
    AND ROUND((COUNT(DISTINCT lo.order_id) / toss.total_orders_per_seller_state) * 100, 2) >= 5)
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- Possible problematic routes: MA -> SP (26.27%), PR -> BA (16.78%), PR -> RJ (13.93%), RJ -> BA (10.85%), MG -> BA (10.67%), RJ -> SC (10.62%), SC -> RJ (10.34%)
-- Routes that dominate the late delivery distribution for their resepctive seller state: MA -> SP (8.38%) -> Most problematic
-- These routes contain one of the identified seller or customer state found in previous analysis -> supported findings ✅

# Identifying any product categories in these routes that contribute severely to the late delivery rates in routes
WITH total_late_orders_route AS (
	SELECT s.seller_state AS seller_state, c.customer_state AS customer_state, COUNT(DISTINCT lo.order_id) AS total_late_orders_per_route
    FROM sellers s
	JOIN order_items oi	
		ON s.seller_id = oi.seller_id
	JOIN late_orders lo
		ON oi.order_id = lo.order_id
	JOIN orders o
		ON lo.order_id = o.order_id
	JOIN customers c
		ON o.customer_unique_id = c.customer_unique_id
	GROUP BY seller_state, customer_state
)
SELECT s.seller_state AS "Seller State",
	c.customer_state AS "Customer State",
	p.product_category_name AS "Product category",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders contianing product category",
    COUNT(DISTINCT o.order_id) AS "Total number of orders containing product category",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Late delivery rate of orders containing product category in route",
    tlor.total_late_orders_per_route AS "Total number of late orders in route",
    ROUND((COUNT(DISTINCT lo.order_id) / tlor.total_late_orders_per_route) * 100, 2) AS "Percent of total deliveries in route containing certain produts that were late"
FROM customers c
JOIN orders o
	ON c.customer_unique_id = o.customer_unique_id
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN sellers s 
	ON oi.seller_id = s.seller_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN total_late_orders_route tlor
	ON s.seller_state = tlor.seller_state
	AND c.customer_state = tlor.customer_state
LEFT JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE (s.seller_state, c.customer_state) IN (('MA', 'SP'), ('PR', 'BA'), ('PR', 'RJ'), ('RJ', 'BA'), ('MG', 'BA'), ('RJ', 'SC'), ('SC', 'RJ'))
GROUP BY s.seller_state, c.customer_state, p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100 
	AND ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) >= 5
ORDER BY c.customer_state, ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlor.total_late_orders_per_route)) * 100, 2) DESC;
-- MA -> SP: health_beauty (31/118 late orders) -> 26.27% route & product level late delivery rate and 100.00% route level late delivery rate
-- PR -> RJ: computers_accessories (32/177 late orders) -> 18.08% route & product level late delivery rate and 23.88% route level late delivery rate
-- PR -> RJ: furniture_decor (21/124 late orders) -> 16.94% route & product level late delivery rate and 15.67% route level late delivery rate
-- PR -> RJ: sports_leisure (13/140 late orders) -> 9.29% route & product level late delivery rate and 9.70% route level late delivery rate
-- VISUALIZATION VERY SUITABLE FOR THIS QUERY 


# Identifying Routes (seller states to customer states) with high total deliveries and little to no late deliveries.
SELECT 
    s.seller_state AS "Seller state",
    c.customer_state AS "Customer State",
    COUNT(DISTINCT lo.order_id) AS "Late deliveries made from seller state to customer state",
    COUNT(DISTINCT o.order_id) AS "Total orders made through route",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Percent of deliveries in route that were late"
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_unique_id = c.customer_unique_id
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) < 5
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) ASC;
-- RS -> SC: Only route with 0% late delivery (0/114)
-- These 21 routes contribute 448 late orders out from 12383 total orders -> 3.62% late delivery rate and 5.83% of all late orders