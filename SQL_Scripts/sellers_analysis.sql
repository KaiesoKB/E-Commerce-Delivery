# SEKKER PERFORMANCE AND OPERATIONS BOTTLENECKS
USE ecommerce_delivery;

# Understanding the distribution of sellers
SELECT COUNT(DISTINCT seller_id) AS "Number of distinct sellers",
	COUNT(DISTINCT seller_city) AS "Number of seller cities",
	COUNT(DISTINCT seller_state) AS "Number of seller states",
    COUNT(DISTINCT seller_zip_code_prefix) AS "Number of seller zip code prefixes"
FROM sellers;
-- Number of unique sellers: 2901, Number of seller cities: 586, Number of seller states: 22, Number of seller zip code prefixes: 2128


# Identifying the seller states that have the highest late delivery rate
SELECT s.seller_state AS "seller state",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders coming from seller state", -- 8532 total late orders
    total_orders.total_orders_per_state AS "Total orders per state",
    ROUND((COUNT(DISTINCT lo.order_id)/total_orders.total_orders_per_state) * 100, 2) AS "late delivery rate per state"
FROM sellers s
JOIN order_items od
	ON s.seller_id = od.seller_id
LEFT JOIN late_orders lo
	ON od.order_id = lo.order_id
JOIN (
	SELECT s.seller_state AS seller_state, 
		COUNT(DISTINCT o.order_id) AS total_orders_per_state
	FROM sellers s
    JOIN order_items oi
		ON s.seller_id = oi.seller_id
	JOIN orders o
		ON oi.order_id = o.order_id
	GROUP BY s.seller_state
) AS total_orders
	ON total_orders.seller_state = s.seller_state
GROUP BY s.seller_state
HAVING total_orders.total_orders_per_state > 100
ORDER BY ROUND((COUNT(DISTINCT lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC;
-- MA has severe late delivery rate (90/383) -> 24.32%
-- Majority of late orders are derived from sellers in SP (5882/66688) -> 8.82%
-- SP as a seller state isnt a problem by itself. 
-- It's scale is relatively high compared to other states, so its contribution to late deliveries naturally increase even though performance is good (8.82% -> Slightly higher than baseline 8.18%)
-- Investigating patterns within the seller state SP should be done separately 
-- RJ also has 8.46 late delivery rate with 347/4102 -> Note for possible reference later on
-- 4th: PR -> 479/7362 (6.51%)

# Identifying the severity of late order delays MA and SP seller states
SELECT s.seller_state AS "Seller state",
	COUNT(DISTINCT lo.order_id) AS "Total number of orders delivered late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END) AS "Number of orders delivered some hours late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered some hours late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END) AS "Number of orders delivered 1 day late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 1 day late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END) AS "Number of orders delivered 2 days late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 2 days late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END) AS "Number of orders delivered 3 days late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 3 days late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END) AS "Number of orders delivered 4-6 days late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 4-6 days late",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delivered 7+ days late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 7+ days late"
FROM sellers s
JOIN order_items oi
	ON s.seller_id = oi.seller_id
JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE s.seller_state IN ('MA', 'SP')
GROUP BY s.seller_state
ORDER BY COUNT(DISTINCT lo.order_id) DESC;
-- Majority of orders sold in these states are delivered 7+ days late -> 46.85% in SP and 47.78% in MA

# Analyzing the products with higher late delivery rate from SP sellers
SELECT p.product_category_name AS "Product category name sold in SP",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders containing product",
    COUNT(DISTINCT oi.order_id) AS "Total number of orders containing product",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT oi.order_id)) * 100, 2) AS "Late delivery rate of orders containing product"
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN sellers s
	ON oi.seller_id = s.seller_id
LEFT JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE s.seller_state IN ('SP')
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) > 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT oi.order_id)) * 100, 2) >= 9
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT oi.order_id)) * 100, 2) DESC;
-- audio, fashion_underwear_beach, fashion_underwear_beach, electronics, industry_commerce_and_business, food, musical_instruments, home_confort -> all over 10% late delivery rate
-- baby, computers_accessories, consoles_games, art, books_general_interest, health_beauty, office_furniture, bed_bath_table, watches_gifts -> between 9% - 10% late delivery rate
-- These 17 product categories contribute to ~50% of all late delivered orders from SP as a seller state (exactly 46.7% -> 2747)
-- Focus on these products from SP (route, pipeline)

# Analyzing the product category names for the products sold by sellers in the states with the highest late delivery rates and mix distribution of days delivered late
SELECT p.product_category_name AS "Product category name",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders containing product",
    COUNT(DISTINCT oi.order_id) AS "Total number of orders containing product",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT oi.order_id)) * 100, 2) AS "Late delivery rate of orders containing product",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered some hours late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 1 day late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 2 days late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 3 days late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 4-6 days late",
    ROUND((COUNT(DISTINCT CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN lo.order_id END)/COUNT(DISTINCT lo.order_id)) * 100, 2) AS "Percent of late orders delivered 7+ days late"
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN sellers s
	ON oi.seller_id = s.seller_id
LEFT JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE s.seller_state IN ('SP')
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) > 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT oi.order_id)) * 100, 2) >= 9
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT oi.order_id)) * 100, 2) DESC;
-- books_technical, food, art -> only product categories sold in SP where majority of them are delivered days later, but earlier than 7 days
-- books_technical (29.63% -> 4-6 days), food (25.64% -> 1 day), art (33.33% -> 4-6 days)
-- The majority of late orders containing the other 14 product categories are delivered 7+ days late

# Identifying if approval time has any influence on the following states: SP, RJ, MS
SELECT s.seller_state AS "Seller state",
	CASE 
		WHEN od.apporval_time_mins <= 200 THEN '0-200'
		WHEN od.apporval_time_mins <= 500 THEN '200-500'
		WHEN od.apporval_time_mins <= 800 THEN '500-800'
		WHEN od.apporval_time_mins <= 1200 THEN '800-1200'
		WHEN od.apporval_time_mins <= 1500 THEN '1200-1500'
        WHEN od.apporval_time_mins <= 2000 THEN '1500-2000'
		ELSE '2000+'
	END AS "approval time bucket",
	COUNT(DISTINCT CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late orders",
    COUNT(DISTINCT od.order_id) AS "Total orders",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(od.order_id)) * 100, 2) AS "Percent of orders that were late per approval time bucket"
FROM orders_duration od
JOIN order_items oi
	ON od.order_id = oi.order_id
JOIN sellers s
	ON oi.seller_id = s.seller_id
WHERE s.seller_state IN ('MA', 'SP')
GROUP BY s.seller_state, 
	CASE 
		WHEN od.apporval_time_mins <= 200 THEN '0-200'
		WHEN od.apporval_time_mins <= 500 THEN '200-500'
		WHEN od.apporval_time_mins <= 800 THEN '500-800'
		WHEN od.apporval_time_mins <= 1200 THEN '800-1200'
		WHEN od.apporval_time_mins <= 1500 THEN '1200-1500'
        WHEN od.apporval_time_mins <= 2000 THEN '1500-2000'
		ELSE '2000+'
	END
HAVING COUNT(DISTINCT od.order_id) > 100
ORDER BY s.seller_state, ROUND((COUNT(DISTINCT CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(DISTINCT od.order_id)) * 100, 2) DESC;
-- Majority of orders sold in MA have approval times of 0-200 (27.80%) -> Indicate that higher approval times have no effect on late orders in MA
-- Distirbution of late delivery rate in SP across differnet levels of approval time is roughly even ~(7% -> 11%)

# Identifying which states have no late orders
SELECT s.seller_state AS "seller state",
	SUM(CASE WHEN od.order_delay_time_mins > 0 THEN 1 ELSE 0 END) AS "total late orders per seller state",
    COUNT(od.order_id) AS "Total orders per seller state"
FROM sellers s
JOIN order_items oi
	ON s.seller_id = oi.seller_id
JOIN orders_duration od
	ON oi.order_id = od.order_id
GROUP BY s.seller_state
HAVING 
	SUM(od.order_delay_time_mins) = 0
ORDER BY s.seller_state ASC;
-- States with no late deliveries: PI, RO, SE
-- PI: 11/11 on time orders, RO: 14/14 on time orders, SE: 10/10 on time orders
-- Not enough orders (data) to draw potential trends that lead to lower late delivery rates


# Identifying if there are any specific sellers that consistently deliver late
SELECT s.seller_id AS "seller",
	COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN 1 END) AS "Number of late orders",
	COUNT(oi.order_id) AS "Number of orders",
	ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN 1 END) / COUNT(oi.order_id)) * 100, 2) AS "Seller's Late delivery rate"
FROM sellers s
JOIN order_items oi
	ON s.seller_id = oi.seller_id
JOIN orders_duration od
	ON oi.order_id = od.order_id
GROUP BY s.seller_id
HAVING COUNT(oi.order_id) > 5
	AND ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN 1 END) / COUNT(oi.order_id)) * 100, 2) > 50 # WHERE used before grouped select terms and HAVING used after grouped select terms
ORDER BY COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN 1 END)  DESC;
-- 8 Sellers with over 50% late delivery and have sold more than 5 orders
-- 41 total late orders amongst these sellers (41/64)