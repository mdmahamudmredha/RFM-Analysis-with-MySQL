# RFM Segmentation Analysis using MySQL

## Overview
This document provides a detailed explanation of the SQL script used to perform RFM (Recency, Frequency, Monetary) segmentation on a sales dataset. The script includes steps for data cleaning, transformation, exploratory data analysis (EDA), and customer segmentation using the RFM model.

## Video Explanation
For a visual walkthrough of the process, refer to the following video link:  
[YouTube Video](https://www.youtube.com/watch?v=MnBbYINMbFc)

## Steps in the Script

### 1. Database Creation and Data Import
```sql
CREATE DATABASE sales_db;
USE sales_db;
```
- This creates a new database `sales_db` where the sales data will be stored.
- The dataset is assumed to be imported into the `sales` table.

### 2. Data Exploration and Format Check
```sql
SELECT COUNT(*) FROM sales;
```
- Verifies the number of records in the dataset.

### 3. Handling Safe Updates Issue
```sql
SET SQL_SAFE_UPDATES = 0;
```
- Disables safe mode to allow updates on tables without specifying a primary key.

### 4. Formatting the `Order Date`
```sql
ALTER TABLE sales ADD COLUMN Formated_Order_Date DATE;

UPDATE sales
SET Formated_Order_Date = DATE_ADD('1899-12-30', INTERVAL `Order Date` DAY);
```
- The `Order Date` is stored as an Excel date format, which is converted to a proper SQL `DATE` type.

### 5. Data Cleaning and Schema Update
```sql
ALTER TABLE sales
MODIFY COLUMN `Order ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Customer ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Sales` DECIMAL(10,2) NOT NULL,
MODIFY COLUMN `Profit` DECIMAL(10,2) NOT NULL;
```
- Ensures appropriate data types for various fields.

# Exploratory Data Analysis (EDA) with SQL

## 1️⃣ Checking for Missing Values
This query counts the total number of records and checks for missing values in key columns.

```sql
SELECT COUNT(*) AS Total_Records,
    SUM(CASE WHEN Formated_Order_Date IS NULL THEN 1 ELSE 0 END) AS Missing_Order_Date,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Missing_Sales,
    SUM(CASE WHEN `Customer ID` IS NULL THEN 1 ELSE 0 END) AS Missing_Customer_ID
FROM sales;
```

## 2️⃣ Checking for Duplicate Records
This query checks for duplicate records based on Customer ID, Product Name, and Order ID.

```sql
SELECT *
FROM sales s1
WHERE EXISTS (
    SELECT 1
    FROM sales s2
    WHERE s1.`Customer ID` = s2.`Customer ID`
        AND s1.`Product Name` = s2.`Product Name`
        AND s1.`Order ID` = s2.`Order ID`
    GROUP BY s2.`Customer ID`
    HAVING COUNT(*) > 1
);
```

## 3️⃣ Key Sales Metrics
This query calculates minimum, maximum, average, and total sales.

```sql
SELECT MIN(Sales) AS Min_Sales,
       MAX(Sales) AS Max_Sales,
       ROUND(AVG(Sales)) AS Avg_Sales,
       ROUND(SUM(Sales)) AS Total_Sales
FROM sales;
```

## 4️⃣ Identifying Top & Bottom Customers
### 🏆 Top Spending Customer
```sql
SELECT `Customer ID`, ROUND(SUM(Sales), 2) AS Total_Spent
FROM sales
GROUP BY `Customer ID`
ORDER BY Total_Spent DESC
LIMIT 1;
```
### 🏅 Lowest Spending Customer
```sql
SELECT `Customer ID`, ROUND(SUM(Sales), 2) AS Total_Spent
FROM sales
GROUP BY `Customer ID`
ORDER BY Total_Spent ASC
LIMIT 1;
```

## 5️⃣ Most & Least Sold Products
### 📈 Best-Selling Product
```sql
SELECT `Product Name`, COUNT(*) AS Total_Sales
FROM sales
GROUP BY `Product Name`
ORDER BY Total_Sales DESC
LIMIT 1;
```
### 📉 Least Sold Product
```sql
SELECT `Product Name`, COUNT(*) AS Total_Sales
FROM sales
GROUP BY `Product Name`
ORDER BY Total_Sales ASC
LIMIT 1;
```

## 6️⃣ Sales Distribution by Region
```sql
SELECT `Region`, COUNT(*) AS Total_Orders, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY `Region`
ORDER BY Total_Sales DESC;
```

## 7️⃣ Sales Performance by Manager
```sql
SELECT `Manager`, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY `Manager`
ORDER BY Total_Sales DESC;
```

## 8️⃣ Customers Who Returned Products
```sql
SELECT `Customer ID`, COUNT(*) AS Total_Returns
FROM sales
WHERE `Return` = 'Yes'
GROUP BY `Customer ID`
ORDER BY Total_Returns DESC;
```
*If there is no Return column, check for an alternative field like Order Status or Returned Order.*

## 9️⃣ Regional Sales in Descending Order
```sql
SELECT `Region`, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY `Region`
ORDER BY Total_Sales DESC;
```

## 🕐 Yearly Sales Performance
```sql
SELECT YEAR(Formated_Order_Date) AS Year, ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY Year
ORDER BY Year;
```

## 1️⃣1️⃣ Monthly Sales Performance
```sql
SELECT YEAR(Formated_Order_Date) AS Year,
       MONTH(Formated_Order_Date) AS Month,
       ROUND(SUM(Sales), 2) AS Total_Sales
FROM sales
GROUP BY Year, Month
ORDER BY Year, Month;
```

## 1️⃣2️⃣ Number of Orders per Customer
```sql
SELECT `Customer ID`, COUNT(`Order ID`) AS Total_Orders
FROM sales
GROUP BY `Customer ID`
ORDER BY Total_Orders DESC;
```



### 7. RFM Segmentation
The RFM model assigns a score based on:
- **Recency (R):** How recently a customer made a purchase.
- **Frequency (F):** How often a customer makes a purchase.
- **Monetary (M):** How much the customer spends.

```sql
CREATE OR REPLACE VIEW RFM_SCORE_DATA AS
WITH CUSTOMER_AGGREGATED_DATA AS (
    SELECT `Customer ID`, `Customer Name`,
           DATEDIFF((SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS RECENCY_VALUE,
           COUNT(DISTINCT `Order ID`) AS FREQUENCY_VALUE,
           ROUND(SUM(Sales)) AS MONETARY_VALUE
    FROM sales
    GROUP BY `Customer ID`, `Customer Name`
),
RFM_SCORE AS (
    SELECT CAD.*,
           NTILE(5) OVER (ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
           NTILE(5) OVER (ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
           NTILE(5) OVER (ORDER BY MONETARY_VALUE ASC) AS M_SCORE
    FROM CUSTOMER_AGGREGATED_DATA AS CAD
)
SELECT RS.*, (R_SCORE + F_SCORE + M_SCORE) AS TOTAL_RFM_SCORE,
       CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION
FROM RFM_SCORE AS RS;
```

### 8. Customer Segmentation Based on RFM Scores
```sql

 CREATE OR REPLACE VIEW RFM_ANALYSIS AS
 SELECT 
 rfm_score_data.*,
 CASE 
    -- ✅ Best Customers: Highly Engaged, Spends More, Very Recent
    WHEN R_SCORE = 5 AND F_SCORE = 5 AND M_SCORE = 5 THEN 'Champion Customers'
    WHEN R_SCORE >= 4 AND F_SCORE >= 4 AND M_SCORE >= 4 THEN 'Loyal Customers'

    -- 🚀 Growing Customers: Engaged & Spending Well, But Slightly Less Recent
    WHEN R_SCORE >= 3 AND F_SCORE >= 4 AND M_SCORE >= 3 THEN 'Potential Loyalists'
    WHEN R_SCORE = 5 AND (F_SCORE BETWEEN 3 AND 4) AND (M_SCORE BETWEEN 3 AND 4) THEN 'New Champions'
    
    -- 🎯 Recent Buyers: Bought Recently, But Low Spending & Frequency
    WHEN R_SCORE >= 4 AND F_SCORE <= 2 AND M_SCORE <= 2 THEN 'Recent Customers'
    WHEN R_SCORE = 5 AND F_SCORE BETWEEN 1 AND 2 AND M_SCORE BETWEEN 1 AND 2 THEN 'New Buyers'
    
    -- 📈 Medium Engagement: Good Buyers but Not Consistent
    WHEN R_SCORE >= 2 AND F_SCORE >= 3 AND M_SCORE >= 2 THEN 'Promising Customers'
    WHEN R_SCORE BETWEEN 3 AND 4 AND F_SCORE BETWEEN 2 AND 3 AND M_SCORE BETWEEN 2 AND 3 THEN 'Potential Promising Customers'
    
    -- 🔥 Engaged but Low Spending
    WHEN F_SCORE >= 4 AND M_SCORE <= 3 THEN 'Frequent But Low Spenders'
    WHEN F_SCORE >= 4 AND M_SCORE >= 4 THEN 'Big Spenders'
    
    -- ⚠️ Warning Zone: Low Engagement, Less Frequency, Low Spending
    WHEN R_SCORE <= 2 AND F_SCORE <= 2 AND M_SCORE <= 2 THEN 'At Risk'
    WHEN R_SCORE BETWEEN 2 AND 3 AND F_SCORE <= 2 AND M_SCORE <= 2 THEN 'About to Lose'
    
    -- ❌ Lost Customers: Very Low Interaction, No Recent Purchase
    WHEN R_SCORE = 1 AND F_SCORE = 1 AND M_SCORE = 1 THEN 'Lost Customers'
    WHEN R_SCORE = 1 AND (F_SCORE BETWEEN 1 AND 2) AND (M_SCORE BETWEEN 1 AND 2) THEN 'Inactive Customers'

    ELSE 'Other'
END AS CUSTOMER_SEGMENT
FROM rfm_score_data;


```

### 9. Summary of Customer Segments
```sql

SELECT 
	CUSTOMER_SEGMENT,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS
GROUP BY CUSTOMER_SEGMENT;
```

## Conclusion
- The script successfully implements RFM segmentation in MySQL.
- It categorizes customers based on their purchasing behavior.
- The segmentation helps businesses target different customer groups effectively.

---
### Notes:
- Ensure the dataset is clean before running the queries.
- Modify segmentation rules based on business needs.
- The `NTILE(5)` function divides the dataset into 5 equal groups, but this can be adjusted.

For further understanding, refer to the [YouTube Video](https://www.youtube.com/watch?v=MnBbYINMbFc).

