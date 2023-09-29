-- create a new database
CREATE DATABASE EightWeeksSqlChallenge;

--specify database of us
USE EightWeeksSqlChallenge;
 


 ----create a schema dataset to analyse-------------
CREATE SCHEMA dannys_diner;


CREATE TABLE dannys_diner.sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO dannys_diner.sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE dannys_diner.menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO dannys_diner.menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE dannys_diner.members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO dannys_diner.members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



  ----------join the 3 tables
SELECT *
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
ON sales.customer_id = members.customer_id
INNER JOIN dannys_diner.menu
ON sales.product_id = menu.product_id



-----------We can now start the case study
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?



-- 1. What is the total amount each customer spent at the restaurant?

SELECT a.customer_id, SUM(b.price) AS Total_amonut_spent
FROM dannys_diner.sales AS a
JOIN dannys_diner.menu AS b ON a.product_id = b.product_id
GROUP BY a.customer_id


-- 2. How many days has each customer visited the restaurant?

SELECT a.customer_id, COUNT(DISTINCT a.order_date) AS visit_count
FROM dannys_diner.sales AS a

GROUP BY a.customer_id


-- 3. What was the first item from the menu purchased by each customer?
---using a CTE
WITH purchases AS (
  SELECT a.customer_id, b.product_name,
  ROW_NUMBER () OVER (PARTITION BY customer_id ORDER BY order_date) row_a
FROM dannys_diner.sales AS a
JOIN dannys_diner.menu AS b ON a.product_id = b.product_id

)

SELECT *
FROM purchases
WHERE row_a = 1;


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(product_name) AS No_of_time_purchased
FROM dannys_diner.menu AS a
LEFT JOIN dannys_diner.sales AS b ON a.product_id = b.product_id
GROUP BY product_name
ORDER BY No_of_time_purchased DESC



--- 5. Which item was the most popular for each customer? 

--We will check for things based on the no of purchases the customers made for each item

SELECT customer_id, product_name, COUNT(product_name) AS No_of_time_purchased
FROM dannys_diner.sales AS a
INNER JOIN dannys_diner.menu AS b ON a.product_id = b.product_id
GROUP BY customer_id, product_name
HAVING COUNT (product_name) = (
	SELECT MAX(No_of_time_purchased)
	FROM(
		SELECT customer_id, COUNT(product_name) AS No_of_time_purchased
		FROM dannys_diner.sales AS a
		INNER JOIN dannys_diner.menu AS b ON a.product_id = b.product_id
		GROUP BY customer_id, product_name
) AS most_pop

WHERE most_pop.customer_id = a.customer_id
)
ORDER BY customer_id



--- 6. Which item was purchased first by the customer after they became a member?
--using CTE
WITH First_purchase AS (
	SELECT *, ROW_NUMBER () OVER (PARTITION BY customer_id ORDER BY order_date) AS firstpurchase
	FROM dannys_diner.sales
)
SELECT customer_id, product_name
FROM First_purchase
LEFT JOIN dannys_diner.menu AS a ON First_purchase.product_id = a.product_id
WHERE firstpurchase = 1



-- 8. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
    customer_id,
    SUM(CASE
        WHEN product_name = 'sushi'  THEN price * 20 -- sushi gets 2x points
        ELSE price * 10 -- $1 spent equates to 10 points
    END) AS total_points
FROM dannys_diner.menu AS a
LEFT JOIN dannys_diner.sales AS b ON a.product_id = b.product_id
GROUP BY customer_id




--- 9. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- using CTE
WITH sales_point AS (
SELECT customer_id, product_id, price, order_date, 
	CASE
		WHEN order_date <= DATEADD(week, 1, join_date) THEN price * 20--2x point for 1st week
		ELSE price * 10-- per $1 equals 10points
	END AS points
FROM dannys_diner.menu AS a
LEFT JOIN dannys_diner.sales AS b ON a.product_id = b.product_id
INNER JOIN dannys_diner.members AS c ON b.customer_id = c.customer_id
WHERE MONTH(order_date) = 1 --for January
)

SELECT customer_id, SUM(points) AS total_points

FROM Sales_point
GROUP BY customer_id
