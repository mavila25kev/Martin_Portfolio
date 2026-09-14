# Data Extraction and Staging Process using Data on Top US Colleges

The goal of this process was to pull data from the [COLLEGE ROI API](https://le-teen.com/api) resource page with python through Juptyer Notebook and load the data into MYSQL to create a schema for future analysis.  

## Context, Data & Tools

There are several sources provided via this API to analyze different factors regarding the return on investment of college degrees in the US. For this process I used the the largest available data found on the site above under the endpoint '/api/v1/colleges.json'. This returns the data on the 500 largest-coverage schools including NPV, cost, earnings and breakeven age. The initial purpose was to just look at this data source but I also used two additional tables/data sources found on [Kaggle](https://www.kaggle.com/datasets/jessemostipak/college-tuition-diversity-and-pay?select=tuition_cost.csv) which include data on US states tuition costs for universities by state and the salary potential by university from each US state. These additional sources were not meant to be included initially but I added them to our schema to summarize and provide context by state and comparison figures to the main colleges data table.

Data Sources:
- [COLLEGE ROI API](https://le-teen.com/api)
- [Kaggle](https://www.kaggle.com/datasets/jessemostipak/college-tuition-diversity-and-pay?select=tuition_cost.csv) (source of each dataset used included in Kaggle Post Description)

Definitions: 
- **NPV**: Present value of lifetime earnings - total cost of degree and opportunity cost
- **Break Even Age**: The expected age a graduate would recoup the amount cost of attendance
- **NPV_Non_Resident**: This value is set to 0 by default for certain schools is the difference with the NPV_Resident Value is negligible 

Tools Used:
- Python
- Juptyer Notebook
- MySQL
- Excel


## Methodology 

1.  The colleges API website provides a sample line of python code to pull the API data and display it as a pandas DataFrame but I modified this slightly to convert the DataFrame into a csv file. This was done initially because I was going to use Power Bi to load the CSV for cleaning and generating visuals for analysis based off this single table. Later this would change as I ended up pulling in two additional datasets to suppliment the data from the top 500 colleges API but this is the reason why this was not coded to directly move into a MySQL database. Below is the code used in Jupyter Notebook to pull the college data in JSON format, convert to a pandas DF and then export as a CSV. Additionally I noticed one of the columns in this dataset was a full url to the listed university website which will not be need and was dropped here before being exported.


```python
import json, urllib.request
import pandas as pd

url = "https://le-teen.com/api/v1/colleges.json"
with urllib.request.urlopen(url) as r:
    data = json.load(r)


colleges = data['colleges']

pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.max_colwidth', None)

df = pd.DataFrame(colleges)
df = df.drop(columns=['url'])


df.to_csv('CollegesData.csv', index= False)
```

2. After exporting to a CSV it can be seen from the image below that all columns are comma separated which can be loaded directly into MYSQL since we will have to option indicate the comma as the delimiter but I went ahead and selected the option within Excel for Text to Columns to have this done now. This will ensure that no data from rows will be lost when loaded into MYSQL. The final result is what I was aiming for seen in the second image.
<br>
<img width="900" height="400" alt="Image" src="https://github.com/user-attachments/assets/8d89ceb6-8e2a-41a1-a30f-00357cb2acd0" />  
<img width="900" height="400" alt="Image" src="https://github.com/user-attachments/assets/00c73c73-f70e-42c8-8898-ae109c97aa41" />

3.  The two other supplementary datasets were already saved in Excel Files. The image on the left shows the final salary potential dataset which takes the median reported salary of graduates for each reporting university by state. There were other columns included which show the stem percentage of students and other survey type results which I removed from the dataset here in the excel file as they we will not be needed. The image on the right shows the final tuition cost dataset which show the in state and out of state tuition totals by reporting university by state. There were other columns which breakdown the tuition cost by room and board, state code, degree length and school type. The degree length was filtered for only 4 year degree schools and the type(private/public/etc) was removed since it is not relevant in our main data table, I kept the state code because the main table includes a state code as well which can be used for future joins between the 3 tables.
<br>
<img width="1200" height="600" alt="Image" src="https://github.com/user-attachments/assets/0492bc79-b1f5-44fc-9ca1-6cb77cbfebe9" /> 
<img width="1200" height="600" alt="Image" src="https://github.com/user-attachments/assets/a9842dac-4283-4217-8ba2-e5c23de775f6" />

4. While attempting to import all three tables into MYSQL several rows were missing from each dataset. Upon reviewing the three datasets I noticed empty cells/Null values for some of the number data type columns which was causing MYSQL to ignore these rows entirely on the load. I used the 'Replace' Function to change all Null number values to '0' after which the import was successful. Below we have the tables of our schema:
<br>
<img width="1000" height="600" alt="Image" src="https://github.com/user-attachments/assets/a16f0fe6-4ef6-47cb-a494-9ac1b5b3e804" />

5. Next I looked over the data as a whole once more and dropped some of the columns which will not be used for any analysis relating to income or tuition, below are the statements used and further explanation on the reasoning for dropping each column from said table:
```sql
/* dropping slug, city, and control columns, slug is the non cleaned verision of the univeristy names
Dropping city because dditional table are on a state level so need to look at the specific city, 
Dropping control because we are looking at univerities as a whole and not classifying them into private/public
*/
ALTER TABLE collegesdata 
	DROP COLUMN slug,
	DROP COLUMN city,
    DROP COLUMN control;

/* Dropping several columns here, type distinguishes between private/public which will not be looking at,
We filtered for 4 year schools only already in Excel so we will drop this now,
Room_and_board, in_state_tuition and out_of_state_tuition all add up to the columns we are keeping with the total for each so we do not need these columns
*/
ALTER TABLE tuition_cost 
	DROP COLUMN type,
	DROP COLUMN degree_length,
    DROP COLUMN room_and_board,
    DROP COLUMN in_state_tuition,
	DROP COLUMN out_of_state_tuition;
```

6.  I created two CTE's to group data by state for both the tuition table and salary potential table. The average salary was taken by state and the average in state and out of state tuition as well per state, below are the statements used:
```sql
/* cte to find average of salary by state for early and mid career pay,
 also removing the hyphen within the state name column for proper grouping
*/
with average_salary_by_state as
(
	select 
		replace(state_name, '-', ' ') as state_name_clean,
        round(avg(early_career_pay),0) as avg_early_career_pay,
		round(avg(mid_career_pay),0) as avg_mid_career_pay
	from salary_potential
    group by state_name_clean
)
/* cte to find average of tutiion by state for in-state and out of state, multipying each average by 4 because these are 4 year colleges,
 and filtering for non NA values in the state column which represent US territories
*/
, average_tuition_by_state as
(
	select 
		state,
        state_code,
        round(avg(in_state_total*4),0) as avg_in_state_total,
		round(avg(out_of_state_total*4),0) as avg_out_of_state_total
	from tuition_cost
    where state not like 'NA'
    group by state, state_code
)
```

7. The two CTEs above were then joined together on the state name column and renamed to provide more clarify to what 'mid and early career pay' meant in terms of years. Finally the CTE was joined to the main table on the state code and to get the final table for analysis. Below are the statements used to create each CTE and the final table is found in the CTE titled ' colleges_final '. 

```sql
-- joining two tables to show avg tuition and salary
, salary_and_tuition_by_state as
( select
	ats.state as state, 
	ats.state_code as state_code, 
    av.avg_early_career_pay as avg_earnings_year_0_10_by_state,
    av.avg_mid_career_pay as avg_earnings_year_11_20_by_state,
    ats.avg_in_state_total as avg_state_cost_of_attendance_resident_usd,
    ats.avg_out_of_state_total as avg_state_cost_of_attendance_nonresident_usd
from average_tuition_by_state as ats
inner join average_salary_by_state as av on ats.state = av.state_name_clean
order by ats.state, ats.state_code
)

-- joining our colleges data with each colleges state statistics
,  colleges_final as (
select 
	cd.name,
    cd.state_name,
    cd.npv_30yr_resident_usd,
    cd.npv_30yr_nonresident_usd,
    cd.total_cost_of_attendance_usd,
    cd.total_cost_of_attendance_nonresident_usd,
    sts.avg_state_cost_of_attendance_resident_usd,
    sts.avg_state_cost_of_attendance_nonresident_usd,
    cd.median_earnings_10yr_usd,
    sts.avg_earnings_year_0_10_by_state,
    sts.avg_earnings_year_11_20_by_state,
    cd.breakeven_age,
    cd.freopp_program_coverage
from collegesdata as cd
left join salary_and_tuition_by_state as sts on cd.state = sts.state_code
)
```

8.  Once I had the final CTE, I ran the query below to return what I would consider to be a list of the top colleges in the US. This was a single query which was more so exploratory since the criteria used for filtering was determined by my opinion of values for tuition, salary, and NPV which would make a college one of the top tier schools to attend.  The values used in the 'where' clause are therefore somewhat arbitrary such as the statement filtering for schools which had a median 10 year pay $30,000 more than the average pay by the state it is located in at 10 years. The other statement filtering for median 10 year earnings greater than $74,000 was based off national statistics showing $74k to be the median 10 year national income for a college graduate. Note that a column has also been added here for additional insights titled 'difference_in_salary' used to gauge the difference in median earnings at 10 years for each college compared to the average earnings at 10 years for the school's state. Below is the query:

```sql
select 
	name,
    state_name,
    npv_30yr_resident_usd,
    npv_30yr_nonresident_usd,
    median_earnings_10yr_usd,
    avg_earnings_year_0_10_by_state,
    median_earnings_10yr_usd - avg_earnings_year_0_10_by_state as difference_in_salary,
    breakeven_age,
    freopp_program_coverage
from colleges_final
where (npv_30yr_resident_usd > 500000) and (avg_earnings_year_0_10_by_state + 30000 < median_earnings_10yr_usd) and (median_earnings_10yr_usd >74000)
order by npv_30yr_resident_usd desc, difference_in_salary desc, breakeven_age desc
;
```

9. This is the result of the above query which returned 14 colleges and was ordered by the NPV, difference in salary and the break even age. The results show colleges most would expect to see, Ivy League schools and schools known for this their technological/STEM programs. 

<img width="1400" height="350" alt="Image" src="https://github.com/user-attachments/assets/c15baf5f-5277-473f-abc6-05db8122bebb" />

<br>

## Limitations and Liabilities

1. The data from the tuition and salary potential tables are collected within a range of the last 10 years and may no longer reflect the present day circumstances for each.
2. The sample sizes vary greatly for the averages and medians of income and tuition as some states have significantly lower colleges for which data is reported (ex. California/New York/Texas have more than 10 schools contributing to the means/median compared to several smaller states).
3. For the purposes of joining all tables together, the averages of median values were used after grouping by state, this distorts the data and final figures stray from true median/average values. This normally should not be done as it is unintentionally introducing bias due to the sample sizes.
4. Overall it is difficult to get accurate values for each college as circumstances vary greatly per person in terms of what they study, where they physically work after graduating and whether they pursue additional education after graduation. Additionally not all colleges report tuition, earnings, etc accurately or on yearly basis to the public.

## Final Notes

To reiterate, the goal of this project was to pull data from an API source, use different data extraction tools like MYSQL, Python and Excel, and utilize the various data cleaning capabilities of each tool. This could have been done entirely with either of the 3 tools and for future projects it may be simplified by pulling from the API via python directly into MYSQL, though the addition of supplementary data may require the knowledge of the capabilities of other resources in the real world which is why I chose to try this out. There are also lots of possibilities in what can be done with this data depending on what one wants to gain insights on. I chose not to explore here instead opting for a simply query but for data analysis purposes and gaining insights this could be heavily expanded on if more accurate supplementary data with greater sample sizes could be found which may be something to come back to in the future.

## Files for Re-Creation

The files used for this project can be found in the file folder.

