--Monday Coffee Data

select * from city;
select * from products;
select * from customers;
select * from sales;

--Data Analysis
--Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?


select city_name,round((population *0.25)/1000000,2) As coffee_consumers_millions,city_rank
from city
order by 2 desc;


--Total Revenue from Coffee Sales
--What is the total revenue generated from coffee sales across all cities in the last quarter of 2024?


select ci.city_name,
     sum(s.total) as Revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where  Extract(year from s.sale_date)= 2024 and 
       Extract(quarter from s.sale_date) = 4
group by 1
order by 2 desc; 


--Sales Count for Each Product
--How many units of each coffee product have been sold?


select p.product_name,
      count(s.sale_id) as total_orders
from products as p
left join sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc;


--Average Sales Amount per City
--What is the average sales amount per customer in each city?


SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;


--City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers
--The query calculates estimated coffee consumers per city and counts unique customers from sales data using CTEs. It then joins both CTEs on city_name to compare coffee consumers with unique customers in each city.

 WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table as
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name


--Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?


select *
from
(
  select 
      ci.city_name,
	  p.product_name,
	  count(s.sale_id) as total_orders,
	  dense_rank() over(partition by ci.city_name order by count(s.sale_id)DESC) as Rank
from sales as s
join products as p
on s.product_id = p.product_id
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1,2
--order by 1,3
)as t1
where rank <=3;


--Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

select
      ci.city_name,
	  count(DISTINCT c.customer_id) as unique_cx  
from city as ci
left join customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
Group by 1;


--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer


WITH city_table as
(
    SELECT 
	ci.city_name,
	sum(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
), 
city_rent as
  (
  select 
        city_name, 
		estimated_rent
  from city
  )

select 
      cr.city_name,
	  cr.estimated_rent,
	  ct.total_cx,
	  ct.avg_sale_pr_cx,
	  Round(cr.estimated_rent::numeric/ct.total_cx::numeric,2) as avg_rent_per_cx
from city_table as ct
join city_rent as cr
on cr.city_name = ct.city_name
order by 4 desc;


 --Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city.


with monthly_sales as
(
  select 
        ci.city_name,
		Extract(Month from sale_date) as Month,
		Extract(Year from sale_date) as Year,
		sum(s.total) as total_sale
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
Group by 1,2,3
order by 1,2,3
),
growth_ratio 
as
(select 
      city_name,
	  Month,
	  Year,
	  total_sale as cr_month_sale,
	  LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
from monthly_sales
)
SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	

-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table as
(
    SELECT 
	ci.city_name,
	sum(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC
), 
city_rent as
  (
  select 
        city_name, 
		Round((population * 0.25)/1000000,3) as estimated_coffee_consumer_in_millions,
		estimated_rent
  from city
  )

SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC