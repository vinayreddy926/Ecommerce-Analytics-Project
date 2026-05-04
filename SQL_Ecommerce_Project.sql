-- ============================================================
-- OLIST E-COMMERCE DATABASE SETUP + KPI QUERIES
-- ============================================================

-- 1. CREATE DATABASE
CREATE DATABASE olist_ecommerce;
USE olist_ecommerce;

-- ============================================================
-- 2. CREATE TABLES
-- ============================================================

CREATE TABLE customers (
customer_id VARCHAR(50),
customer_unique_id VARCHAR(50),
customer_zip_code_prefix INT,
customer_city VARCHAR(100),
customer_state VARCHAR(10)
);
DROP TABLE orders;
CREATE TABLE orders (
order_id VARCHAR(50),
customer_id VARCHAR(50),
order_status VARCHAR(50),
order_purchase_timestamp VARCHAR(50),
order_approved_at DATETIME,
order_delivered_carrier_date DATETIME,
order_delivered_customer_date VARCHAR(50),
order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
order_id VARCHAR(50),
order_item_id INT,
product_id VARCHAR(50),
seller_id VARCHAR(50),
shipping_limit_date DATETIME,
price FLOAT,
freight_value FLOAT
);

CREATE TABLE payments (
order_id VARCHAR(50),
payment_sequential INT,
payment_type VARCHAR(50),
payment_installments INT,
payment_value FLOAT
);
DROP TABLE reviews;
CREATE TABLE reviews (
review_id VARCHAR(50),
order_id VARCHAR(50),
review_score INT,
review_creation_date DATE,
review_answer_timestamp DATETIME
);

CREATE TABLE products (
product_id VARCHAR(50),
product_category_name VARCHAR(100),
product_name_lenght INT,
product_description_lenght INT,
product_photos_qty INT,
product_weight_g INT,
product_length_cm INT,
product_height_cm INT,
product_width_cm INT
);

CREATE TABLE sellers (
seller_id VARCHAR(50),
seller_zip_code_prefix INT,
seller_city VARCHAR(100),
seller_state VARCHAR(10)
);

CREATE TABLE category_translation (
product_category_name VARCHAR(100),
product_category_name_english VARCHAR(100)
);

-- ============================================================
-- 3. IMPORT CSV DATA
-- ============================================================

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_reviews_dataset.csv'
INTO TABLE reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ============================================================
-- KPI 1
-- Weekday vs Weekend Payment Statistics
-- ============================================================

SELECT
CASE
WHEN DAYOFWEEK(o.order_purchase_timestamp) IN (1,7)
THEN 'Weekend'
ELSE 'Weekday'
END AS order_day_type,
COUNT(DISTINCT o.order_id) AS total_orders,
SUM(p.payment_value) AS total_payment
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
GROUP BY order_day_type;

-- ============================================================
-- KPI 2
-- Orders with Review Score 5 and Payment Type Credit Card
-- ============================================================

SELECT COUNT(DISTINCT r.order_id) AS orders_count
FROM reviews r
JOIN payments p
ON r.order_id = p.order_id
WHERE r.review_score = 5
AND p.payment_type = 'credit_card';

-- ============================================================
-- KPI 3
-- Average Delivery Days for Pet Shop Category
-- ============================================================
SET SQL_SAFE_UPDATES = 0;
UPDATE orders
SET order_purchase_timestamp =
STR_TO_DATE(order_purchase_timestamp,'%d-%m-%Y %H:%i');
UPDATE orders
SET order_delivered_customer_date =
STR_TO_DATE(order_delivered_customer_date,'%d-%m-%Y %H:%i');

ALTER TABLE orders
MODIFY order_purchase_timestamp DATETIME;
ALTER TABLE orders
MODIFY order_delivered_customer_date DATETIME;

SELECT
AVG(DATEDIFF(o.order_delivered_customer_date,
o.order_purchase_timestamp)) AS avg_delivery_days
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products pr
ON oi.product_id = pr.product_id
JOIN category_translation ct
ON pr.product_category_name = ct.product_category_name
WHERE ct.product_category_name = 'pet_shop';


-- ============================================================
-- KPI 4
-- Average Price and Payment Value for Sao Paulo Customers
-- ============================================================

SELECT
AVG(oi.price) AS avg_price,
AVG(p.payment_value) AS avg_payment
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN payments p
ON o.order_id = p.order_id
WHERE c.customer_city = 'sao paulo';

-- ============================================================
-- KPI 5
-- Relationship between Shipping Days and Review Scores
-- ============================================================

SELECT
r.review_score,
AVG(DATEDIFF(o.order_delivered_customer_date,
o.order_purchase_timestamp)) AS avg_shipping_days
FROM orders o
JOIN reviews r
ON o.order_id = r.order_id
GROUP BY r.review_score
ORDER BY r.review_score;
