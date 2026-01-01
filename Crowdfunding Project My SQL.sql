Create Database crowdfunding;
use crowdfunding;
-- Q1 Convert the Date fields to Natural Time
create view myprojects as SELECT *,
FROM_UNIXTIME(deadline) AS new_deadline,
FROM_UNIXTIME(created_at) AS new_created_at,
FROM_UNIXTIME(launched_at) AS new_launched_at,
FROM_UNIXTIME(updated_at) AS new_updated_at,
FROM_UNIXTIME(successful_at) AS new_successful_at,
FROM_UNIXTIME(state_changed_at) AS new_state_changed_at
FROM projects;
-- Q2 
-- a Creating Table Calendar
create table calender(
CalendarDate int);
-- 2b.Add all the Columns in the Calendar Table using the Formulas
insert into calender (CalendarDate) select created_at from projects;
create view mycalender as with cte as (select CalendarDate,FROM_UNIXTIME(CalendarDate) as date from Calender)
select date,
year(date) as year,
month(date) as month,
monthname(date) as monthfullname,
CONCAT("Q",quarter(date)) as Quarter,
CONCAT(20,date_format(date,'%y-%b')) as yearmonth,
weekday(date) as Weekdayno,
dayname(Date) as weekdayname,
Case
When monthname(date)="April" then "FM1"
When monthname(date)="May" then "FM2"
When monthname(date)="June" then "FM3"
When monthname(date)="July" then "FM4"
When monthname(date)="August" then "FM5"
When monthname(date)="September" then "FM6"
When monthname(date)="October" then "FM7"
When monthname(date)="November" then "FM8"
When monthname(date)="December" then "FM9"
When monthname(date)="January" then"FM10"
When monthname(date)="February" then"FM11"
else "FM12"
END as Financial_month,
Case
when monthname(date)="April" or monthname(date)="May" or monthname(date)="June" Then"FQ-1"
When monthname(date)="July" or monthname(date)="August" or monthname(date)="September" Then "FQ-2"
When monthname(date)="October" or monthname(date)="November" or monthname(date)="December"Then "FQ-3"
When monthname(date)="January" or monthname(date)="February" or monthname(date)="March" Then "FQ-4"
end as financialquarters
from cte;
create view  mycategory as select id as category_id,name as category_name,parent_id,position from category;
create view mylocation as select id as location_id,displayable_name,type,name as location_name,short_name,is_root,country,localized_name from location;
create view mycreator as select id as creator_id,name as creator_name,chosen_currency from creator;
select * from myprojects;
select * from mycalender;

Select * from mycategory;
select * from mycreator;
select * from mylocation;

-- Build the Data Model

select * from myprojects as p left join mylocation as l on l.location_id=p.location_id
left join mycreator as cr on p.creator_id=cr.creator_id
left join mycategory as ct on p.category_id=ct.category_id;
-- create a goal  amount
select *,(goal*static_usd_rate) as goal_amount from myprojects as p left join mylocation as l on l.location_id=p.location_id
left join mycreator as cr on p.creator_id=cr.creator_id
left join mycategory as ct on p.category_id=ct.category_id;

-- 5. Projects Overview KPI
-- a.Total Number of Projects based on outcome
select state,count(Projectid) as total_projects from myprojects group by state;
-- b.Total Number of Projects based on Locations
select country,count(projectid) as total_projects from myprojects group by country order by total_projects desc;
-- c.Total number of projects based on category
with ct as (select ct.category_name,p.projectid from myprojects as p join mycategory as ct on p.category_id=ct.category_id)
select category_name,count(projectid) as total_projects from ct group by category_name order by total_projects desc;
-- d.Total Projects based on year
with cte as (select * from myprojects as p left join mycalender as cal on cal.date=p.new_created_at)
select year,count(projectid) as total_projects from cte group by year order by year;

-- 6.  Successful Projects
-- a. Amount raised for Successful Projects
select state,SUM(usd_pledged) as Amount_Raised from myprojects where state="Successful" group by state;
-- b. Number of Backers for successful Projects
select state,sum(backers_count) as number_of_backers from myprojects where state="Successful" group by state;
-- c. Avg No Of Days for Successful Projects
select state,avg((deadline-launched_at)/86400) as avg_No_of_Days from myprojects where state="successful" group by state;

-- 7 . Top Successful Projects

-- a. Top Successful Projects based on number of backers
select name,sum(backers_count) as number_of_backers from myprojects where state="Successful" group by name order by number_of_backers desc limit 5;
-- b. Top  Successful Projects based on Amount Raised
select name,sum(usd_pledged) as Amount_Raised from myprojects where state="Successful" group by name order by Amount_Raised desc limit 5;

-- Q8. Percentage of Successful Projects

-- a. Percentage of Successful Projects overall
select state,CONCAT((COUNT(projectid) * 100.0 / (SELECT COUNT(*) FROM myprojects)),"%") AS percentage_of_total from myprojects group by state;
-- b.Percentage of Sucessful Projects by category
select category_name,CONCAT((COUNT(projectid) * 100.0 / (SELECT COUNT(*) FROM myprojects)),"%") AS percentage_of_total 
from myprojects left join mycategory on myprojects.category_id=mycategory.category_id 
where category_name is not null and state="Successful"
group by category_name order by percentage_of_total desc limit 5;
-- c.Percentage of Successful Projects by year
select year,CONCAT((COUNT(projectid) * 100.0 / (SELECT COUNT(*) FROM myprojects)),"%") AS percentage_of_total 
from myprojects join mycalender on myprojects.new_created_at=mycalender.date
where state="successful" group by year ;
-- Percentage of Projects by goal Range
WITH cte AS (
    SELECT projectid,state,(goal * static_usd_rate) AS goal_amount,
        CASE 
		WHEN (goal * static_usd_rate) <= 100 THEN '100-1000'
		WHEN (goal * static_usd_rate) <= 1000 THEN '1000-10000'
		ELSE '10000-20000'
        END AS Goal_Range
    FROM myprojects
)
SELECT 
    goal_range,
    CONCAT(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM cte WHERE state = 'Successful'),'%') AS percentage_of_total
FROM cte 
WHERE state = 'Successful'
GROUP BY goal_range;
