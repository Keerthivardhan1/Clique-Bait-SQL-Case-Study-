use clique_bait_db;

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

-- select count(distinct cookie_id)as `Total number of users` from clique_bait.users;
select count(distinct user_id)as `Total number of users` from clique_bait.users ;

-- 2. How many cookies does each user have on average?  := 3


-- 2.1 :  calculating the number of cookies each user has 
		select 
			user_id , 
			count(cookie_id) 
        from clique_bait.users
        group by user_id;
-- 2.2 : now we have the number of cookies each user has so, we find the avg
		with cte as (
				select user_id , count(cookie_id) as cnt 
                from clique_bait.users
				group by user_id
        )
        select floor(avg(cnt)) as `average number of cookies` from cte;


-- 3. What is the unique number of visits by all users per month?
	 
     /*
			events table consists all the logs genarated 
			for each visit there will be unique visit_id that gets genarated so, our job is to count how many unique visit_ids
			are genarated for each month 
			
			select * from clique_bait.events where month(event_time) > 6;  : 
            
            months range = [1, 5]
		   
	*/
    
    select  
		month(event_time) as month_number,
        count(distinct visit_id) as number_of_visits 
	from clique_bait.events
    group by month_number;
    

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
    
    
    
    
    
    select 
    ed.event_name,
    count(*) as `number_of_events`
    from clique_bait.events e, clique_bait.event_identifier ed
    where e.event_type = ed.event_type
    group by event_name;
    
    
    
    
    
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

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

		select count(*) as total , count( distinct  visit_id) , count(distinct cookie_id) from     clique_bait.events;
        
        select * from clique_bait.event_identifier;
        select * from clique_bait.page_hierarchy;
		
		
		select 
			visit_id,
			max(case when ed.event_name = 'Purchase' then 1 else 0 end) as `purchased`,
			max(case when p.page_name = 'Checkout' then 1 else 0 end) as `visited_checkout`
		from 
			clique_bait.events e, clique_bait.event_identifier ed, clique_bait.page_hierarchy p
		where 
			e.event_type = ed.event_type and 
			e.page_id = p.page_id 
		group by e.visit_id;
    
    /*
    -------------------------------------   testing
    
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
    having purchased=1 and visited_checkout= 0;
    
    
    output : no rows 
					-- which should be the correct answer
    
    */
    
    
        

-- 7. What are the top 3 pages by number of views?

/*

-- In each visit, a user can view same page multiple times, 
	and each view is valid for this question 



*/
	with cte as (
		select page_id as id , count(*) as cnt  from clique_bait.events
        group by page_id
        order by cnt
        desc
        limit 3
	) 
    select page_name , cnt 
    from cte , clique_bait.page_hierarchy p
    where cte.id = p.page_id;
    

	
-- 8. What is the number of views and cart adds for each product category?

/*
		we need to find 
			1. Number of views , 
            2. Number of cart adds 
					for each product category
                    
			Number of views can be find using event genarated on  
*/

		select * from clique_bait.page_hierarchy;

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
        
        

-- 9. What are the top 3 products by purchases?
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
			group by product_id
            order by purchases desc
            limit 3;    
        
        







-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

select * from clique_bait.event_identifier limit 5;
select * from clique_bait.campaign_identifier limit 5;
select * from clique_bait.page_hierarchy ;
select * from  clique_bait.users;
select * from  clique_bait.events limit 5;

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

--  table that shows , in a visit what products are purchased if purchased

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
    
    select 
		product_category,
		count(event_type='Page View') as "Number_of_views"
    from clique_bait.event_and_page
    where product_category is not null
    group by product_category;
    
    -- through product_id
    
    select 
		product_id,
		count(event_type='Page View') as "Number_of_views"
    from clique_bait.event_and_page
    where product_id is not null 
    group by product_id;
    

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
        
        
        
        
        select 
			product_id,
			sum(
			case when event_name = 'Add to Cart' then 1 else 0 end
			) as `add_to_carts`
        from clique_bait.event_page_and_eventidn
        where product_id is not null
        group by product_id;

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
    
    -- =======================================
    
   -- through product_category
      
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
