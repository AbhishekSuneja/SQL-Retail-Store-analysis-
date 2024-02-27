
--1.  What is the total number of rows in each of the 3 tables in the database?

     select (select count(*) from customer$)+(select count(*) from prod_cat_info$)+ (select count(*) from Transactions$) as Total_rows
	 
    --Or 
	
	  with ABC as 
	       ( select 'Customer$' as Table_name, count(*) as Row_count from Customer$
		     union all
			 select 'prod_cat_info$'  as Table_name, count(*) as Row_count from prod_cat_info$
			 union all
			 select  'Transactions$' as Table_name, count(*) as Row_count from Transactions$)

			 select 'Tables' as All_mix, Sum(row_count) as total_rows from ABC

--2.  What is the total number of transactions that have a return?

   select count(total_amt)as count_trans from transactions$
   where total_amt like '-%'

   --or 

   select count(total_amt)as count_trans from transactions$
   where sign(total_amt)<0

/*3.	As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, pls 
	    convert the date variables into valid date formats before proceeding ahead.*/

		SELECT CONVERT(DATE, DOB) AS DATES FROM Customer$ 
SELECT CONVERT(DATE, TRAN_DaTE) FROM transactions$

/*4.	What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously
	    in different columns.*/

		select datediff(YY,min(TRAN_DaTE),max(TRAN_DaTE)) as Years_diff,
		       datediff(mm,min(TRAN_DaTE),max(TRAN_DaTE)) as months_diff,
			   datediff(dd,min(TRAN_DaTE),max(TRAN_DaTE)) as months_diff
		  from transactions$

--5.	Which product category does the sub-category “DIY” belong to?

        Select prod_cat from prod_cat_info$
		where prod_subcat = 'DIY'


--***********Part B Data Analysis Problems***********

--1.	Which channel is most frequently used for transactions?

        select  top 1 store_type, count(store_type) as total from transactions$
		group by store_type
		order by  2 desc


--2.	What is the count of Male and Female customers in the database?

        select  gender, count(gender) as total from Customer$
		group by gender 
		having count(gender)>0

		--OR--

        Select 'Male' as Gender_type, count(gender) as CNT from Customer$
		group by gender
		having gender='M'
		union all
		Select 'Female' as Gender_type, count(gender) as CNT from Customer$
		group by gender
		having gender='F'

--3.	From which city do we have the maximum number of customers and how many?

        select top 1 city_code, count(city_code) from Customer$
		group by city_code
		order by 2 desc

--4.  	How many sub-categories are there under the Books category?

        select prod_cat, count(prod_subcat)as Subcat_CNT from prod_cat_info$
		where prod_cat='books'
		group by prod_cat


--5.    What is the maximum quantity of products ever ordered in a single transaction?

        select top 1 Qty as total_Qty from Transactions$
		order by 1 desc

--5.1    What is the maximum quantity of products ever ordered and what was the product?

        select c.prod_cat, count(c.prod_cat) as total_Qty from Transactions$ a 
		
		left join prod_cat_info$ c on c.prod_cat_code=a.prod_cat_code and c.prod_sub_cat_code=a.prod_subcat_code
		group by c.prod_cat
		order by 2 desc

--5.2   For which product category, there were max no of transactions

        SELECT TOP 1  a.PROD_CAT_CODE, b.PROD_CAT , COUNT(a.PROD_CAT_CODE) QUANTITY
        FROM Transactions$ a
        LEFT JOIN prod_cat_info$ b ON a.PROD_CAT_CODE = b.PROD_CAT_CODE
        GROUP BY a.PROD_CAT_CODE, b.PROD_CAT
        ORDER BY 3 DESC 

--6.	What is the net total revenue generated in categories Electronics and Books?  

        select 
		a.prod_cat, round(sum(b.total_amt),2) as Revenue from prod_cat_info$ a 
		inner join Transactions$ b on a.prod_cat_code=b.prod_cat_code and PROD_SUB_CAT_CoDE = PROD_SUBCAT_CODE
		where a.prod_cat in ('books','electronics')
		group by a.prod_cat


--7.    How many customers have >10 transactions with us, excluding returns?

       Select count(cust_id)as Total_cust 
	   from --transaction_id where cust_id in 
	      ( select cust_id, count(transaction_id) as Trans_CNT 
		    from Transactions$
	        where total_amt not like'-%'
		group by cust_id
		having count(transaction_id)>10)A

/*8.   What is the combined revenue earned from the “Electronics” & “Clothing”
	   categories, from “Flagship stores”?  */

	    select 
		a.prod_cat, round(sum(b.total_amt),2) as Revenue from prod_cat_info$ a 
		inner join Transactions$ b on a.prod_cat_code=b.prod_cat_code and PROD_SUB_CAT_CoDE = PROD_SUBCAT_CODE
		where a.prod_cat in ('clothing','electronics') and store_type = 'Flagship store'
		group by a.prod_cat


/*9.   What is the total revenue generated from “Male” customers in “Electronics” category? 
       Output should display total revenue by prod sub-cat.*/

       select b.prod_subcat, sum(total_amt)  as total_Amnt from Transactions$ a 
	   inner join prod_cat_info$ b on a.prod_cat_code = b.prod_cat_code and a.prod_subcat_code = b.prod_sub_cat_code
	   inner join Customer$ c on c.customer_id = a.cust_id
	   where gender='M' and b.prod_cat = 'Electronics'
	   group by b.prod_subcat
	  
/*10.   What is percentage of sales and returns by product sub category. 
        Display only top 5 sub categories in terms of sales?*/

	    SELECT TOP 5 b.PROD_SUBCAT, 
	    (SUM(TOTAL_AMT)/(SELECT SUM(TOTAL_AMT) FROM Transactions$))*100 AS PERCANTAGE_OF_SALES, 
        (COUNT(CASE WHEN QTY< 0 THEN QTY ELSE NULL END)/SUM(QTY))*100 AS PERCENTAGE_OF_RETURN
        FROM Transactions$ a
        INNER JOIN prod_cat_info$ b ON a.PROD_CAT_CoDE = b.PROD_CAT_CODE AND a.PROD_SUBCAT_CODE= b.PROD_SUB_CAT_CoDE
        GROUP BY b.PROD_SUBCAT
        ORDER BY SUM(TOTAL_AMT) DESC


/*11.	For all customers aged between 25 to 35 years, find what is the net total revenue generated by these consumers
        in last 30 days of transactions from max transaction date available in the data?*/

		with CTE1 as 
		     ( select customer_Id,datediff(yy,dob,getdate())as Cust_age 
			   from Customer$
			   group by customer_id,dob),

		     CTE2 as
			 ( select cust_id,datediff(DD,max(convert(date,tran_date,103)),convert(date,tran_date,103))as period from transactions$
			   group by cust_id, tran_date)
		select Sum(total_amt) as Net_revenue from CTE1 
		inner join CTE2 b on cust_id = customer_Id
		where 
		period <=30 and Cust_age between 25 and 35  --  incomplete

		select dateadd(mm,-3,max(tran_date)) from transactions$
---OR-----
	
    select cust_id, sum(total_amt) as Revenue from transactions$
    where cust_ID in
	         ( select customer_id from customer$ 
			   where datediff(YY,dob,getdate()) between 25 and 35)
    And tran_date between dateadd(day,-30,(select max(tran_date) from transactions$))
	and (select max(tran_date) from transactions$)
	group by cust_id
	order by 2 desc
	

--12.   Which product category has seen the max value of returns in the last 3 months of transactions?                
       
	  select top 1 prod_cat, sum(total_amt) from prod_cat_info$ a
	   inner join transactions$ b on a.prod_cat_code=b.prod_cat_code 
	                      and a.prod_sub_cat_code=b.prod_subcat_code 
	   where total_amt<0 and
	                      convert(date,tran_date,103) between dateadd(MM,-3,(select max(tran_date) from transactions$))
						  And (select max(tran_date) from transactions$)
	  group by prod_cat
	  order by 2 desc

/*13.   Which store-type sells the maximum products; by value of sales amount and
	    by quantity sold?*/

	  select top 1 store_type, sum(total_amt) as sales, sum(Qty) as tota_Qty  from transactions$ 
		 group by store_type 
		 order by 2 desc

--OR-- Using ALL function

		 SELECT  STORE_TYPE, SUM(TOTAL_AMT) TOT_SALES, SUM(QTY) TOT_QUAN
         FROM transactions$
         GROUP BY STORE_TYPE
         HAVING SUM(TOTAL_AMT) >=ALL (SELECT SUM(TOTAL_AMT) FROM transactions$ GROUP BY STORE_TYPE)
         AND SUM(QTY) >=ALL (SELECT SUM(QTY) FROM transactions$ GROUP BY STORE_TYPE)

		
/*14.   What are the categories for which average revenue is above the overall average.*/

        select a.prod_cat, avg(total_amt) as Avg_revenue
	    from prod_cat_info$ a inner join transactions$ b
	    on a.prod_cat_code = b.prod_cat_code
		group by a.prod_cat
		having avg(total_amt)>(select avg(total_amt) from transactions$)
        
/*15    Find the average and total revenue by each subcategory for the categories 
	    which are among top 5 categories in terms of quantity sold.*/

		select prod_cat, prod_subcat, avg(total_amt) as avg_revenue, sum(total_amt) as tot_revenue 
		from  prod_cat_info$ a inner join transactions$ b
		on a.prod_cat_code = b.prod_cat_code and a.prod_sub_cat_code = b.prod_subcat_code
		where prod_cat in (select prod_cat from ( select top 5 prod_cat, sum(qty) as total_qty from prod_cat_info$ a inner join transactions$ b
		on a.prod_cat_code = b.prod_cat_code and a.prod_sub_cat_code = b.prod_subcat_code
		group by prod_cat
		order by 2 desc)A)
		group by a.prod_cat, a.prod_subcat
		order by 3 desc

		---OR---

		SELECT PROD_CAT, PROD_SUBCAT, AVG(TOTAL_AMT) AS AVERAGE_REV, SUM(TOTAL_AMT) AS REVENUE
        FROM transactions$ a
        INNER JOIN prod_cat_info$ b ON a.PROD_CAT_CoDE=b.PROD_CAT_CODE AND b.PROD_SUB_CAT_CoDE=a.PROD_SUBCAT_CODE
        WHERE PROD_CAT IN
        (
        select top 5 PROD_CAT FROM transactions$ 
          INNER JOIN prod_cat_info$ ON a.PROD_CAT_CoDE= b.PROD_CAT_CODE 
		        AND b.PROD_SUB_CAT_CoDE = a.PROD_SUBCAT_CODE
        group by PROD_CAT
        order by SUM(QTY) DESC
        )
        group by PROD_CAT, PROD_SUBCAT
        order by 3 desc

	
	                