USE phils_chocolates;

-- SHOW EACH TABLE.

SELECT * FROM customers;
SELECT * FROM chocolates;
SELECT * FROM orders;

-- SHOW THE ENTIRE DATA SET.

SELECT *
FROM orders o
	JOIN chocolates ch ON o.product_id = ch.product_id
		JOIN customers c ON o.customer_id = c.customer_id;

-- SHOW ALL CUSTOMERS FROM VIC.

SELECT
	customer_id,
    first_name,
    last_name,
    state
FROM customers
WHERE state = 'VIC';

-- HOW MANY CUSTOMERS LIVE IN SYDNEY?

SELECT
	city,
    COUNT(customer_id) AS no_customers
FROM customers
WHERE city = 'Sydney'
GROUP BY 1;

-- WHAT ARE THE CUSTOMERS NAME'S IN MELBOURNE WHO ARE BETWEEN 30 AND 50 YEARS OLD?

SELECT
	CONCAT(first_name, ' ', last_name) AS 'name',
    city,
    age
FROM customers
WHERE city = 'MELBOURNE'
	AND age >= 30
	AND age <= 50
ORDER BY 3;
    
-- CUSTOMER SCOTT MADDISON CONTACTED PHIL'S CHOCOLOATES TO UPDATE THEIR GENDER STATUS.
-- HE HAD NEGLECTED TO ENTER DETAILS IN THE GENDER FIELD WHEN SIGNING UP TO ORDER.
-- HE DID NOT KNOW HIS CUSOMER ID NUMBER.

SELECT * FROM customers WHERE gender IS NULL;

-- HIS CUSTOMER_ID IS 8.

UPDATE customers
SET gender = 'Male'
WHERE customer_id = 8;

SELECT first_name, last_name, gender FROM customers WHERE customer_id = 8;

-- GENDER SUCCESSFULLY UPDATED.

-- CUSTOMER SERVICE STAFF ARE OFTEN SEARCHING FOR CUSTOMERS BY SURNAME (as per above example).
-- CREATE INDEX TO SPEED UP PERFORMANCE OF CUSTOMER TABLE.
-- MORE USEFUL FOR LARGER DATA TABLES WHERE UPDATES AREN'T COMMON. SHOWN HERE FROM DEMONSTARTION PURPOSES.

CREATE INDEX last_name_search
ON customers (last_name);

SHOW INDEXES FROM customers;

-- INDEX SUCCESSFULLY CREATED.

-- SHOW ORDER COUNT FOR YEARS 2022 & 2023 FOR EACH STATE.

SELECT
	YEAR(order_date),
    COUNT(CASE WHEN state = 'VIC' THEN order_id ELSE NULL END) AS vic_order_count,
	COUNT(CASE WHEN state = 'NSW' THEN order_id ELSE NULL END) AS nsw_order_count,
	COUNT(CASE WHEN state = 'QLD' THEN order_id ELSE NULL END) AS qld_order_count
FROM orders o
	JOIN customers c
		ON o.customer_id = c.customer_id
WHERE order_date BETWEEN '2022-01-01' AND '2023-12-31'
GROUP BY 1;

-- EXTRACT ORDER TOTALS
-- (a) JOINS solution.
    
SELECT
	o.order_id AS orderid,
	SUM(o.quantity * ch.price_aud) AS order_total
FROM orders o
    LEFT JOIN chocolates ch
		ON o.product_id = ch.product_id
			LEFT JOIN customers c
				ON o.customer_id = c.customer_id
GROUP BY o.order_id;

-- EXTRACT ORDER TOTALS
-- (b) TEMPORARY TABLE solution for Top 20 orders by total.
-- First extract order information as a TEMPORARY TABLE.

CREATE TEMPORARY TABLE order_information
SELECT
	o.order_id AS orderid,
    o.product_id AS product,
    o.quantity AS qty,
    ch.price_aud AS price
FROM  orders o
    LEFT JOIN chocolates ch
		ON o.product_id = ch.product_id;

SELECT * FROM order_information;  -- For reference and checking.

-- Then use order_information TEMPORARY TABLE to calculate Top 20 order totals.

SELECT
	orderid,
    SUM(qty * price) AS order_total
FROM order_information
GROUP BY 1
ORDER BY 2
LIMIT 20;

-- EXTRACT ORDER TOTALS
-- (c) SUBQUERY solution by order total formatted with dollar symbol.
-- First extract order information.
    
SELECT
	o.order_id AS orderid,
    o.product_id AS product,
    o.quantity AS qty,
    ch.price_aud AS price
FROM  orders o
    LEFT JOIN chocolates ch
		ON o.product_id = ch.product_id;

-- Then use order information as SUBQUERY with dollar formatting.

SELECT
    orderid,
    CONCAT('$', FORMAT(SUM(qty * price), 2)) AS order_total
FROM (
	SELECT
		o.order_id AS orderid,
		o.product_id AS product,
		o.quantity AS qty,
		ch.price_aud AS price
	FROM  orders o
		LEFT JOIN chocolates ch
			ON o.product_id = ch.product_id
	) AS order_info
GROUP BY 1
ORDER BY 2 DESC;

-- SHOW REVENUE BY YEAR BY STATE.

SELECT
	YR,
    SUM(CASE WHEN state = 'VIC' THEN revenue END) AS vic_revenue,
	SUM(CASE WHEN state = 'NSW' THEN revenue END) AS nsw_reveue,
	SUM(CASE WHEN state = 'QLD' THEN revenue END) AS qld_revenue
FROM(
	SELECT
		YEAR(o.order_date) AS YR,
		o.order_id AS order_id,
		c.state AS state,
		o.quantity AS qty,
		ch.price_aud AS price,
		SUM(o.quantity * ch.price_aud) AS revenue
	FROM orders o
		JOIN chocolates ch
			ON o.product_id = ch.product_id
		JOIN customers c
			ON o.customer_id = c.customer_id
	GROUP BY 1, 2, 3, 4, 5
	ORDER BY 1
	) AS state_order_revenue
GROUP BY 1
ORDER BY 1;

-- CREATE VIEW OF REVENUE BY MONTH (asked for often by management)

CREATE VIEW order_revenue_by_month AS
SELECT
	YEAR(order_date) AS 'Year',
    MONTH(order_date) AS 'Month_#',
    MONTHNAME(order_date) AS 'Month',
    COUNT(order_id) AS orders,
    SUM(o.quantity * ch.price_aud) AS revenue
FROM orders o
	JOIN chocolates ch
		ON o.product_id = ch.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2;

-- CHECK VIEW VALUES ARE CORRECT FOR INTERNAL CONSISTENCY.

SELECT * FROM order_revenue_by_month;

SELECT
    YEAR(order_date) AS 'Year',
    MONTHNAME(order_date) AS 'Month',
    o.order_id AS orders,
    o.product_id AS product,
    o.quantity AS quantity,
    ch.price_aud AS price,
    SUM(o.quantity * ch.price_aud) AS revenue
FROM orders o
	JOIN chocolates ch
		ON o.product_id = ch.product_id
WHERE YEAR(o.order_date) = 2022 AND MONTHNAME(o.order_date) = 'January'
GROUP BY 1, 2, 3, 4, 5, 6
ORDER BY 3;

-- JANUARY 2022 REVENUE = $208.40 FOR BOTH QUERIES.
-- CHANGED WHERE CLAUSE ABOVE TO JUNE & DECEMBER. 
-- REVENUE AMOUNTS MATCH.

-- WHOLESALE SUPPLIERS ARE CONSATNTLY CHANGING UNIT PRICES PER PRODUCT AFFECTING COST OF GOODS (COG) AND THEREFORE PROFITS.
-- CREATED A STORED PROCEDURE AS A QUERY TO BE RUN OFTEN TO CHECK PROFIT MARGINS.
-- THIS HELPS MANAGEMENT MAKE DECISIONS ON POSSIBLE PRICE INCREASES / DECREASES.

DELIMITER //
CREATE PROCEDURE profit_per_product(IN id INT)
BEGIN
	SELECT
		product_id,
		product_name,
		CONCAT('$', price_aud) as price,
		CONCAT('$', cog_aud) AS cog,
		CONCAT('$', SUM(price_aud - cog_aud)) as profit
	FROM chocolates
    WHERE product_id = id
	GROUP BY 1, 2, 3, 4;
END //
DELIMITER ;

CALL profit_per_product(3);

-- STORED PROCEDURE SUCCESSFULLY CREATED.

-- MANAGEMENT ARE THINKING OF INTRODUCING A CUSTOMER LOYALTY PROGRAM TO OFFER CUSTOMERS DISCOUNTS.
-- SHOW CUSTOMER SPEND RANKS BY CITY AND STATE.
-- FIRST CREATE QUERY TO CALCULATE CUSTOMER SPENDS.

SELECT
	c.customer_id AS customer_id,
    CONCAT(c.last_name,', ',c.first_name) AS customer,
    c.city AS city,
    c.state AS state,
    SUM(o.quantity * ch.price_aud) AS customer_spend
FROM orders o
	JOIN customers c ON o.customer_id = c.customer_id
		JOIN chocolates ch ON o.product_id = ch.product_id
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;

-- CHECK ALL CUSTOMER ORDERS TO ENSURE CUSTOMER SPEND CORRECT.

SELECT
	c.customer_id,
    c.first_name,
    c.last_name,
    o.order_id,
	o.product_id,
    o.quantity,
    ch.price_aud,
    SUM(o.quantity * ch.price_aud) AS customer_spend
 FROM orders o
	JOIN customers c ON o.customer_id = c.customer_id
		JOIN chocolates ch ON o.product_id = ch.product_id
WHERE c.customer_id = 8
GROUP BY 1, 2, 3, 4, 5, 6, 7;

-- CHECKED NUMEROUS CUSTOMERS SPEND BY CHANGING 'WHERE' CLAUSE ABOVE.
-- CUSTOMER SPENDS CALCULATING CORRECTLY.

-- SHOW OVERALL SPEND RANKINGS AND BY STATE AVERAGE USING QUERY ABOVE AS SUBQUERY.

SELECT
	customer_id,
    customer,
    city,
    state,
    ROUND(AVG(customer_spend) OVER(), 2) AS overall_spend_avg,
    customer_spend,
    ROUND(AVG(customer_spend) OVER(PARTITION BY state), 2) AS state_spend_avg,
    DENSE_RANK() OVER(PARTITION BY state ORDER BY customer_spend DESC) AS state_spend_rank
FROM(
	SELECT
		c.customer_id AS customer_id,
		CONCAT(c.last_name,', ',c.first_name) AS customer,
		c.city AS city,
		c.state AS state,
		SUM(o.quantity * ch.price_aud) AS customer_spend
	FROM orders o
		JOIN customers c ON o.customer_id = c.customer_id
			JOIN chocolates ch ON o.product_id = ch.product_id
	GROUP BY 1, 2, 3, 4
    ) AS total_customer_spend
ORDER BY 4, 8, 2;

-- QUERY ALLOWS MANAGEMENT TO MAKE DECICIONS RE CUSTOMER LOYALTY CUT OFFS FOR POTENTIAL LOYALTY PROGRAMS.