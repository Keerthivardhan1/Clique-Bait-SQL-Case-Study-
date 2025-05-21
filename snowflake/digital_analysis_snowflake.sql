use clique_bait;

select * from PAGE_HIERARCHY;
select * from users;
select * from events;
select * from event_identifier;
select * from campaign_identifier;


/*
========================================================================================
========================================================================================
2. Digital Analysis

*/

/*
===========================================
1. How many users are there?
*/

select count(distinct user_id) from users; 

/*
output : 500
============================================ 
*/


/*
===========================================
2. How many cookies does each user have on average?
*/

with cte as (
				select user_id , count(cookie_id) as "cnt" 
                from users
				group by user_id
        )
select floor(avg("cnt")) as "average number of cookies" from cte;

/*
output : 3
============================================ 
*/

/*
===========================================
3. What is the unique number of visits by all users per month?
*/
with cte as (
select 
*,
month(event_time) as "month_number"
from events
) 
select 
"month_number",
count(distinct visit_id) as "visits"
from cte
group by "month_number"
order by "month_number";


/*
output : 
1	876
2	1488
3	916
4	248
5	36
============================================ 
*/

/*
===========================================
4. What is the number of events for each event type?
*/

select
ed.event_name,  count(e.visit_id)
from
events e, event_identifier ed
where e.event_type = ed.event_type
group by ed.event_name
; 

/*
output : 
Page View	20928
Ad Click	702
Purchase	1777
Add to Cart	8451
Ad Impression	876
============================================ 
*/

/*
===========================================
5.  What is the percentage of visits which have a purchase event?
*/

with cte  as (
    select 
    visit_id,
    max(case when event_name = 'Purchase' then 1 else 0 end ) as purchase
    from
    events e, event_identifier ed
    where e.event_type = ed.event_type
    group by visit_id
)
select 
(sum(purchase)/count(visit_id))*100 as "purchase_percent"
from cte;
/*
output : 49.85%
============================================ 
*/
/*
===========================================
6.  What is the percentage of visits which view the checkout page but do not have a purchase
event?

*/

with cte  as (
    select 
    visit_id,
    max(case when page_name = 'Checkout' then 1 else 0 end ) as checkout,
    max(case when event_name = 'Purchase' then 1 else 0 end ) as purchase
    from
    events e, event_identifier ed, PAGE_HIERARCHY ph
    where e.event_type = ed.event_type and e.page_id = ph.page_id
    group by visit_id
    
)
select 
(sum( case when((checkout = 1) and (purchase = 0)) then 1 else 0 end ) / sum(checkout))*100 as "purchase_percent"
from cte;



/*
output : 15.5
============================================ 
*/

/*
===========================================
7. What are the top 3 pages by number of views?
*/

select page_name,
count(distinct visit_id) as "visits"
from 
events e ,PAGE_HIERARCHY ph
where  e.page_id = ph.page_id
group by page_name
order by "visits" desc
limit 3;

/*
output : 
All Products	3174
Checkout	2103
Home Page	1782
============================================ 
*/

-- **************************************************
    select 
    *,
    max(case when event_name = 'Purchase' then 1 else 0 end ) over (partition by visit_id ) as purchase
    from
    events e, event_identifier ed, PAGE_HIERARCHY ph
    where e.event_type = ed.event_type and e.page_id = ph.page_id;


-- ************************************************


/*
===========================================
8. What is the number of views and cart adds for each product category?

*/

drop table temp;
create  table temp as 
with cte as (
    select 
    e.*,
    ed.*,
    ph.*,
    max(case when event_name = 'Purchase' then 1 else 0 end ) over (partition by visit_id ) as purchase
    from
    events e, event_identifier ed, PAGE_HIERARCHY ph
    where e.event_type = ed.event_type and e.page_id = ph.page_id
) 
select 
PRODUCT_CATEGORY,
product_id,
page_name,
sum(case when event_name = 'Page View' then 1 else 0 end) as "views",
sum(case when event_name = 'Add to Cart' then 1 else 0 end) as "cart_adds",
sum(purchase) as "purchase"
from cte
where PRODUCT_CATEGORY != 'NULL'
group by PRODUCT_CATEGORY , product_id , page_name;

DESC TABLE temp;

select 
"PRODUCT_CATEGORY", 
sum("views") as "views",
sum("cart_adds") as "cart_adds"  
from temp group by PRODUCT_CATEGORY ;


/*
output : 
Luxury	3032	1870	3537
Shellfish	6204	3792	7340
Fish	4633	2789	5373
============================================ 
*/

/*
===========================================
9. What are the top 3 products by purchases?
*/

select 
product_id,
"PRODUCT_CATEGORY",
page_name,
"purchase"
from temp 
order by "purchase" desc
limit 3; 

/*
output : 
7	Shellfish	Lobster	1867
9	Shellfish	Oyster	1862
8	Shellfish	Crab	1827
============================================ 
*/
