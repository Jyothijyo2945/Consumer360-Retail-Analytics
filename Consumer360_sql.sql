CREATE DATABASE retail_db;
USE retail_db;

-- WEEK 1 – SQL DATA ENGINEERING & CLEANSING
-- Step 1. Store raw unprocessed transaction logs

CREATE TABLE retail_sales (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    Price DECIMAL(10,2),
    CustomerID VARCHAR(20),
    Country VARCHAR(50)
);
select * from retail_sales;

-- Step 2. Data Cleaning
-- 1. Clean and standardize raw transaction data

Create table retail_sales_cleaned as
select InvoiceNo, StockCode , 
-- Standardize product descriptions
trim(Description) as Description,
Quantity,
-- Convert string date to DATETIME
str_to_date(InvoiceDate, '%Y-%m-%d %H:%i:%s') as InvoiceDate,
Price,
-- Standardize missing customer IDs
nullif(CustomerID, "") as CustomerID,
Country 
from retail_sales
where
   Quantity > 0 and Price > 0 and InvoiceNo not like 'C%';
   
select * from retail_sales_cleaned;

-- STEP 3: STAR SCHEMA
-- Customer dimension for segmentation & CLV
create table dim_customer (
    CustomerID varchar(20) not null,
    Country VARCHAR(50),
    PRIMARY KEY (CustomerID)
);

INSERT INTO dim_customer
SELECT DISTINCT
    CustomerID,
    Country
FROM retail_sales_cleaned
WHERE CustomerID IS NOT NULL;

select * from dim_customer;


-- Product dimension for product analytics

CREATE TABLE dim_product (
    StockCode VARCHAR(20) NOT NULL,
    Description TEXT,
    PRIMARY KEY (StockCode)
);


INSERT INTO dim_product (StockCode, Description)
SELECT
    StockCode,
    MIN(Description) AS Description
FROM retail_sales_cleaned
GROUP BY StockCode;

select * from dim_product;

-- Central fact table for all sales analytics
CREATE TABLE fact_sales (
    SalesID INT AUTO_INCREMENT PRIMARY KEY,
    InvoiceNo VARCHAR(20),
    CustomerID VARCHAR(20),
    StockCode VARCHAR(20),
    InvoiceDate DATETIME,
    Quantity INT,
    Price DECIMAL(10,2),
    Sales_Amount DECIMAL(12,2),

    CONSTRAINT fk_customer
        FOREIGN KEY (CustomerID)
        REFERENCES dim_customer(CustomerID),

    CONSTRAINT fk_product
        FOREIGN KEY (StockCode)
        REFERENCES dim_product(StockCode)
);

INSERT INTO fact_sales (
    InvoiceNo,
    CustomerID,
    StockCode,
    InvoiceDate,
    Quantity,
    Price,
    Sales_Amount
)
SELECT
    InvoiceNo,
    CustomerID,
    StockCode,
    InvoiceDate,
    Quantity,
    Price,
    Quantity * Price
FROM retail_sales_cleaned
WHERE CustomerID IS NOT NULL;


select * from fact_sales;


-- Step 4 : Core Business Metrics
-- calculate Total Revenue
select sum(sales_amount) as total_revenue from fact_sales;

-- Calculate Total Orders
select count(distinct InvoiceNo) as total_orders from fact_sales;

-- Calculate Total Customers
select count(distinct CustomerID) as total_customers from  fact_sales;

-- STEP 4: Top-Selling Products
select p.description, sum(f.sales_amount) as Revenue
from fact_sales f 
join dim_product p
    on f.stockcode = p.stockcode 
group by p.description
order by revenue desc
limit 10;

-- Step 5: Sales by Country
select c.country, sum(f.sales_amount) as country_revenue
from fact_sales f 
join dim_customer c
    on f.customerID = c.customerID
group by c.country
order by country_revenue desc;

-- Step 6: RFM TABLE
-- create and calculate Recency,frequency,monetary values 
create table rfm_table as
select
CustomerID,
datediff(curdate(), max(Invoicedate)) as Recency,  -- Calculate Recency
count(distinct invoiceno) as Frequency,      -- Calculate Frequency
sum(Sales_Amount) as Monetary      -- Calculate Monetary
from fact_sales
group by customerId;

select * from rfm_table;

select * from rfm_customer_segments;
SELECT COUNT(*) FROM rfm_customer_segments;



   



