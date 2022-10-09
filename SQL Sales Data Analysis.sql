-------- inspecting data ---------------
select * from [dbo].[sales_data_sample];

-- Checking Unique Values ------------
select distinct STATUS from [dbo].[sales_data_sample] --Nice one to plot
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] ---Nice to plot
select distinct COUNTRY from [dbo].[sales_data_sample] ---Nice to plot
select distinct DEALSIZE from [dbo].[sales_data_sample] ---Nice to plot
select distinct TERRITORY from [dbo].[sales_data_sample] ---Nice to plot
select distinct CITY from [dbo].[sales_data_sample] ---Nice to plot
select distinct STATE from [dbo].[sales_data_sample] ---Nice to plot

-- Simple Analysis ----------
select distinct MONTH_ID from [dbo].[sales_data_sample] where year_id = 2003;
select distinct MONTH_ID from [dbo].[sales_data_sample] where year_id = 2005; -- operated only for first 5 months
select distinct ORDERLINENUMBER from [dbo].[sales_data_sample];
select distinct QUANTITYORDERED from [dbo].[sales_data_sample] where QUANTITYORDERED > 70;

-- Further Analysis ---------

-- 1) grouping sales by productline --------
select PRODUCTLINE, sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc;

-- 2) grouping sum(sales) per YEAR_ID
select YEAR_ID, sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc;

-- 3) grouping sum(sales) per DEALSIZE
select  DEALSIZE,  sum(sales) as Revenue
from [dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc;

-- 4) grouping sum(sales) per MONTH_ID, and ORDERNUMBER
select  MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 --change year to see the rest
group by  MONTH_ID
order by 2 desc;

-- 5) November seems to be the month, what product do they sell in November
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER)
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc;

-- 6) Who our Best Customer is -----
-- we will use rfm then group customers into 4 groups

DROP TABLE IF EXISTS #rfm;
with rfm as (
	select CUSTOMERNAME, 
	SUM(sales) as MonetaryValue, 
	AVG(sales) as AVGMonetaryValue, 
	COUNT(ORDERNUMBER) as How_Many_Orders_Received,
	max(ORDERDATE) as last_order_date,
	(select max(ORDERDATE) from [dbo].[sales_data_sample]) as max_order_date,
	DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) as Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),

rfm_calc as (

select *,
NTILE(4) over (order by Recency desc) as rfm_recency,
NTILE(4) over (order by How_Many_Orders_Received) as rfm_How_Many_Orders_Received,
NTILE(4) over (order by MonetaryValue) as rfm_Monetary
from rfm as r

)
select
c.*,
rfm_recency + rfm_How_Many_Orders_Received + rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(rfm_How_Many_Orders_Received as varchar) + cast(rfm_monetary  as varchar) as rfm_cell_string
into #rfm
from rfm_calc as c;

select * from #rfm;

-- case statements
select CUSTOMERNAME , rfm_recency, rfm_How_Many_Orders_Received, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
		else 'Absent Because No Data was Provided (NULL)'
	end as rfm_segment

from #rfm

-- 7) What products are most often sold together?

select distinct ORDERNUMBER,  stuff(
(select ',' + PRODUCTCODE
from [dbo].[sales_data_sample] as p
where ORDERNUMBER in 
(
select ORDERNUMBER from 
(select ORDERNUMBER, count(*) as rn
FROM [dbo].[sales_data_sample]
where STATUS = 'Shipped'
group by ORDERNUMBER
) as m
where rn = 3
)
and p.ORDERNUMBER = s.ORDERNUMBER
for xml path ('')), 1, 1, '') as ProductCodes
from [dbo].[sales_data_sample] as s
order by 2 desc;

-- 8) What city has the highest number of sales in a specific country
select city, sum(sales) as sum_of_sales
from [dbo].[sales_data_sample]
where country ='UK' -- change the country
group by city
order by 2 desc;

-- 9) What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc;