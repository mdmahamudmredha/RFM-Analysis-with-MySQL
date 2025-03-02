-- Explanation video link : https://www.youtube.com/watch?v=MnBbYINMbFc

CREATE DATABASE sales_db; -- CREATE A DATABASE IN MYSQL

USE sales_db; -- INSERT THE ATTACH DATA THERE (PREFERABLY BULK INSERTION)
SELECT COUNT(*) FROM sales;
-- EXPLORE THE DATA AND CHECK IF ALL THE DATA IS IN THE PROPER FORMAT

SET SQL_SAFE_UPDATES = 0;
/* Error Code: 1175. You are using safe update mode and you tried to update a table without a WHERE that uses a KEY column.  To disable safe mode, toggle the option in Preferences -> SQL Editor and reconnect. */


ALTER TABLE sales ADD COLUMN Formated_Order_Date DATE;
-- Order Date Contains Excel Days from 1899-12-30 (For 1900 -> non leaper)

UPDATE sales 
SET 
    Formated_Order_Date = DATE_ADD('1899-12-30',
        INTERVAL `Order Date` DAY);


SELECT * FROM sales LIMIT 100;
-- Date Formated Done.

-- DO THE NECESSARY CLEANING AND UPDATE THE TABLE SCHEMA IF REQUIRED
SELECT * FROM (
    SELECT *, COUNT(*) OVER (PARTITION BY `Customer ID`) AS order_count 
    FROM sales
) t 
; -- Frequency Cheking 

ALTER TABLE sales
MODIFY COLUMN `Order ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Customer ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Sales` DECIMAL(10,2) NOT NULL,
MODIFY COLUMN `Profit` DECIMAL(10,2) NOT NULL;


SELECT COUNT(*) FROM sales;



-- PERFORM EXPLORATORY DATA ANALYSIS
DESC sales; -- Decribe dataset
SELECT COUNT(*) AS Total_Records FROM sales;


-- Missing Value  Check
SELECT 
    COUNT(*) AS Total_Records,
    SUM(CASE WHEN Formated_Order_Date IS NULL THEN 1 ELSE 0 END) AS Missing_Order_Date,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Missing_Sales,
    SUM(CASE WHEN `Customer ID` IS NULL THEN 1 ELSE 0 END) AS Missing_Customer_ID
FROM sales; -- No Missing Value

-- Check Duplicate Recoords
SELECT * 
FROM sales s1
WHERE EXISTS (
    SELECT 1 
    FROM sales s2 
    WHERE s1.`Customer ID` = s2.`Customer ID` AND s1.`Product Name` = s2.`Product Name` AND S1.`ORDER ID`= S2.`ORDER ID`
    GROUP BY s2.`Customer ID`
    HAVING COUNT(*) > 1
);-- Not Exist Duplicate Recoords;


SELECT COUNT(DISTINCT `Customer ID`) AS Unique_Customers FROM sales; -- Total Unique_Customers

SELECT 
    MIN(Sales) AS Min_Sales,
    MAX(Sales) AS Max_Sales,
    ROUND(AVG(Sales)) AS Avg_Sales,
    ROUND(SUM(Sales)) AS Total_Sales
FROM sales; -- Overal Sales


SELECT -- History of Each Customer.
	`Customer ID`,
    `Customer Name`,
    COUNT(*) AS Total_Order,
    MIN(Sales) AS Min_Sales,
    MAX(Sales) AS Max_Sales,
    ROUND(AVG(Sales),0) AS Avg_Sales,
    ROUND(SUM(Sales),0) AS Total_Sales
FROM sales
GROUP BY `Customer ID`, `Customer Name`
ORDER BY Total_Order DESC, Avg_Sales DESC; -- Total_Order 18 te etar use hoise.

SELECT COUNT(*) FROM 
(SELECT -- History of Each Customer.
	`Customer ID`,
    `Customer Name`,
    COUNT(*) AS Total_Item,
    MIN(Sales) AS Min_Sales,
    MAX(Sales) AS Max_Sales,
    ROUND(AVG(Sales),0) AS Avg_Sales,
    ROUND(SUM(Sales),0) AS Total_Sales
FROM sales
GROUP BY `Customer ID`, `Customer Name`
ORDER BY Total_Order DESC, Avg_Sales DESC) p;-- total koita row ekhane asche check korlam

SELECT MIN(Formated_Order_Date) AS FIRST_order_date FROM sales; -- 2010-01-02 FIRST order date
SELECT MAX(Formated_Order_Date) AS last_order_date FROM sales; -- 2013-12-31 Last order date

SELECT COUNT(`ORDER ID`) FROM SALES; -- 9033
SELECT COUNT(DISTINCT `ORDER ID`) FROM SALES; -- 6274


-- FRM Segmentation: 
	-- Segment the customers based opn their Recency(R), Frequency(F), Monetary(M) 
SELECT
	`Customer ID`, 
    `Customer Name`,
    DATEDIFF( (SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS RECENCY_VALUE,
    COUNT(DISTINCT `Order ID`) AS FREQUENCY_VALUUE,
    ROUND(sum(Sales)) AS MONETARY_VALUE
FROM SALES
GROUP BY `Customer ID`, `Customer Name`;
    
    
SELECT * FROM SALES WHERE `CUSTOMER ID`=1008; -- 1316

CREATE OR REPLACE VIEW RFM_SCORE_DATA AS -- VIEW
WITH CUSTOMER_AGGREGATED_DATA AS -- CTE COMMON TABLE EXPRESSION
(SELECT
	`Customer ID`, 
    `Customer Name`,
    DATEDIFF( (SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS RECENCY_VALUE,
    COUNT(DISTINCT `Order ID`) AS FREQUENCY_VALUE,
    ROUND(sum(Sales)) AS MONETARY_VALUE
FROM SALES
GROUP BY `Customer ID`, `Customer Name`),

RFM_SCORE AS
(SELECT
 CAD.*,
	 NTILE(5) OVER (ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
	 NTILE(5) OVER (ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
	 NTILE(5) OVER (ORDER BY MONETARY_VALUE ASC) AS M_SCORE
 FROM CUSTOMER_AGGREGATED_DATA AS CAD)
 
 SELECT 
	RS.* ,
    (R_SCORE + F_SCORE + M_SCORE) AS TOTAL_RFM_SCORE,
    CONCAT_WS('', R_SCORE, F_SCORE,M_SCORE) AS RFM_SCORE_COMBINATION
 FROM RFM_SCORE AS RS;
 
 
 
 -- Labeling
 
 CREATE OR REPLACE VIEW RFM_ANALYSIS AS -- Best fit Labeling 
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


SELECT 
	CUSTOMER_SEGMENT,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS
GROUP BY CUSTOMER_SEGMENT;
	



-- CUSTOMER SEGMENT 2
CREATE OR REPLACE VIEW RFM_ANALYSIS2 AS 
WITH CUSTOMER_AGGREGATED_DATA AS 
(
    SELECT
        `Customer ID`, 
        `Customer Name`,
        DATEDIFF((SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS RECENCY_VALUE,
        COUNT(DISTINCT `Order ID`) AS FREQUENCY_VALUE,
        ROUND(SUM(Sales)) AS MONETARY_VALUE
    FROM SALES
    GROUP BY `Customer ID`, `Customer Name`
),

RFM_SCORE AS
(
    SELECT
        CAD.*,
        NTILE(5) OVER (ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
        NTILE(5) OVER (ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
        NTILE(5) OVER (ORDER BY MONETARY_VALUE ASC) AS M_SCORE
    FROM CUSTOMER_AGGREGATED_DATA AS CAD
)

SELECT 
    RS.* ,
    (R_SCORE + F_SCORE + M_SCORE) AS TOTAL_RFM_SCORE,
    CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION,

    CASE 
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('555', '554', '553', '552', '551') THEN 'Champion Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('543', '542', '541', '532', '531') THEN 'Loyal Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('535', '534', '533', '525', '524', '523') THEN 'Potential Loyalists'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('515', '514', '513', '412', '411') THEN 'Recent Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('421', '422', '423', '321', '322') THEN 'Promising Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('311', '312', '313', '211', '212') THEN 'Needs Attention'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('431', '432', '433', '331', '332') THEN 'About to Sleep'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('221', '222', '223', '121', '122') THEN 'At Risk'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('113', '112', '111') THEN 'Lost Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('511', '522', '531') THEN 'Cannot Lose Them'
        ELSE 'Other'
    END AS CUSTOMER_SEGMENT2

FROM RFM_SCORE AS RS;

SELECT 
	CUSTOMER_SEGMENT2,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS2
GROUP BY CUSTOMER_SEGMENT2;


-- CUSTOMER SEGMENT 3
CREATE OR REPLACE VIEW RFM_ANALYSIS3 AS 
WITH CUSTOMER_AGGREGATED_DATA AS 
(
    SELECT
        `Customer ID`, 
        `Customer Name`,
        DATEDIFF((SELECT MAX(Formated_Order_Date) FROM sales), MAX(Formated_Order_Date)) AS RECENCY_VALUE,
        COUNT(DISTINCT `Order ID`) AS FREQUENCY_VALUE,
        ROUND(SUM(Sales)) AS MONETARY_VALUE
    FROM SALES
    GROUP BY `Customer ID`, `Customer Name`
),

RFM_SCORE AS
(
    SELECT
        CAD.*,
        NTILE(5) OVER (ORDER BY RECENCY_VALUE DESC) AS R_SCORE,
        NTILE(5) OVER (ORDER BY FREQUENCY_VALUE ASC) AS F_SCORE,
        NTILE(5) OVER (ORDER BY MONETARY_VALUE ASC) AS M_SCORE
    FROM CUSTOMER_AGGREGATED_DATA AS CAD
)

SELECT 
    RS.* ,
    (R_SCORE + F_SCORE + M_SCORE) AS TOTAL_RFM_SCORE,
    CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) AS RFM_SCORE_COMBINATION,

    CASE 
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('555', '554', '553') THEN 'Champion Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('552', '551', '543', '542') THEN 'Loyal Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('541', '532', '531') THEN 'Potential Loyalists'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('535', '534', '533', '525') THEN 'Recent Customers - High Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('524', '523', '515', '514', '513') THEN 'Recent Customers - Low Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('512', '511', '421', '422') THEN 'Promising Customers'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('423', '321', '322') THEN 'Need Attention'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('311', '312', '313', '211', '212') THEN 'About to Sleep'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('431', '432', '433', '331', '332') THEN 'At Risk'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('221', '222', '223', '121', '122') THEN 'Lost Customers - High Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('113', '112', '111') THEN 'Lost Customers - Low Value'
        WHEN CONCAT_WS('', R_SCORE, F_SCORE, M_SCORE) IN ('522', '533', '511') THEN 'Cannot Lose Them'
        ELSE 'Other'
    END AS CUSTOMER_SEGMENT3

FROM RFM_SCORE AS RS;


SELECT -- 
	CUSTOMER_SEGMENT3,
    COUNT(*) AS NUMBER_OF_CUSTOMERS,
    ROUND(AVG(MONETARY_VALUE),0) AS AVERAGE_MONETARY_VALUE
FROM RFM_ANALYSIS3
GROUP BY CUSTOMER_SEGMENT3;

    



