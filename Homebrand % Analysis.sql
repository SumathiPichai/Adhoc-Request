select     
 cast((start_txn_date (format 'YYYYMM')) as char(6)) as YearMonth  
  , sum (case when hmbrnd.article_id  is  null  then 0.0000 else TOT_AMT_INCLD_GST end   )  as HB_SALES_AMT
  , sum (TOT_AMT_INCLD_GST)   as  Total_sales_amt 
  , sum( TOT_AMT_INCLD_GST /(1+(gst_pct/100)) ) as Total_sales_amt_excld_gst 
  ,  sum (case when hmbrnd.article_id  is  null  then 0.0000  else (TOT_AMT_INCLD_GST /(1+(gst_pct/100)) ) end ) as HB_sales_amt_excld_gst 

from PROD_EDW_IDS.prod_SALES_SUMMARY pss 
  left join 
	      PROD_WA_QUERY.Homebrand_art  hmbrnd
	      on 
          cast( hmbrnd.article_id as varchar(50) )   = pss.item_nbr 

 where checkout_nbr = 100 and 
division_nbr = '1005' and 
   start_txn_date  >= date'2016-07-01' 
  group by 1;
  
  
  
SELECT 
           cast((orl.pickup_dtime (format 'YYYYMM')) as char(6)) as YearMonth  
           , sum(COALESCE(CAST(INV.Invoice_Line_Amount 	AS DECIMAL(14,4))	,0.0000) ) 	as total_invc_amt 
           , sum(case when hmbrnd.article_id  is  null  then 0.0000 else ( COALESCE(CAST(INV.Invoice_Line_Amount 	AS DECIMAL(14,4))	,0.0000)) end )	as HB_invc_amt 
                ,  sum(COALESCE(CAST(INV.Invoice_Line_Amount 	AS DECIMAL(14,4))	,0.0000) / ( 1 + (COALESCE(CAST(INV.Tax_rate		AS  DECIMAL(14,4)),0.00)	/100) ) ) AS  total_invc_amt_excld_gst 
                  ,  sum(case when hmbrnd.article_id  is  null  then 0.0000 else(COALESCE(CAST(INV.Invoice_Line_Amount 	AS DECIMAL(14,4))	,0.0000) / ( 1 + (COALESCE(CAST(INV.Tax_rate		AS  DECIMAL(14,4)),0.00)	/100) ) )  end ) AS  HB_invc_amt_excld_gst 
                 
          
     
      FROM      PROD_EDW_SIF.MOR_SMKT_ECF_Order_Detail ord
      
     INNER  JOIN PROD_EDW_SIF.MOR_SMKT_ECF_Order_Header orl
      	ON ord.order_no  = orl.Order_No
      	AND  orl.ss_exp_tmstmp = TIMESTAMP'2099-12-31 00:00:00'

                	      	 
     	  LEFT OUTER JOIN 	PROD_EDW_SIF.MOR_SMKT_ECF_Invoice_detail  inv
     	 
     	  ON 			ord.Order_no = inv.order_no
     	  AND 			ord.line_no  = inv.order_line_no
     	   AND          inv.ss_exp_tmstmp = TIMESTAMP'2099-12-31 00:00:00'
     	   AND           inv.branch_no = ord.branch_no 
     	  left join 
	      PROD_WA_QUERY.Homebrand_art  hmbrnd
	      on 
           hmbrnd.article_id = COALESCE( inv.stockcode,ord.stockcode)
   
   WHERE 
              	 ord.ss_exp_tmstmp = TIMESTAMP'2099-12-31 00:00:00'  
              	 and  cast(orl.pickup_dtime as date) >= date'2016-07-01' 
                  and orl.Order_Status_Ind   in ('DIS','COL' ,'CLS' ) 
          group by 1