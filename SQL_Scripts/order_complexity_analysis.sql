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
	COUNT( order_id) AS "Number of orders per number of items"
FROM (
	SELECT order_id,
		COUNT(order_item_id) AS items_per_order
	FROM order_items
    GROUP BY order_id
) filter
GROUP BY items_per_order
ORDER BY items_per_order;
-- Majority orders have 1 item and least orders have 13 or 21 items 
-- The amount of orders decreases the more items they have -> orders with 8+ items are less than 10

# Identifing the number of late orders with differnet number of order items