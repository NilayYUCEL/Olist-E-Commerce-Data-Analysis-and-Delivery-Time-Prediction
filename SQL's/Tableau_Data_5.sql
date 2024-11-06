--Customers and locations (1)
CREATE TABLE tableau_customer as 
SELECT  DISTINCT cus.customer_id,cus.customer_unique_id,cus.customer_zip_code_prefix, 
geo.geolocation_state as customer_state, geo.geolocation_city as customer_city
FROM olist_customers_dataset cus --99441
LEFt JOIN olist_geolocation_dataset geo ON cus.customer_zip_code_prefix=geo.geolocation_zip_code_prefix;

--Sellers and locations (2)
CREATE TABLE tableau_seller as 
SELECT DISTINCT sel.seller_id,sel.seller_zip_code_prefix,
geo.geolocation_state as seller_state ,geo.geolocation_city  as seller_city,
sc.score as seller_score
FROM olist_sellers_dataset sel --3095
LEFT JOIN olist_geolocation_dataset geo ON sel.seller_zip_code_prefix=geo.geolocation_zip_code_prefix
LEFT JOIN sellers_score sc ON sel.seller_id=sc.seller_id;

--Delivered Orders (3)
CREATE TABLE tableau_orders as 
with products as (
	SELECT pro.*,cat.product_category_name_english
	FROM olist_products_dataset pro 
	LEFt JOIN product_category_name_translation cat ON pro.product_category_name=cat.product_category_name
), seller as (
	SELECT DISTINCT sel.seller_id,sel.seller_zip_code_prefix,
	geo.geolocation_state as seller_state ,geo.geolocation_city  as seller_city,
	sc.score as seller_score
	FROM olist_sellers_dataset sel --3095
	LEFT JOIN olist_geolocation_dataset geo ON sel.seller_zip_code_prefix=geo.geolocation_zip_code_prefix
	LEFT JOIN sellers_score sc ON sel.seller_id=sc.seller_id
), customer as (
	SELECT  DISTINCT cus.customer_id,cus.customer_unique_id,cus.customer_zip_code_prefix, 
	geo.geolocation_state as customer_state, geo.geolocation_city as customer_city
	FROM olist_customers_dataset cus --99441
	LEFt JOIN olist_geolocation_dataset geo ON cus.customer_zip_code_prefix=geo.geolocation_zip_code_prefix
)
SELECT ordi.order_id,ordi.shipping_limit_date,ordi.price,ordi.freight_value,
ord.order_status,ord.order_purchase_timestamp,ord.order_approved_at,ord.order_delivered_carrier_date,ord.order_delivered_customer_date,ord.order_estimated_delivery_date,
pro.product_id,pro.product_category_name_english,
sel.seller_id,sel.seller_state,sel.seller_city,sel.seller_score,
cus.customer_id,cus.customer_unique_id,cus.customer_state,cus.customer_city
FROM olist_order_items_dataset ordi --112650
LEFT JOIN olist_orders_dataset ord ON ordi.order_id=ord.order_id
LEFT JOIN products pro ON ordi.product_id=pro.product_id
LEFT JOIN seller sel ON ordi.seller_id=sel.seller_id
LEFT JOIN customer cus ON ord.customer_id=cus.customer_id
WHERE ord.order_status='delivered';

--Payments (4)
SELECT * FROM olist_order_payments_dataset; --99441


