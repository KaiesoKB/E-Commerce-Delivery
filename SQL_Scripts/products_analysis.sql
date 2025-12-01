# PRODUCT LEVEL DELIVERY PERFORMANCE 
USE ecommerce_delivery;

# Product Category analysis 
SELECT p.product_category_name AS "Product Category",
	COUNT(DISTINCT CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "Number of late deliveries",
	COUNT(od.order_id) AS "Number of orders in category",
    ROUND ((COUNT(DISTINCT CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END)/COUNT(od.order_id)) * 100, 2) AS "Percent of category delivered late"
FROM orders_duration od
JOIN order_items oi 
	ON od.order_id = oi.order_id
JOIN products p 
	ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY ROUND ((COUNT(DISTINCT CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END)/COUNT(od.order_id)) * 100, 2) DESC;

# Product Characteristics analysis 
# Average dimensions of all products
SELECT ROUND(AVG(p.product_weight_g), 2) AS "avg_product_weight", # 2273.46
	ROUND(AVG(p.product_length_cm), 2) AS "avg_product_length", # 30.84
	ROUND(AVG(p.product_height_cm), 2) AS "avg_product_height", # 16.89
    ROUND(AVG(p.product_width_cm), 2) AS "avg_product_width"# 23.19
FROM products p;

# # Average dimensions of late delivered products
SELECT ROUND(AVG(p.product_weight_g), 2) AS "avg_product_weight", # 2389.37
	ROUND(AVG(p.product_length_cm), 2) AS "avg_product_length", # 31.16
    ROUND(AVG(p.product_height_cm), 2) AS "avg_product_height", # 17.13
    ROUND(AVG(p.product_width_cm), 2) AS "avg_product_width" # 23.29
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN late_orders lo
	ON oi.order_id = lo.order_id;
# This implies that product dimentions play liitle to no part in an order being delayed based on their average dimensions. 

# Confirmation of this can be done by checking the Maximum and Minimum of each dimension for every product, both in general and for late deliveries
# Max and Min dimensions of all products
SELECT MIN(p.product_weight_g) AS "Min_product_weight", # 0.00
	MAX(p.product_weight_g) AS "Max_product_weight", # 40425.00
    MIN(p.product_length_cm) AS "Min_product_length", # 7.00
	MAX(p.product_length_cm) AS "Max_product_length", # 105.00
    MIN(p.product_height_cm) AS "Min_product_height", # 2.00
	MAX(p.product_height_cm) AS "Max_product_height", # 105.00
    MIN(p.product_width_cm) AS "Min_product_width", # 6.00
	MAX(p.product_width_cm) AS "Max_product_width" # 118.00
FROM products p;

# Max and Min dimensions of late delivered products
SELECT MIN(p.product_weight_g) AS "Min_product_weight", # 50.00
	MAX(p.product_weight_g) AS "Max_product_weight", # 40425.00
    MIN(p.product_length_cm) AS "Min_product_length", # 11.00
	MAX(p.product_length_cm) AS "Max_product_length", # 105.00
    MIN(p.product_height_cm) AS "Min_product_height", # 2.00
	MAX(p.product_height_cm) AS "Max_product_height", # 105.00
    MIN(p.product_width_cm) AS "Min_product_width", # 8.00
	MAX(p.product_width_cm) AS "Max_product_width" # 118.00
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN late_orders lo
	ON oi.order_id = lo.order_id;
# It seems that the heaviest, longest, tallest, and widest prodct was delivered late.

# Identifying how many products in total meet maximum dimensions
SELECT SUM(p.product_weight_g = max_dimensions.max_weight) AS "Total_num_products_with_max_weight",
    SUM(p.product_length_cm = max_dimensions.max_length) AS "Total_num_products_with_max_length",
    SUM(p.product_height_cm = max_dimensions.max_height) AS "Total_num_products_with_max_height",
    SUM(p.product_width_cm = max_dimensions.max_width) AS "Total_num_products_with_max_width"
FROM products p
JOIN (
    SELECT 
        MAX(p2.product_weight_g) AS max_weight,
        MAX(p2.product_length_cm) AS max_length,
        MAX(p2.product_height_cm) AS max_height,
        MAX(p2.product_width_cm) AS max_width
    FROM products p2
) AS max_dimensions;
# 163 products meet one of the max dimensions. (1 max weight, 138 max length, 23 max height, 1 max width)

# Identifying how many LATE DELIVERED PRODUCTS meet the max dimensions
SELECT 
    SUM(p.product_weight_g = max_dimensions.max_weight) AS "Num_late_delivered_products_with_max_weight",
    SUM(p.product_length_cm = max_dimensions.max_length) AS "Num_late_delivered_products_with_max_length",
    SUM(p.product_height_cm = max_dimensions.max_height) AS "Num_late_delivered_products_with_max_height",
    SUM(p.product_width_cm = max_dimensions.max_width) AS "NNum_late_delivered_products_with_max_width"
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN late_orders lo ON oi.order_id = lo.order_id
JOIN (
    SELECT 
        MAX(p2.product_weight_g) AS max_weight,
        MAX(p2.product_length_cm) AS max_length,
        MAX(p2.product_height_cm) AS max_height,
        MAX(p2.product_width_cm) AS max_width
    FROM products p2
    JOIN order_items oi2 ON p2.product_id = oi2.product_id
    JOIN late_orders lo2 ON oi2.order_id = lo2.order_id
) AS max_dimensions;
# 50 products meet one of the max dimensions. (1 max weight, 26 max length, 22 max height, 1 max width)