# ORDER COMPLEXITY ANALYSIS
USE ecommerce_delivery;

# Identifying the most items in an order
SELECT MAX(order_item_id) AS "Max items in at least 1 order", MIN(order_item_id) AS "Min items in at least 1 order"
FROM order_items;
-- Orders contain up to 21 items 

# Identifing how many unique orders have more than 1 item
SELECT COUNT(DISTINCT order_id)
FROM order_items
WHERE order_item_id > 1;
-- 9355 unique orders with over 1 item

# Identifying the number of unique order with different amount of order items
SELECT items_per_order AS "Number of items in an order",
	COUNT(DISTINCT order_id) AS "Number of unique orders per number of items",
    SUM(items_per_order) AS "Cumulative order items" -- This is a sanity check to ensure that all items involved in an order are accounted for
FROM (
	SELECT order_id,
		COUNT(order_item_id) AS items_per_order
	FROM order_items
    GROUP BY order_id
) ipo
GROUP BY items_per_order
ORDER BY items_per_order;
-- Majority orders have 1 item and least orders have 13 or 21 items 
-- The amount of orders decreases the more items they have -> orders with 8+ items are less than 10
-- There seems to be no orders that contain 16 -> 19 items

# Confirming that there are no orders with MAX 16 to 19 items
SELECT order_id, order_item_id
FROM order_items
WHERE order_item_id > 16;
-- There are 3 orders that have at least 16 items, but each contains 20, 20 and 21 items respectively (not 16 max)

# Identifing the number of late orders with different number of order items
SELECT ipo.items_per_order AS "Number of items in an order",
	COUNT(DISTINCT lo.order_id) AS "Number of unique late orders",
	COUNT(DISTINCT ipo.order_id) AS "Number of unique orders per number of items",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT ipo.order_id)) * 100, 2) AS "Percent of late orders per number of items"
FROM (
	SELECT order_id,
		COUNT(order_item_id) AS items_per_order
	FROM order_items
    GROUP BY order_id
) ipo
LEFT JOIN late_orders lo
	ON ipo.order_id = lo.order_id
GROUP BY ipo.items_per_order
HAVING COUNT(DISTINCT ipo.order_id) > 100
ORDER BY ipo.items_per_order;
-- There are less than 100 total unique orders for items with 7 or more. The sample is too small to dictate anything. 
-- Orders with at least 7 items also have 0% late delivery, except for the 1 order with 21 items. (100%)
-- The number of total unique orders drastically decrease from those containing 1 item to those containing 6 items
-- However, the late delivery rate remains roughly the same: between 5.79% (4 itemed orders) -> 8.36% (1 itemed orders)

# Identifying if more items in an order will cause the order to be delayed later
SELECT ipo.items_per_order AS "Number of items in an order",
	COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN lo.order_id END) AS "Number of unique orders late by 1 day",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '1 Day' THEN lo.order_id END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of unique orders late by 1 day",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN lo.order_id END) AS "Number of unique orders late by 2 days",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '2 Days' THEN lo.order_id END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of unique orders late by 2 days",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN lo.order_id END) AS "Number of unique orders late by 3 days",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '3 Days' THEN lo.order_id END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of unique orders late by 3 days",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN lo.order_id END) AS "Number of unique orders late by 4-6 days",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '4-6 Days' THEN lo.order_id END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of unique orders late by 4-6 days",
    COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN lo.order_id END) AS "Number of unique orders late by 7+ days",
    ROUND((COUNT(CASE WHEN lo.days_delivered_late_bucket = '7+ Days' THEN lo.order_id END) / COUNT(lo.order_id)) * 100, 2) AS "Percent of unique orders late by 7+ days"
FROM (
	SELECT order_id,
		COUNT(order_item_id) AS items_per_order
	FROM order_items
    GROUP BY order_id
) ipo
JOIN late_orders lo
	ON ipo.order_id = lo.order_id
GROUP BY ipo.items_per_order
ORDER BY ipo.items_per_order;
-- Majority of LATE orders with more than 1 item was late by 7+ days. 
-- 7+ days delivered late: 2 items -> 43.96%, 3 items -> 38.16%, 4 items -> 50.00%, 5 items -> 33.33, 6 items -> 53.33
-- The 1 late order with 21 items was delivered late by 4-6 days

# Identifying if orders with multiple items have times in the operational pipeline
SELECT ipo.items_per_order AS "Number of items in an order",
	AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.apporval_time_mins END) AS "Average approval time of late orders per number of items",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.apporval_time_mins END) AS "Average approval time of non late orders per number of items",
    AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.carrier_pickup_time_mins END) AS "Average carrier pickup time of late orders per number of items",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.carrier_pickup_time_mins END) AS "Average carrier pickup time of non late orders per number of items",
    AVG(CASE WHEN od.order_delay_time_mins > 0 THEN od.shipping_time_mins END) AS "Average shipping time of late orders per number of items",
    AVG(CASE WHEN od.order_delay_time_mins = 0 THEN od.shipping_time_mins END) AS "Average shipping time of non late orders per number of items"
FROM (
	SELECT order_id,
		COUNT(order_item_id) AS items_per_order
	FROM order_items
    GROUP BY order_id
) ipo
LEFT JOIN orders_duration od
	ON ipo.order_id = od.order_id
GROUP BY ipo.items_per_order
HAVING COUNT(CASE WHEN od.order_delay_time_mins = 0 THEN od.order_id END) > 100
ORDER BY ipo.items_per_order;
-- Carrier pickup time is ~2.5x longer for late orders compared to non late orders regardless of number of items. 
-- Shipping time is ~3x longer for late orders compared to non late orders regardless of number of items.
-- Operational logistics carry more of an impact on late orders than the number of items