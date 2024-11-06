COMMIT;

SELECT * FROM sqlite_master WHERE type = 'table';

SELECT geolocation_zip_code_prefix,COUNT( DISTINCT geolocation_state)  FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_state)>1;

SELECT * FROM olist_sellers_dataset ORDER BY seller_zip_code_prefix;

SELECT * FROM olist_customers_dataset ORDER BY customer_zip_code_prefix;

SELECT COUNT(*) FROM olist_order_items_dataset; --112650

SELECT COUNT(*) FROM olist_orders_dataset; --99441

SELECT * FROM olist_orders_dataset  ord
LEFT JOIN olist_order_items_dataset oi ON ord.order_id=oi.order_id; --113425

SELECT * FROM olist_order_items_dataset oi
LEFT JOIN olist_orders_dataset  ord   ON ord.order_id=oi.order_id; --112650

SELECT * FROM olist_orders_dataset WHERE order_id not in (SELECT order_id FROM olist_order_items_dataset) --775

SELECT * FROM olist_order_reviews_dataset;--99224

SELECT * FROM olist_order_payments_dataset; --103886

SELECT * FROM olist_order_items_dataset oi LEFT JOIN olist_order_payments_dataset  pay ON oi.order_id=pay.order_id;

SELECT order_id,count(*) FROM olist_order_payments_dataset GROUP BY order_id HAVING COUNT(*) > 1;

SELECT * FROM olist_orders_dataset WHERE order_id = '009ac365164f8e06f59d18a08045f6c4'

SELECT * FROM olist_order_payments_dataset WHERE order_id = '009ac365164f8e06f59d18a08045f6c4';

SELECT * FROM olist_order_items_dataset oi LEFT JOIN olist_order_reviews_dataset  rew ON oi.order_id=rew.order_id; --113314

SELECT * FROM olist_orders_dataset ord LEFT JOIN olist_order_reviews_dataset  rew ON ord.order_id=rew.order_id; --99992

SELECT order_id,count(*) FROM olist_order_reviews_dataset GROUP BY order_id HAVING COUNT(*) > 2;

SELECT * FROM olist_order_reviews_dataset WHERE order_id = '03c939fd7fd3b38f8485a0f95798f1f6';

SELECT * FROM olist_order_items_dataset WHERE order_id = '03c939fd7fd3b38f8485a0f95798f1f6';

SELECT * FROM olist_orders_dataset WHERE order_id = '03c939fd7fd3b38f8485a0f95798f1f6';

SELECT * FROM olist_order_payments_dataset WHERE order_id = '03c939fd7fd3b38f8485a0f95798f1f6';

SELECT * FROM olist_products_dataset WHERE product_id = 'ab5da1daa941470d14366f4e76a99dd2';


-- Exploratory data analysis about seller, sellers location and orders. 
CREATE --[UNIQUE] 
INDEX geo_zipcode 
ON olist_geolocation_dataset(geolocation_zip_code_prefix);

CREATE --[UNIQUE] 
INDEX seller_zipcode 
ON olist_sellers_dataset(seller_zip_code_prefix);

CREATE UNIQUE
INDEX seller_sellerid
ON olist_sellers_dataset(seller_id);

CREATE --UNIQUE
INDEX ordi_sellerid
ON olist_order_items_dataset(seller_id);

COMMIT;

with seller_geo as (
SELECT DISTINCT sel.seller_id,geo.geolocation_zip_code_prefix,geolocation_city,geolocation_state
FROM olist_sellers_dataset sel LEFT JOIN olist_geolocation_dataset geo ON sel.seller_zip_code_prefix=geo.geolocation_zip_code_prefix
)
SELECT ordi.order_id, ordi.order_item_id,ordi.product_id,ordi.shipping_limit_date,ordi.price,ordi.freight_value,
selgeo.*
FROM olist_order_items_dataset ordi 
LEFT JOIN olist_sellers_dataset selgeo ON ordi.seller_id=selgeo.seller_id




 
