use clique_bait;

select * from events;
select * from campaign_identifier;
select * from clique_bait.event_identifier;
select * from clique_bait.page_hierarchy ;
select * from  clique_bait.users;

create temporary table temp as 
select 
	e.*,
	u.user_id,
	u.start_date as user_start_date,
	p.page_name,
	p.product_category,
	p.product_id,
	ed.event_name
from 
events e, users u, event_identifier ed, page_hierarchy p
where 
e.event_type = ed.event_type and
u.cookie_id = e.cookie_id and
e.page_id = p.page_id;

select * from temp;

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

		with cte as (
				select 
				visit_id,
				user_id,
				min(event_time) as `visit_start_time`,
				count( distinct page_id)  as `page_views`,
				sum(event_name = 'Add to Cart') as `cart_adds`,
				max(case when (event_name = 'Purchase') then 1 else 0 end) as `purchase`,
				sum(case when (event_name = 'Ad Impression') then 1 else 0 end) as `Impression`,
				sum(event_name = 'Ad Click') as `click`,
				group_concat(
					case when (event_name = 'Add to Cart') then product_id end
					order by sequence_number
					) as `cart_product`
				from temp
				group by visit_id, user_id
		)
		select 
			cte.*,
			cd.campaign_name
		from cte  , campaign_identifier cd
		where 
        cte.visit_start_time >= cd.start_date and
		cte.visit_start_time <= cd.end_date;