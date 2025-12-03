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
	COUNT(lo.order_id) AS "Number of late orders coming from seller state", -- 8532 total late orders
    total_orders.total_orders_per_state AS "Total orders per state",
    ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) AS "late delivery rate per state",
    DENSE_RANK() OVER (ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC) AS "Rank"
FROM sellers s
JOIN order_items od
	ON s.seller_id = od.seller_id
JOIN late_orders lo
	ON od.order_id = lo.order_id
JOIN (
	SELECT s2.seller_state AS seller_state, 
		COUNT(o.order_id) AS total_orders_per_state
	FROM sellers s2
    JOIN order_items od2
		ON s2.seller_id = od2.seller_id
	JOIN orders o
		ON od2.order_id = o.order_id
	GROUP BY s2.seller_state
) AS total_orders
	ON total_orders.seller_state = s.seller_state
GROUP BY s.seller_state
ORDER BY ROUND((COUNT(lo.order_id)/total_orders.total_orders_per_state) * 100, 2) DESC;
-- States with over 10% late delivery rate: AM(66.67% -> 2/3 orders), MA(24.80%), PA(12.50%), RN(10.71%)
-- SP has 8.58% late delivery rate (5th highest) but 76364 total orders sold
-- 6th: MS(8.16%), 7th: RJ(8.14%)
-- All other states have less than 8% late delivery rate
-- STATES TO FURTHER ANALYZE: AM, MA, PA, RN, SP, MS, RJ
-- Consider PR, SC, MG, RS -> all over 1000 orders in each state

# Analyzing the approval time for seller from states with high late delivery rates
WITH all_orders AS (
    SELECT s.seller_state,
        AVG(od.apporval_time_mins) AS avg_all,
        MAX(od.apporval_time_mins) AS max_all,
        MIN(od.apporval_time_mins) AS min_all
    FROM sellers s
    JOIN order_items oi 
        ON s.seller_id = oi.seller_id
    JOIN orders_duration od 
        ON oi.order_id = od.order_id
    GROUP BY s.seller_state
),
late_orders AS (
    SELECT s.seller_state,
        AVG(od.apporval_time_mins) AS avg_late,
        MAX(od.apporval_time_mins) AS max_late,
        MIN(od.apporval_time_mins) AS min_late
    FROM sellers s
    JOIN order_items oi 
        ON s.seller_id = oi.seller_id
    JOIN late_orders lo 
        ON oi.order_id = lo.order_id
    JOIN orders_duration od 
        ON lo.order_id = od.order_id
    GROUP BY s.seller_state
)
SELECT ao.seller_state,
    ROUND(ao.avg_all, 2) AS avg_approval_time_all_orders,
    ROUND(lo.avg_late, 2) AS avg_approval_time_late_orders,
    ao.max_all AS longest_approva_timel_all_orders,
    lo.max_late AS longest_approval_time_late_orders,
    ao.min_all AS shortest_approval_time_all_orders,
    lo.min_late AS shortest_approval_time_late_orders
FROM all_orders ao
LEFT JOIN late_orders lo
    ON ao.seller_state = lo.seller_state
WHERE ao.seller_state IN ('AM', 'MA', 'PA', 'RN', 'SP', 'MS', 'RJ')
ORDER BY ao.avg_all DESC;
-- SP: longest approval time for any order was late (confirm if all were late), average approval time of late orders were 130 mins longer 
-- RN: Approval time for late orders generally shorter 
-- RJ: higher average for late orders and longest approval time for any order was a late delivered order (confirm if all were late)
-- MA: Approval time for late orders generally shorter 
-- AM: Approval time very short in general -> avg for late orders higher and longest approval time for any order was delivered late
-- (confirm if all were late) This seems unelikely for state AM due to only 3 total orders sold in this state
-- MS: for late orders, teh average time is higher, but the longest time is shorter than the longest time of all orders
-- PA: only 1 late order -> took 1446 mins
-- States to confirm possible approval time influence: SP, RJ, MS

# Confirming if approval time has any influence on the following states: SP, RJ, MS
WITH late_orders_state AS (
    SELECT s.seller_state,
        lo.order_id,
        od.apporval_time_mins
    FROM sellers s
    JOIN order_items oi ON s.seller_id = oi.seller_id
    JOIN late_orders lo ON oi.order_id = lo.order_id
    JOIN orders_duration od ON lo.order_id = od.order_id
    WHERE s.seller_state IN ('SP', 'MS', 'RJ')
),
max_times AS (
    SELECT seller_state,
        MAX(apporval_time_mins) AS max_approval_time
    FROM late_orders_state
    GROUP BY seller_state
)
SELECT los.seller_state,
    COUNT(los.order_id) AS number_of_late_orders,
    COUNT(CASE WHEN los.apporval_time_mins = m.max_approval_time THEN 1 END)AS number_of_late_orders_with_max_approval_time
FROM late_orders_state los
JOIN max_times m
    ON los.seller_state = m.seller_state
GROUP BY 
    los.seller_state;
-- SP: 1/6554 late order took the max approval time 
-- RJ: 2/370 late orders took the max approval time
-- MS: 1/4 late order took the max approval time 
-- Approval may ONLY have an impact on late deliveries from sellers in the MS state ✅


# Identifying the states with the most severe late order delays
SELECT s.seller_state AS "Seller state",
	COUNT(lo.order_id) AS "Total number of orders delivered late",
	-- 	COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END) AS "Number of orders delivered some hours late",
	-- 	COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END) AS "Number of orders delivered 1 day late",
	-- 	COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END) AS "Number of orders delivered 2 days late",
	--  COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END) AS "Number of orders delivered 3 days late",
	--  COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END) AS "Number of orders delivered 4-6 days late",
	--  COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of orders delivered 7+ days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = 'Some Hours' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders delivered some hours late",
	ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders delivered 1 day late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders delivered 2 days late",
	ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders delivered 3 days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders delivered 4-6 days late",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END)/COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders delivered 7+ days late"
FROM sellers s
JOIN order_items oi
	ON s.seller_id = oi.seller_id
JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE s.seller_state IN ('AM', 'MA', 'PA', 'RN', 'SP', 'MS', 'RJ')
GROUP BY s.seller_state
ORDER BY COUNT(lo.order_id) DESC;
-- Majority of late orders in: SP(46.26%), RJ(47.84%), MA(45.26%), RN(50%) were 7+ days late when delivered [NOTE: -> RN had 6 late orders]
-- MS: 50% 4-6 days, 25% 7+ days, 25% 1 day (4 late orders)
-- AM: 50% 7+ days and 50% some hours (2 late orders)
-- PA: 100% 1 day (1 late order)
-- MS, AM and PA has too few late delivered orders to generalize and make suggestions based on their them being a seller state
-- AM:2/3 late orders, PA: 1/8 late orders  MS: 4/49 late orders, 

# Analyzing the product category names for the products sold by sellers in the states with the highest late delivery rates and mix distribution of days delivered late
SELECT s.seller_state AS "seller state",
	p.product_category_name AS "product category",
    COUNT(lo.order_id) AS "Number of late orders per category",
    lo.days_delivered_late_bucket AS "days delivered late"
FROM sellers s
JOIN order_items oi
	ON s.seller_id = oi.seller_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE s.seller_state IN ('AM', 'PA', 'MS')
GROUP BY s.seller_state, p.product_category_name, lo.days_delivered_late_bucket;
-- AM: both late orders were telephony product catetogy
-- PA: the late order was sports_leisure
-- MS: 1 late order was toys(1 day late) and 3 were auto(1 -> 7+ days late and 2 -> 4-6 days late)

# Comparing the product category names delivered late to all the product categories delivered from the sellers in states 'AM', 'PA', 'MS'
SELECT s.seller_state AS "seller state",
	p.product_category_name AS "product category",
    COUNT(oi.order_id) AS "Number of on time orders per category"
FROM sellers s
JOIN order_items oi
	ON s.seller_id = oi.seller_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN orders_duration od
	ON oi.order_id = od.order_id
WHERE s.seller_state IN ('AM', 'PA', 'MS') AND od.order_delay_time_mins = 0
GROUP BY s.seller_state, p.product_category_name;
-- AM: telephony 1
-- PA: sports_leisure 7
-- MS: health_beauty(20), auto(19), air_conditioning(1), toys(1), cool_stuff(4)
-- Confirmed that product_category_name has NO IMPACT on these states ✅

# Analyzing the product category names for the products sold by sellers in the states with the highest late delivery rates and majority of late delveries being 7+ days delayed
SELECT s.seller_state AS "seller state",
	p.product_category_name AS "product category",
    COUNT(lo.order_id) AS "Number of late orders per category",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) AS "Number of late orders 7+ days delayed",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of late orders in category that were 7+ days delayed"
FROM sellers s
JOIN order_items oi
	ON s.seller_id = oi.seller_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN late_orders lo
	ON oi.order_id = lo.order_id
WHERE s.seller_state IN ('MA', 'RN', 'SP', 'RJ')
GROUP BY s.seller_state, p.product_category_name
HAVING COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) > 0
ORDER BY s.seller_state, ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN 1 END) / COUNT(lo.order_id)) * 100, 2) DESC;
-- MA: 43/95 late orders were health_beauty -> Only product category with late deliveries 7+ days 
-- RJ: bed_bath_table(2), stationery(3) and furniture_mattress_and_upholstery(1) ALWAYS(100%) take 7+ days to deliver from sellers in RJ
-- RJ: books_general_interest, sports_leisure, health_beauty take 7+ days to deliver 50% of time from sellers in RJ
-- RJ: Most late deiveries that take 7+ days happen with health_beauty (56) -> (59.57% of late deliveries for this product in this seller state)
-- RN: 50% of orders in furniture_decor take 7+ days to deliver from sellers in RN -> Only product category with late deliveries 7+ days 
-- SP: air_conditioning, dvds_blu_ray, music ALWAYS(100%) take 7+ days to deliver from sellers in SP
-- SP: Most late deiveries that take 7+ days happen with bed_bath_table (412) -> (49.28% of late deliveries for this product in this seller state)
-- SP: This is followed by Health_and_Beauty having 2nd most late deliveries in SP taking 7+ days (243) -> (41.05% of late deliveries for this product in this seller state)


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