# PAYMENT BEHAVIOR ANALYSIS
USE ecommerce_delivery;

SELECT COUNT(order_id)
FROM payments;
-- 97913 payments
-- 93763 unique orders

# Exploring the payment installments
SELECT MAX(payment_installments), MIN(payment_installments)
FROM payments;
-- 1 -> 24

SELECT
	CASE 
		WHEN payment_installments = 1 THEN '1'
        WHEN payment_installments = 2 THEN '2'
        WHEN payment_installments = 3 THEN '3'
        WHEN payment_installments = 4 THEN '4'
        WHEN payment_installments = 5 THEN '5'
        WHEN payment_installments = 6 THEN '6'
        WHEN payment_installments = 7 THEN '7'
        WHEN payment_installments = 8 THEN '8'
        WHEN payment_installments = 9 THEN '9'
        WHEN payment_installments = 10 THEN '10'
        WHEN payment_installments = 11 THEN '11'
        WHEN payment_installments = 12 THEN '12'
        WHEN payment_installments = 13 THEN '13'
        WHEN payment_installments = 14 THEN '14'
        WHEN payment_installments = 15 THEN '15'
        WHEN payment_installments = 16 THEN '16'
        WHEN payment_installments = 17 THEN '17'
        WHEN payment_installments = 18 THEN '18'
        WHEN payment_installments = 19 THEN '19'
        WHEN payment_installments = 20 THEN '20'
        WHEN payment_installments = 21 THEN '21'
        WHEN payment_installments = 22 THEN '22'
        WHEN payment_installments = 23 THEN '23'
        ELSE '24'
	END AS "payment_installments",
    COUNT(DISTINCT order_id)
FROM payments
GROUP BY 
	CASE 
		WHEN payment_installments = 1 THEN '1'
        WHEN payment_installments = 2 THEN '2'
        WHEN payment_installments = 3 THEN '3'
        WHEN payment_installments = 4 THEN '4'
        WHEN payment_installments = 5 THEN '5'
        WHEN payment_installments = 6 THEN '6'
        WHEN payment_installments = 7 THEN '7'
        WHEN payment_installments = 8 THEN '8'
        WHEN payment_installments = 9 THEN '9'
        WHEN payment_installments = 10 THEN '10'
        WHEN payment_installments = 11 THEN '11'
        WHEN payment_installments = 12 THEN '12'
        WHEN payment_installments = 13 THEN '13'
        WHEN payment_installments = 14 THEN '14'
        WHEN payment_installments = 15 THEN '15'
        WHEN payment_installments = 16 THEN '16'
        WHEN payment_installments = 17 THEN '17'
        WHEN payment_installments = 18 THEN '18'
        WHEN payment_installments = 19 THEN '19'
        WHEN payment_installments = 20 THEN '20'
        WHEN payment_installments = 21 THEN '21'
        WHEN payment_installments = 22 THEN '22'
        WHEN payment_installments = 23 THEN '23'
        ELSE '24'
	END;

# Identifying if payment isntallment correlate to higher late delivery rate or high volumes of late delivery    
SELECT p.payment_installments AS "Number of payment installments",
	COUNT(lo.order_id) AS "Number of late orders per payment installments amount",
    COUNT(p.order_id) AS "Total number of orders per payment installments amount",
    ROUND((COUNT(lo.order_id) / COUNT(p.order_id)) * 100, 2) AS "Percent of orders per payment installments amount that were delivered late"
FROM payments p
LEFT JOIN late_orders lo
	ON p.order_id = lo.order_id
GROUP BY p.payment_installments
HAVING COUNT(p.order_id) > 100
ORDER BY COUNT(p.order_id) DESC;
-- Higher payment installments have too little data sample to infer if payment installments amount have an effect on late deliveries
-- All payment installments amount with over 100 orders have roughly the same late delivery rate (between 7% -> 11%)
-- orders with 1 installment has most late orders but most total orders (3921/49467)


# Exploring the payment types
SELECT payment_type, COUNT(payment_type) AS "Frequency of payment type"
FROM payments
GROUP BY payment_type;
-- credit_card: 72525, boleto: 18640, voucher: 5332, debit_card: 1416 -> 97913 total ✅

# Identifying if payment types correlate to higher late delivery rate or high volumes of late delivery  
SELECT p.payment_type AS "Payment type",
	COUNT(lo.order_id) AS "Number of late orders per payment type",
    COUNT(p.order_id) AS "Total number of orders per payment type",
    ROUND((COUNT(lo.order_id) / COUNT(p.order_id)) * 100, 2) AS "Percent of orders per payment type that were delivered late"
FROM payments p
LEFT JOIN late_orders lo
	ON p.order_id = lo.order_id
GROUP BY p.payment_type
ORDER BY COUNT(p.order_id) DESC;
-- All payment types have roughly the same late delivery rate regardless of the huge difference in volume of orders between each payment type
-- credit card: 5821/72525 (8.03%), boleto: 1674/18640 (8.98%), voucher: 365/5332 (6.85%), debit_card: 110/1416 (7.77%)


# Exploring the sequential payments
SELECT MAX(payment_sequential), MIN(payment_sequential)
FROM payments
WHERE order_id IS NOT NULL;
-- 1 -> 26

SELECT p.order_id
FROM payments p
WHERE p.payment_sequential = 26;

SELECT *
FROM payments
WHERE order_id = 'ccf804e764ed5650cd8759557269dc13';

# Identifying if more sequential payments correlate to higher late delivery rate or high volumes of late delivery  
SELECT p.payment_sequential AS "max payment sequential",
	COUNT(DISTINCT lo.order_id) AS "Number of late orders per sequential payments count",
    COUNT(DISTINCT p.order_id) AS "Total number of orders per sequential payments count",
    ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT p.order_id)) * 100, 2) AS "Percent of orders with sequential payments count that were delivered late"
FROM payments p
LEFT JOIN late_orders lo
	ON p.order_id = lo.order_id
GROUP BY p.payment_sequential
HAVING ROUND((COUNT(lo.order_id) / COUNT(p.order_id)) * 100, 2) > 0
ORDER BY ROUND((COUNT(lo.order_id) / COUNT(p.order_id)) * 100, 2) DESC;
-- order with 9+ sequential payments have no late orders but very little sample data (168 total amongst ranges 9 -> 26)
-- Majority of orders had 1 stand alone payment (93701 orders) with 7667 of them being late -> 8.18%
-- Only orders ranging from 1 -> 8 sequential payments had late orders with late delivery rate ranging from 2.22% (8 oayments) -> 8.33% (3 payments)


# Identifying if higher payment values lead to late deleveries more frequently 
SELECT ROUND(AVG(p.payment_value)) AS "Average payment value for late orders", -- 166
	MIN(p.payment_value) AS "Minimum payment value for late orders", -- 0.09
    MAX(p.payment_value) AS "Maximum payment value for late orders" -- 6922.21
FROM payments p
JOIN late_orders lo
	ON p.order_id = lo.order_id;
    
SELECT ROUND(AVG(p.payment_value)) AS "Average payment value for non late orders", -- 152
	MIN(p.payment_value) AS "Minimum payment value for non late orders", -- 0.00
    MAX(p.payment_value) AS "Maximum payment value for non late orders" -- 13664.08
FROM payments p
JOIN orders_duration od
	ON p.order_id = od.order_id
WHERE od.order_delay_time_mins = 0;
-- Statistical values (avg, min and max) arent enough to see any anomalies that can help determine if there is a correlation between payment value and late orders

# Segmenting payment values to uncover any hidden patterns that connect to late orders
SELECT
	CASE
		WHEN p.payment_value <= 50 THEN '50'
		WHEN p.payment_value <= 100 THEN '100'
		WHEN p.payment_value <= 200 THEN '200'
		WHEN p.payment_value <= 500 THEN '500'
        WHEN p.payment_value <= 1000 THEN '1000'
        WHEN p.payment_value <= 2000 THEN '2000'
        WHEN p.payment_value <= 5000 THEN '5000'
        WHEN p.payment_value <= 10000 THEN '10000'
        ELSE '10000+'
	END AS "Payment value bucket",
    COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) AS "NUmber of late orders per payment value bucket",
    COUNT(CASE WHEN od.order_delay_time_mins = 0 THEN od.order_id END) AS "Total number of orders per payment value bucket",
    ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(CASE WHEN od.order_delay_time_mins = 0 THEN od.order_id END)) * 100, 2)
		AS "Percent of orders per payment value bucket delivered late"
FROM payments p
JOIN orders_duration od
	ON p.order_id = od.order_id
GROUP BY 
	CASE
		WHEN p.payment_value <= 50 THEN '50'
		WHEN p.payment_value <= 100 THEN '100'
		WHEN p.payment_value <= 200 THEN '200'
		WHEN p.payment_value <= 500 THEN '500'
        WHEN p.payment_value <= 1000 THEN '1000'
        WHEN p.payment_value <= 2000 THEN '2000'
        WHEN p.payment_value <= 5000 THEN '5000'
        WHEN p.payment_value <= 10000 THEN '10000'
        ELSE '10000+'
	END
ORDER BY ROUND((COUNT(CASE WHEN od.order_delay_time_mins > 0 THEN od.order_id END) / COUNT(CASE WHEN od.order_delay_time_mins = 0 THEN od.order_id END)) * 100, 2) DESC;
-- Sample size for large payment values are too small too state if payment value has any correlation with late orders even though the late delivery rates are higher
-- Majority of the data lies within the smaller buckets (50 -> 1000)
-- The late delivery rate in these buckets range from 7.48% -> 10.17% 