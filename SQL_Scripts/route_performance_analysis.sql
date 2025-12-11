# ROUTE OPERATIONS ANALYSIS
USE ecommerce_delivery;

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
# LEFT JOIN to avoid filtering out non-late orders
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) >= 10
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) DESC;
-- 8532 total late order items and 107058 total order items 
-- 7677 late orders and 94250 total orders -> Using 'DISTINCT'
-- Routes with 100% late delivery has too little data sample
-- Routes with over 10%  late delivery and 100+ total deliveries:
-- MA -> SP: 31/118 late orders delivered (26.27%), SP -> AL: 65/251 (25.90%), SP -> MA: 105/477 (22.01%), SP -> PI: 59/321 (18.38%)
-- PR -> BA: 24/143 (16.78%), SP -> SE: 34/206 (16.50%), SP -> RJ: 1242/7982 (15.56%), SP -> CE: 144/942 (15.29%), SP -> BA: 337/2255 (14.94%)
-- SP -> MS: 69/467 (14.78%), SP -> ES: 202/1440 (14.03%), PR -> RJ: 134/962 (13.93%), SP -> PA: 88/662 (13.29%), SP -> TO: 25/193 (12.95%)
-- SP -> RN: 39/324 (12.04%), SP -> PB: 36/327 (11.01%), SP -> SC: 246/2256 (10.90%), SP -> PE: 120/1105 (10.86%), RJ -> BA: 14/129 (10.85%)
-- MG -> BA: 38/356 (10.67%), RJ -> SC: 12/113 (10.62), SC -> RJ: 48/464 (10.34%)

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
# LEFT JOIN to avoid filtering out non-late orders
LEFT JOIN late_orders lo
    ON oi.order_id = lo.order_id
GROUP BY s.seller_state, c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
	AND ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) < 5
ORDER BY ROUND((COUNT(DISTINCT lo.order_id) / COUNT(DISTINCT o.order_id)) * 100, 2) ASC;
-- RS -> SC: Only state with 0% late delivery (0/114)
-- DF -> MG: 1/101 (0.99%), MG -> PR: 7/354 (1.98%), RS -> SP: 14/644 (2.17%), MG -> GO: 4/144 (2.78%), RS -> MG: 5/179 (2.79%)
-- PE -> SP: 3/103 (2.91%), DF -> SP: 9/300 (3.00%), SP -> RO: 5/164 (3.05%), SC -> PR: 9/282 (3.19%), MG -> MG: 47/1467 (3.20%)
-- MG -> DF: 6/183 (3.28%), PR -> SP: 101/2903 (3.48%), PR -> DF: 6/145 (4.14%), GO -> SP: 5/120 (4.17%), MG -> SP: 105/2476 (4.24%)
-- PR -> PR: 30/703 (4.27%), SC -> SP: 57/1302 (4.38%), MG -> ES: 8/169 (4.73%), RJ -> GO: 5/103 (4.85%), SC -> MG: 21/427 (4.92%)