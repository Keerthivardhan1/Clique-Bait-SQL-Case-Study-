use clique_bait;

/*
	3. Product Funnel Analysis
    part 2
*/

-- =============================================================================================================
select * from clique_bait_reporting.product_info;

-- 1. Which product had the most views, cart adds and purchases?

select * from clique_bait_reporting.product_info
order by views desc, add_to_carts desc , purchases desc
limit 1;

-- 2. Which product was most likely to be abandoned?

select * from clique_bait_reporting.product_info
order  by Abandoned desc
limit 1;

-- 3. Which product had the highest view to purchase percentage?

create table if not exists clique_bait_reporting.highest_view_to_purchase_percentage as
select page_name, product_category,
round((purchases/views)*100 , 2) as `views_to_purchases_ratio`
from clique_bait_reporting.product_info
order by views_to_purchases_ratio desc
limit 1;


-- 4. 4. What is the average conversion rate from view to cart add?

create table if not exists clique_bait_reporting.avg_conversion_rate_from_view_to_addCart2 as
with cte as (
	select page_name , product_category, 
    round((add_to_carts/views)*100 , 2) as `views_to_add_cart_ratio`
    from clique_bait_reporting.product_info
)
select avg(views_to_add_cart_ratio) as `average_conversion_rate` from cte;

-- 5. What is the average conversion rate from cart add to purchase?

create table if not exists clique_bait_reporting.avg_conversion_rate_from_cartAdd_to_purchase2 as
with cte as (
	select page_name , product_category, 
    round((purchases/add_to_carts)*100 , 2) as `add_cart_ratio_to_purchases`
    from clique_bait_reporting.product_info
)
select avg(add_cart_ratio_to_purchases) as `average_conversion_rate` from cte;

select * from clique_bait_reporting.product_info;
select * from clique_bait_reporting.avg_conversion_rate_from_cartAdd_to_purchase2;

-- ================================================ Method 2===========================================================

create temporary table processed_table 
as
select 
	e.*,
	ed.event_name,
	p.page_name,
	p.product_id,
	p.product_category,
	max(case when (e.event_type in (3)) then 1 else 0 end ) over (partition by e.visit_id) as `purchased_or_not`,
	max(case when (e.page_id not in (12, 13)) then e.page_id end ) over (partition by e.visit_id) as `purchased_product`,
	max(case when (ed.event_name = 'Add to Cart') then 1 else 0 end ) over (partition by e.visit_id)  as `add_to_cart_or_not`
from 
	events e, 
	event_identifier ed,
	page_hierarchy p
where 
	e.event_type = ed.event_type and
	p.page_id = e.page_id ;

select * from processed_table;


-- 1. Which product had the most views, cart adds and purchases?

drop table product_vists_purch_carts;

create temporary table product_vists_purch_carts as
with cte as (
		select 
		product_category,
		visit_id,
		max(purchased_or_not) as por,
		max(add_to_cart_or_not) as acrn
		from processed_table
		where product_category is not null
		group by product_category , visit_id
)
select 
	product_category,
	count(visit_id) as `total_visits`,
    sum(acrn) as `total_add_to_cart`,
	sum(por) as `total_purcheses` 
from cte
group by product_category;

select * from product_vists_purch_carts;


create table if not exists clique_bait_reporting.visits_purchases_addcarts_per_PC as
select * from product_vists_purch_carts;

select * from clique_bait_reporting.visits_purchases_addcarts_per_PC;

-- 2. Which product was most likely to be abandoned?

/*
In e-commerce, an "abandoned" product refers to:
A product that a user added to their cart
But did not complete the purchase
*/
	select * from product_vists_purch_carts;
    
    create table if not exists clique_bait_reporting.abandoned_pc as
    select 
		product_category,
		(total_add_to_cart - total_purcheses) as `pending_purchese`
    from product_vists_purch_carts
    order by pending_purchese desc;
    
    select * from clique_bait_reporting.abandoned_pc;
    
    

-- 3. Which product had the highest view to purchase percentage?
	
    create table if not exists clique_bait_reporting.view_to_purchase_percent_per_pc as
	select 
		product_category,
		round((total_purcheses/total_visits)*100, 2) as `purchese_percent`
	from product_vists_purch_carts
	order by purchese_percent desc ;
    
    select * from clique_bait_reporting.view_to_purchase_percent_per_pc;

-- 4. 4. What is the average conversion rate from view to cart add?


		select * from product_vists_purch_carts;

		-- conversion rate for each product 

		select 
			product_category,
			round((total_add_to_cart/total_visits),2) as `conversion_rate`
		from  product_vists_purch_carts;

		-- avarage conversion rate 
		
        
        create table if not exists clique_bait_reporting.avg_conversion_rate_from_view_to_addCart as
		with cte as (
				select 
				product_category,
				round((total_add_to_cart/total_visits),2) as `conversion_rate`
				from  product_vists_purch_carts
		)
		select avg(conversion_rate) as `avg_conersion_rate`
		from cte;
		
        select * from clique_bait_reporting.avg_conversion_rate_from_view_to_addCart;

-- 5. What is the average conversion rate from cart add to purchase?


		-- conversion rate for each product 

		select 
			product_category,
			round((total_purcheses/total_add_to_cart),2) as `purchese_conversion_rate`
		from  product_vists_purch_carts;

		-- avarage conversion rate 
		
        create table if not exists clique_bait_reporting.avg_conversion_rate_from_cartAdd_to_purchase as
		with cte as (
				select 
				product_category,
				round((total_purcheses/total_add_to_cart),2) as `purchase_conversion_rate`
				from  product_vists_purch_carts
		)
		select avg(purchase_conversion_rate) as `avg_purchase_rate`
		from cte;
        
        select * from clique_bait_reporting.avg_conversion_rate_from_cartAdd_to_purchase;
        select * from clique_bait_reporting.avg_conversion_rate_from_view_to_addCart;













