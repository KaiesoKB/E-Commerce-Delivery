# ROUTE OPERATIONS ANALYSIS
USE ecommerce_delivery;

# Identifying routes high volumes of orders and high late delivery rate
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
WHERE s.seller_state NOT IN ('SP')
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- Possible problematic routes: MA -> SP (26.27%), PR -> BA (16.78%), PR -> RJ (13.93%), RJ -> BA (10.85%), MG -> BA (10.67%), RJ -> SC (10.62%), SC -> RJ (10.34%)
-- All customer states were identified in customer analysis EXCEPT SC (Route: RJ -> SC only has 12/113 late orders)
-- This route is identified as RJ was ranked 3rd in highest late delivery rate seller state
-- These routes contain one of the identified seller or customer state found in previous analysis -> supported findings ✅

# Identifying which customer states that SP is selling to with high volumes of orders
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
WHERE s.seller_state IN ('SP')
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 1000
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- 61492/66688 of total orders are delivered to these 11 customer states -> RJ(15.56%), BA(14.94%), ES(14.03%), SC(10.90%), PE(10.86%), GO(9.14%)
																		 -- DF(8.44%) , RS(7.75%), MG(6.42%), SP(6.24%), PR(5.43%)
-- Route SP -> RJ, BA, ES, SC, PE are contributes most to late delivery rate - NEEDS FURTHER ANALYSIS TO UNCOVER THE CAUSE
-- SP -> SP has 1871 late deliveries but 29967 total orders (late deliveries are relatively controlled). However this route accounts for 24.48% of total late deliveries
-- Investigate possible causes for this route as well

# Identifying Routes (seller states to customer states) with high total deliveries and little to no late deliveries.
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
WHERE s.seller_state NOT IN ('SP')
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) < 10
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) ASC;
-- RS -> SC: Only route with 0% late delivery (0/114)