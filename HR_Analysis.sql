# CREATE A DATABASE
CREATE DATABASE hr_attrition_analysis;

# USE THE DATABASE
USE hr_attrition_analysis;

SELECT * FROM hr_employee_attrition;

ALTER TABLE hr_employee_attrition RENAME COLUMN 
`Age1` TO `Age`;

-- 1. Total employees, attritude_employees and attrition_rate

SELECT 
	COUNT(*) total_employees,
    SUM((CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)) attritude_employees,
    ROUND(SUM((CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END))*100/COUNT(*),2) attrition_rate
FROM hr_employee_attrition;

-- 2. Remove outliers

SELECT 
	AGE, MonthlyIncome 
FROM hr_employee_attrition
WHERE AGE < 18 OR AGE > 65 OR MonthlyIncome = 0;

-- 3. Create Age group

SELECT *,
	CASE
		WHEN AGE BETWEEN 18 AND 25 THEN '18-25'
        WHEN AGE BETWEEN 26 AND 35 THEN '26-35'
        WHEN AGE BETWEEN 36 AND 45 THEN '36-45'
        WHEN AGE BETWEEN 46 AND 55 THEN '46-55'
        WHEN AGE > 55 THEN '55+'
        END AS Age_Group
FROM hr_employee_attrition
ORDER BY Age ASC
;
ALTER TABLE hr_employee_attrition ADD Age_Group char(10);

UPDATE hr_employee_attrition 
SET Age_Group = CASE
		WHEN AGE BETWEEN 18 AND 25 THEN '18-25'
        WHEN AGE BETWEEN 26 AND 35 THEN '26-35'
        WHEN AGE BETWEEN 36 AND 45 THEN '36-45'
        WHEN AGE BETWEEN 46 AND 55 THEN '46-55'
        WHEN AGE > 55 THEN '55+'
        END;
# Create salary bands
SELECT *,
	CASE
		WHEN MonthlyIncome BETWEEN 1009 AND 3000 THEN 'Entry-Level'
        WHEN MonthlyIncome BETWEEN 3001 AND 10000 THEN 'Mid-Level'
        WHEN MonthlyIncome > 10001 THEN 'Senior-Level'
        
	END Salary_Band
        
 FROM hr_employee_attrition;
 
 ALTER TABLE hr_employee_attrition ADD Salary_Band VARCHAR(20);

UPDATE hr_employee_attrition 
SET Salary_Band = CASE
		WHEN MonthlyIncome BETWEEN 1009 AND 3000 THEN 'Entry-Level'
        WHEN MonthlyIncome BETWEEN 3001 AND 10000 THEN 'Mid-Level'
        WHEN MonthlyIncome > 10001 THEN 'Senior-Level'
        
	END;
SELECT * FROM hr_employee_attrition;

-- 1. What is the overall attrition rate, and how many employees left the company?

SELECT COUNT(*) AS Total_Employees, 
	SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attritude_Employees,
    ROUND((SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)/COUNT(*)*100),2) AS Attrition_Rate
 FROM hr_employee_attrition;

-- 2. Which departments have the highest attrition rates, and are there specific roles within those departments that are most affected?

SELECT 
	Department, JobRole, COUNT(*) Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attritude_Employees,
    ROUND((SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)/COUNT(*)*100),2) AS Attrition_Rate
	FROM hr_employee_attrition
GROUP BY Department, JobRole
ORDER BY Attritude_Employees DESC, Attrition_Rate DESC;

-- 3. How does salary level (Entry/Mid/Senior) correlate with attrition rates? Are we losing people due to compensation issues?

SELECT Salary_Band, COUNT(*) Total_Employees,
		SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) Attritude_Employees,
        ROUND(SUM((CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END))/COUNT(*)*100,2) AS Attrition_Rate
        FROM hr_employee_attrition
GROUP BY Salary_Band 
ORDER BY Attrition_Rate DESC;

-- 4. Which age groups show the highest attrition rates, and what does this tell us about our workforce stability?
SELECT Age_Group, COUNT(*) Total_Employees,
		SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) Attritude_Employees,
        ROUND(SUM((CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END))/COUNT(*)*100,2) AS Attrition_Rate
        FROM hr_employee_attrition
GROUP BY Age_Group 
ORDER BY Attrition_Rate DESC;
-- 5. At what stage of employment (tenure category) are we losing the most employees?

SELECT CASE 
        WHEN YearsAtCompany < 2 THEN 'New Hire (0-2 years)'
        WHEN YearsAtCompany BETWEEN 2 AND 5 THEN 'Experienced (2-5 years)'
        WHEN YearsAtCompany BETWEEN 6 AND 10 THEN 'Veteran (6-10 years)'
        WHEN YearsAtCompany > 10 THEN 'Long-term (10+ years)'
        ELSE 'Unknown'
    END AS Tenure_Category,
    COUNT(*) as Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) as Attrited_Employees,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Attrition_Rate 
    FROM hr_employee_attrition
    GROUP BY Tenure_Category
	ORDER BY Attrition_Rate DESC;
    
-- 6. Who are the top 10% most likely to leave based on multiple risk factors?

SELECT * FROM hr_employee_attrition;
WITH risK_factor AS (
SELECT Department, JobRole, (
CASE WHEN JobSatisfaction <= 2 THEN 3 ELSE 0 END +
CASE WHEN MonthlyIncome < 10000 THEN 1 ELSE 0 END +
CASE WHEN WorkLifeBalance <= 2 THEN 2 ELSE 0 END +
CASE WHEN YearsSinceLastPromotion >3 THEN 2 ELSE 0 END +
CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END) AS Risk_score, Attrition
FROM hr_employee_attrition
WHERE Attrition = 'No'),
risk_ranking AS (
SELECT Department, JobRole,
NTILE(10) OVER(ORDER BY Risk_score DESC) as ntile_decile,
RANK() OVER(PARTITION BY Department ORDER BY Risk_score Desc) as dept_risk
 FROM risk_factor)
SELECT Department, Jobrole, Count(*) as high_risk
FROM risk_ranking
WHERE ntile_decile = 1
GROUP BY Department, Jobrole
ORDER BY high_risk desc
;

-- 7. Categorize employees based on their distance from work and show average job satisfaction in each category.

SELECT AVG(JobSatisfaction) Avg_Satisfaction, 
CASE 
	WHEN DistanceFromHome BETWEEN 1 AND 10 THEN "Close (1-10 Mile)"
    WHEN DistanceFromHome BETWEEN 11 AND 20 THEN "Medium (11-20 Mile)"
    WHEN DistanceFromHome BETWEEN 21 AND 30 THEN "Far (21-30 Mile)"
	ELSE "Very Far (>30 Mile)"
END Office_Distance
FROM hr_employee_attrition
GROUP BY Office_Distance
ORDER BY Avg_Satisfaction;

-- 8. What percentage of employees who work overtime have left the company?

SELECT Department, Count(*) Total_OT_Employees, 
SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) Attritude_Employees,
ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)/Count(*)*100,2) Attrition_rate
FROM hr_employee_attrition
WHERE OverTime = "Yes"
GROUP BY Department
ORDER BY Attrition_rate desc;

-- 9.  Are we losing high performers or low performers?

SELECT PerformanceRating,
       COUNT(*) as Total_Employees,
       SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) as Attrited_Employees,
       ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Attrition_Rate
FROM hr_employee_attrition
GROUP BY PerformanceRating
ORDER BY PerformanceRating DESC;

-- 10. Is there a gender disparity in attrition rates?
SELECT Gender,
       COUNT(*) as Total_Employees,
       SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) as Attrited_Employees,
       ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as Attrition_Rate
FROM hr_employee_attrition
GROUP BY Gender
ORDER BY Attrition_Rate DESC;

-- 11. How does promotion history affect attrition?
SELECT 
    CASE 
        WHEN YearsSinceLastPromotion = 0 THEN 'Recently Promoted'
        WHEN YearsSinceLastPromotion BETWEEN 1 AND 2 THEN '1-2 Years Since Promotion'
        WHEN YearsSinceLastPromotion BETWEEN 3 AND 5 THEN '3-5 Years Since Promotion'
        ELSE 'Over 5 Years Since Promotion'
    END as Promotion_Timeline,
    COUNT(*) as Total_Employees,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0.0 END) * 100, 2) as Attrition_Rate
FROM hr_employee_attrition
GROUP BY Promotion_Timeline
ORDER BY Attrition_Rate DESC;

