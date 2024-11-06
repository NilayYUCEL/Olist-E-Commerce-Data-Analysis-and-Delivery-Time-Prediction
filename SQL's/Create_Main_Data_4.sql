
---CREATE MAIN DATA FOR MACHINE LEARNING

SELECT * FROM brazil_states; -- Create with python

CREATE --[UNIQUE] 
INDEX customer_zipcode 
ON olist_customers_dataset(customer_zip_code_prefix);

CREATE --[UNIQUE] 
INDEX geo_zipcode 
ON olist_geolocation_dataset(geolocation_zip_code_prefix);

COMMIT;

DROP TABLE ml_data;

COMMIT;

CREATE TABLE ml_data as 
with products as (
	SELECT product_id,product_weight_g,product_height_cm,product_length_cm,product_width_cm,
	(product_height_cm*product_length_cm*product_width_cm) as cargo_volume_cm3 
	FROM olist_products_dataset
), prep_data as (
	SELECT ordi.order_id,ordi.order_item_id, ordi.freight_value,
	ord.order_purchase_timestamp,ord.order_delivered_carrier_date,ord.order_delivered_customer_date,ord.order_estimated_delivery_date,
	ROUND(JULIANDAY(ord.order_delivered_carrier_date)-JULIANDAY(ord.order_purchase_timestamp),4) as cargo_time,
	ROUND(JULIANDAY(ord.order_delivered_customer_date)-JULIANDAY(ord.order_purchase_timestamp),4) as delivery_time,
	ROUND(JULIANDAY(ord.order_estimated_delivery_date)-JULIANDAY(ord.order_purchase_timestamp),4) as estimate_time,
	pro.product_weight_g,pro.cargo_volume_cm3,
	ordi.seller_id,ord.customer_id 
	FROM olist_order_items_dataset ordi 
	LEFT JOIN olist_orders_dataset ord ON ordi.order_id=ord.order_id
	LEFT JOIN products pro ON ordi.product_id=pro.product_id
	WHERE order_status = 'delivered'
), seller_data as(
	SELECT DISTINCT sel.seller_id,geolocation_city as seller_city ,geolocation_state as seller_state ,sco.score as seller_score
	FROM olist_sellers_dataset sel 
	LEFT JOIN olist_geolocation_dataset geo ON sel.seller_zip_code_prefix=geo.geolocation_zip_code_prefix
	LEFT JOIN sellers_score sco ON sel.seller_id=sco.seller_id
), geo_zipcode as (
	SELECT DISTINCT geolocation_zip_code_prefix,geolocation_city,geolocation_state 
	FROM olist_geolocation_dataset
),customer_data as (
	SELECT cus.customer_id,geo.geolocation_city as customer_city,geo.geolocation_state as customer_state
	FROM olist_customers_dataset cus 
	LEFT JOIN geo_zipcode geo ON cus.customer_zip_code_prefix=geo.geolocation_zip_code_prefix
), main_data as (
	SELECT pre.order_id,pre.order_item_id,pre.freight_value,pre.cargo_time,pre.delivery_time,pre.estimate_time,pre.cargo_volume_cm3,
	pre.order_purchase_timestamp,pre.order_delivered_carrier_date,pre.order_delivered_customer_date,pre.order_estimated_delivery_date,
	sel.seller_id,sel.seller_city,sel.seller_state,sel.seller_score,
	cus.customer_id,cus.customer_city,cus.customer_state, concat(sel.seller_state,cus.customer_state) as distance_id
	FROM prep_data pre 
	LEFT JOIN seller_data sel ON pre.seller_id=sel.seller_id
	LEFT JOIN customer_data cus ON pre.customer_id=cus.customer_id
)
SELECT data.*,
sta.area1 as seller_state_area, sta.population1 as seller_state_population, sta.density1 as seller_state_density,
sta.area as customer_state_area, sta.population2 as customer_state_population, sta.density2 as customer_state_density,
sta.distance_km as states_distance
FROM main_data data 
LEFT JOIN brazil_states sta ON data.distance_id=sta.distance_id; --110197

COMMIT;

SELECT * FROM ml_data;