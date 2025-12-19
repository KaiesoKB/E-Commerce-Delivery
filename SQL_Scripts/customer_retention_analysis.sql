# CUSTOMER RETENTION ANALYSIS
USE ecommerce_delivery;

SELECT COUNT(DISTINCT customer_unique_id) AS "Number of unique customers",
	COUNT(DISTINCT order_id) AS "Total number of orders"
FROM orders;
-- 93763 total unique customers and 93763 total orders

SELECT
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS null_customer_unique_ids,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids
FROM orders;
-- No null customer_unique_ids or order_ids exist
-- Each order is mapped to a distinct customer_unique_id (1 DISTINCT order_id -> 1 DISTINCT customer_unique_id)
-- No repeat customers found -> Customer retention cannot be tracked