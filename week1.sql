--1.What is the total amount each customer spent at the restaurant?
SELECT
  s.customer_id
  --aggregate at customer level
  ,SUM(m.price) AS total_spent
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  --group at customer level
  GROUP BY 1
  ORDER BY 1;

--2.How many days has each customer visited the restaurant?
SELECT
  customer_id
  ,COUNT(DISTINCT order_date) AS num_days
  FROM sales
  GROUP BY 1;

--3.What was the first item from the menu purchased by each customer?
SELECT
  b.customer_id
  ,b.product_name
  ,b.order_date
  FROM
    (SELECT
	     a.*
       --Split the dataset by customer, order by order date and assign rownum
       ,ROW_NUMBER() OVER(PARTITION BY a.customer_id ORDER BY a.order_date) AS orderseq
       FROM
       (SELECT
	        s.customer_id
          ,s.product_id
          ,s.order_date
          ,m.product_name
          FROM sales s
          JOIN menu m
          ON s.product_id=m.product_id
        )a
    )b
  --output only the first item
  WHERE b.orderseq=1;

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
  b.product_name,
  b.times_purchased
  FROM
    (SELECT
      a.*
      --Sort the item by number of times it was purchased in descending order
	     ,RANK() OVER(ORDER BY a.times_purchased DESC) AS rank_order
       FROM
        (SELECT
	       product_name
         ,COUNT(product_name) AS times_purchased
         FROM menu m
         JOIN sales s
         ON m.product_id = s.product_id
         GROUP BY 1
       )a
    )b
  --output the highest purchased item
  WHERE b.rank_order = 1;

-- 5. Which item was the most popular for each customer?
SELECT
  b.*
  FROM
    (SELECT
	    a.*
      --Split the dataset by customer and sort the resultant dataset by number of times it was purchased in descending order
      ,RANK () OVER(PARTITION BY a.customer_id ORDER BY a.times_purchased DESC) AS rank_order
      FROM
      (SELECT
	       s.customer_id
 	       ,m.product_name
         --Calculate the number of times an item has been purchased
         ,COUNT (s.product_id) AS times_purchased
         FROM sales s
         JOIN menu m
         ON s.product_id=m.product_id
         --Aggregate the joined dataset by customer and each item purchased by the customer
         GROUP BY 1,2
       )a
    )b
WHERE b.rank_order=1
;

-- 6.Which item was purchased first by the customer after they became a member?
SELECT
  b.*
  FROM
    (SELECT
	     a.*
       --Split the dataset by Customer and sort by order date in asc order gives the first order details
       ,RANK() OVER(PARTITION BY a.customer_id ORDER BY a.order_date) AS rank_order
    FROM
      (SELECT
        s.customer_id
        ,s.order_date
        ,m.product_name
        ,me.join_date
        FROM sales s
        JOIN menu m
        ON s.product_id = m.product_id
        JOIN members me
        ON s.customer_id = me.customer_id
        --retains only the orders placed by customers after they became members
        WHERE s.order_date >= me.join_date
      )a
    )b
  WHERE b.rank_order=1
;

-- 7. Which item was purchased just before the customer became a member?
SELECT
  b.*
  FROM
    (SELECT
	     a.*
       --split the dataset by customer and sort by order date in desc order gives the latest order details
       ,RANK() OVER(PARTITION BY a.customer_id ORDER BY a.order_date DESC) AS rank_order
    FROM
      (SELECT
        s.customer_id
        ,s.order_date
        ,m.product_name
        ,me.join_date
        FROM sales s
        JOIN menu m
        ON s.product_id = m.product_id
        JOIN members me
        ON s.customer_id = me.customer_id
        --retains only the orders placed by customers before they became members
        WHERE s.order_date < me.join_date
      )a
    )b
  WHERE b.rank_order=1
;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
  s.customer_id
  ,count(m.product_name) AS total_items
  ,sum(m.price) AS total_spend
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  JOIN members me
  ON s.customer_id = me.customer_id
  --gives orders prior to becoming a member
  WHERE s.order_date < me.join_date
  GROUP BY 1

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
  a.customer_id
  ,SUM(a.points) AS total_points
FROM
  (SELECT
    s.customer_id
    ,CASE
    -- if the items is sushi, points are 2*mulitplied in addition to 10 points awarded for every $1 spent
      WHEN m.product_name='sushi' THEN m.price*10*2
    -- if the items is not sushi, 10 points are awarded for every $1 spent
      ELSE m.price*10
    END AS points
    FROM sales s
    JOIN menu m
    ON s.product_id = m.product_id
  ) a
GROUP BY 1

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
  a.customer_id
  ,SUM(a.points) AS total_points
  FROM
    (SELECT
      s.customer_id
 	    ,me.join_date
 	    ,s.order_date
      ,CASE
      -- if the order date is within a week of becoming a member, the points should be doubled
    	 WHEN s.order_date-me.join_date<=7 THEN m.price*10*2
       ELSE m.price*10
      END AS points
      FROM sales s
      JOIN menu m
      ON s.product_id = m.product_id
      JOIN members me
      ON s.customer_id=me.customer_id
      WHERE s.order_date>=me.join_date
      -- using extract function in postgre sql
      AND EXTRACT (MONTH FROM s.order_date)=1
    ) a
  GROUP BY 1
