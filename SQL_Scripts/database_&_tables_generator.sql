CREATE DATABASE ecommerce_delivery;
USE ecommerce_delivery;

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
	customer_unique_id CHAR(32) PRIMARY KEY,
	customer_id CHAR(32),
    customer_zip_code_prefix INT,
    customer_city CHAR(32),
    customer_state CHAR(2)
);

DROP TABLE IF EXISTS products;
CREATE TABLE products (
	product_id CHAR(32) PRIMARY KEY,
    product_category_name CHAR(40),
    product_name_length DECIMAL(4, 2),
    product_description_length DECIMAL(6, 2),
    product_photos_qty DECIMAL(4, 2),
    product_weight_g DECIMAL(7, 2),
    product_length_cm DECIMAL(5, 2),
    product_height_cm DECIMAL(5, 2),
    product_width_cm DECIMAL(5, 2)
);

DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
	seller_id CHAR(32) PRIMARY KEY,
    seller_city CHAR(40),
    seller_state CHAR(2),
    seller_zip_code_prefix INT
);

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
	order_id CHAR(32) PRIMARY KEY,
    customer_unique_id CHAR(32),
    order_status CHAR(9),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATE,
    CONSTRAINT fk_customer FOREIGN KEY (customer_unique_id) REFERENCES customers (customer_unique_id)
);

DROP TABLE IF EXISTS orders_duration;
CREATE TABLE orders_duration (
	order_id CHAR(32) PRIMARY KEY,
    apporval_time_mins INT,
    carrier_pickup_time_mins INT,
    shipping_time_mins INT,
    total_delivery_time_mins INT,
    order_delay_days INT,
    order_delay_time_mins INT,
    FOREIGN KEY (order_id) REFERENCES orders (order_id)
);

DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
	order_id CHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id CHAR(32),
    seller_id CHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(6, 2),
    freight_value DECIMAL(5, 2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders (order_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers (seller_id)
);

DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
	order_id CHAR(32),
    payment_sequential INT,
    payment_type CHAR(12),
    payment_installments INT,
    payment_value DECIMAL(7, 2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders (order_id)
);