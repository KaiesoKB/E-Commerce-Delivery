# TIME/SEASONS ANALYSIS
USE ecommerce_delivery;

SELECT MIN(order_delivered_customer_date) AS "Min date",
    MAX(order_delivered_customer_date) AS "Max date"
FROM orders;
-- Data recorded from October 2016 to October 2018

# Identifying specific months in each year that exhibit the most late deliveries 
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	MONTH(o.order_delivered_customer_date) AS "Month",
	COUNT(lo.order_id) AS "number of late delivered orders per month",
	COUNT(o.order_id) AS "Total number of orders per month",
    ROUND((COUNT(lo.order_id) / COUNT(o.order_id)) * 100, 2) AS "Percent of late orders per month"
FROM orders o
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
GROUP BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date)
HAVING COUNT(o.order_id) > 100
	AND ROUND((COUNT(lo.order_id) / COUNT(o.order_id)) * 100, 2) >= 10
ORDER BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date);
-- 2017 -> December: 746/7080 late orders (10.54%)
-- 2018 -> January: 653/6433 (10.15%), March: 1063/6693 (15.88%), April: 1446/7528 (19.21%), August: 865/8124 (10.65%)
-- These 5 time periods account for 4773/7673 total late orders (62.16% of all late orders)


# Identifying the routes that contribute to the most late orders in these time periods
	-- WITH total_late_orders AS (
	-- 	SELECT order_id, COUNT(DISTINCT order_id) AS total_late_orders
	--     FROM late_orders
	--     GROUP BY order_id
	-- )
	-- SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	-- 	   MONTH(o.order_delivered_customer_date) AS "Month",
	-- 	   s.seller_state AS "Seller state",
	-- 	   c.customer_state AS "Customer state",
	-- 	   COUNT(DISTINCT lo.order_id) AS "Number of late orders",
	-- 	   COUNT(DISTINCT o.order_id) AS "Total number of orders",
	--     ROUND((COUNT(DISTINCT lo.order_id) /COUNT(DISTINCT o.order_id)) * 100, 2) AS "Late delivery rate of route",
	--     ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlo.total_late_orders)) * 100, 2) AS "Percent of all late deliveries"
	-- FROM sellers s
	-- JOIN order_items oi
	-- 		ON s.seller_id = oi.seller_id
	-- JOIN orders o
	-- 		ON oi.order_id = o.order_id
	-- JOIN customers c
	-- 		ON o.customer_unique_id = c.customer_unique_id
	-- LEFT JOIN late_orders lo
	-- 		ON o.order_id = lo.order_id
	-- CROSS JOIN total_late_orders tlo
	-- WHERE (YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date)) IN ((2017, 12), (2018, 1), (2018, 3), (2018, 4), (2018, 8))
	-- GROUP BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date), s.seller_state, c.customer_state
	-- HAVING COUNT(DISTINCT o.order_id) > 100
	-- ORDER BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date), ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlo.total_late_orders)) * 100, 2) DESC;
-- Inefficient query (keep recorded)

WITH total_late_orders AS (
    SELECT COUNT(DISTINCT order_id) AS total_late_orders
    FROM late_orders
),
route_orders AS (
    SELECT o.order_id,
        YEAR(o.order_delivered_customer_date) AS order_year,
        MONTH(o.order_delivered_customer_date) AS order_month,
        s.seller_state,
        c.customer_state,
        CASE WHEN lo.order_id IS NULL THEN 0 ELSE 1 END AS is_late
    FROM orders o
    JOIN order_items oi
		ON o.order_id = oi.order_id
    JOIN sellers s 
		ON oi.seller_id = s.seller_id
    JOIN customers c 
		ON o.customer_unique_id = c.customer_unique_id
    LEFT JOIN late_orders lo
		ON o.order_id = lo.order_id
    WHERE (YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date))
          IN ((2017, 12), (2018, 1), (2018, 3), (2018, 4), (2018, 8))
)
SELECT order_year AS "Year",
    order_month AS "Month",
    seller_state AS "Seller state",
    customer_state AS "Customer state",
    SUM(is_late) AS "Number of late orders",
    COUNT(order_id) AS "Total number of orders",
    ROUND(SUM(is_late)*100.0/COUNT(order_id),2) AS "Late delivery rate of route",
    ROUND(SUM(is_late)*100.0/tlo.total_late_orders,2) AS "Percent of all late deliveries"
FROM route_orders
CROSS JOIN total_late_orders tlo
GROUP BY order_year, order_month, seller_state, customer_state, tlo.total_late_orders
HAVING (COUNT(order_id) > 100 AND ROUND(SUM(is_late)*100.0/COUNT(order_id),2) >= 10)
	OR (COUNT(order_id) > 100 AND ROUND(SUM(is_late)*100.0/tlo.total_late_orders,2) >= 1)
ORDER BY order_year, order_month, ROUND(SUM(is_late)*100.0/tlo.total_late_orders,2) DESC;
-- 2017: December: SP-> SP 2.49% of all late deliveries, SP -> RJ 2.36% of all late deliveries
-- 2018: January: SP -> RJ 3.08% of all late deliveries | March: SP -> SP: 3.38% of all late deliveries, SP -> RJ 2.72% of all late deliveries, SP -> MG: 1.19% of all late deliveries
-- 2018: April: SP -> RJ: 3.99% of all late deliveries, SP -> SP: 2.72% of all late deliveries, SP -> MG: 2.06% of all late deliveries, SP -> BA: 1.07% of all late deliveries
-- 2018: August: SP -> SP: 7.78% of all late deliveries
-- All other routes in during these times have high late delivery rate at a route level

# Idenfitying the product categories that contribute most to the high deliery rate within the specific times
WITH total_late_orders AS (
    SELECT COUNT(DISTINCT order_id) AS total_late_orders
    FROM late_orders
)
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
    MONTH(o.order_delivered_customer_date) AS "Month",
    p.product_category_name AS "Product category",
    COUNT(DISTINCT lo.order_id) AS "Number of late orders containing product cateogry",
    COUNT(DISTINCT o.order_id) AS "Total number of orders containing product cateogry",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100,2) AS "Late delivery rate for product in time period",
    ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlo.total_late_orders)) * 100,2) AS "Percent of all late deliveries"
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
JOIN products p
	ON oi.product_id = p.product_id
LEFT JOIN late_orders lo
	ON oi.order_id = lo.order_id
CROSS JOIN total_late_orders tlo
WHERE (YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date)) IN ((2017, 12), (2018, 1), (2018, 3), (2018, 4), (2018, 8))
GROUP BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date), p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100 
	AND ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlo.total_late_orders)) * 100,2) > 1
ORDER BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date), ROUND((COUNT(DISTINCT lo.order_id) / MAX(tlo.total_late_orders)) * 100,2);
-- Problematic categories in this time period -> bed_bath_table, health_beauty, sports_leisure, computers_accessories, furniture_decor, watches_gifts, computers_accessories
-- Visualization for these specific product categories over time is beneficial - NOTE


# Identifying seasons in each year that exhibit the most late deliveries 
WITH total_late_orders AS (
    SELECT COUNT(DISTINCT order_id) AS total_late_orders
    FROM late_orders
)
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN lo.order_id END) AS num_late_orders_spring,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN 1 END) AS total_orders_spring,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN 1 END)) * 100, 2) AS "Percent of late orders in Spring",
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 THEN lo.order_id END) / MAX(tlo.total_late_orders)) * 100, 2) AS "Percent of all late orders", 
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN lo.order_id END) AS num_late_orders_summer,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN 1 END) AS total_orders_summer,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN 1 END)) * 100, 2) AS "Percent of late orders in Summer",
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 THEN lo.order_id END) / MAX(tlo.total_late_orders)) * 100, 2) AS "Percent of all late orders", 
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN lo.order_id END) AS num_late_orders_autumn,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN 1 END) AS total_orders_autumn,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN 1 END)) * 100, 2) AS "Percent of late orders in Autumn",
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) BETWEEN 9 AND 11 THEN lo.order_id END) / MAX(tlo.total_late_orders)) * 100, 2) AS "Percent of all late orders", 
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN lo.order_id END) AS num_late_orders_winter,
    COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN 1 END) AS total_orders_winter,
    ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN lo.order_id END) / COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN 1 END)) * 100, 2) AS "Percent of late orders in Winter",
	ROUND((COUNT(CASE WHEN MONTH(o.order_delivered_customer_date) IN (1, 2, 12) THEN lo.order_id END) / MAX(tlo.total_late_orders)) * 100, 2) AS "Percent of all late orders"
FROM orders o
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
CROSS JOIN total_late_orders tlo
GROUP BY YEAR(o.order_delivered_customer_date)
ORDER BY YEAR(o.order_delivered_customer_date);
-- Spring 2018 -> 2967 late orders (38.67% of all late orders), Summer 2018 -> 1532 late orders (19.97% of all late orders),  Winter 2018 -> 1018 late orders (13.27% of all late orders),
-- Winter 2017 -> 748 late orders (9.75% of all late orders), Autumn 2017 -> 625 late orders (8.15% of all late orders)
-- These results support the findings gathered from the monthly analysis
-- Spring 2018 has systematic breakdwon, especially compared to Spring 2017. This needs further investigation
-- Summer exhibits similar trend


# Identifying if there is a difference in the routes (seller to customer states) that contribute to higher late delivery rates in Spring 2018 compared to Spring 2017:
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
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
WHERE MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 
GROUP BY YEAR(o.order_delivered_customer_date), s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY YEAR(o.order_delivered_customer_date), s.seller_state, ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- Problematic routes in spring 2017: SP -> SC 
-- There were 19 routes in Spring 2018 that contributed to the high volume of late deliveries, with 15 of them being from SP -> different customer states

# Identifying if there is a difference in the product_categories that contribute to higher late delivery rates in Spring 2018 compared to Spring 2017:
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
    p.product_category_name AS "Product category",
    COUNT(DISTINCT lo.order_id) AS "Late deliveries made from seller state to customer state",
    COUNT(DISTINCT o.order_id) AS "Total orders made through route",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) AS "Percent of deliveries in route that were late"
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON o.order_id = oi.order_id
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id
WHERE MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 
GROUP BY YEAR(o.order_delivered_customer_date), p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY YEAR(o.order_delivered_customer_date), ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC
LIMIT 10;
-- There are no product categories that contribute meaningfully to the late delivery rate in Spring 2017
-- There were 26 products that contribute meaningfully to the late delivery rate in Spring 2018. The top 10 include(from highest to lowest rate): 
-- bed_bath_table, electronics, telephony, consoles_games, health_beauty, stationery, garden_tools, sports_leisure, computers_accessories, baby


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
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND lo.order_id IS NOT NULL THEN lo.order_id END) AS "Late deliveries made through route in Winter 2017",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND o.order_id IS NOT NULL THEN o.order_id END) AS "Total orders made through route in Winter 2017",
    ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND o.order_id IS NOT NULL THEN o.order_id END)) * 100, 2) AS "Percent of deliveries in route that were late in Winter 2017",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END) AS "Late deliveries made through route in Winter 2018",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END) AS "Total orders made through route in Winter 2018",
    ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL  THEN o.order_id END)) * 100, 2) AS "Percent of deliveries in route that were late in Winter 2018"
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
HAVING COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END) >= 100
	AND ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END)) * 100, 2) >= 10
ORDER BY ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END)) * 100, 2) DESC;
-- In Winter 2017, there were 6 routes with over 100 total deliveries and over 10% late delivery rate. From highest to lowest late delivery rate (23.97% -> 11.36%):
-- SP -> ES, SP -> RJ, SP -> GO, SP -> DF, SP -> SC, SP -> BA
-- In Winter 2018, there were 9 routes with voer 100 total deliveries and over 10% late delivery rate. From highest to lowest late delivery rate (25.79%, 11.30%):
-- SP -> RJ, MG -> RJ, PR -> RJ, SP -> BA, SP -> RS, SP -> SC, SP -> PE, RJ -> SP, SP -> CE

# Identifying the product categories that contribute most to the higher late delivery rates in Winter 2017 and Winter 2018
SELECT p.product_category_name AS "Product Category",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND lo.order_id IS NOT NULL THEN lo.order_id END) AS "Late deliveries made per product category in Winter 2017",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND o.order_id IS NOT NULL THEN o.order_id END) AS "Total orders made per product category in Winter 2017",
    ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2017 AND o.order_id IS NOT NULL THEN o.order_id END)) * 100, 2) AS "Percent of deliveries per product category that were late in Winter 2017",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END) AS "Late deliveries made per product category in Winter 2018",
    COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END) AS "Total orders made per product category in Winter 2018",
    ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END)) * 100, 2) AS "Percent of deliveries per product category that were late in Winter 2018"
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
JOIN orders o 
    ON oi.order_id = o.order_id
LEFT JOIN late_orders lo
	ON o.order_id = lo.order_id
WHERE MONTH(o.order_delivered_customer_date) IN (1, 2, 12)
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END) >= 80
	AND ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END)) * 100, 2) >= 10
ORDER BY ROUND((COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND lo.order_id IS NOT NULL THEN lo.order_id END)
			/ COUNT(DISTINCT CASE WHEN YEAR(o.order_delivered_customer_date) = 2018 AND o.order_id IS NOT NULL THEN o.order_id END)) * 100, 2) DESC;
-- 748/8660 (2017) and 1018/12130 (2018)
-- In Winter 2017; there were 5 product categories with over 50 total deliveries and over 10% late delivery rate (from highest to lowest: 15.38% -> 10.39%)
-- office_furniture, bed_bath_table, baby, electronics, telephony
-- In Winter 2018; there were 7 product categories with over 80 total deliveries and over 10% late delivery rate (from highest to lowest: 16.67% -> 10.47%)
-- toys, baby, consoles_games, garden_tools, furniture_decor, bed_bath_table, musical_instruments