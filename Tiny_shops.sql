-- Case Study Questions

--1) Which product has the highest price? Only return a single row.

SELECT
	product_name,
	price AS highest_price
FROM
	products
WHERE
	price = (
	SELECT
		MAX(price)
	FROM
		products);

--2) Which customer has made the most orders?
	
WITH total_orders AS (						
SELECT
	c.first_name first_name,				
	c.last_name last_name,
	COUNT(o.order_id) as number_of_orders	
FROM
	customers as c
JOIN orders as o
		USING (customer_id)
GROUP BY
	customer_id
)
SELECT
	first_name,								
	last_name,
	number_of_orders
FROM
	total_orders							
WHERE									
	number_of_orders = (
	SELECT
		MAX(number_of_orders)
	FROM
		total_orders
);


--3) What’s the total revenue per product?

SELECT
	o.product_id,
	p.price,
	p.price * SUM(o.quantity) AS total_revenue	
FROM
	products AS p
JOIN											
	order_items AS o
		USING (product_id)
GROUP BY									   
	o.product_id,
	p.price
ORDER BY
	o.product_id;     

--4) Find the day with the highest revenue.

WITH revenue_by_date AS (							                              
SELECT
	o.order_date order_date,
	p.price * SUM(oi.quantity) AS revenue_per_date
FROM
	order_items AS oi
JOIN
    orders AS o
		USING (order_id)
JOIN
    products AS p
		USING (product_id)
GROUP BY
	o.order_date,
	p.product_id,
	p.price
)
SELECT												
	order_date,
	revenue_per_date
FROM
	revenue_by_date
WHERE
	revenue_per_date = (							
	SELECT
		MAX(revenue_per_date)
	FROM
		revenue_by_date
);

--5) Find the first order (by date) for each customer.

SELECT
	o.customer_id,
	CONCAT(c.first_name || ' ' || c.last_name) full_name,
	MIN(o.order_date) first_order
FROM
	orders AS o
JOIN
    customers AS c
		USING (customer_id)
GROUP BY
	o.customer_id,
	c.first_name,
	c.last_name
ORDER BY
	o.customer_id;

--6) Find the top 3 customers who have ordered the most distinct products

WITH producttypecount AS (
  SELECT p.product_name AS Product, CONCAT(c.first_name || ' ' || c.last_name) AS fullname
  FROM customers AS c
  JOIN orders AS o
    USING (customer_id)
  JOIN order_items AS oi
    USING (order_id)
  JOIN products AS p
    USING (product_id)
  GROUP BY p.product_name, fullname
  ORDER BY fullname
)
SELECT DISTINCT fullname, COUNT(Product) OVER (PARTITION BY fullname) AS total_cnt_producttype
FROM producttypecount
ORDER BY total_cnt_producttype DESC
LIMIT 3;

--7) Which product has been bought the least in terms of quantity?

WITH total_quantity AS (
  SELECT product_name, product_id, SUM(quantity) AS tot_quantity
  FROM order_items
  JOIN products
      USING (product_id)
  GROUP BY product_id, product_name
  ORDER BY tot_quantity
  )
SELECT product_name, product_id, tot_quantity
FROM total_quantity
WHERE tot_quantity = (SELECT MIN(tot_quantity) FROM total_quantity);

--8) What is the median order total?

WITH total_quantity AS (
  SELECT product_name, product_id, SUM(product_id * quantity) AS tot_quantity
  FROM order_items
  JOIN products
      USING (product_id)
  GROUP BY product_id, product_name
  ORDER BY tot_quantity
  )
SELECT PERCENTILE_CONT(.5 ) 
		WITHIN GROUP(ORDER BY tot_quantity ) AS median_order_total
FROM total_quantity;

--9) For each order, determine if it was ‘Expensive’ (total over 300), ‘Affordable’ (total over 100), or ‘Cheap’.
 
 SELECT order_id, SUM(price * quantity) AS total_price_per_order,
 		CASE
        	WHEN SUM(price * quantity) > 300 THEN 'Expensive'
            WHEN SUM(price * quantity) > 100 THEN 'Affordable'
            ELSE 'Cheap'
        END AS price_category
 FROM products
 JOIN order_items
 	USING(product_id)
 GROUP BY order_id
 ORDER BY total_price_per_order


--10) Find customers who have ordered the product with the highest price.
 
 WITH max_price AS (
SELECT
	product_id,
	MAX(price) AS mx_price
FROM
	products
GROUP BY
	product_id
ORDER BY
	MAX(price) DESC
)
SELECT
	c.customer_id,
	c.first_name,
	c.last_name,
    mx_price AS highest price
FROM
	max_price
JOIN products as p
		USING (product_id)
JOIN order_items as oi
		USING (product_id)
JOIN orders as o
		USING (order_id)
JOIN customers AS c
		USING (customer_id)
WHERE
	p.price = (
	SELECT
		MAX(price)
	FROM
		products);


--11) Additional: Find customers who have the order with the highest price.

WITH price_order AS (
   	SELECT order_id, SUM(price * quantity) AS total_price_per_order
     FROM products
     JOIN order_items
        USING(product_id)
     GROUP BY order_id
     ORDER BY total_price_per_order
  )
SELECT order_id, CONCAT(c.first_name || ' ' || c.last_name) AS fullname, total_price_per_order
FROM price_order
JOIN orders
	USING (order_id)
JOIN customers AS c
	USING (customer_id)
WHERE total_price_per_order = (
    SELECT MAX(total_price_per_order)
    FROM price_order
  	);
