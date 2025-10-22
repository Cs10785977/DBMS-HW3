-- Hw3, By Cooper Simon
CREATE DATABASE hw3_db;
USE hw3_db;
/* *********************************************************************************************
   Marketplace Database Model
********************************************************************************************* */




/* ******************************************************************
   Add PRIMARY KEY constraints
****************************************************************** */
-- Assigns Unique keys to each entity
alter table merchants 
    add constraint PK_merchants primary key(mid); 

alter table products 
    add constraint PK_products primary key(pid);

alter table customers 
    add constraint PK_customers primary key(cid);

alter table orders 
    add constraint PK_orders primary key(oid);
-- Composite keys 
alter table sell 
    add constraint PK_sell primary key(mid, pid);

alter table contains 
    add constraint PK_contians primary key(oid, pid);

alter table place 
    add constraint PK_place primary key(cid, oid);



/* ******************************************************************
   Add FOREIGN KEY constraints with CASCADE options
****************************************************************** */

-- Create referential integrity between related tables.
-- CASCADE ensures that when a parent is deleted or updated, 
-- related rows in child tables are automatically updated/deleted.

alter table sell
    add constraint FK_sell_merchants foreign key(mid)
        references merchants(mid) on delete cascade on update cascade,
    add constraint FK_sell_products foreign key(pid)
        references products(pid) on delete cascade on update cascade;

alter table contains
    add constraint FK_contains_orders foreign key(oid)
        references orders(oid) on delete cascade on update cascade,
    add constraint FK_contains_products foreign key(pid)
        references products(pid) on delete cascade on update cascade;

alter table place
    add constraint FK_place_customers foreign key(cid)
        references customers(cid) on delete cascade on update cascade,
    add constraint FK_place_orders foreign key(oid)
        references orders(oid) on delete cascade on update cascade;



/* ******************************************************************
   Add CHECK constraints for validation
****************************************************************** */
-- Restrict product names and categories to known valid options.
alter table products
    add constraint CK_product_name check (name in 
        ('Printer', 'Ethernet Adapter', 'Desktop', 'Hard Drive', 'Laptop',
         'Router', 'Network Card', 'Super Drive', 'Monitor')),
    add constraint CK_product_category check (category in 
        ('Peripheral', 'Networking', 'Computer'));
-- Restrict price range and quality qheck
alter table sell
    add constraint CK_price check (price between 0 and 100000),
    add constraint CK_quantity check (quantity_available between 0 and 1000);
-- Restrict shipping metheod string and the cost 
alter table orders
    add constraint CK_ship_method check (shipping_method in ('UPS', 'FedEx', 'USPS')),
    add constraint CK_ship_cost check (shipping_cost between 0 and 500);
-- When working with restraints no way to set current dates so i made it a date in the future.
alter table place
    add constraint CK_order_date check (order_date between '2000-01-01' and '2099-12-31'); -- Assumption








/* *********************************************************************************************
   QUERY SECTION (Part II)
   *********************************************************************************************
   Each query answers one of the required assignment questions using proper 
   joins, grouping, and aggregate functions, following the structure and 
   documentation style of previous assignments.
********************************************************************************************* */

/* *********************************************************************************************
   QUERY SECTION (Question 1)
   *********************************************************************************************
  List names and sellers of products that are no longer available (quantity=0)
********************************************************************************************* */
-- Products are joined with sell using pid
select products.name as products_name, 
	   merchants.name as merchant_name
from products inner join sell using(pid)
			  inner join merchants using(mid)
where sell.quantity_available = 0; -- checks for quanity avaliable to be 0

/* *********************************************************************************************
   QUERY SECTION (Question 2)
   *********************************************************************************************
  List names and descriptions of products that are not sold.
********************************************************************************************* */
-- Left join between products and sell
select products.name as product_name, 
	   products.description as descriptions
from products left outer join sell 
	 on products.pid = sell.pid
where sell.pid is null; -- Only when product id is not linked to sell

/* *********************************************************************************************
   QUERY SECTION (Question 3)
   *********************************************************************************************
 How many customers bought SATA drives but not any routers?
********************************************************************************************* */
-- Count customers who purchased items with “SATA” in the description
-- but never purchased any product described as “Router”.
select count(*) as total_count
from (
    select distinct cid
    from customers inner join place using (cid)
    inner join contains using (oid)
    inner join products using (pid)
    where products.description like '%SATA%' -- Like means somewhere
    
    except
    
    select distinct cid
    from customers inner join place using (cid)
    inner join contains using (oid)
    inner join products using (pid)
    where products.description like '%Router%'
) as total_count;
 
/* *********************************************************************************************
   QUERY SECTION (Question 4)
   *********************************************************************************************
HP has a 20% sale on all its Networking products.
********************************************************************************************* */
-- Does not update the database
select merchants.name as merchant,
       products.name as product,
       sell.price as current_price,
       sell.price * 0.8 as discounted_price
from sell inner join merchants using (mid)
		  inner join products using (pid)
where merchants.name = 'HP' and products.category = 'Networking';
-- displays the current and discounted prices
/* *********************************************************************************************
   QUERY SECTION (Question 5)
   *********************************************************************************************
What did Uriel Whitney order
********************************************************************************************* */
-- Shows all items Uriel Whitney Orders
select distinct products.name as Product_Name,
       avg(sell.price) as Price -- gives the avg price for each item she ordered
from customers inner join place using (cid)
			   inner join contains using (oid)
               inner join products using (pid)
               inner join sell using (pid)
where customers.fullname = 'Uriel Whitney'
group by products.name;
-- Unable to link how much she actually paid for each item
/* *********************************************************************************************
   QUERY SECTION (Question 6)
   *********************************************************************************************
List the annual total sales for each company (sort the results along the company and the year attributes).
********************************************************************************************* */
-- Calculates total yearly revenue per merchant, sorted alphabetically and chronologically. 
select merchants.name as Merchant,
	   year(place.order_date) as year,
       sum(sell.price * sell.quantity_available) as Total_Sales
from merchants inner join sell using(mid)
			   inner join products using(pid)
               inner join contains using(pid)
               inner join place using (oid)
group by Merchant, year
order by Merchant, year;

/* *********************************************************************************************
   QUERY SECTION (Question 7)
   *********************************************************************************************
Which company had the highest annual revenue and in what year?
********************************************************************************************* */
-- Same as previous Query however limits it to the highest company and year
select merchants.name as Merchant,
	   year(place.order_date) as year,
       sum(sell.price * sell.quantity_available) as Total_Sales
from merchants inner join sell using(mid)
			   inner join products using(pid)
               inner join contains using(pid)
               inner join place using (oid)
group by Merchant, year
order by year limit 1;
/* *********************************************************************************************
   QUERY SECTION (Question 8)
   *********************************************************************************************
On average, what was the cheapest shipping method used ever?
********************************************************************************************* */
-- Displays the cheapest shipping metheod ever used
select orders.shipping_method as Shipping_Method,
	   round(avg(orders.shipping_cost), 2) as AVG_Cost
from orders
group by shipping_method
order by AVG_Cost asc limit 1;
/* *********************************************************************************************
   QUERY SECTION (Question 9)
   *********************************************************************************************
What is the best sold ($) category for each company?
********************************************************************************************* */
-- For each merchant, finds the category with the highest total revenue.
select
select
    merchants.name as Merchant,
    products.category as Category,
    round(sum(sell.price * sell.quantity_available), 2)as Total_Sales
from sell
     inner join merchants using (mid)
     inner join products  using (pid)
group by merchants.name, products.category

having sum(sell.price * sell.quantity_available) >= all
(
    /* for this same merchant, compute the totals across its categories and
       keep only those categories whose total is >= every other category total */
    select
        sum(s2.price * s2.quantity_available)
    from sell s2
         inner join merchants m2 using (mid)
         inner join products  p2 using (pid)
    where m2.name = merchants.name               -- correlate on the SAME merchant
    group by p2.category
)
order by Merchant;
/* *********************************************************************************************
   QUERY SECTION (Question 10)
   *********************************************************************************************
For each company find out which customers have spent the most and the least amounts
********************************************************************************************* */
-- Finds the customer in each company which has spent the most and least amount, to display all at once group concat was needed.
select sales.Merchant,
	   Group_Concat(distinct case 
			when sales.Total_Sales = maxmin.max_total then sales.Customer
            end SEPARATOR ', ') as Highest_Spender,
            round(maxmin.max_total, 2) as Highest_Spent,
	   Group_Concat(distinct case 
			when sales.Total_Sales = maxmin.min_total then sales.Customer
            end SEPARATOR ', ') as Lowest_Spender,
            round(maxmin.min_total, 2) as Lowest_Spent

from (
	select
		merchants.name as Merchant,
		customers.fullname AS Customer,
		sum(sell.price * sell.quantity_available)as Total_Sales
	from customers
	inner join place using(cid)
    inner join contains using(oid)
    inner join products using(pid)
    inner join sell using(pid)
    inner join merchants using(mid)
    group by Merchant, Customer
) as sales
 inner join (
	select
		Merchant,
        MAX(Total_Sales) as max_total,
        MIN(Total_Sales) as min_total
	from (
		select
		merchants.name as Merchant,
		customers.fullname AS Customer,
		sum(sell.price * sell.quantity_available)as Total_Sales
		from customers inner join place using(cid)
					   inner join contains using(oid)
                       inner join products using(pid)
                       inner join sell using(pid)
                       inner join merchants using(mid)
                       group by Merchant, Customer
		

    ) as sub
    group by Merchant
) as maxmin
on sales.Merchant = maxmin.Merchant
group by sales.Merchant
order by sales.Merchant;
            
        
        
        

  
