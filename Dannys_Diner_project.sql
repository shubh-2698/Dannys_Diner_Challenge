-- In this Project, I'm going to answer the questions specified by Danny to analyze the restaurant business
-- Firstly created the database, tables and use the command to use it by default

CREATE SCHEMA dannys_diner;
use dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
);

INSERT INTO sales
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
 
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INT
);

INSERT INTO menu
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- Question 1: What is the total amount each customer spent at the restaurant?
-- Answer : 
		A	76
		B	74
		C	36

-- Query 1: 
		with cte as (
		select s.customer_id, s.product_id,count(s.product_id)*m.price as Amount
		from sales s
		join menu m on s.product_id = m.product_id
		group by 1,2)

		select customer_id, sum(amount)
		from cte
		group by 1;



-- Question 2: How many days has each customer visited the restaurant?
-- Answer :
		A	4
		B	6
		C	2

-- Query 2: Since there are same entries for a date for a customer, I'm choosing to find unique days on which customer visited.
		select customer_id, count(distinct order_date) as No_of_days
		from sales
		group by 1;

-- Question 3: What was the first item from the menu purchased by each customer?
-- Answer : 
		A	sushi
		B	curry
		C	ramen

-- Query 3: Since the question is only to fetch first item, I choose to assign numbers to the items orderered in menu by customer and fetch the first one from list.
		with cte as (select *, row_number() over ( partition by customer_id) rn 
		from sales)
		select cte.customer_id, m.product_name 
		from cte 
		join menu m on m.product_id = cte.product_id
		where rn =1;

-- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?
-- Answer: 
		ramen	8

-- Query 4: 
		with cte as (select customer_id, product_id, row_number() over (partition by product_id) rn
		from sales
		order by product_id)
		select m.product_name as Item_name, cte.rn as Times_purchased
		from cte
		join menu m on cte.product_id = m.product_id
		where rn = (select max(rn) from cte);

-- Another approach is to simply join the tables , ordering by count in descending order and fetching 1st item with max count
		select m.product_name, count(s.product_id) as Count
		from sales s
		join menu m on m.product_id = s.product_id
		group by 1 
		order by count desc
		limit 1;

-- Question 5: Which item was the most popular for each customer?
-- Answer: 
		A	ramen
		B	sushi
		B	curry
		B	ramen
		C	ramen

-- QUery 5: Firstly fetching the count of items ordered by customer and then assigning rank to them in descending order then fetching the item ranking as 1
		with cte as (select customer_id, product_id,  count(*) as count_items, dense_rank() over (partition by customer_id
		order by count(product_id) desc ) rn  
		from sales
		group by 1,2
		order by customer_id)
		select cte.customer_id, m.product_name
		from cte
		join menu m
		on cte.product_id = m.product_id
		where rn = 1
		order by 1;

-- Question 6: Which item was purchased first by the customer after they became a member?
-- Answer: 
		A	curry
		B	sushi

-- Query 6: 
		with cte as (
		select c.customer_id, c.join_date,
		s.order_date, s.product_id, row_number() over ( partition by c.customer_id) rn
		from members c
		join sales s on c.customer_id = s.customer_id
		where s.order_date >= c.join_date) 
		select cte.customer_id, m.product_name
		from cte 
		join menu m on cte.product_id = m.product_id
		where rn = 1
		order by 1;

-- Question 7: Which item was purchased just before the customer became a member?
-- Answer: 
		A	sushi
		A	curry
		B	sushi

-- Query 7: I accomplished this using CTE and assigning dense_rank to the item ordered in descending order of order date which helped 
	--  me to fetch the latest date before becoming member.
		with cte as (select c.customer_id, c.join_date,
		s.order_date, s.product_id, dense_rank() over ( partition by c.customer_id order by s.order_date desc) rn
		from members c
		join sales s on c.customer_id = s.customer_id
		where s.order_date < c.join_date)
		select cte.customer_id, m.product_name
		from cte 
		join menu m on cte.product_id = m.product_id
		where rn = 1
		order by 1;

-- Question 8: What is the total items and amount spent for each member before they became a member?
-- Answer: 
		A	2	25
		B	3	40

-- Query 8 : 
		select c.customer_id, count(s.product_id) as Total_Items , sum(m.price) as Total_Amount
		from members c
		join sales s on c.customer_id = s.customer_id
		join menu m on m.product_id = s.product_id
		where s.order_date < c.join_date 
		group by 1
		order by 1;

-- Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- Answer: 
		A	860
		B	940
		C	360

-- Query 9: In this I summed up the points based on item name and grouped using customer id to fetch results
		select s.customer_id, sum( case when m.product_name = 'sushi' then price*20	else price*10 end ) points
		from sales s
		join menu m on m.product_id = s.product_id
		group by 1;

-- Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
	    --  not just sushi - how many points do customer A and B have at the end of January?
Answer: 
		A	1370
		B	1060

-- Query 10: In this firstly, I found the the first week end date for both users after they become member and then put the condition of 
	  -- joindate + 7 days to find and compute the results based on that. 

		select a.customer_id, b.join_date, a.order_date from sales a
		join members b on a.customer_id = b.customer_id
		where a.order_date between b.join_date and b.join_date + 7;

		select s.customer_id, sum(case when s.order_date between c.join_date and c.join_date + 7 then m.price*20 
									   when m.product_name = 'sushi' then price*20
					       else price*10 end ) points
			from sales s
			join menu m on m.product_id = s.product_id
			join members c on s.customer_id = c.customer_id
			group by 1
			order by 1;

-- Bonus question: To recreate a new table using combination of all tables specifying their member status before and after join  date
-- Answer: 
		A	2021-01-01	sushi	10	N
		A	2021-01-01	curry	15	N
		A	2021-01-07	curry	15	Y
		A	2021-01-10	ramen	12	Y
		A	2021-01-11	ramen	12	Y
		A	2021-01-11	ramen	12	Y
		B	2021-01-01	curry	15	N
		B	2021-01-02	curry	15	N
		B	2021-01-04	sushi	10	N
		B	2021-01-11	sushi	10	Y
		B	2021-01-16	ramen	12	Y
		B	2021-02-01	ramen	12	Y
		C	2021-01-01	ramen	12	N
		C	2021-01-01	ramen	12	N
		C	2021-01-07	ramen	12	N

-- Query Bonus Question 1: 
		select s.customer_id, s.order_date, m.product_name, m.price, 
		(case when s.customer_id = c.customer_id and s.order_date >= c.join_date then 'Y' 
			  else 'N' end) Member_Status
		from sales s
		join menu m on m.product_id = s.product_id
		left join members c on c.customer_id = s.customer_id; 

-- 2nd Bonus question: To rank the customer purchases for members only and show rank as Null for non_members
-- Answer: 
	A	2021-01-01	sushi	10	N	Null
	A	2021-01-01	curry	15	N	Null
	A	2021-01-07	curry	15	Y	1
	A	2021-01-10	ramen	12	Y	2
	A	2021-01-11	ramen	12	Y	3
	A	2021-01-11	ramen	12	Y	3
	B	2021-01-01	curry	15	N	Null
	B	2021-01-02	curry	15	N	Null
	B	2021-01-04	sushi	10	N	Null
	B	2021-01-11	sushi	10	Y	1
	B	2021-01-16	ramen	12	Y	2
	B	2021-02-01	ramen	12	Y	3
	C	2021-01-01	ramen	12	N	Null
	C	2021-01-01	ramen	12	N	Null
	C	2021-01-07	ramen	12	N	Null

-- Query 2nd Bonus Question: 
	with cte as (select s.customer_id, s.order_date, m.product_name, m.price, 
	(case when s.customer_id = c.customer_id and s.order_date >= c.join_date then 'Y' 
		  else 'N' end) Member_Status
	from sales s
	join menu m on m.product_id = s.product_id
	left join members c on c.customer_id = s.customer_id)

	select customer_id, order_date, product_name, price, member_status,
	(case when member_status = 'Y' then dense_rank() over (partition by customer_id, member_status order by order_date)
		 else 'Null' end) Ranking
	from cte; 
