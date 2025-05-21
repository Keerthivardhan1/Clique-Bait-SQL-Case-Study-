use clique_bait;

select * from clique_bait.event_identifier limit 5;
select * from clique_bait.campaign_identifier limit 5;
select * from clique_bait.page_hierarchy limit 5;
select * from  clique_bait.users;
select * from  clique_bait.events limit 5;


-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- =============================== 2.   Digital Analysis         ======================================
-- ----------------------------------------------------------------------------------------------------------

-- 1. How many users are there? :=  500
		
        create table if not exists clique_bait_reporting.total_users as
		select count(distinct user_id)as `Total number of users` from clique_bait.users;
        
        select * from clique_bait_reporting.total_users;
        

-- 2. How many cookies does each user have on average?  := 3


-- 2.1 :  calculating the number of cookies each user has 
		select 
			user_id , 
			count(cookie_id) 
        from clique_bait.users
        group by user_id;
-- 2.2 : now we have the number of cookies each user has so, we find the avg

		create table if not exists clique_bait_reporting.avg_cookies_per_user as
		with cte as (
				select user_id , count(cookie_id) as cnt 
                from clique_bait.users
				group by user_id
        )
        select floor(avg(cnt)) as `average number of cookies` from cte;
        
        select * from clique_bait_reporting.avg_cookies_per_user;


-- 3. What is the unique number of visits by all users per month?
	 
     /*
			events table consists all the logs genarated 
			for each visit there will be unique visit_id that gets genarated so, our job is to count how many unique visit_ids
			are genarated for each month 
			
			select * from clique_bait.events where month(event_time) > 6;  : 
            
            months range = [1, 5]
		   
	*/
    
    create table if not exists clique_bait_reporting.unique_visits_per_month as
    select  
		month(event_time) as month_number,
        count(distinct visit_id) as number_of_visits 
	from clique_bait.events
    group by month_number;
    
    select * from clique_bait_reporting.unique_visits_per_month;
    

-- 4. What is the number of events for each event type?
	
    /*
		event table consists of all the logs/events genarated in website thoughout its life line 
		event_identifier : contains information about event_type and event_name
        
        join event and event_identifier to know type of event and we group on event_type/event_name
			- aggregate the count() to know number of events
    
    */
    
    select * from clique_bait.events;
    
    /*
    
   --  Method 1 
    
    with cte as(
		select 
			clique_bait.events.event_type,
			clique_bait.event_identifier.event_name
		from 
		clique_bait.events join clique_bait.event_identifier
		on clique_bait.events.event_type = clique_bait.event_identifier.event_type
    )
    select 
		event_name , 
		count(cookie_id)  
    from cte
    group by event_name;
    
    */
    
    
    
    
    create table if not exists clique_bait_reporting.events_per_event as
	select 
	ed.event_name,
	count(*) as `number_of_events`
	from clique_bait.events e, clique_bait.event_identifier ed
	where e.event_type = ed.event_type
	group by event_name;
    
    select * from clique_bait_reporting.events_per_event;
    
    
    
-- 5. What is the percentage of visits which have a purchase event?   := 49.86%

	/*
		events table contains only event type but to understand what is that event we need to 
		join with event_identifier table 

		To solve this problem 
		1. we should know weather purchase is done in a visit or not 
		2. So, we need to know weather, purchase event is genarated in visit or not 
			
				for this, we will group on each visit, then we will find weather, it contains purchese 
				event or not
        
    */
    
    
    /*
    
    -- Method 1 : Using Window functions
    
    
    with cte as (
			select 
				clique_bait.events.visit_id,
				clique_bait.events.event_type,
				clique_bait.event_identifier.event_name
			from 
			clique_bait.events join clique_bait.event_identifier
			on clique_bait.events.event_type = clique_bait.event_identifier.event_type
    )
    select  
		event_name,
		round((count(distinct visit_id)/
		(select count(distinct visit_id) from clique_bait.events)) * 100, 2)
    as `percentage of purchases` 
    from cte
    group by event_name
    having event_name = 'Purchase';
    
    */
    
    -- total number of visits = 32734
    -- Purchase percentage = 49.86%
    
    
    -- Method 2 : using group by 
    
    
    create table if not exists clique_bait_reporting.percent_of_purchase_visits as
	with cte as (
		select visit_id,
		max(case when event_name = 'Purchase' then 1 else 0 end) as `purchased_or_not`
		from 
		clique_bait.events e,  clique_bait.event_identifier ed
		where e.event_type = ed.event_type
		group by e.visit_id
	)
	select 
	round((sum(purchased_or_not=1)/count(visit_id))*100 , 2) as `purchase_event_percent`
	from cte;
    
select * from  clique_bait_reporting.percent_of_purchase_visits;

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

		select count(*) as total , count( distinct  visit_id) , count(distinct cookie_id) from     clique_bait.events;
        
        select * from clique_bait.event_identifier;
        select * from clique_bait.page_hierarchy;
		
		
--        create table if not exists clique_bait_reporting.visits_that_view_checkout_but_not_purchase as
with cte as (
		select 
			visit_id,
			max(case when ed.event_name = 'Purchase' then 1 else 0 end) as `purchased`,
			max(case when p.page_name = 'Checkout' then 1 else 0 end) as `visited_checkout`
		from 
			clique_bait.events e, clique_bait.event_identifier ed, clique_bait.page_hierarchy p
		where 
			e.event_type = ed.event_type and 
			e.page_id = p.page_id 
		group by e.visit_id
)
select 
	round(
	(sum(visited_checkout = 1 & purchased = 0 )/
	sum(visited_checkout))*100
	, 2) as `checkout but not purchased %`
from cte;


-- 7. What are the top 3 pages by number of views?

/*

-- In each visit, a user can view same page multiple times, 
	and each view is valid for this question 

*/

-- 	create table if not exists clique_bait_reporting.top_3_pages_by_views as;
    
	with cte as (
		select page_id as id , count( distinct visit_id) as cnt  from clique_bait.events
		group by page_id
		order by cnt
		desc
		limit 3
	) 
	select page_name , cnt 
	from cte , clique_bait.page_hierarchy p
	where cte.id = p.page_id;
    
    select 
    page_name,
    count(*) as `views`
    from clique_bait.events e join clique_bait.page_hierarchy p
    on e.page_id = p.page_id
    group by page_name
    order by views desc
    limit 3;
    
    select 
    page_name,
    count(distinct visit_id) as `views`
    from clique_bait.events e join clique_bait.page_hierarchy p
    on e.page_id = p.page_id
    group by page_name
    order by views desc
    limit 3;

select * from clique_bait_reporting.top_3_pages_by_views;

	
-- 8. What is the number of views and cart adds for each product category?

	/*
			we need to find 
				1. Number of views , 
				2. Number of cart adds 
						for each product category
						
				Number of views can be find using event genarated on  
	*/

			select * from clique_bait.page_hierarchy;

			create table if not exists clique_bait_reporting.total_views_and_cart_adds_per_product_category as
			select
				p.product_category,
				sum(case when event_name = 'Page View' then 1 else 0 end) as `number_of_views`,
				sum(event_name = 'Add to Cart') as `number_of_add_to_carts`
			from 
				clique_bait.events e , clique_bait.page_hierarchy p, clique_bait.event_identifier ed
			where 
				e.page_id = p.page_id and
				e.event_type = ed.event_type and
				product_category is not null
			group by product_category;
            
            select * from clique_bait_reporting.total_views_and_cart_adds_per_product_category;
			
			

-- 9. What are the top 3 products by purchases? 


/*
		First we need to know weather in a visit purchase happend or not
			if happend what is the product purchased
            else quit the process
            
*/
		-- create table clique_bait_reporting.purchases_per_product_id_cat_name as
			with cte as (
					
					select 
						e.*,
						ed.event_name,
						p.product_id,
						p.page_name,
						p.product_category,
						max(
							case 
								when event_name = 'Purchase' 
									then 1
									else 0
							end
							) 
								over (partition by visit_id ) as `purchased`
						
					from 
						clique_bait.events e,
						clique_bait.event_identifier ed,
						clique_bait.page_hierarchy p
					where
						e.event_type= ed.event_type and
						e.page_id = p.page_id 
			)
			select 
			product_id ,
			product_category,
			page_name,
			count(*) as `purchases`
			from cte
			where
				event_name = 'Add to Cart' and
				purchased = 1
			group by product_id,product_category,page_name
			order by purchases desc
			limit 3;
		

        

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------


create table clique_bait_reporting.product_info as
		with cte as (
			select 
				e.*,
				ed.event_name,
				p.page_name,
				p.product_category,
				p.product_id
			from events e, event_identifier ed, page_hierarchy p
			where e.event_type = ed.event_type and e.page_id = p.page_id 
		),
		cte2 as (
			select page_name,
				product_id,
				product_category,
				case when  event_name = 'Add to Cart' then visit_id end as `cart_id`,
				case when event_name = 'Page View' then visit_id end as `viewed`
			from cte
			where product_id is not null
		),
		cte3 as (
			select visit_id as `purchased_visit_id`
			from cte 
			where event_name = 'Purchase' 
		)
		select 
			cte2.page_name,
			cte2.product_id,
			product_category,
			COUNT(DISTINCT cte2.viewed) AS `views`,
			COUNT(DISTINCT cte2.cart_id) AS `add_to_carts`,
			COUNT(distinct cte3.purchased_visit_id) AS `purchases`,
			count(DISTINCT cte2.cart_id) - COUNT(distinct cte3.purchased_visit_id) as `Abandoned`
		from 
		cte2
		left join cte3 on cte2.cart_id = cte3.purchased_visit_id
		group by 
			cte2.page_name,
			product_id,
			product_category;



-- 1. How many times was each product viewed? 
select 
	page_name , product_id , product_category , views 
from clique_bait_reporting.product_info;
-- 2. How many times was each product added to cart?
select 
	page_name , product_id , product_category , add_to_carts 
from clique_bait_reporting.product_info;
-- 3. How many times was each product added to a cart but not purchased (abandoned)?
select 
	page_name , product_id , product_category , Abandoned 
from clique_bait_reporting.product_info;
-- 4. How many times was each product purchased?
select 
	page_name , product_id , product_category , purchases 
from clique_bait_reporting.product_info;


-- Solution : 
select * from clique_bait_reporting.product_info;


-- ==================================================(1 - 4) Method 2 ======================================================================




	DROP TABLE if exists clique_bait.event_and_page;

	create table clique_bait.event_and_page
	as
	select 
		e.*,
		ed.event_name,
		p.page_name, 
		p.product_category,
		p.product_id
	from clique_bait.events e, clique_bait.page_hierarchy p, clique_bait.event_identifier ed
	where e.page_id = p.page_id and
	e.event_type = ed.event_type;

	select visit_id,
	max(case when event_type=3 then 1 else 0 end) as `p`,
	group_concat(
	case when product_id is not null then product_id end 
	order by sequence_number desc) as `view_sequence`  
	 from clique_bait.event_and_page where visit_id = 'ccf365'
	 group by visit_id;
	 
	 
	 /*
			each visit as single purchase, 
				so product bought = product_id that viewed before checkout page
									we will use sequence number to trak last product_id viewd before checkout page
									
	 */
	 
	 -- number of purchases in single visit
	 
	 select 
	 -- cookie_id , 
	 visit_id,
	 sum(event_type = 3) as `number_of_perchuses`
	 from clique_bait.event_and_page
	 -- group by cookie_id
	 group by visit_id;
	 -- having number_of_perchuses;

-- it is either 0 or 1
	 
	 
	 -- number if add_to_carts in single visit and products that added to cart 
	 
	select 
	visit_id,
	sum(event_name='Add to Cart') as `add_to_carts`,
	group_concat(
		case when (event_name = 'Add to Cart') then product_id end
		order by sequence_number
	) as cart
	from clique_bait.event_and_page
	group by visit_id;

	-- ************************************  table that shows , in a visit what products are purchased if purchased

	select 
	visit_id,
	sum(event_name='Add to Cart') as `add_to_carts`,
	max(case when event_name = 'Purchase' then 1 else 0 end) as `purchased`,
	group_concat(
		case when (event_name = 'Add to Cart') then product_id end
		order by sequence_number
	) as cart
	from clique_bait.event_and_page
	group by visit_id; 
    
-- ====================================================================

-- product_id and its purches 
		create table if not exists clique_bait_reporting.purchases_per_pid as	
			with cte as (
					
					select 
						e.*,
						ed.event_name,
						p.product_id,
						p.product_category,
						max(
							case 
								when event_name = 'Purchase' 
									then 1
									else 0
							end
							) 
								over (partition by visit_id ) as `purchased`
						
					from 
						clique_bait.events e,
						clique_bait.event_identifier ed,
						clique_bait.page_hierarchy p
					where
						e.event_type= ed.event_type and
						e.page_id = p.page_id 
			)
			select 
			product_id ,
			count(*) as `purchases`
			from cte
			where
				event_name = 'Add to Cart' and
				purchased = 1
			group by product_id;
			


select * from clique_bait_reporting.purchases_per_pid;


select * from page_hierarchy;

-- 1. How many times was each product viewed?
			
			/*
				in same cookie sesssion, user may view same product multiple times 
				so, 
				we use visit_id to track number of times a user visited a product
			*/
			
			
			-- through product_category 
			
			select * from clique_bait.page_hierarchy;
			select * from clique_bait.event_identifier;
			select * from clique_bait.events;
			
			
			select * from clique_bait.event_and_page;
			
			create table if not exists clique_bait_reporting.views_per_PC as
			select 
				product_category,
				count(event_type='Page View') as "Number_of_views"
			from clique_bait.event_and_page
			where product_category is not null
			group by product_category;
			
			-- through product_id
			
			create table if not exists clique_bait_reporting.views_per_pid as
			select 
				product_id,
				count(event_type='Page View') as "Number_of_views"
			from clique_bait.event_and_page
			where product_id is not null 
			group by product_id;
			
            
           -- create table if not exists clique_bait_reporting.views_per_pid as
			select 
				product_id,
                product_category,
                page_name,
				count(event_type='Page View') as "Number_of_views"
			from clique_bait.event_and_page
			where product_id is not null 
			group by product_id, product_category, page_name;

-- 2. How many times was each product added to cart?

			select * from clique_bait.events;
			select * from clique_bait.event_and_page;
			
			create table clique_bait.event_page_and_eventidn
			as
			select 
			e.*,ed.event_name
			from clique_bait.event_and_page e ,clique_bait.event_identifier ed
			where e.event_type = ed.event_type;
			
			select * from clique_bait.event_page_and_eventidn;
			
			
			
			
			create table if not exists clique_bait_reporting.add_to_carts_per_pid as
			select 
				product_id,
				sum(
				case when event_name = 'Add to Cart' then 1 else 0 end
				) as `add_to_carts`
			from clique_bait.event_page_and_eventidn
			where product_id is not null
			group by product_id;
            
            select * from clique_bait_reporting.add_to_carts_per_pid;
            
            
-- 3. How many times was each product added to a cart but not purchased (abandoned)?

			select * from clique_bait.events;
			select * from clique_bait.event_identifier;
			
			/* 
			core :
				select *, 
					max(case when event_name = 'Purchase' then 1 else 0 end)  over (partition by visit_id) as `Purchase` 
					from clique_bait.event_page_and_eventidn
			*/
			
		   
		   
		   -- through product id
		   
		   create table if not exists clique_bait_reporting.added_cart_but_not_purchased_per_pid as
			with cte as (
					select *, 
					max(case when event_name = 'Purchase' then 1 else 0 end)  over (partition by visit_id) as `Purchase` 
					from clique_bait.event_page_and_eventidn
			) 
			select 
				product_id,
				count(event_time) as `added_to_cart_but_not_purchased`
			from cte 
			where 
			event_name = 'Add to Cart' and 
			Purchase=0 
			group by product_id;
            
            select * from clique_bait_reporting.added_cart_but_not_purchased_per_pid;
			
			-- =======================================
			
		   -- through product_category
			
			create table if not exists clique_bait_reporting.added_cart_but_not_purchased_per_pc as
			with cte as (
					select *, 
					max(case when event_name = 'Purchase' then 1 else 0 end)  over (partition by visit_id) as `Purchase` 
					from clique_bait.event_page_and_eventidn
			) 
			select 
				product_category,
				count(event_time) as `added_to_cart_but_not_purchased`
			from cte 
			where 
			event_name = 'Add to Cart' and 
			Purchase=0 
			group by product_category;
			
				

	
		
-- 4. How many times was each product purchased?
		
        	create table if not exists clique_bait_reporting.purchases_per_product as	
			with cte as (
					
					select 
						e.*,
						ed.event_name,
						p.product_id,
						p.product_category,
						max(
							case 
								when event_name = 'Purchase' 
									then 1
									else 0
							end
							) 
								over (partition by visit_id ) as `purchased`
						
					from 
						clique_bait.events e,
						clique_bait.event_identifier ed,
						clique_bait.page_hierarchy p
					where
						e.event_type= ed.event_type and
						e.page_id = p.page_id 
			)
			select 
			product_id ,
			count(*) as `purchases`
			from cte
			where
				event_name = 'Add to Cart' and
				purchased = 1
			group by product_id;
            
           select * from  clique_bait_reporting.purchases_per_product;


-- =========================================================================

select * from events where visit_id = '2f76a8';


-- create table if not exists clique_bait_reporting.visits_last_page as	;

-- with cte2 as (

create table if not exists clique_bait_reporting.page_pid_pc_and_Number_of_visits_ended as
with cte as (
select 
visit_id,
max(sequence_number)  as `msn`
from events
group by visit_id
)
select 
p.page_name ,
COALESCE(p.product_id, 'no product_id') as product_id,
COALESCE(p.product_category, 'no product_category') as product_category,
count(*) as `Number of visits ended`
from cte , events e , clique_bait.page_hierarchy p
where e.visit_id = cte.visit_id and e.sequence_number = cte.msn and
p.page_id = e.page_id
group by p.page_name,p.product_id,
p.product_category;

select * from clique_bait_reporting.page_pid_pc_and_Number_of_visits_ended;

select count( distinct visit_id ) from clique_bait.events;


create table if not exists clique_bait_reporting.Total_number_of_visits as
select count(distinct(visit_id))  as `Total number of visits` from events;



create table clique_bait_reporting.page_hierarchy as
select * from clique_bait.page_hierarchy;



with cte as(
select 
users.*,date(start_date) as dt   from users
)
select dt,   count( distinct user_id) as `users` , count(cookie_id) as `visits`  from cte
group by dt
order by dt;