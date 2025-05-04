-- This query creates a table to store retail transaction data
CREATE TABLE retail_data_raw(
transaction_id INT PRIMARY KEY,
date DATE,
customer_id VARCHAR(10) UNIQUE,
gender VARCHAR(10),
age INT,
product_category VARCHAR(50),
quantity INT,
price_per_unit DECIMAL(10,2),
total_amount DECIMAL(10,2)
);

-- Creating a 'customers' table to store customer-related information.
CREATE TABLE customers(
customer_id VARCHAR(10) PRIMARY KEY,
gender VARCHAR(10),
age INT
);

-- Inserting distinct customer data from the raw table
INSERT INTO customers
SELECT DISTINCT
customer_id,gender,age FROM retail_data_raw;

-- Creating a 'products' table to store product-related information and creating new column product_id.
CREATE TABLE products(
product_id SERIAL PRIMARY KEY, -- Unique ID for each product
product_category VARCHAR(50),
price_per_unit DECIMAL(10,2)
);

-- Inserting data into the products table from retail_data_raw
INSERT INTO products (product_category, price_per_unit)
SELECT DISTINCT product_category, price_per_unit
FROM retail_data_raw;

-- Creating a 'transactions' table.
CREATE TABLE transactions(
transaction_id INT PRIMARY KEY,
date DATE,
customer_id VARCHAR(10),
product_id INT,
quantity INT,
price_per_unit DECIMAL(10,2),
total_amount DECIMAL(10,2),
FOREIGN KEY(customer_id) REFERENCES customers(customer_id),
FOREIGN KEY(product_id) REFERENCES products(product_id)
);

-- Inserting transaction records from the raw table & joining tables for new product_id column.
INSERT INTO transactions(
transaction_id, date, customer_id, product_id,
quantity, price_per_unit, total_amount
)
SELECT
r.transaction_id,
r.date,
r.customer_id,
p.product_id,
r.quantity,
r.price_per_unit,
r.total_amount
FROM retail_data_raw r
JOIN products p
ON r.product_category = p.product_category AND r.price_per_unit = p.price_per_unit;

--Adding product_category column in transactions
ALTER TABLE transactions
ADD COLUMN product_category VARCHAR(50);

UPDATE transactions t
SET product_category = p.product_category
FROM products p
WHERE t.product_id = p.product_id;

-- Total number of transactions made
SELECT COUNT(*) AS total_transactions
FROM retail_data_raw;

-- Sum of all sales amount
SELECT TO_CHAR(SUM(total_amount),'FM999,999,999.00') AS total_sales
FROM retail_data_raw;

-- Gender-wise customer distribution
SELECT gender, COUNT(*) AS count
FROM retail_data_raw
GROUP BY gender;

-- Average age of customers
SELECT ROUND(AVG(age)) AS average_age
FROM retail_data_raw;

-- Monthly-wise sales analysis
SELECT
TO_CHAR(date, 'YYYY-MM') AS monthly_sales,
TO_CHAR(SUM(total_amount), 'FM999,999,999.00') AS total_sales
FROM retail_data_raw
GROUP BY TO_CHAR(date, 'YYYY-MM')
ORDER BY TO_CHAR(date, 'YYYY-MM');

--Product categories that have sales greater than 1000
SELECT product_category
FROM retail_data_raw
GROUP BY product_category
HAVING SUM(total_amount) > 1000;

--maximum quantity per product
SELECT product_category, MAX(quantity) AS max_quantity
FROM transactions
GROUP BY product_category;

--Top 10 customers based on total spend
SELECT
c.customer_id,
SUM(t.total_amount) AS total_spent
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- Gender-wise total spending for each product category
SELECT 
t.product_category,
c.gender,
SUM(t.total_amount) AS total_spent
FROM transactions t
LEFT JOIN customers c ON t.customer_id = c.customer_id
GROUP BY t.product_category, c.gender;

-- Top 5 age groups spending on Clothing using CTE
WITH age_spending AS(
SELECT
CASE
WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
WHEN C.age BETWEEN 36 AND 45 THEN '36-45'
WHEN c.age BETWEEN 46 AND 60 THEN '46-60'
ELSE '60+'
END AS age_group,
t.total_amount
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
WHERE t.product_category = 'Clothing'
)
SELECT age_group,
SUM(total_amount) AS total_spent
FROM age_spending
GROUP BY age_group
ORDER BY total_spent DESC
LIMIT 5;

--Correlation analysis Between cusomer age, spending and product categories.
SELECT
c.age,
t.product_category,
SUM(t.total_amount) AS total_spent
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.age, t.product_category
ORDER BY total_spent DESC;

--Comparing total sales between 2 years (2022 vs 2023)
SELECT
EXTRACT(YEAR FROM date) AS year,
SUM(total_amount) AS total_sales
FROM retail_data_raw
WHERE EXTRACT(YEAR FROM date) IN (2022, 2023)
GROUP BY year
ORDER BY year;

-- Classifying customers based on their total spending, sorted by customer type
WITH customer_spending AS(
SELECT
customer_id,
SUM(total_amount) AS total_spent
FROM transactions
GROUP BY customer_id
)
SELECT
customer_id,
CASE
WHEN total_spent > 500 THEN 'High spender'
ELSE 'Low Spender'
END AS customer_type
FROM customer_spending
ORDER BY customer_type DESC;

-- Use raw data to get average price per unit per category
SELECT 
product_category,
ROUND(AVG(price_per_unit), 2) AS avg_price_per_unit
FROM retail_data_raw
GROUP BY product_category
ORDER BY avg_price_per_unit DESC;

