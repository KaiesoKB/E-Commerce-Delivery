# TIME/SEASONS ANALYSIS
USE ecommerce_delivery;

SELECT MIN(YEAR(order_delivered_customer_date)) AS "Min year",
	MAX(YEAR(order_delivered_customer_date)) AS "Max year"
FROM orders;

# Identifying months in each year that exhibit the most late deliveries 
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	MONTH(o.order_delivered_customer_date) AS "Month",
	COUNT(lo.order_id) AS "number of late delivered orders per month",
	COUNT(o.order_id) AS "Total number of orders per month",
    ROUND((COUNT(lo.order_id) / COUNT(o.order_id)) * 100, 2) AS "Percent of late orders per month"
FROM orders o
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
GROUP BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date)
ORDER BY  YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date);
-- 2016: 3 late orders. 2/4 in december
-- 2017: 2096 late orders: 746/7080 in december (most orders made in the year) -> 10.54%
-- 2018: 5574 late orders: 
-- 653/6433 in January (10.15%), 1063/6693 in March (15.88%), 1446/7528 in April (19.21%), 865/8124 in August (10.65%), 54/54 in September (100.00%), 3/3 in October (100%)

# Identifying seasons in each year that exhibit the most late deliveries 
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN lo.order_id END) AS num_late_orders_spring,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN 1 END) AS total_orders_spring,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN 1 END)) * 100, 2) AS "Percent of late orders in Spring",
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN lo.order_id END) AS num_late_orders_summer,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN 1 END) AS total_orders_summer,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN 1 END)) * 100, 2) AS "Percent of late orders in Summer",
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN lo.order_id END) AS num_late_orders_autumn,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN 1 END) AS total_orders_autumn,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN 1 END)) * 100, 2) AS "Percent of late orders in Autumn",
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN lo.order_id END) AS num_late_orders_winter,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN 1 END) AS total_orders_winter,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN 1 END)) * 100, 2) AS "Percent of late orders in Winter"
FROM orders o
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
GROUP BY YEAR(o.order_delivered_customer_date)
ORDER BY YEAR(o.order_delivered_customer_date);
-- Spring: 2016: 0/0 late orders (0%), 2017: 380/7760 late orders (4.90%), 2018: 2967/21090 late orders (14.07%)
-- Summer: 2016: 0/0 late orders (0%), 2017: 343/10777 late orders (3.18%), 2018: 1532/20091 late orders (7.63%)
-- Autumn: 2016: 1/261 late orders (0.38%), 2017: 625/12933 late orders (4.83%), 2018: 57/57 late orders (100.00%)
-- Winter -> 2016: 2/4 late orders (50%), 2017: 748/8660 late orders (8.64%) , 2018: 1018/12130 late orders (8.39%)
-- Summer consistently performs well. 2018 shows significant increase in orders but was underprepared/demonstrated operational or scaling strain based on spring 2018 (high orders and high late delivered orders)
-- Summer showed management of the growth in scale with roughly same amount of orders and half the amount of late orders
-- Autumn is an anomaly as there are only 57 orders. Although 100% late orders, sample is too small. Underperformance in winter 2018 as number of orders halved from summer, but late orders were still 2/3 the amount from summer


# Digging deeper into the routes (seller to customer states) with high volumes of late deliveries in spring 2018
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
WHERE YEAR(o.order_delivered_customer_date) = 2018 
	AND MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- Problematic routes in spring 2018 (from most to least):
-- SP -> CE, SP ->,PA, SP -> MS, PR -> RJ, SP -> RJ, SP -> ES, SP -> BA, SP -> SC, SP -> PE (9 routes that were problematic during spring 2018 and problematic in the entire database)
-- 10 routes that were problematic only during spring 2018:
-- RJ -> MG (23/105), RJ -> SP (59/291), SP -> GO (61/326), MG -> RJ (33/198), SP -> DF (54/343),
-- SP -> MG (244/1614), SP -> RS (123/829), SP -> MT (19/144), PR -> MG (24/208), SP -> PR (70/686) 


# Identifying if there are specific product categories that contribute to the high late deliveries in these routes during spring 2018
SELECT s.seller_state AS "Seller state",
    c.customer_state AS "Customer State",
    p.product_category_name AS "Product Category",
	COUNT(CASE WHEN lo.order_id IS NOT NULL THEN oi.product_id END) AS "Number of products in category delivered late",
    COUNT(CASE WHEN o.order_id IS NOT NULL THEN oi.product_id END) AS "Total number of products in category delivered",
    ROUND((COUNT(CASE WHEN lo.order_id IS NOT NULL THEN oi.product_id END) / COUNT(CASE WHEN o.order_id IS NOT NULL THEN oi.product_id END)) * 100, 2) AS "Percent of products delivered in route that were late"
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
JOIN sellers s
	ON oi.seller_id = s.seller_id
JOIN orders o 
    ON oi.order_id = o.order_id
JOIN customers c
	ON o.customer_unique_id = c.customer_unique_id
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
WHERE YEAR(o.order_delivered_customer_date) = 2018 
	AND MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 
	AND (s.seller_state, c.customer_state) IN (
											('RJ', 'MG'), ('RJ', 'SP'), ('SP', 'GO'), ('MG', 'RJ'), ('SP', 'DF'),
											('SP', 'MG'), ('SP', 'RS'), ('SP', 'MT'), ('PR', 'MG'), ('SP', 'PR')
											)
GROUP BY s.seller_state, c.customer_state, p.product_category_name
HAVING COUNT(CASE WHEN lo.order_id IS NOT NULL THEN oi.product_id END) >= 10
ORDER BY s.seller_state, p.product_category_name, COUNT(CASE WHEN o.order_id IS NOT NULL THEN oi.product_id END) DESC;
-- THere are 13 product categories delivering through the routes with the highest volumes of late deliveries per product (over 10) in spring 2018:
-- auto, bed_bath_table, computers_accessories, cool_stuff, furniture_decor, garden_tools, health_beauty, housewares, perfumery, sports_leisure, telephony, toys, watches_gifts
-- product categories with high volumes of late deliveres in multiple routes: bed_bath_table, computers_accessories, health_beauty, housewares, sports_leisure
-- Seller states with high volumes of late deliveries in specific product categories: SP, PR, RJ
-- PR -> MG: computers_accessories
-- RJ: health_beauty, perfumery, health_beauty
-- SP: all BUT perfumery (12 of the 13 product categories)