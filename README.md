# 🍺 Adolescent Alcohol Abuse Analysis – Oklahoma BRFSS Data Warehouse

## 📌 Project Overview
Designed and implemented a dimensional data warehouse using **BRFSS (Behavioral Risk Factor Surveillance System)** survey data to uncover patterns in adolescent alcohol abuse across Oklahoma. Structured the data into a **star schema** and queried it using SQL to identify high-risk age groups and locations for targeted public health strategies.

> 🎯 *Goal:* Enable data-driven decision-making for alcohol abuse prevention programs by transforming raw public health data into a queryable analytical framework.

---

## 🧰 Tools & Technologies Used
- **MySQL / MySQL Workbench**
- **ERDPlus**
- **SQL** (DDL, DML, JOINs, aggregations)
- **CSV data preprocessing & transformation**

---

## 🧱 Architecture & Features

**✅ Dimensional Modeling (Star Schema)**  
- **Dimension Tables**:  
  - `Location` (County, City)  
  - `Question` (Survey questions)  
  - `Response` (Answer codes)  
  - `Demographics` (Breakouts by gender, race, and age)  
- **Fact Table**: Central BRFSS response data with foreign keys to all dimensions

**✅ ETL Process**
- Cleaned and normalized raw CSV data  
- Built schema and populated tables using SQL  
- Maintained referential integrity and optimized for querying

**✅ Analytical SQL Queries**
- Identified cities and counties with highest alcohol abuse  
- Segmented abuse rates by age groups  
- Produced insights to support intervention strategies

---

## 🔍 Key Insights
- 📍 **Oklahoma City** had the highest abuse rate among **18–24-year-olds**: **56.02%**
- 🧑‍🎓 **25–34** and **18–24** were the most affected age groups overall
- 📊 **Cleveland County** topped county-level abuse rates with **85.41%**

---

## 👩‍💻 Author

**Sruthi Kondra**  
🎓 Master’s in Analytics – Northeastern University  
🔗 [LinkedIn](https://www.linkedin.com/in/sruthi-kondra-5773981a1)

