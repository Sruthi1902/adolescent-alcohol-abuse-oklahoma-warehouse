-- The below query creates a new database (schema) named "OK_BRFSS_Survey"
CREATE DATABASE OK_BRFSS_Survey;

-- The below query displays all available databases on the server
SHOW DATABASES;

-- The below query selects and sets "OK_BRFSS_Survey" as the active database for subsequent operations
USE OK_BRFSS_Survey;

-- The below query (commented out) is used to permanently delete the "OK_BRFSS_Survey" database from the server.
-- DROP DATABASE OK_BRFSS_Survey;

-- This query creates a staging table for initial survey data related to alcohol consumption in Oklahoma.
CREATE TABLE OK_BRFSS_Survey (
    survey_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique identifier for each survey response (Auto-incrementing primary key)
    question_text VARCHAR(255), -- The survey question asked (Limited to 255 characters)
    response VARCHAR(30) CHECK (response IN ('Yes', 'No')), -- Response to the question (Only "Yes" or "No" allowed)
    break_out VARCHAR(100), -- General category of respondent demographics (e.g., "Household Income")
    break_out_category VARCHAR(100), -- Specific demographic category (e.g., "$15,000-$24,999")
    sample_size INT, -- Total number of respondents who answered the survey question
    data_value INT, -- Number of respondents who answered "Yes"
    zipcode VARCHAR(10) -- Zip code of the respondent
);

-- Retrieve all records from the 'OK_BRFSS_Survey' table to verify that data has been imported successfully.
SELECT * FROM OK_BRFSS_Survey; -- Displays the contents of the table.

-- This query creates a staging table for demographic data specific to Oklahoma, including zip code, city, and county.
CREATE TABLE Demographics_OK (
    zipcode VARCHAR(10) PRIMARY KEY, -- Unique zip code as primary key
    city VARCHAR(100), -- City corresponding to the zip code
    county VARCHAR(100) -- County corresponding to the zip code
);

-- Retrieve all records from the 'Demographics_OK' table to verify that data has been imported successfully
SELECT * FROM Demographics_OK; -- Displays the contents of the table.

-- This query creates a staging table for general demographic data covering all US locations, including zip code, city, and county.
CREATE TABLE Demographics (
    zipcode VARCHAR(10) PRIMARY KEY, -- Unique zip code as primary key
    city VARCHAR(100), -- City corresponding to the zip code
    county VARCHAR(100) -- County corresponding to the zip code
);

-- Retrieve all records from the 'Demographics' table to verify that data has been imported successfully.
SELECT * FROM Demographics; -- Displays the contents of the table.

-- We have successfully loaded the raw survey data. 
-- Now, we are creating dimension tables to reduce redundancy and improve query performance by normalizing the dataset

-- Creating the Question Dimension Table
-- This table stores unique survey questions with an auto-increment primary key.
CREATE TABLE Question_Dim (
    question_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique ID for each question
    question_text VARCHAR(255) -- Stores the survey question text
);

-- Insert distinct questions from the OK_BRFSS_Survey table into Question_Dim
INSERT INTO Question_Dim (question_text)
SELECT DISTINCT question_text FROM OK_BRFSS_Survey;

-- Display all entries in the Question_Dim table to verify data insertion
SELECT * FROM Question_Dim;


-- Creating the Response Dimension Table
-- This table stores survey response options ("Yes" or "No") with an auto-increment primary key.
CREATE TABLE Response_Dim (
    response_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique ID for each response
    response VARCHAR(30) CHECK (response IN ('Yes', 'No')) -- Stores response values
);

-- Insert distinct responses from OK_BRFSS_Survey into Response_Dim
INSERT INTO Response_Dim (response)
SELECT DISTINCT response FROM OK_BRFSS_Survey;

-- Display all entries in the Response_Dim table to verify data insertion
SELECT * FROM Response_Dim;


-- Creating the Location Dimension Table
-- This table stores geographic details like city and county, using zip code as the primary key.
CREATE TABLE Location_Dim (
    zipcode VARCHAR(10) PRIMARY KEY, -- Unique identifier for location
    city VARCHAR(100), -- City associated with the zip code
    county VARCHAR(100) -- County associated with the zip code
);

-- Insert distinct location data from both Demographics_OK and Demographics into Location_Dim
INSERT INTO Location_Dim (zipcode, city, county)
SELECT DISTINCT zipcode, city, county FROM (
    SELECT zipcode, city, county FROM Demographics_OK
    UNION
    SELECT zipcode, city, county FROM Demographics
) AS combined_locations;

-- Display count of all entries in Location_Dim to confirm data insertion
SELECT COUNT(*) FROM Location_Dim;


-- Creating the Breakout Dimension Table
-- This table categorizes respondents based on demographic groups like income or age.
CREATE TABLE Breakout_Dim (
    break_out_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique ID for each breakout category
    break_out_type VARCHAR(100) -- Type of breakout (e.g., "Household Income", "Age Group")
);

-- Insert distinct breakout types from OK_BRFSS_Survey into Breakout_Dim
INSERT INTO Breakout_Dim (break_out_type)
SELECT DISTINCT break_out FROM OK_BRFSS_Survey;

-- Display all entries in the Breakout_Dim table to verify data insertion
SELECT * FROM Breakout_Dim;


-- Creating the Breakout Category Dimension Table
-- This table stores specific demographic values within breakout types.
CREATE TABLE Breakout_Category_Dim (
    break_out_category_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique ID for each breakout category
    break_out_category VARCHAR(100) -- Specific demographic category (e.g., "$15,000-$24,999")
);

-- Insert distinct breakout categories from OK_BRFSS_Survey into Breakout_Category_Dim
INSERT INTO Breakout_Category_Dim (break_out_category)
SELECT DISTINCT break_out_category FROM OK_BRFSS_Survey;

-- Display all entries in the Breakout_Category_Dim table to verify data insertion
SELECT * FROM Breakout_Category_Dim;


-- Creating the Fact Table (BRFSS_Survey_Fact)
-- This table stores the actual survey responses, linking to all dimension tables.
CREATE TABLE BRFSS_Survey_Fact (
    survey_id INT PRIMARY KEY AUTO_INCREMENT, -- Unique ID for each survey response
    zipcode VARCHAR(10), -- Foreign key linking to Location_Dim
    question_id INT, -- Foreign key linking to Question_Dim
    response_id INT, -- Foreign key linking to Response_Dim
    break_out_id INT, -- Foreign key linking to Breakout_Dim
    break_out_category_id INT, -- Foreign key linking to Breakout_Category_Dim
    sample_size INT, -- Total respondents for the survey question
    data_value INT, -- Number of respondents who answered "Yes"
    FOREIGN KEY (zipcode) REFERENCES Location_Dim (zipcode),
    FOREIGN KEY (question_id) REFERENCES Question_Dim (question_id),
    FOREIGN KEY (response_id) REFERENCES Response_Dim (response_id),
    FOREIGN KEY (break_out_id) REFERENCES Breakout_Dim (break_out_id),
    FOREIGN KEY (break_out_category_id) REFERENCES Breakout_Category_Dim (break_out_category_id)
);

-- Insert data into the Fact Table by joining staging and dimension tables
INSERT INTO BRFSS_Survey_Fact (zipcode, question_id, response_id, break_out_id, break_out_category_id, sample_size, data_value)
SELECT 
    l.zipcode, 
    q.question_id, 
    r.response_id, 
    bo.break_out_id, 
    boc.break_out_category_id, 
    bs.sample_size, 
    bs.data_value 
FROM 
    OK_BRFSS_Survey bs
    JOIN Location_Dim l ON bs.zipcode = l.zipcode
    JOIN Question_Dim q ON bs.question_text = q.question_text
    JOIN Response_Dim r ON bs.response = r.response
    JOIN Breakout_Dim bo ON bs.break_out = bo.break_out_type
    JOIN Breakout_Category_Dim boc ON bs.break_out_category = boc.break_out_category;

-- Display all entries from the Fact Table to verify data insertion
SELECT * FROM BRFSS_Survey_Fact;

-- The below queries drop staging tables after data has been successfully transferred into the dimensional model
DROP TABLE OK_BRFSS_Survey;
DROP TABLE Demographics_OK;
DROP TABLE Demographics;

------------------------------------------------------------------------

-- Question 1 :Find the areas of Oklahoma with the highest and lowest percent
-- of respondents for adolescent alcohol abuse.

-- Query to identify adolescent age groups at the highest risk for alcohol abuse.
-- This calculates the alcohol abuse percentage for each age group by dividing 
-- the total number of positive responses by the total number of participants.

SELECT 
    boc.break_out_category AS demographic_group, -- General category like "Age Group"
    bo.break_out_type AS age_group, -- Specific age range like "18-24"
    SUM(bsf.data_value) AS total_people_responded, -- Total people who reported alcohol abuse
    SUM(bsf.sample_size) AS total_participants, -- Total number of respondents
    CASE 
        WHEN SUM(IFNULL(bsf.sample_size, 0)) = 0 THEN 0 -- Avoid division by zero
        ELSE ((SUM(IFNULL(bsf.data_value, 0)) / SUM(IFNULL(bsf.sample_size, 0))) * 100)
    END AS adolescent_alcohol_abuse_ratio -- Percentage of alcohol abuse cases
FROM 
    BRFSS_Survey_Fact bsf
    JOIN Breakout_Dim bo ON bsf.break_out_id = bo.break_out_id 
    JOIN Breakout_Category_Dim boc ON bsf.break_out_category_id = boc.break_out_category_id
WHERE 
    boc.break_out_category = 'Age Group' -- Ensuring we filter correctly
GROUP BY 
    boc.break_out_category, bo.break_out_type -- Group by category and specific age range
ORDER BY 
    adolescent_alcohol_abuse_ratio DESC; -- Display from highest to lowest


-- Question 2  :Find the areas of Oklahoma with the highest and lowest percent 
-- of respondents for adolescent alcohol abuse by city

-- Query to identify cities in Oklahoma with the highest and lowest adolescent alcohol abuse percentages.
-- This calculates the alcohol abuse ratio per city by dividing the total number of positive responses 
-- by the total number of participants in that city.

SELECT 
    ld.city, -- City in Oklahoma
    SUM(bsf.data_value) AS total_people_responded, -- Total people who reported alcohol abuse
    SUM(bsf.sample_size) AS total_participants, -- Total number of respondents
    CASE 
        WHEN SUM(IFNULL(bsf.sample_size, 0)) = 0 THEN 0 -- Avoid division by zero
        ELSE ((SUM(IFNULL(bsf.data_value, 0)) / SUM(IFNULL(bsf.sample_size, 0))) * 100)
    END AS adolescent_alcohol_abuse_ratio -- Percentage of alcohol abuse cases
FROM 
    BRFSS_Survey_Fact bsf
    JOIN Location_Dim ld ON bsf.zipcode = ld.zipcode -- Joining with location dimension table
    JOIN Breakout_Dim bo ON bsf.break_out_id = bo.break_out_id
    JOIN Breakout_Category_Dim boc ON bsf.break_out_category_id = boc.break_out_category_id
WHERE 
    boc.break_out_category = 'Age Group' -- Ensuring we filter only for age group data
    AND bo.break_out_type = '18-24' -- Filtering for respondents aged 18-24
GROUP BY 
    ld.city -- Grouping by city to get city-wise percentage
ORDER BY 
    adolescent_alcohol_abuse_ratio DESC; -- Display from highest to lowest

-- Question 3: Find the areas of Oklahoma with the highest and lowest percent 
-- of respondents for adolescent alcohol abuse by county

-- Query to identify counties in Oklahoma with the highest and lowest adolescent alcohol abuse percentages.
-- This calculates the alcohol abuse ratio per county by dividing the total number of positive responses 
-- by the total number of participants in that county.

SELECT 
    ld.county, -- County in Oklahoma
    SUM(bsf.data_value) AS total_people_responded, -- Total people who reported alcohol abuse
    SUM(bsf.sample_size) AS total_participants, -- Total number of respondents
    CASE 
        WHEN SUM(IFNULL(bsf.sample_size, 0)) = 0 THEN 0 -- Avoid division by zero
        ELSE ((SUM(IFNULL(bsf.data_value, 0)) / SUM(IFNULL(bsf.sample_size, 0))) * 100)
    END AS adolescent_alcohol_abuse_ratio -- Percentage of alcohol abuse cases
FROM 
    BRFSS_Survey_Fact bsf
    JOIN Location_Dim ld ON bsf.zipcode = ld.zipcode -- Joining with location dimension table
    JOIN Breakout_Dim bo ON bsf.break_out_id = bo.break_out_id
    JOIN Breakout_Category_Dim boc ON bsf.break_out_category_id = boc.break_out_category_id
WHERE 
    boc.break_out_category = 'Age Group' -- Ensuring we filter only for age group data
    AND bo.break_out_type = '18-24' -- Filtering for respondents aged 18-24
GROUP BY 
    ld.county -- Grouping by county to get county-wise percentage
ORDER BY 
    adolescent_alcohol_abuse_ratio DESC; -- Display from highest to lowest
