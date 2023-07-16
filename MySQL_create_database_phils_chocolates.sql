-- PHIL MCKECHNIE MySQL PROJECT - PHIL'S CHOCOLATES.
-- Database of mock Australian chocolate supplier orders over three years.

-- STEP 1: Create Database.

DROP DATABASE IF EXISTS phils_chocolates;
CREATE DATABASE phils_chocolates;
USE phils_chocolates;

-- STEP 2: Create customers table and insert values.

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
	customer_id SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    age TINYINT NOT NULL,
    gender ENUM ('Male', 'Female', 'Non-Binary', 'Not Disclosed'),
    city VARCHAR(20) NOT NULL,
    state ENUM ('VIC', 'NSW', 'QLD')
);
    
INSERT INTO customers (first_name, last_name, age, gender, city, state)
VALUES
	('John', 'Smith', 32, 'Male', 'Melbourne', 'VIC'),
    ('Amanda', 'Jones', 44, 'Female', 'Melbourne', 'VIC'),
    ('Cassandra', 'McIntosh', 56, 'Non-Binary', 'Sydney', 'NSW'),
    ('Adam', 'Crenshaw', 27, 'Male', 'Sydney', 'NSW'),
    ('Deborah', 'Shpley', 39, 'Female', 'Brisbane', 'QLD'),
    ('Harry', 'Papadopoulos', 52, 'Male', 'Horsham', 'VIC'),
    ('Emma', 'Templeton', 23, 'Not Disclosed', 'Tamworth', 'NSW'),
    ('Scott', 'Maddison', 40, null, 'Melbourne', 'VIC'),
    ('Byron', 'Jones', 68, 'Male', 'Ipswich', 'QLD'),
    ('Krystal', 'Bailey', 49, 'Female', 'Melbourne', 'VIC'),
    ('David', 'Montgomery', 25, 'Non-Binary', 'Brisbane', 'QLD'),
    ('Elizabeth', 'Scarlett', 35, 'Female', 'Tamworth', 'NSW'),
    ('Michael', 'Thompson', 55, 'Male', 'Sydney', 'NSW'),
    ('Kylie', 'Anderson', 39, 'Female', 'Horsham', 'VIC'),
    ('Jody', 'Franklin', 26, 'Non-Binary', 'Brisbane', 'QLD'),
    ('Martin', 'Reginald', 34, 'Male', 'Sydney', 'NSW'),
    ('Amelia', 'Naughton', 60, null, 'Melbourne', 'VIC'),
    ('Peter', 'Winter', 30, 'Male', 'Tamworth', 'NSW'),
    ('Amelia', 'Shorten', 29, 'Female', 'Melbourne', 'VIC'),
    ('Yasmin', 'Pilbeck', 43, 'Female', 'Leongatha', 'VIC');

-- STEP 3: Create chocolates table and insert values.

DROP TABLE IF EXISTS chocolates;
CREATE TABLE chocolates (
	product_id SMALLINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(20),
    details VARCHAR(255),
    price_aud DECIMAL (6, 2),
    cog_aud DECIMAL (6, 2)
);
	
INSERT INTO chocolates (product_name, details, price_aud, cog_aud)
VALUES
	('delight_bar', 'milk chocolate waffer nuts', 3.50, 1.12),
    ('protein_choc', 'dark chocolate protein nuts mint', 5.50, 1.90),
    ('white_charm', 'white chocolate nougat waffer', 4.20, 1.35),
    ('caramel_krunch', 'milk chocolate caramel sultanas', 3.50, 1.17),
    ('fam_share_tray', 'assorted milk chocolate tray', 15.50, 6.89),
    ('sr8t_up', 'milk chocolate', 3.10, 0.95),
    ('phils_magnus', 'milk chocolate dark chocolate waffer caramel', 4.50, 1.38),
    ('peppermint_swirl', 'dark chocolate waffer mint', 3.20, 1.15),
    ('choc_attack', 'assorted milk dark white chocolate tray', 22.75, 13.10);

-- STEP 4: Create orders table.

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
	order_id VARCHAR(10) NOT NULL,
	order_date DATE NOT NULL,
	customer_id SMALLINT NOT NULL,
	product_id SMALLINT NOT NULL,
	quantity TINYINT,
	FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
	FOREIGN KEY (product_id) REFERENCES chocolates(product_id)
);

-- STEP 5: Find filepath for file upload and change permissions.

SHOW VARIABLES LIKE "secure_file_priv";
SET GLOBAL local_infile = true;

-- STEP 6: Load .csv file data into orders table (.csv file created using website Mockaroo).

LOAD DATA INFILE "C:/.../phils_chocolates_orders_data.csv"
INTO TABLE orders
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Database ready for analysis.