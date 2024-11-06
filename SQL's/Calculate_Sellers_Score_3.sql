
-------------------------------------------------
--Calculate Seller Score
DROP TABLE sellers_score;

CREATE TABLE sellers_score as 
with table_order_item as (
	SELECT * 
	FROM olist_order_items_dataset WHERE order_item_id=1 
	--Reviews have an order_id, but each review must include each item on the same order_id. 
	--Therefore, we need to focus on the order_id. Other data should not be used because each item on the same order might belong to different sellers.
),
table_sellers_score as (
	SELECT DISTINCT rev.review_id,rev.review_score,seller_id
	FROM olist_order_reviews_dataset rev LEFT JOIN table_order_item ordi ON rev.order_id=ordi.order_id
	WHERE review_id NOT IN (SELECT review_id as cnt FROM olist_order_reviews_dataset GROUP BY review_id HAVING COUNT(*)>1) --Each order should have one review. So, we should eliminate other reviews.
	AND seller_id IS NOT NULL
)
SELECT seller_id,AVG(review_score) as score FROM table_sellers_score GROUP BY seller_id ; --3074

COMMIT;

SELECT * FROM sellers_score;

SELECT seller_id,NULL FROM olist_sellers_dataset WHERE seller_id NOT IN (SELECT seller_id FROM sellers_score); --21

INSERT INTO sellers_score
SELECT seller_id,NULL FROM olist_sellers_dataset WHERE seller_id NOT IN (SELECT seller_id FROM sellers_score);

COMMIT;
