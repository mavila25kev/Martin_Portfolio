# Data Extraction and Staging Process using Data on Top US Colleges

The goal of this process was to pull data from the [COLLEGE ROI API](https://le-teen.com/api) resource page with python through Juptyer Notebook and load the data into MYSQL to create a schema for future analysis.  

## Context, Data & Tools

There are several sources provided via this API to analyze different factors regarding the return on investment of college degrees in the US. For this process I used the the largest available data found on the site above under the endpoint '/api/v1/colleges.json'. This returns the data on the 500 largest-coverage schools including NPV, cost, earnings and breakeven age. The initial purpose was to just look at this data source but I also used two additional tables/data sources found on [Kaggle](https://www.kaggle.com/datasets/jessemostipak/college-tuition-diversity-and-pay?select=tuition_cost.csv) which include data on US states tuition costs for universities by state and the salary potential by university from each US state. These additional sources were not meant to be included initially but I added them to our schema to summarize and provide context by state and comparison figures to the main colleges data table.

Data Sources:
- [COLLEGE ROI API](https://le-teen.com/api)
- [Kaggle](https://www.kaggle.com/datasets/jessemostipak/college-tuition-diversity-and-pay?select=tuition_cost.csv) (source of each dataset used included in Kaggle Post Description)

Definitions: 
- **NPV**: Present value of lifetime earnings - total cost of degree and opportunity cost

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

<img width="450" height="400" alt="Image" src="https://github.com/user-attachments/assets/8d89ceb6-8e2a-41a1-a30f-00357cb2acd0" />  <img width="550" height="400" alt="Image" src="https://github.com/user-attachments/assets/00c73c73-f70e-42c8-8898-ae109c97aa41" />

3.  The two other supplementary datasets were already saved in Excel Files. The image on the left shows the final salary potential dataset which takes the median reported salary of graduates for each reporting university by state. There were other columns included which show the stem percentage of students and other survey type results which I removed from the dataset here in the excel file as they we will not be needed. The image on the right shows the final tuition cost dataset which show the in state and out of state tuition totals by reporting university by state. There were other columns which breakdown the tuition cost by room and board, state code, degree length and school type. The degree length was filtered for only 4 year degree schools and the type(private/public/etc) was removed since it is not relevant in our main data table, I kept the state code because the main table includes a state code as well which can be used for future joins between the 3 tables.

<img width="475" height="400" alt="Image" src="https://github.com/user-attachments/assets/0492bc79-b1f5-44fc-9ca1-6cb77cbfebe9" /> 
