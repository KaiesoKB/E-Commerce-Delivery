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

# Identifying if there is a difference in the logistics times that contribute to higher late delivery rates in Summer 2018 compared to Summer 2017:
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	MONTH(o.order_delivered_customer_date) AS "Month",
	ROUND(AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.apporval_time_mins END), 2) AS "Average approval time of late orders",
    ROUND(AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.apporval_time_mins END), 2) AS "Average approval time of non late orders",
    ROUND(AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.carrier_pickup_time_mins END), 2) AS "Average Carrier pickup time of late orders",
    ROUND(AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.carrier_pickup_time_mins END), 2) AS "Average Carrier pickup time of non late orders",
    ROUND(AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.shipping_time_mins END), 2) AS "Average shipping time of late orders",
    ROUND(AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.shipping_time_mins END), 2) AS "Average shipping time of non late orders"
FROM orders o
JOIN orders_duration od
	ON o.order_id = od.order_id
LEFT JOIN late_orders lo
    ON o.order_id = lo.order_id
WHERE (YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date)) IN ((2017, 12), (2018, 1), (2018, 3), (2018, 4), (2018, 8))
GROUP BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date)
ORDER BY YEAR(o.order_delivered_customer_date), MONTH(o.order_delivered_customer_date);
-- December 2017: higher approval and pickup times, lower shipping times
-- January 2018: Higher approval, pickup and shipping times
-- March 2018: Lower approval and pickup times, roughly same shipping times
-- April 2018: Lower approval and pickup times, higher shipping times
-- August 2018: roughly same approval and pickup times, lower shipping times


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

# Identifying if there is a difference in the logistics times that contribute to higher late delivery rates in Spring 2018 compared to Spring 2017:
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.apporval_time_mins END) AS "Average approval time of late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.apporval_time_mins END) AS "Average approval time of non late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.carrier_pickup_time_mins END) AS "Average Carrier pickup time of late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.carrier_pickup_time_mins END) AS "Average Carrier pickup time of non late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.shipping_time_mins END) AS "Average shipping time of late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.shipping_time_mins END) AS "Average shipping time of non late orders per year"
FROM orders o
JOIN orders_duration od
	ON o.order_id = od.order_id
LEFT JOIN late_orders lo
    ON o.order_id = lo.order_id
WHERE MONTH(o.order_delivered_customer_date) BETWEEN 3 AND 5 
GROUP BY YEAR(o.order_delivered_customer_date)
ORDER BY YEAR(o.order_delivered_customer_date), ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- Approval time did not contribute to the rise in late deliveries.
-- Carrier pickup time cannot explain the higher late delivery rate.
-- Shipping time is the primary contributor to the increased late delivery rate, in terms of logistics operations


# Identifying if there is a difference in the routes (seller to customer states) that contribute to higher late delivery rates in Summer 2018 compared to Summer 2017:
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
WHERE MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8
GROUP BY YEAR(o.order_delivered_customer_date), s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY YEAR(o.order_delivered_customer_date), s.seller_state, ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- No problematic routes in Summer 2017
-- There were 5 routes in Summer 2018 that contributed to the high volume of late deliveries. 4 from SP and 1 from RJ (seller states)

# Identifying if there is a difference in the product_categories that contribute to higher late delivery rates in Summer 2018 compared to Summer 2017:
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
WHERE MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8 
GROUP BY YEAR(o.order_delivered_customer_date), p.product_category_name
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY YEAR(o.order_delivered_customer_date), ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- There are no product categories that contribute meaningfully to the late delivery rate in Summer 2017
-- There were only 2 products that contribute meaningfully to the late delivery rate in Summer 2018. food: 25/186 (13.44%) and office_furniture: 21/195 (10.77%)

# Identifying if there is a difference in the logistics times that contribute to higher late delivery rates in Summer 2018 compared to Summer 2017:
SELECT YEAR(o.order_delivered_customer_date) AS "Year",
	AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.apporval_time_mins END) AS "Average approval time of late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.apporval_time_mins END) AS "Average approval time of non late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.carrier_pickup_time_mins END) AS "Average Carrier pickup time of late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.carrier_pickup_time_mins END) AS "Average Carrier pickup time of non late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.shipping_time_mins END) AS "Average shipping time of late orders per year",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.shipping_time_mins END) AS "Average shipping time of non late orders per year"
FROM orders o
JOIN orders_duration od
	ON o.order_id = od.order_id
LEFT JOIN late_orders lo
    ON o.order_id = lo.order_id
WHERE MONTH(o.order_delivered_customer_date) BETWEEN 6 AND 8
GROUP BY YEAR(o.order_delivered_customer_date)
ORDER BY YEAR(o.order_delivered_customer_date), ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- There is no mechanism in the logistics timeline that could explain an increase in late deliveries during summer 2018.