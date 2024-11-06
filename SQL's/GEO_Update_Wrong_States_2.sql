PRAGMA table_info(olist_geolocation_dataset);

--geolocation_zip_code_prefix
--geolocation_lat
--geolocation_lng
--geolocation_city
--geolocation_state



-- Wrong classification for states. Same zip codes had got different states.
SELECT geolocation_zip_code_prefix,COUNT( DISTINCT geolocation_state)  
FROM olist_geolocation_dataset
WHERE LENGTH(geolocation_zip_code_prefix) <= 10
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_state)>1;

--2116	2
--4011	2
--21550	2
--23056	2
--72915	2
--78557	2
--79750	2
--80630	2

SELECT * FROM olist_geolocation_dataset WHERE geolocation_zip_code_prefix = 2116;

-- Finding most repeated value for a state. 
DROP TABLE updated_states;

CREATE TABLE updated_states as 
with group_zip_loc as (
	SELECT geolocation_zip_code_prefix,geolocation_state,COUNT(*) as cnt  FROM olist_geolocation_dataset
	WHERE LENGTH(geolocation_zip_code_prefix) <= 10
	GROUP BY geolocation_zip_code_prefix, geolocation_state
),
more_than_one_state as (
	SELECT geolocation_zip_code_prefix,COUNT(DISTINCT geolocation_state) as different_cnt FROM group_zip_loc
	WHERE LENGTH(geolocation_zip_code_prefix) <= 10
	GROUP BY geolocation_zip_code_prefix
	HAVING COUNT(DISTINCT geolocation_state)>1
)
SELECT mto.geolocation_zip_code_prefix,zl.cnt,zl.geolocation_state FROM more_than_one_state mto 
LEFT JOIN group_zip_loc zl ON mto.geolocation_zip_code_prefix=zl.geolocation_zip_code_prefix
WHERE cnt <> 1;

COMMIT;

SELECT * FROM updated_states;

--Finding the number of values ​​to update  in same zip code. 
SELECT COUNT(*) 
FROM olist_geolocation_dataset 
WHERE geolocation_zip_code_prefix in (SELECT up.geolocation_zip_code_prefix FROM updated_states up);--865

-- Update the states that have same zip code but different state
UPDATE olist_geolocation_dataset 
SET geolocation_state = (SELECT up.geolocation_state 
							FROM updated_states up 
							WHERE olist_geolocation_dataset.geolocation_zip_code_prefix=up.geolocation_zip_code_prefix)
WHERE olist_geolocation_dataset.geolocation_zip_code_prefix in (SELECT up2.geolocation_zip_code_prefix FROM updated_states up2); --865

COMMIT;

--CONTROL
SELECT geolocation_zip_code_prefix,COUNT( DISTINCT geolocation_state)  FROM olist_geolocation_dataset
WHERE LENGTH(geolocation_zip_code_prefix) <= 10
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_state)>1;


SELECT * FROM olist_geolocation_dataset WHERE geolocation_zip_code_prefix in (2116,4011,21550);

SELECT * FROM olist_geolocation_dataset WHERE geolocation_zip_code_prefix in (21550);

SELECT * FROM olist_geolocation_dataset ORDER BY geolocation_zip_code_prefix;

--Add missing zipcodes. Add data that exists in customer and seller table but not exists in the geolocation table 
INSERT INTO olist_geolocation_dataset 
SELECT DISTINCt customer_zip_code_prefix,0 as geolocation_lat,0 as geolocation_lng,customer_city,customer_state FROM olist_customers_dataset 
WHERE customer_zip_code_prefix not in (SELECT geolocation_zip_code_prefix FROM olist_geolocation_dataset) --157
UNION
SELECT seller_zip_code_prefix,0 as geolocation_lat,0 as geolocation_lng,seller_city,seller_state FROM olist_sellers_dataset
WHERE seller_zip_code_prefix not in (SELECT geolocation_zip_code_prefix FROM olist_geolocation_dataset) --7

COMMIT;

-- Wrong classification for cities. Same zip codes had got different cities.
-- And fix latin alphabet
SELECT geolocation_zip_code_prefix,COUNT( DISTINCT geolocation_city)  
FROM olist_geolocation_dataset
WHERE LENGTH(geolocation_zip_code_prefix) <= 10
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_city)>1;

SELECT * FROM olist_geolocation_dataset WHERE geolocation_zip_code_prefix in (99930);

-- Fix latin alphabet
SELECT 
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(geolocation_city,'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u'),'â','a'),'ê','e'),'ô','o'),'ã','a'),'õ','o');
FROM olist_geolocation_dataset

UPDATE olist_geolocation_dataset
SET geolocation_city = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(geolocation_city,'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u'),'â','a'),'ê','e'),'ô','o'),'ã','a'),'õ','o'),'ç','c'),'ş','s'),'ö','o'),'ü','u');

COMMIT;

-- Finding most repeated value for a city in same zip code.
DROP TABLE updated_cities;

CREATE TABLE updated_cities as
with group_zip_city as (
	SELECT geolocation_zip_code_prefix,geolocation_city,COUNT(*) as cnt  
	FROM olist_geolocation_dataset
	WHERE LENGTH(geolocation_zip_code_prefix) <= 10
	GROUP BY geolocation_zip_code_prefix, geolocation_city
),
more_than_one_city as (
	SELECT geolocation_zip_code_prefix,COUNT(DISTINCT geolocation_city) as different_cnt 
	FROM group_zip_city
	WHERE LENGTH(geolocation_zip_code_prefix) <= 10
	GROUP BY geolocation_zip_code_prefix
	HAVING COUNT(DISTINCT geolocation_city)>1
),
max_cnt_city as (
	SELECT geolocation_zip_code_prefix,max(cnt) as max_cnt 
	FROM group_zip_city 
	WHERE geolocation_zip_code_prefix in (SELECT geolocation_zip_code_prefix from more_than_one_city)
	GROUP BY geolocation_zip_code_prefix
),
min_cnt_city as (
	SELECT geolocation_zip_code_prefix,min(cnt) as min_cnt 
	FROM group_zip_city 
	WHERE geolocation_zip_code_prefix in (SELECT geolocation_zip_code_prefix from more_than_one_city)
	GROUP BY geolocation_zip_code_prefix
), min_max_eq as (
	SELECT mi.geolocation_zip_code_prefix
	FROM min_cnt_city mi JOIN max_cnt_city ma on max_cnt=min_cnt and mi.geolocation_zip_code_prefix=ma.geolocation_zip_code_prefix
), update_data as (
	SELECT zc.geolocation_zip_code_prefix,max_cnt,zc.geolocation_city 
	FROM max_cnt_city mcc 
	LEFt JOIN group_zip_city zc  ON zc.geolocation_zip_code_prefix=mcc.geolocation_zip_code_prefix AND zc.cnt=mcc.max_cnt
	WHERE zc.geolocation_zip_code_prefix NOT IN (SELECT * FROM min_max_eq) 
), update_data_cust as (
	SELECT DISTINCT customer_zip_code_prefix,0 as cnt,customer_city 
	FROM olist_customers_dataset 
	WHERE customer_zip_code_prefix IN (SELECT * FROM min_max_eq)
), update_data_eq as (
	SELECT zc.geolocation_zip_code_prefix,cnt,zc.geolocation_city, row_number() over(PARTITION BY zc.geolocation_zip_code_prefix) AS rnum 
	FROM max_cnt_city mcc 
	LEFt JOIN group_zip_city zc  ON zc.geolocation_zip_code_prefix=mcc.geolocation_zip_code_prefix AND zc.cnt=mcc.max_cnt
	WHERE zc.geolocation_zip_code_prefix IN (SELECT * FROM min_max_eq) 
	AND zc.geolocation_zip_code_prefix NOT IN (SELECT customer_zip_code_prefix FROM update_data_cust)
	AND zc.geolocation_zip_code_prefix NOT IN (SELECT geolocation_zip_code_prefix FROM update_data) 
)SELECT geolocation_zip_code_prefix,cnt,geolocation_city FROM update_data_eq WHERE rnum = 1
UNION 
SELECT * FROM update_data_cust
UNION 
SELECT * FROM update_data;

COMMIT;

SELECT * FROM updated_cities;

--Finding the number of values ​​to update  in same zip code. 
SELECT * FROM olist_geolocation_dataset
WHERE geolocation_zip_code_prefix in (SELECT up2.geolocation_zip_code_prefix FROM updated_cities up2); --27973

-- Update the cities that have same zip code but different cities.
UPDATE olist_geolocation_dataset 
SET geolocation_city = (SELECT up.geolocation_city
							FROM updated_cities up 
							WHERE olist_geolocation_dataset.geolocation_zip_code_prefix=up.geolocation_zip_code_prefix)
WHERE olist_geolocation_dataset.geolocation_zip_code_prefix in (SELECT up2.geolocation_zip_code_prefix FROM updated_cities up2); --27973

COMMIT;

--Control
SELECT geolocation_zip_code_prefix,COUNT( DISTINCT geolocation_city)  
FROM olist_geolocation_dataset
WHERE LENGTH(geolocation_zip_code_prefix) <= 10
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_city)>1;--0

SELECT * FROM olist_geolocation_dataset ORDER BY geolocation_city ;

-- Fix city names that same name but have got punctuations.
SELECT * FROM olist_geolocation_dataset WHERE geolocation_city like '%-%' or 
geolocation_city like '%''%';

SELECT 
REPLACE(REPLACE(geolocation_city,'''',' '),'-',' ')
FROM olist_geolocation_dataset
WHERE geolocation_city like 'mogi%' or geolocation_city like 'embu%';

UPDATE olist_geolocation_dataset
SET geolocation_city = REPLACE(REPLACE(geolocation_city,'''',' '),'-',' ');

COMMIT;

SELECT * FROm olist_geolocation_dataset;
