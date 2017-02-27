-------------to get the OOS ---------------
create table prod_wa_query.RDA_OOS 
as (
select 
yearmonth 
, DEPT_NAME
,store_nbr
,count(distinct order_no)  as count_ordr
,sum(case when OOS_QTY >0.0000 then OOS_QTY else 0.0000 end)  as OOS_qty_calc
,sum(case when OOS_QTY >0.0000 then oos_amt   else 0.0000 end)   as oos_amt_calc
, OOS_qty_calc / count_ordr as AVG_OOS_QTY 
, oos_amt_calc/ count_ordr as AVG_OOS_amt
from 
( 

select  
 cast((oh.pickup_dtime (format 'YYYYMM')) as char(6)) as YearMonth ,
 DEPT_NAME,
 id.branch_no as store_nbr, 
-- cast(oh.pickup_dtime as date) ,
--id.order_no  as order_no ,
 id.order_no , 
SUM(CASE WHEN OD.Pricing_Unit = 'KG' AND ID.Order_Quantity > 0 THEN 1 ELSE ID.Order_Quantity END) AS Ordered,
SUM(CASE WHEN OD.Pricing_Unit = 'KG' AND ID.Supplied_Quantity > 0 AND ID.Supplied_Quantity < ID.Order_Quantity THEN 0 
WHEN OD.Pricing_Unit = 'KG' AND ID.Supplied_Quantity > 0 THEN 1 
        ELSE ID.Supplied_Quantity 
   END) AS Supplied,
 sum(  id.total_sale_price_amount  )    as total_sale_price_amount_1,
sum(  id.invoice_line_amount  )  as  invoice_line_amount_1,
  Ordered - Supplied AS OOS_QTY ,
     total_sale_price_amount_1  -  invoice_line_amount_1  as oos_amt  
   
  
from PROD_EDW_SIF.MOR_SMKT_ECF_Invoice_Detail  ID
inner join 
PROD_EDW_SIF.MOR_SMKT_ECF_order_Detail OD
on 
id.order_no = od.order_no 
and   id.order_line_no = od.line_no 
and id.branch_no = od.branch_no 
and  cast( od.ss_exp_tmstmp  as date) =date'2099-12-31'  

inner join 
PROD_EDW_SIF.MOR_SMKT_ECF_order_header OH
on 
oh.order_no = od.order_no 
and oh.branch_no = od.branch_no 
and oh.order_status_ind in ('DIS','COL','CLS') 
and  cast( oh.ss_exp_tmstmp  as date) =date'2099-12-31'  
and cast(oh.pickup_dtime as date) >= date'2014-01-01' 
and OH.deleted_flag = 'F'

inner join 
(select distinct 
     ECCPROD.articlenumber  as StockCode
    ,  DEPT_NAME
from 
prod_edW_wil.dim_prod_article_curr_v prod
inner join 
   PROD_EDW_sif.ECC_ARTICLE  ECCPROD
  ON
	     
	                     ECCPROD.end_date =date'2099-12-31' 
	          and   ECCPROD.Record_Deleted_Flag = 0
	          and   COALESCE(ECCPROD.PackbreakdownArticle,ECCPROD.ArticleNumber)||'-'||ECCPROD.UOM   = prod.prod_nbr 
              and prod.division_nbr = '1005'  
) prod 
on prod. StockCode =     CAST(id.StockCode AS VARCHAR(100))

where 
  cast( id.ss_exp_tmstmp  as date) =date'2099-12-31'  
group by 1,2,3,4  
) ORD 

group by 1,2,3  ) with data 

----------To get the instore sales repeat the query for every month needed-------------------

insert into  prod_wa_query.RDA_product_instr_Sales 
  
select    cast((start_txn_date (format 'YYYYMM')) as char(6)) as YearMonth  , store_nbr,   DEPT_NAME , sum(TOT_GROSS_INCLD_GST)  
, sum(TOT_GROSS_EXCLD_GST)   ,count(distinct basket_key) 
 from PROD_EDW_WIL.FACT_PROD_SALES_SUMM_V  pss
 inner join 
 
PROD_WA_QUERY.online_stores str
on str.store_number = pss.store_nbr 

inner join 
prod_edW_wil.dim_prod_article_curr_v prod

on pss.prod_nbr = prod.prod_nbr 
and pss.division_nbr = '1005'  and pss.checkout_nbr not in(0,100)


 where 
start_txn_date >= date'2014-01-01'  and start_txn_date < date'2014-02-01' 

group by 1,2 ,3 
;

------------------Final Query to pull the info -------------


select    CAST( SLS.YEARMONTH||'01' AS DATE  FORMAT 'yyyymmdd' )   , sls.* ,oos.*   
 
 
 from 
  prod_wa_query.RDA_product_instr_Sales  sls 
 full outer join 
prod_wa_query.RDA_OOS  oos

on 
    sls.dept_name =  oos.dept_name
and  sls.yearmonth    =  oos.YearMonth
and  sls.store_nbr =    oos.store_nbr

where sls.yearmonth ='201401' 
and oos.store_nbr = '1030' 


 
 