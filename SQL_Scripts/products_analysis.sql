# PRODUCT LEVEL DELIVERY PERFORMANCE 
USE ecommerce_delivery;

SELECT COUNT(DISTINCT product_id)
FROM products;
# There are 31296 unique products

SELECT COUNT(product_id)
FROM order_items;
# There are 107058 products ordered

SELECT COUNT(*)
FROM products p
JOIN order_items oi
	ON p.product_id = oi.product_id
JOIN late_orders lo
	ON oi.order_id = lo.order_id;
# There are 8532 products delivered late

# Product Category Analysis 
SELECT COUNT(DISTINCT product_category_name) AS "Number of product categories"
FROM products;

# Standardizing product dimensions to obtain general relative average dimensions of each product category =
WITH stats AS (
    SELECT
        MIN(product_weight_g) AS min_w,
        MAX(product_weight_g) AS max_w,
        MIN(product_length_cm) AS min_l,
        MAX(product_length_cm) AS max_l,
        MIN(product_height_cm) AS min_h,
        MAX(product_height_cm) AS max_h,
        MIN(product_width_cm) AS min_wd,
        MAX(product_width_cm) AS max_wd
    FROM products
),
normalized AS (
    SELECT
        product_category_name,
        (product_weight_g - min_w) / (max_w - min_w) AS norm_weight,
        (product_length_cm - min_l) / (max_l - min_l) AS norm_length,
        (product_height_cm - min_h) / (max_h - min_h) AS norm_height,
        (product_width_cm - min_wd) / (max_wd - min_wd) AS norm_width
    FROM products, stats
),
aggregation AS (
	SELECT 
		product_category_name,
		ROUND(AVG(norm_weight), 4) AS avg_norm_weight,
		ROUND(AVG(norm_length), 4) AS avg_norm_length,
		ROUND(AVG(norm_height), 4) AS avg_norm_height,
		ROUND(AVG(norm_width), 4) AS avg_norm_width,
		ROUND(
			AVG(norm_weight) +
			AVG(norm_length) +
			AVG(norm_height) +
			AVG(norm_width)
		, 4) AS combined_normalized_score
	FROM normalized
	GROUP BY product_category_name
)
SELECT 
	DENSE_RANK() OVER (ORDER BY combined_normalized_score DESC) AS "Rank",
    product_category_name,
    avg_norm_weight,
    avg_norm_length,
    avg_norm_height,
    avg_norm_width,
    combined_normalized_score
FROM aggregation
ORDER BY combined_normalized_score DESC;
-- office_furniture is relatively the largest product category with a combined normalized score of 1.4789 (1st)
-- telephony is relatively the smallest product category with a combined normalized score of 0.2332 (73rd)

SELECT p.product_category_name AS "Product Category",
	COUNT(DISTINCT CASE WHEN lo.order_id IS NOT NULL THEN lo.order_id END) AS "Number of orders delivered late containing the product category",
	COUNT(DISTINCT oi.order_id) AS "Total Number of orders containing the product category",
    ROUND((COUNT(DISTINCT CASE WHEN lo.order_id IS NOT NULL THEN lo.order_id END)/COUNT(DISTINCT oi.order_id)) * 100, 2) AS "Percent of orders containing the product category delivered late"
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
LEFT JOIN late_orders lo 
    ON oi.order_id = lo.order_id
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT oi.order_id) > 300
ORDER BY ROUND((COUNT(DISTINCT CASE WHEN lo.order_id IS NOT NULL THEN lo.order_id END)/COUNT(DISTINCT oi.order_id)) * 100, 2) DESC
LIMIT 15;
-- These high volume products range from 8.52% late delivery rate (furniture_living_room) -> 13.08% (audio)
-- Compared to baseline late delivery %, audio is prooblematic. food, comfort and electronics needs more attention and observation
-- All other categories fall within the baseline
-- audio, home_comfort, food and electronics together make up 3649 total orders with 375 late orders
-- This entails that 4.9% of late orders contain at least one of these products 
-- ANALYZE THESE 4 PRODUCTS FURTHER IN ORDER COMPLEXITY AND ROUTE PERFORMANCE 

# Identifying what % of late orders contain at least one of the noticeable product categories
SELECT COUNT(CASE WHEN p.product_category_name IN ('audio', 'home_confort', 'food', 'electronics') THEN lo.order_id END) AS "Late orders with target categories",
    COUNT(DISTINCT lo.order_id) AS "Total late orders",
    ROUND((COUNT(CASE WHEN p.product_category_name IN ('audio', 'home_confort', 'food', 'electronics') THEN lo.order_id END) / COUNT(DISTINCT lo.order_id)) * 100.0, 2) 
		AS "Percent late orders with target categories"
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id;
-- Orders that contain at least one of these products make up 5.25% of late orders
-- Product categories seem to carry no correlation to late orders ✅

# Product Dimensions Analysis 
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
-- This implies that product dimentions play liitle to no part in an order being delayed based on their average dimensions. 

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
-- It seems that the heaviest, longest, tallest, and widest prodct was delivered late.

DROP VIEW IF EXISTS max_product_dimensions;

CREATE VIEW max_product_dimensions AS
SELECT 
	MAX(p.product_weight_g) AS max_weight,
	MAX(p.product_length_cm) AS max_length,
	MAX(p.product_height_cm) AS max_height,
	MAX(p.product_width_cm) AS max_width
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN late_orders lo ON oi.order_id = lo.order_id;

# Identifying how many products in total meet maximum dimensions
SELECT SUM(p.product_weight_g = mpd.max_weight) AS "Total_num_products_with_max_weight",
    SUM(p.product_length_cm = mpd.max_length) AS "Total_num_products_with_max_length",
    SUM(p.product_height_cm = mpd.max_height) AS "Total_num_products_with_max_height",
    SUM(p.product_width_cm = mpd.max_width) AS "Total_num_products_with_max_width"
FROM products p
JOIN max_product_dimensions mpd;
-- 163 products meet one of the max dimensions. (1 max weight, 138 max length, 23 max height, 1 max width)

# Identifying how many LATE DELIVERED PRODUCTS meet the max dimensions
SELECT 
    SUM(p.product_weight_g = mpd.max_weight) AS "Num_late_delivered_products_with_max_weight",
    SUM(p.product_length_cm = mpd.max_length) AS "Num_late_delivered_products_with_max_length",
    SUM(p.product_height_cm = mpd.max_height) AS "Num_late_delivered_products_with_max_height",
    SUM(p.product_width_cm = mpd.max_width) AS "Num_late_delivered_products_with_max_width"
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN late_orders lo ON oi.order_id = lo.order_id
CROSS JOIN max_product_dimensions mpd;
# 50 products meet one of the max dimensions. (1 max weight, 26 max length, 22 max height, 1 max width)

WITH late_delivered_products_with_max_dimension AS (
	SELECT 
		CASE 
			WHEN p.product_weight_g = mpd.max_weight
			OR p.product_length_cm = mpd.max_length
			OR p.product_height_cm = mpd.max_height
			OR p.product_width_cm = mpd.max_width
			THEN 1
			ELSE 0
		END AS max_dimension_matched
	FROM products p
	JOIN order_items oi ON p.product_id = oi.product_id
	JOIN late_orders lo ON oi.order_id = lo.order_id
	CROSS JOIN max_product_dimensions mpd
)
SELECT SUM(max_dimension_matched) AS "late products that have a max dimension",
	COUNT(*) AS "Total number of products delivered late",
	ROUND((SUM(max_dimension_matched)/COUNT(*)) * 100, 2) AS "Percent of products delivered late that have max dimensions"
FROM late_delivered_products_with_max_dimension;
-- 0.59% of products delivered late meet one of the max dimensions

# Analyzing how late these products with max dimensions were delivered.
SELECT 
	CASE
		WHEN lo.order_delay_days = 0 THEN 'Some Hours'
		WHEN lo.order_delay_days = 1 THEN '1 day'
        WHEN lo.order_delay_days = 2 THEN '2 days'
        WHEN lo.order_delay_days = 3 THEN '3 days'
        WHEN lo.order_delay_days BETWEEN 4 AND 6 THEN '4-6 days'
        WHEN lo.order_delay_days >= 7 THEN '7+ days'
	END AS Time_delivered_late,
	SUM(p.product_weight_g = mpd.max_weight) AS "Num_late_delivered_products_with_max_weight",
    SUM(p.product_length_cm = mpd.max_length) AS "Num_late_delivered_products_with_max_length",
    SUM(p.product_height_cm = mpd.max_height) AS "Num_late_delivered_products_with_max_height",
    SUM(p.product_width_cm = mpd.max_width) AS "Num_late_delivered_products_with_max_width"
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN late_orders lo ON oi.order_id = lo.order_id
CROSS JOIN max_product_dimensions mpd
WHERE
	p.product_weight_g = mpd.max_weight
    OR p.product_length_cm = mpd.max_length
    OR p.product_height_cm = mpd.max_height
    OR p.product_width_cm = mpd.max_width
GROUP BY Time_delivered_late
ORDER BY 
	CASE 
		WHEN Time_delivered_late = '1 day' THEN 1
		WHEN Time_delivered_late = '2 days' THEN 2
		WHEN Time_delivered_late = '3 days' THEN 3
		WHEN Time_delivered_late = '4-6 days' THEN 4
		WHEN Time_delivered_late = '7+ days' THEN 5
	END;
-- Hours: 1 product had max height
-- 1 Day: 2 max length, 1 max height
-- 2 Days: 1 max weight, 6 max length, 2 max height
-- 3 Days: 2 max length, 2 max height
-- 4-6 Days: 4 max length, 2 max height
-- 7+ Days: 12 max length, 14 max height, 1 max width

# Product Photos Quantity Analysis 
SELECT p.product_photos_qty AS "Number of product photos",
	COUNT(lo.order_id) AS "Number of late delivered products per photo qty",
	total_products.Total_product_photos_qty AS "Total number of products per photo qty",
    ROUND((COUNT(lo.order_id) / total_products.Total_product_photos_qty) * 100, 2) AS "Percentage of products delivered late"
FROM late_orders lo
JOIN order_items oi 
	ON lo.order_id = oi.order_id
JOIN products p
	ON oi.product_id = p.product_id
JOIN (
	SELECT product_photos_qty, COUNT(product_photos_qty) AS Total_product_photos_qty
    FROM products
    GROUP BY product_photos_qty
) AS total_products 
	ON p.product_photos_qty = total_products.product_photos_qty
GROUP BY p.product_photos_qty
ORDER BY ((COUNT(lo.order_id) / total_products.Total_product_photos_qty) * 100) DESC;
-- Only qty 6 and 7 seems off (6 = 33.26% and 7 = 42.90%)
-- Higher photo qty have high chance of being delivered late, but they are very rare (very few products have 11+ photos)
-- Lower photo qty have around the same range of late delivery % (24.53% -> 29.79%)