use clique_bait;

select * from events;
select * from campaign_identifier;
select * from clique_bait.event_identifier;
select * from clique_bait.page_hierarchy ;
select * from  clique_bait.users;

drop table if exists temp;

create temporary table temp as 
select 
	e.*,
	u.user_id,
	u.start_date as user_start_date,
	p.page_name,
	p.product_category,
	p.product_id,
	ed.event_name,
    cd.campaign_name,
    cd.products
from 
events e, users u, event_identifier ed, page_hierarchy p, campaign_identifier cd
where 
e.event_type = ed.event_type and
u.cookie_id = e.cookie_id and
e.page_id = p.page_id and 
(date(e.event_time) >= date(cd.start_date)) and 
(date(e.event_time) <= date(cd.end_date));

select * from temp;
select user_id , count(distinct visit_id) , count(distinct cookie_id) from temp group by user_id;


/*
each user has multiple visits and cookie_id
*/
/*

• user_id
• visit_id
• visit_start_time: the earliest event_time for each visit
• page_views: count of page views for each visit
• cart_adds: count of product cart add events for each visit
• purchase: 1/0 flag if a purchase event exists for each visit
• campaign_name: map the visit to a campaign if the visit_start_time falls between 
the start_date and end_date
• impression: count of ad impressions for each visit
• click: count of ad clicks for each visit
• (Optional column) cart_products: a comma separated text value with products added to 
the cart sorted by the order they were added to the cart (hint: use the sequence_number)


*/

-- select visit_id,
-- count(distinct event_time) from temp group by visit_id;

drop table if exists campaigns_analysis;
create table if not exists campaigns_analysis as
with cte as (
    select 
        visit_id,
        user_id,
        min(event_time) as visit_start_time,
        count(distinct page_id) as page_views,
        sum(case when event_name = 'Add to Cart' then 1 else 0 end) as cart_adds,
        max(case when event_name = 'Purchase' then 1 else 0 end) as purchase,
        sum(case when event_name = 'Ad Impression' then 1 else 0 end) as Impression,
        sum(case when event_name = 'Ad Click' then 1 else 0 end) as click,
        LISTAGG(CASE WHEN event_name = 'Add to Cart' THEN product_id END, ',') 
            WITHIN GROUP (ORDER BY sequence_number) AS cart_product_ids,
        LISTAGG(CASE WHEN event_name = 'Add to Cart' THEN page_name END, ',') 
            WITHIN GROUP (ORDER BY sequence_number) AS cart_products_name
    from temp
    group by visit_id, user_id
)
select 
    cte.*,
    cd.campaign_name,
    cd.products
from cte
join campaign_identifier cd
    on cte.visit_start_time >= cd.start_date
    and cte.visit_start_time <= cd.end_date;



select * from campaigns_analysis
limit 5;


/*
=====================================================================================
Identifying users who have received impressions during each campaign period and 
comparing each metric with other users who did not have an impression event
*/
-- drop table clique_bait_reporting.users_recived_impression;


select * from clique_bait_reporting.campaigns_analysis;



select 
campaign_name,
case when (impression=1) then 'Received' else 'Not Received' end as Impression,
count(visit_id) as "total_visits",
sum(page_views)/count( visit_id) as "avg_page_views_per_visit",
sum(cart_adds)/count( visit_id) as "avg_cart_adds_per_visit",
(sum(case when purchase=1 then cart_adds else 0 end )/sum(purchase)) as "avg_purchases"
from campaigns_analysis
group by campaign_name, impression
order by campaign_name; 	

/*
impression : in each campaign percentage of purchase from cart_adds are higher compared to not_recived_impression

*/


/*
=====================================================================
2. Does clicking on an impression lead to higher purchase rates?
*/

-- ================
select 
	case when click=1 then 'Yes' else 'No' end as "clicked",
	(sum(purchase)/count(visit_id))*100 as "purchase_rate_percentage"
from campaigns_analysis
where impression= 1
group by  click;


-- ======================================================================

/*

What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression?
 What if we compare them with users who just an impression but do not click?

*/


/**
	i. uplift in purchase rate when comparing users
    who click on a campaign impression versus users who do not receive an impression
**/

select * from campaigns_analysis;

with cte1 as (
  select 
    click,
    (sum(purchase)/count(visit_id))*100 as purchase_rate,
    1 as dummy_col
  from campaigns_analysis
  where click = 1
  group by click
),
cte2 as (
  select 
    impression,
    (sum(purchase)/count(visit_id))*100 as purchase_rate,
    1 as dummy_col
  from campaigns_analysis
  where impression = 0
  group by impression
)
select 
  (cte1.purchase_rate - cte2.purchase_rate) as purchase_rate_uplift
from cte1 
join cte2 on cte1.dummy_col = cte2.dummy_col;



select 
'users clicked on impression' as "Description ",
case when  impression=1 then 'Recevied' else 'Not Recevied' end as Impression,
case when  click=1 then 'clicked' else 'not clicked' end as clicked,
(sum(purchase)/count(visit_id))*100 as "purchase_rate"
from campaigns_analysis
where impression =1 and  click = 1
group by impression , click
union all
select 
'users not recived impression' as "Description ",
case when  impression=1 then 'Recevied' else 'Not Recevied' end as Impression,
case when  click=1 then 'clicked' else 'not clicked' end as clicked,
(sum(purchase)/count(visit_id))*100 as "purchase_rate"
from campaigns_analysis
where impression= 0 and click =0
group by impression , click;


/**
===========================================================================
	ii. uplift in purchase rate when comparing users who click on a 
	campaign impression versus users who just an impression but do not click

*/

select 
	'users clicked on impression' as "Description ",
	case when  impression=1 then 'Recevied' else 'Not Recevied' end as Impression,
	case when  click=1 then 'clicked' else 'not clicked' end as clicked,
	(sum(purchase)/count(visit_id))*100 as "purchase_rate"
from campaigns_analysis
where impression =1 and  click = 1
group by impression , click
union all
select 
	'users recived impression but not clicked' as "Description ",
	case when  impression=1 then 'Recevied' else 'Not Recevied' end as Impression,
	case when  click=1 then 'clicked' else 'not clicked' end as clicked,
	(sum(purchase)/count(visit_id))*100 as "purchase_rate"
from campaigns_analysis
where impression= 1 and click =0
group by impression , click;

-- =======================================================================================================================


/*
	• What metrics can you use to quantify the success or failure of each campaign compared to 
	each other?
*/



select 
	campaign_name,
	count( distinct user_id) as "total_users",
	count( distinct visit_id) as "total_visits",
	sum(page_views)/count( visit_id) as "avg_page_views_per_visit",
	(sum(cart_adds)/count(visit_id)) as "avg_purchases_per_visit",
	(sum(purchase)/count(visit_id))*100 as "purchase_rate"
from  campaigns_analysis
group by campaign_name;




-- =========================================================================================================================



/*
	dt_users_visits_camp :
		table : it consists number of users visited and number of visits on each date and in which campaign 

*/

create table if not exists dt_users_visits_camp as
with cte as 
(
		select 
		date(event_time) as dt,
		count(distinct user_id) as "users",
		count(e.cookie_id) as "visits"
		from events e , users u
		where e.cookie_id  = u.cookie_id
		group by dt
		order by dt
)
select cte.*,cd.campaign_name
from 
cte , campaign_identifier cd
where
cte.dt >= date(cd.start_date) and
		cte.dt <= date(cd.end_date);

select * from dt_users_visits_camp;





