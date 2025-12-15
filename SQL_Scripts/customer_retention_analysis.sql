# CUSTOMER RETENTION ANALYSIS
USE ecommerce_delivery;

SELECT COUNT(DISTINCT customer_unique_id)
FROM orders;
-- 93763 total unique customers

# Identifying how many unique customers received late orders.
SELECT COUNT(DISTINCT c.customer_unique_id) AS "Number of customers who received late deliveries"
FROM customers c
JOIN orders o 
	ON c.customer_unique_id = o.customer_unique_id
JOIN late_orders lo
	ON o.order_id = lo.order_id;
-- Number of late orders = 7673 ORDERS
-- Number of customers received late orders = 7673 unique customers received a late order
-- Want to find how many of those customers had more than 1 order

# What percent of total customers received late orders
SELECT COUNT(DISTINCT CASE WHEN lo.order_id IS NOT NULL THEN c.customer_unique_id END) AS "Customers who received late deliveries",
    COUNT(DISTINCT c.customer_unique_id) AS "Total customers",
    ROUND(COUNT(DISTINCT CASE WHEN lo.order_id IS NOT NULL THEN c.customer_unique_id END) / COUNT(DISTINCT c.customer_unique_id) * 100.0, 2) AS "Percent of customers that received late orders"
FROM customers c
JOIN orders o
    ON c.customer_unique_id = o.customer_unique_id
LEFT JOIN late_orders lo
    ON o.order_id = lo.order_id;
-- 7673/93763 (8.18%) of customers received late orders. 

# Identifying how many customers, that receieved late orders, made more than 1 order. 
SELECT c.customer_unique_id AS "Customer ID", 
	COUNT(DISTINCT o.order_id) AS "Total number of orders made by customer"
FROM orders o
JOIN customers c 
	ON o.customer_unique_id = c.customer_unique_id
WHERE c.customer_unique_id IN (
	SELECT DISTINCT c2.customer_unique_id
	FROM customers c2
    JOIN orders o2
		ON c2.customer_unique_id = o2.customer_unique_id
    JOIN late_orders lo
		ON o2.order_id = lo.order_id
)
GROUP BY c.customer_unique_id 
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY COUNT(DISTINCT o.order_id) DESC;
-- No customers that received late orders, made a second order

# Let's confirm to see if there were any customers that made more than 1 order
SELECT COUNT(DISTINCT customer_unique_id) AS "Total number of unique customers",
	COUNT(DISTINCT CASE WHEN orders_per_customer > 1 THEN customer_unique_id END) AS "Number of repeat customers"
FROM (
	SELECT customer_unique_id, COUNT(DISTINCT order_id) AS orders_per_customer
    FROM orders
    GROUP BY customer_unique_id
) AS repeat_customer_count;
-- There are 93763 unqiue customers and no repeat customers in the database
-- This signals that no customer made a repeat order. 
-- Safe to assume then that we cannot determine if customer retention is affected by late orders/deliveries.