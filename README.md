# 🧮 RFM Segmentation Analysis using MySQL

## 🎥 Video Walkthrough

* 📺 **Full SQL + Concept Explanation (For Learners)**: [Watch Here](https://www.youtube.com/watch?v=MnBbYINMbFc)

## 📌 Project Overview

This project demonstrates how to use MySQL for performing **RFM Segmentation** — a marketing analytics technique to categorize customers based on their purchase behavior. By analyzing **Recency**, **Frequency**, and **Monetary** value, businesses can identify and target high-value customers.

## 🎯 Problem Statement

A retail business wants to segment its customers to improve marketing strategies. The goal is to classify customers into segments like loyal, potential, or at-risk based on their latest purchase date, number of purchases, and spending amount.

## 🧠 Objective

* Extract actionable customer segments using RFM metrics.
* Help businesses optimize marketing strategies and retain high-value customers.
* Implement the entire pipeline using SQL (without external tools).

## 🧾 Dataset

The project uses a sales dataset with key fields like:

* `Order Date` (stored in Excel format)
* `Customer ID`
* `Sales`
* `Order ID`
* `Profit`

## 🧪 Step-by-Step SQL Implementation

### 1. 📂 Database Creation and Data Import

```sql
CREATE DATABASE sales_db;
USE sales_db;
```

* Creates a dedicated database and loads the sales table.

### 2. 📊 Data Exploration

```sql
SELECT COUNT(*) FROM sales;
```

* Checks the volume of data to ensure successful import.

### 3. ⚙️ Handling Safe Updates

```sql
SET SQL_SAFE_UPDATES = 0;
```

* Allows updates without strict primary key constraints.

### 4. 📅 Order Date Formatting

```sql
ALTER TABLE sales ADD COLUMN Formated_Order_Date DATE;

UPDATE sales
SET Formated_Order_Date = DATE_ADD('1899-12-30', INTERVAL `Order Date` DAY);
```

* Converts Excel date serials to proper SQL `DATE`.

### 5. 🧹 Data Cleaning and Type Conversion

```sql
ALTER TABLE sales
MODIFY COLUMN `Order ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Customer ID` VARCHAR(50) NOT NULL,
MODIFY COLUMN `Sales` DECIMAL(10,2) NOT NULL,
MODIFY COLUMN `Profit` DECIMAL(10,2) NOT NULL;
```

### 6. 🧠 RFM Metric Calculation

```sql
-- Set today's date
SET @today = '2022-12-31';

-- Create RFM table
CREATE TABLE rfm_table AS
SELECT 
  `Customer ID`,
  DATEDIFF(@today, MAX(Formated_Order_Date)) AS Recency,
  COUNT(DISTINCT `Order ID`) AS Frequency,
  SUM(Sales) AS Monetary
FROM sales
GROUP BY `Customer ID`;
```

### 7. 🧮 Assigning RFM Scores (1 to 4 scale)

```sql
ALTER TABLE rfm_table
ADD COLUMN R_Score INT,
ADD COLUMN F_Score INT,
ADD COLUMN M_Score INT;

-- Recency: lower is better (1 = worst, 4 = best)
UPDATE rfm_table
SET R_Score = CASE
    WHEN Recency <= 30 THEN 4
    WHEN Recency <= 90 THEN 3
    WHEN Recency <= 180 THEN 2
    ELSE 1
END;

-- Frequency: higher is better
UPDATE rfm_table
SET F_Score = CASE
    WHEN Frequency >= 15 THEN 4
    WHEN Frequency >= 10 THEN 3
    WHEN Frequency >= 5 THEN 2
    ELSE 1
END;

-- Monetary: higher is better
UPDATE rfm_table
SET M_Score = CASE
    WHEN Monetary >= 5000 THEN 4
    WHEN Monetary >= 1000 THEN 3
    WHEN Monetary >= 500 THEN 2
    ELSE 1
END;
```

### 8. 🔖 Customer Segment Tagging

```sql
ALTER TABLE rfm_table
ADD COLUMN Segment VARCHAR(50);

UPDATE rfm_table
SET Segment = CASE
    WHEN R_Score = 4 AND F_Score = 4 AND M_Score = 4 THEN 'Champions'
    WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers'
    WHEN R_Score >= 3 AND F_Score <= 2 THEN 'Potential Loyalist'
    WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk'
    ELSE 'Others'
END;
```

## 📈 Key Findings

* Identified customer segments like **Champions**, **Loyal Customers**, and **At Risk**.
* Allowed business to tailor marketing strategies based on segment behavior.
* Clean, scalable SQL-only implementation — no need for Python/R tools.

## 🛠 Technologies Used

* MySQL
* Excel (for initial dataset)
* SQL Queries (No-Code Analytics)

## 📚 Learnings

* Learned end-to-end implementation of **RFM Segmentation** using SQL.
* Practiced SQL data cleaning, transformation, and CASE logic.
* Applied advanced SQL features like `DATEDIFF`, `CASE`, and group-level aggregation.

## 💼 Use Cases

* Customer retention strategies
* Marketing analytics
* E-commerce customer targeting

## 🚀 How to Run

1. Open MySQL Workbench or any SQL IDE.
2. Run the script `RFM_SEGMENTATION.sql`.
3. Query `rfm_table` to explore customer segments.

## 🤝 Contact

Made by Md. Mahamud Mredha – feel free to connect:

* LinkedIn: [https://www.linkedin.com/in/md-mahamud-mredha-294046208/](https://www.linkedin.com/in/md-mahamud-mredha-294046208/)
* GitHub: [https://github.com/mdmahamudmredha](https://github.com/mdmahamudmredha)
* YouTube: [![YouTube](https://img.shields.io/badge/YouTube-Dropout_Programmer-red?style=for-the-badge\&logo=youtube)](https://www.youtube.com/@DropoutProgrammer)

---

> "Know your customers. Segment with SQL. Sell smarter."

