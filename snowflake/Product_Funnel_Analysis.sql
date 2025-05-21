/*
========================================================================================
========================================================================================
3. Product Funnel Analysis

*/

use clique_bait;

select * from PAGE_HIERARCHY;
select * from users;
select * from events;
select * from event_identifier;
select * from campaign_identifier;


/*
===========================================
1. How many times was each product viewed?
*/
select PRODUCT_CATEGORY,product_id, page_name, "views" from product_info;

/*
output : 
Fish	2	Kingfish	1559
Fish	3	Tuna	1515
Luxury	5	Black Truffle	1469
Shellfish	7	Lobster	1547
Shellfish	9	Oyster	1568
Shellfish	8	Crab	1564
Fish	1	Salmon	1559
Luxury	4	Russian Caviar	1563
Shellfish	6	Abalone	1525
============================================ 
*/

/*
===========================================
2. How many times was each product added to cart?
*/

select PRODUCT_CATEGORY,product_id, page_name, "cart_adds" from product_info;

/*
output : 
Fish	2	Kingfish	920
Fish	3	Tuna	931
Luxury	5	Black Truffle	924
Shellfish	7	Lobster	968
Shellfish	9	Oyster	943
Shellfish	8	Crab	949
Fish	1	Salmon	938
Luxury	4	Russian Caviar	946
Shellfish	6	Abalone	932
============================================ 
*/

/*
===========================================
3. How many times was each product added to a cart but not purchased (abandoned)?
*/

select * from product_info;

select PRODUCT_CATEGORY,product_id, page_name, ("cart_adds" - "purchase") as "abandoned" from product_info;


/*
output : 
Fish	2	Kingfish	213
Fish	3	Tuna	234
Luxury	5	Black Truffle	217
Shellfish	7	Lobster	214
Shellfish	9	Oyster	217
Shellfish	8	Crab	230
Fish	1	Salmon	227
Luxury	4	Russian Caviar	249
Shellfish	6	Abalone	233
============================================ 
*/

/*
===========================================
4. How many times was each product purchased?
*/

select PRODUCT_CATEGORY,product_id, page_name, "purchase" from product_info;

/*
output :
Fish	2	Kingfish	707
Fish	3	Tuna	697
Luxury	5	Black Truffle	707
Shellfish	7	Lobster	754
Shellfish	9	Oyster	726
Shellfish	8	Crab	719
Fish	1	Salmon	711
Luxury	4	Russian Caviar	697
Shellfish	6	Abalone	699
============================================ 
*/

/*
===========================================
5. Which product had the most views, cart adds and purchases?
*/

select * from product_info
order by "views" desc, "cart_adds" desc , "purchase" desc
limit 1;

/*
output : 
Shellfish	9	Oyster	1568	943	726
============================================ 
*/

/*
===========================================
6. Which product was most likely to be abandoned?

*/

select * from product_info
order by ("cart_adds" - "purchase") desc
limit 1;
/*
output : 
Luxury	4	Russian Caviar	1563	946
============================================ 
*/

/*
===========================================
7 . Which product had the highest view to purchase percentage?

*/

with cte as (
select *, ("purchase"/"views")*100 as view_purchase_percent from product_info
)
select * from cte 
order by view_purchase_percent  desc 
limit 1;

WITH cte AS (
    SELECT *, ("purchase" / "views") * 100 AS view_purchase_percent
    FROM product_info
)
SELECT *
FROM cte
ORDER BY view_purchase_percent DESC
LIMIT 1;

/*
output : 
Shellfish	7	Lobster	1547	968	754	48.739500
============================================ 
*/

/*
===========================================
8. What is the average conversion rate from view to cart add??
*/
with cte as (
    select 
    page_name , product_category,
    round(("cart_adds"/"views")*100, 2) as "views_to_add_cart_ratio"
    from product_info
)
select avg("views_to_add_cart_ratio") as "average_conversion_rate" from
cte;

/*
output : 60.00
============================================ 
*/

/*
===========================================
9. What is the average conversion rate from cart add to purchase??
*/

select * from product_info;

with cte as (
    select 
    page_name , product_category,
    round(("purchase"/"cart_adds")*100, 2) as "add_cart_ratio_to_purchases"
    from product_info
)
select avg("add_cart_ratio_to_purchases") as "average_conversion_rate" from
cte;

/*
output : 75.9
============================================ 
*/
