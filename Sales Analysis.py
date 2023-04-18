#!/usr/bin/env python
# coding: utf-8

# # Sales Analysis By Joshua Aiyeetan

# ### Loading Data and doing a comprehensive check on it

# In[1]:


#importing libraries 
import pandas as pd
import numpy as np
from datetime import datetime


# In[2]:


#loading the salse data into pandas
file = pd.read_csv('salesforcourse.csv')


# In[3]:


#Checking the content of the sales data
file


# In[4]:


#The table has two index columns, (original index form python and index from the file)


# In[5]:


#Checking the datatype of each column
file.info()


# In[6]:


#Checking for anomalies in the table
file.nunique()


# In[7]:


#Is there Null values in this data?
file.isnull().values.any()


# In[8]:


#Which columns columns has Null values?
file.isnull().sum()


# In[9]:


#Are there any duplicates in the dataset
file.duplicated().any()


# ### Data Cleaning

# In[10]:


#Dropping the first column in the file ('index')
file.drop(['index'], axis =1, inplace = True)


# In[11]:


#Check to comfirm one of the index columns is removed.
file


# In[12]:


#Examing the Null values 
file[file['Column1'].isnull()].head()


# In[13]:


#Comfirming that column1 doesn't contain meaningful data.
file[file['Column1'].notnull()].head()


# In[14]:


#Dropping 'Column1' because the majority of its content are Null, and the once not Null are duplicate values of Revenue 
file.drop(['Column1'], axis =1, inplace = True)


# In[15]:


#locating the Nulls in the other part of the data.
file[file['Date'].isnull()]


# In[16]:


#Dropping the Nulls in the data
file = file.dropna()


# In[17]:


#Confirming that all Nulls has been taken care of.
file.isnull().sum()


# In[18]:


#Converting the 'Year' and the 'Customer Age' into int, while the 'Date' into Date type
file['Date'] = pd.to_datetime(file['Date'])

file['Year'] = file['Year'].astype(int)

file['Customer Age'] = file['Customer Age'].astype(int)


# In[19]:


#Comfirming the datetypes are now corrected
file.info()


# ### Analysis

# In[20]:


#Creating two columns 1. Profit and 2. Profit Margin
#A column to calculate the profit made from each sale.
file['Profit'] = file['Revenue'] - file['Cost']

#A column for the profit margin
file['Profit Margin'] = file['Unit Price'] - file['Unit Cost']


# In[21]:


#Checking the new columns created
file


# In[22]:


#Breakdown by Year.
sales = file[['Cost','Month','Year','Revenue','Profit','Quantity']]
sales.groupby(sales['Year']).sum()


# In[23]:


#Monthly Sales, breakdown into Cost, Revenue, Profit and Quantity
sales = sales.groupby(['Year','Month']).sum().reset_index()
sales


# In[24]:


#What are the Top Performing Products by Profit?
product = file[['Product Category','Sub Category','Quantity','Profit']]
product.groupby(['Product Category','Sub Category']).sum().sort_values('Profit', ascending = False).reset_index()


# In[25]:


# Calculating profit margin for each product sub category
margin_sub_Category = (file.groupby('Sub Category')['Profit'].sum() / file.groupby('Sub Category')['Revenue'].sum())*100

# Sort categories by profit margin in descending order
profit_margin_by_category = margin_sub_Category.sort_values(ascending=False)

#list of product sub categories ranked by their profit margin from highest to lowest
print(round(profit_margin_by_category))


# In[26]:


#Profit by Country broken down into quantity, cost, revenue and profit
product = product = file[['Country','Sub Category','Quantity','Revenue','Profit']]
product.groupby(['Country']).sum().sort_values('Profit', ascending = False).reset_index()


# In[27]:


#Based on Revenue, US has the higest quantity of goods sold, highest revenue but when it comes to profit, they are the 2nd
product.groupby(['Country']).sum().sort_values('Revenue', ascending = False).reset_index()


# ### Visualization

# In[28]:


import matplotlib
import matplotlib.pyplot as plt
import seaborn as sns
get_ipython().run_line_magic('matplotlib', 'inline')


# In[29]:


#What is the Gender distribution of their customers?
gender_counts = file.groupby('Customer Gender').size()

labels = ['Female', 'Male']
colors = ['pink', 'lightblue']
plt.pie(gender_counts, labels=labels, colors=colors, autopct='%1.1f%%')

# Set the title
plt.title('Gender Distribution')

# Display the pie chart
plt.show()


# In[30]:


#Trend of sales overtime
Trend = file.groupby('Date')['Revenue'].sum().reset_index()


# In[31]:


# Create line chart of sales over time
fig1 = plt.figure(figsize=(12, 6))

plt.plot(Trend['Date'], Trend['Revenue'], color = 'blue')
plt.title('Revenue Trend')
plt.xlabel('Date')
plt.ylabel('Revenue')
#plt.xticks(pd.date_range(start=Trend['Date'].min(), end=Trend['Date'].max(), freq='1M'))
plt.show()


# In[32]:


#Country's Revenue by Product Category
sales_by_category_country = file.groupby(['Product Category', 'Country'])['Revenue'].sum().unstack()

sales_by_category_country.plot(kind='bar', stacked=True)
plt.title('Revenue by Product Category and Country')
plt.xlabel('Revenue', fontsize=12)
plt.ylabel('Product Category', fontsize=12)

# Turn off scientific notation on the x-axis
plt.gca().get_yaxis().get_major_formatter().set_scientific(False)


#Sales by Sub Category
sales_by_category_country = file.groupby(['Sub Category', 'Country'])['Revenue'].sum().unstack()

sales_by_category_country.plot(kind='bar', stacked=True)
plt.title('Revenue by Sub Category and Country')
plt.xlabel('Revenue', fontsize=12)
plt.ylabel('Sub Category', fontsize=12)

# Turn off scientific notation on the x-axis
plt.gca().get_yaxis().get_major_formatter().set_scientific(False)


# In[33]:


#Country's Profit by Product Category
sales_by_category_country = file.groupby(['Product Category', 'Country'])['Profit'].sum().unstack()

sales_by_category_country.plot(kind='bar', stacked=True)
plt.title('Profit by Product Category and Country')
plt.xlabel('Revenue', fontsize=12)
plt.ylabel('Product Category', fontsize=12)

# Turn off scientific notation on the x-axis
plt.gca().get_yaxis().get_major_formatter().set_scientific(False)


#Profit by Sub Category
sales_by_category_country = file.groupby(['Sub Category', 'Country'])['Profit'].sum().unstack()

sales_by_category_country.plot(kind='bar', stacked=True)
plt.title('Profit by Sub Category and Country')
plt.xlabel('Profit', fontsize=12)
plt.ylabel('Sub Category', fontsize=12)

# Turn off scientific notation on the x-axis
plt.gca().get_yaxis().get_major_formatter().set_scientific(False)


# In[34]:


#Sales by Category
sales_by_category = file.groupby('Product Category')['Quantity'].count().reset_index()
fig3 = plt.figure(figsize = (6,4))
plt.title('Quantity BY Product Category')
plt.bar(sales_by_category['Product Category'], sales_by_category['Quantity'])
plt.xlabel('Product Category')
plt.ylabel('Quantity')
plt.gca().get_yaxis().get_major_formatter().set_scientific(False)


# In[35]:


sales_profit_by_country = file.groupby(['Country'])[['Revenue', 'Profit']].sum()
plt.title('Revenue Vs Profit by Country')
plt.scatter(x=sales_profit_by_country['Revenue'], y=sales_profit_by_country['Profit'])

# Add labels for each country
for i, txt in enumerate(sales_profit_by_country.index):
    plt.annotate(txt, (sales_profit_by_country['Revenue'][i], sales_profit_by_country['Profit'][i]))

plt.xlabel('Revenue')
plt.ylabel('Profit')

plt.xticks(rotation=45)

plt.gca().get_yaxis().get_major_formatter().set_scientific(False)
plt.gca().get_xaxis().get_major_formatter().set_scientific(False)

#plt.scatter(x='Revenue', y='Profit', data=sales_profit_by_country, s=100)

plt.show()


# In[36]:


#What is the customera age distribution?
plt.hist(x='Customer Age', data=file, bins=70)

plt.title('Distribution of Customer Age')
plt.xlabel('Customer Age')
plt.ylabel('Number of Occurrences')


# ### Observation and Recommendations

# - Based on this Analysis, it evident that a high revenue does not necessarily translate to high profit. "The Company recorded the highest revenue from the United States but there highest profit was from Germany".
# 
# - The Company needs to consider and find ways to reduce their cost of production without compromising quality in the United States in other to increase their profit margin.
# 
# - Product with High Profit margins should be prioritized in marketing and sales efforts
# 

# In[ ]:




