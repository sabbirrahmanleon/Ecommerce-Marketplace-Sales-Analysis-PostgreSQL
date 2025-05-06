-- Number of products
select
	count(productid)
from
	sales;

-- Total unique products
select
	count(distinct productname)
from
	sales;

-- Top 10 most expensive products 
select
	productname,
	price
from
	sales
order by
	price desc
limit 10;

-- Number of product categories
select
	count(distinct category)
from
	sales;

-- List of product categories
select
	distinct category
from
	sales;

-- Number of products in every category
select
	category,
	count(distinct productid) as total_product
from
	sales
group by
	1;

-- Average rating and total items sold in every category
select
	category,
	round(avg(rating), 2) as avg_rating,
	sum(sales) as total_sales
from
	sales
group by
	1;

--Top 5 highest rated categories
select
	category,
	round(avg(rating), 2) as avg_rating,
	sum(sales) as total_sales
from
	sales
group by
	1
order by
	avg_rating desc
limit 5;

--Top 5 categories by products sold
select
	category,
	round(avg(rating), 2) as avg_rating,
	sum(sales) as total_sales
from
	sales
group by
	1
order by
	total_sales desc
limit 5;

-- Top product by items sold in each category
with top_product as(
select
category,
	productname,
	sum(sales) as total_sold,
	rank() over (partition by category order by sum(sales) desc) as rank
from sales
group by 1, 2
)
select
	category,
	productname,
	total_sold
from
	top_product
where
	rank = 1
order by
	total_sold desc;

-- Total cities
select
	count(distinct city)
from
	sales;

-- List of cities
select
	distinct city
from
	sales;

-- Average discount in every city
select
	city,
	round(avg(discount), 2) as avg_discount
from
	sales
group by
	1;

-- List of products from newest to oldest
select
	productname,
	dateadded
from
	sales
order by
	dateadded desc;

-- List of products having an above average rating 
select
	category,
	productname,
	rating
from
	sales
where
	rating > (
	select
		avg(rating)
	from
		sales)
order by
	rating desc;

-- Create view: product overview
create view vw_product_overview as
select
	productid,
	productname,
	category,
	price,
	discount,
	price *(1-discount) as discounted_price,
	rating,
	sales,
	case
		when stockquantity > 0 then 'In Stock'
		else 'Out Of Stock'
	end as stock_status,
	dateadded,
	city,
	sales * (price * (1-discount)) as revenue
from
	sales;

select
	*
from
	vw_product_overview;

-- Create a summary table
create table DailyProductSummary(
	SummaryDate date,
	Category text,
	TotalSales int,
	AvgPrice numeric(10, 2),
	AvgRating numeric(10, 2),
	TopProduct text

);
-- Create a procedure to automate the process for creating Daily Product Summary Table.
CREATE OR REPLACE PROCEDURE run_daily_product_summary()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM DailyProductSummary
    WHERE SummaryDate = CURRENT_DATE;
END;
$$;


insert
	into
	DailyProductSummary
select
	current_date as SummaryDate,
	Category,
	sum(sales) as TotalSales,
	avg(price) as AvgPrice,
	avg(rating) as AvgRating,
	(
	select
		productname
	from
		sales p2
	where
		p1.category = p2.category
	order by
		sales desc
	limit 1
	) as TotalProduct
from
	sales p1
group by
	category;
end;

-- call the function
call run_daily_product_summary();

select
	*
from
	DailyProductSummary;
