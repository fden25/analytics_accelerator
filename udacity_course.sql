-- 5.3 Quiz


-- Use the test environment below to find the number of events that occur for each day for each channel.
SELECT DATE_TRUNC('day',occurred_at) AS day,
       channel, COUNT(*) as events
FROM web_events
GROUP BY 1,2
ORDER BY 3 DESC;

-- Now create a subquery that simply provides all of the data from your first query.
SELECT *
FROM (SELECT DATE_TRUNC('day',occurred_at) AS day,
                channel, COUNT(*) as events
          FROM web_events 
          GROUP BY 1,2
          ORDER BY 3 DESC) sub;

-- Now find the average number of events for each channel.
-- Since it was broken out by day earlier, this gives an average per day.
SELECT channel, AVG(events) AS average_events
FROM (SELECT DATE_TRUNC('day',occurred_at) AS day,
                channel, COUNT(*) as events
         FROM web_events 
         GROUP BY 1,2) sub
GROUP BY channel
ORDER BY 2 DESC;



-- 5.9 Quiz


-- 1. Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.

-- Find the total_amt_usd totals associated with each sales rep, and the region in which they were located.
SELECT s.name AS rep, r.name AS region, SUM(o.total_amt_usd) AS total_sales
FROM sales_reps s
JOIN region r
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
GROUP BY 1, 2
ORDER BY 3 DESC;

--Next, pull the max for each region.
SELECT region, MAX(total_sales) total_sales
FROM(
  SELECT s.name AS rep, r.name AS region, SUM(o.total_amt_usd) AS total_sales
  FROM sales_reps s
  JOIN region r
  ON s.region_id = r.id
  JOIN accounts a
  ON a.sales_rep_id = s.id
  JOIN orders o
  ON o.account_id = a.id
  GROUP BY 1, 2
) AS t1
GROUP BY 1;

-- Essentially, this is a JOIN of these two tables, where the region and amount match.
SELECT t3.rep, t3.region, t3.total_sales
FROM(
  SELECT region, MAX(total_sales) total_sales
  FROM(
  SELECT s.name AS rep, r.name AS region, SUM(o.total_amt_usd) AS total_sales
    FROM sales_reps s
    JOIN region r
    ON s.region_id = r.id
    JOIN accounts a
    ON a.sales_rep_id = s.id
    JOIN orders o
    ON o.account_id = a.id
    GROUP BY 1, 2
    ) AS t1
  GROUP BY 1) AS t2
JOIN (SELECT s.name AS rep, r.name AS region, SUM(o.total_amt_usd) AS total_sales
    FROM sales_reps s
    JOIN region r
    ON s.region_id = r.id
    JOIN accounts a
    ON a.sales_rep_id = s.id
    JOIN orders o
    ON o.account_id = a.id
    GROUP BY 1, 2
  ORDER BY 3 DESC) AS t3
ON t3.region = t2.region AND t3.total_sales = t2.total_sales;


-- 2. For the region with the largest (sum) of sales total_amt_usd, how many total (count) orders were placed?

-- The first query pulls the total_amt_usd for each region.
SELECT r.name AS region, SUM(o.total_amt_usd) AS total_sales
FROM sales_reps s
JOIN region r
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
GROUP BY r.name;

-- Then we just want the region with the max amount from this table. 
-- Two ways to get this amount are: 1. Pull the max using a subquery, 2. Order descending and pull the top value.
SELECT MAX(total_sales)
FROM(
  SELECT r.name AS region, SUM(o.total_amt_usd) AS total_sales
  FROM sales_reps s
  JOIN region r
  ON s.region_id = r.id
  JOIN accounts a
  ON a.sales_rep_id = s.id
  JOIN orders o
  ON o.account_id = a.id
  GROUP BY r.name
  ) AS sub;

-- Finally, we want to pull the total orders for the region with this amount.
SELECT r.name, COUNT(o.total) AS total_orders
FROM sales_reps s
JOIN region r
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
	SELECT MAX(total_sales)
  FROM(
    SELECT r.name AS region, SUM(o.total_amt_usd) AS total_sales
    FROM sales_reps s
    JOIN region r
    ON s.region_id = r.id
    JOIN accounts a
    ON a.sales_rep_id = s.id
    JOIN orders o
    ON o.account_id = a.id
    GROUP BY r.name
    ) AS sub);


-- 3. How many accounts had more total purchases than the account name which has bought the most 
-- standard_qty paper throughout their lifetime as a customer?

-- First, find the account that had the most standard_qty paper. 
--The query here pulls that account, as well as the total amount:
SELECT a.name, SUM(o.standard_qty) AS total_std, SUM(o.total) AS total
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Use this to pull all the accounts with more total sales:
SELECT a.name
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY 1
HAVING SUM(o.total) > (SELECT total
	FROM (SELECT a.name, SUM(o.standard_qty) AS total_std, SUM(o.total) AS total
    FROM accounts a
    JOIN orders o
    ON a.id = o.account_id
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1) 
  AS sub);

-- This is now a list of all the accounts with more total orders. 
-- We can get the count with just another simple subquery.
SELECT COUNT(*)
FROM (
  SELECT a.name
  FROM accounts a
  JOIN orders o
  ON a.id = o.account_id
  GROUP BY 1
  HAVING SUM(o.total) > (SELECT total
  	FROM (SELECT a.name, SUM(o.standard_qty) AS total_std, SUM(o.total) AS total
      FROM accounts a
      JOIN orders o
      ON a.id = o.account_id
      GROUP BY 1
      ORDER BY 2 DESC
      LIMIT 1) 
    AS sub)
) AS final_count;


-- 4. For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, 
-- how many web_events did they have for each channel?

-- First pull the customer with the most spent in lifetime value.
SELECT a. id, a.name, SUM(o.total_amt_usd) AS total_spent
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY a.id, a.name
ORDER BY 3 DESC
LIMIT 1;

-- Now, we want to look at the number of events on each channel this company had, which we can match with just the id.
SELECT a.name, w.channel, COUNT(*)
FROM accounts a
JOIN web_events  w
ON a.id = w.account_id AND a.id = (SELECT id
	FROM (
		SELECT a. id, a.name, SUM(o.total_amt_usd) AS total_spent
    FROM accounts a
    JOIN orders o
    ON a.id = o.account_id
    GROUP BY a.id, a.name
    ORDER BY 3 DESC
    LIMIT 1) AS sub)
GROUP BY 1, 2
ORDER BY 3 DESC;


-- 5. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?

-- First, we just want to find the top 10 accounts in terms of highest total_amt_usd.SELECT a.id, a.name, 
-- SUM(o.total_amt_usd) AS total_spent
FROM accounts a
JOIN orders o
ON a.id = o.account_id
GROUP BY a.id, a.name
ORDER BY 3 DESC
LIMIT 10;

-- Take the average of these 10 amounts.
SELECT AVG(total_spent)
FROM (
	SELECT a.id, a.name, SUM(o.total_amt_usd) AS total_spent
  FROM accounts a
  JOIN orders o
  ON a.id = o.account_id
  GROUP BY a.id, a.name
  ORDER BY 3 DESC
  LIMIT 10
  ) AS sub;


-- 6. What is the lifetime average amount spent in terms of **total_amt_usd**, including only the companies 
-- that spent more per order, on average, than the average of all orders.

-- First, pull the average of all accounts in terms of **total_amt_usd**: 
SELECT AVG(total_amt_usd) AS liftetime_avg
FROM orders;

-- Then, pull only the accounts with more than this average amount.
SELECT account_id, AVG(total_amt_usd) AS account_avg
FROM orders
GROUP BY 1
HAVING AVG(total_amt_usd) >  
	(SELECT AVG(total_amt_usd) AS liftetime_avg
  FROM orders);

-- Finally, we just want the average of these values.
SELECT AVG(account_avg)
  FROM (
  SELECT account_id, AVG(total_amt_usd) AS account_avg
  FROM orders
  GROUP BY 1
  HAVING AVG(total_amt_usd) >  
  	(SELECT AVG(total_amt_usd) AS liftetime_avg
    FROM orders)) 
  AS sub;



-- 5.13 Quiz: WITH


-- 1. Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.

WITH t1 AS (
  SELECT s.name AS rep, r.name AS region, SUM(o.total_amt_usd) AS total_sales
  FROM sales_reps s
  JOIN region r
  ON s.region_id = r.id
  JOIN accounts a
  ON a.sales_rep_id = s.id
  JOIN orders o
  ON o.account_id = a.id
  GROUP BY 1, 2
  ORDER BY 3 DESC),
t2 AS (
  SELECT region, MAX(total_sales) total_sales
  FROM t1
  GROUP BY 1)
SELECT t1.rep, t1.region, t1.total_sales
FROM t1
JOIN t2
ON t1.region = t2.region AND t1.total_sales = t2.total_sales;


-- 2. For the region with the largest sales total_amt_usd, how many total orders were placed?

WITH t1 AS (
  SELECT r.name AS region, SUM(o.total_amt_usd) AS total_sales
  FROM sales_reps s
  JOIN region r
  ON s.region_id = r.id
  JOIN accounts a
  ON a.sales_rep_id = s.id
  JOIN orders o
  ON o.account_id = a.id
  GROUP BY r.name),
t2 AS (
  SELECT MAX(total_sales)
	FROM t1)
SELECT r.name, COUNT(o.total) AS total_orders
FROM sales_reps s
JOIN region r
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
  SELECT *
  FROM t2);


-- 3. For the account that purchased the most (in total over their lifetime as a customer) standard_qty paper, 
-- how many accounts still had more in total purchases?

WITH t1 AS (
  SELECT a.name, SUM(o.standard_qty) AS total_std, SUM(o.total) AS total
    FROM accounts a
    JOIN orders o
    ON a.id = o.account_id
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1),
t2 AS (
  SELECT a.name
  FROM accounts a
  JOIN orders o
  ON a.id = o.account_id
  GROUP BY 1
  HAVING SUM(o.total) > (SELECT total FROM t1))
SELECT COUNT(*)
FROM t2;


-- 4. For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, 
--how many web_events did they have for each channel?

WITH t1 AS (
  SELECT a. id, a.name, SUM(o.total_amt_usd) AS total_spent
  FROM accounts a
  JOIN orders o
  ON a.id = o.account_id
  GROUP BY a.id, a.name
  ORDER BY 3 DESC
  LIMIT 1)
SELECT a.name, w.channel, COUNT(*)
FROM accounts a
JOIN web_events  w
ON a.id = w.account_id AND a.id = (SELECT id FROM t1)
GROUP BY 1, 2
ORDER BY 3 DESC;


-- 5. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?

WITH t1 AS (
  SELECT a.id, a.name, SUM(o.total_amt_usd) AS total_spent
  FROM accounts a
  JOIN orders o
  ON a.id = o.account_id
  GROUP BY a.id, a.name
  ORDER BY 3 DESC
  LIMIT 10)
SELECT AVG(total_spent)
FROM t1;


-- 6. What is the lifetime average amount spent in terms of **total_amt_usd**, including only the companies 
-- that spent more per order, on average, than the average of all orders.

WITH t1 AS (
  SELECT account_id, AVG(total_amt_usd) AS account_avg
  FROM orders
  GROUP BY 1
  HAVING AVG(total_amt_usd) >  
  	(SELECT AVG(total_amt_usd) AS liftetime_avg
  FROM orders))
SELECT AVG(account_avg)
FROM t1;
