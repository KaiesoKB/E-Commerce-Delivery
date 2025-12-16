# TIME/SEASONS ANALYSIS
USE ecommerce_delivery;

SELECT MIN(order_delivered_customer_date) AS "Min date",
    MAX(order_delivered_customer_date) AS "Max date"
FROM orders;
-- Data recorded from October 2016 to October 2018

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


# Identifying if there are specific routes (seller to customer states) that contribute to higher late delivery rates in Spring 2018:
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

# To confirm if these specific routes in particulat contribute to higher late deliveries in spring 2019, we can compare them to the highest late delivery rate routes of spring 2017
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
WHERE YEAR(o.order_delivered_customer_date) = 2017 
	AND MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 33
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 5
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- Used the limit for amount of total orders as 33 since Spring 2018 had almost 3x the amount of total orders as Spring 2017
-- Only 3 routes had late delivery rate over 10%: SP -> SC: 28/195 (14.36%), MG -> BA: 5/36 (13.89%), SP -> CE: 7/61 (11.48%)
-- Only common routes are SP -> SC and SP -> CE 
-- Only 10 routes with over 5% late delivery rate (and under 10%): SP -> MT, SP -> MA, SC -> SP, PR -> SP, PR -> PR, SP -> BA, SP -> RJ, SC -> MG, MG -> RJ, PR -> RJ


# Identifying the product categories that contribute to most late deliveries in each season
SELECT p.product_category_name,
	COUNT(CASE WHEN lo.order_id IS NOT NULL THEN oi.product_id END) AS "Number of product per category delivered late during Spring 2018",
	COUNT(CASE WHEN o.order_id IS NOT NULL THEN oi.product_id END) AS "Total number of products per cateogry delivered during Spring 2018",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Percent of products per category delivered late during Spring 2018"
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
JOIN orders o 
    ON oi.order_id = o.order_id
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
WHERE YEAR(o.order_delivered_customer_date) = 2018 
	AND MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- 26 product categories had over 100 total delivers and over 10% late delivery rate in Spring 2018
-- From highest late delivery rate to lowest (17.67% -> 10.48%):
-- bed_bath_table, electronics, telephony, consoles_games, health_beauty, stationery, garden_tools, sports_leisure, computers_accessories, baby, watches_gifts, perfumery, industry_commerce_and_business
-- fashion_bags_accessories, furniture_decor, auto, toys, construction_tools_construction, home_construction, pet_shop, cool_stuff, musical_instruments, office_furniture, luggage_accessories
-- housewares, small_appliances

# To confirm if these specific product categories in particulat contribute to higher late deliveries in spring 2019, we can compare them to the highest late delivery rate product categories of spring 2017
SELECT p.product_category_name,
	COUNT(CASE WHEN lo.order_id IS NOT NULL THEN oi.product_id END) AS "Number of product per category delivered late during Spring 2018",
	COUNT(CASE WHEN o.order_id IS NOT NULL THEN oi.product_id END) AS "Total number of products per cateogry delivered during Spring 2018",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Percent of products per category delivered late during Spring 2018"
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
JOIN orders o 
    ON oi.order_id = o.order_id
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
WHERE YEAR(o.order_delivered_customer_date) = 2017 
	AND MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 33
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 5
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- There was only 1 product category with over 33 total deliveries and over 10% late delivery rate: food
-- There are 14 products that have over 33 total deliveries and over 5% late delivery rate
-- From highest to lowest late delivery rate (7.66% -> 5.36%)
-- furniture_decor, small_appliances, musical_instruments, consoles_games, auto, electronics, furniture_living_room
-- perfumery, baby, office_furniture, home_confort, audio, cool_stuff, telephony
-- 10 of the 14 15 categories contribute to high late delivery rates in Spring 2018 and and the higher late delivery rates in Spring 2017


# Identifying if there are specific product categories that contribute to the high late deliveries in high late delivery routes during spring 2018
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


# Analyzing Winter 2017 and Winter 2018 that comprise of controlled levels of late deliveries (~8% acrorss both years) to compare to Spring 2018 findings
# Identifying if there are specific routes (seller to customer states) that contribute to late delivery rates in Winter 2017 and winter 2018:
SELECT 
    s.seller_state AS "Seller state",
    c.customer_state AS "Customer State",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 THEN lo.order_id END) AS "Late deliveries made through route in Winter 2017",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 THEN o.order_id END) AS "Total orders made through route in Winter 2017",
    ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 THEN o.order_id END)) * 100, 2) AS "Percent of deliveries in route that were late in Winter 2017",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN lo.order_id END) AS "Late deliveries made through route in Winter 2018",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN o.order_id END) AS "Total orders made through route in Winter 2018",
    ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN o.order_id END)) * 100, 2) AS "Percent of deliveries in route that were late in Winter 2018"
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_unique_id = c.customer_unique_id
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id
WHERE MONTH(o.order_delivered_customer_date) IN (1, 2, 12)
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN o.order_id END) >= 100
	AND ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN o.order_id END)) * 100, 2) >= 10
ORDER BY ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 THEN o.order_id END)) * 100, 2) DESC;
-- In Winter 2017, there were 6 routes with over 100 total deliveries and over 10% late delivery rate. From highest to lowest late delivery rate (23.97% -> 11.36%):
-- SP -> ES, SP -> RJ, SP -> GO, SP -> DF, SP -> SC, SP -> BA
-- In Winter 2018, there were 9 routes with voer 100 total deliveries and over 10% late delivery rate. From highest to lowest late delivery rate (25.79%, 11.30%):
-- SP -> RJ, MG -> RJ, PR -> RJ, SP -> BA, SP -> RS, SP -> SC, SP -> PE, RJ -> SP, SP -> CE