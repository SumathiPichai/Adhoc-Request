 
 -----------Query to get the Sample customers -------------------------
 
 select customer_no,  avg(order_amount) , sum(order_amount), count(distinct order_no) cnt_order  ,  avg(days_bet_order )  avg_day ,
 count(distinct fw_end_date ) num_weeks ,
 sum( CNT_MNDY_ORDRS) as CNT_MNDY_ORDRS  , 
 sum(CNT_TUES_ORDRS) as CNT_TUES_ORDRS, 
 sum( CNT_WED_ORDRS) as CNT_WED_ORDRS , 
 sum(CNT_THU_ORDRS) as  CNT_THU_ORDRS , 
 sum( CNT_FRI_ORDRS) as CNT_FRI_ORDRS , 
 sum(CNT_SAT_ORDRS) as CNT_SAT_ORDRS , 
 sum(CNT_SUN_ORDRS) as CNT_SUN_ORDRS ,
 GREATEST(GREATEST( GREATEST(sum(CNT_MNDY_ORDRS) ,sum(CNT_TUES_ORDRS)),GREATEST(sum( CNT_WED_ORDRS),sum(CNT_THU_ORDRS))),
 GREATEST(GREATEST(sum(CNT_FRI_ORDRS), sum(CNT_SAT_ORDRS)), sum(CNT_SUN_ORDRS))) as MAX_ORDRS_SAME_DAY,
 min(pickup_date)  min_pick_date,  max(pickup_date)  max_pickup_date  
 
 
 from 
 (
 select  customer_no, order_no,  Order_Amount   ,  cast( pickup_dtime as date) as  pickup_date   , date1.fw_end_date ,   
 case when dow  = 1 then 1 else 0 end as CNT_MNDY_ORDRS, 
  case when dow  = 2 then 1 else 0 end as CNT_TUES_ORDRS, 
  case when dow  =3  then 1 else 0 end as CNT_WED_ORDRS, 
  case when dow  = 4 then 1 else 0 end as CNT_THU_ORDRS, 
  case when dow  = 5 then 1 else 0 end as CNT_FRI_ORDRS, 
  case when dow  = 6 then 1 else 0 end as CNT_SAT_ORDRS, 
  case when dow  = 7 then 1 else 0 end as CNT_SUN_ORDRS, 
 max (cast( pickup_dtime as date)) OVER (PARTITION BY  customer_no ORDER BY cast( pickup_dtime as date)  ROWS BETWEEN 1 following AND      1 following ) 
 as prev_pick_date  ,( prev_pick_date -  pickup_date) as  days_bet_order  
 
  from  PROD_EDW_SIF.MOR_SMKT_ECF_Order_header  a
  inner join 
  PROD_EDW_WIL.DIM_DATE_CURR_V    date1
  on 
  date1.clndr_date =  cast(pickup_dtime as date)
   
    where cast( ss_exp_tmstmp  as date) =date'2099-12-31'  and 
     cast(pickup_dtime as date) > current_date - 730 
   and Order_Status_Ind   in ('DIS','COL' ,'CLS' ) 
   and customer_no not in ( select shopperid  from  
 PROD_EDW_SIF.MOR_SMKT_STR_SHOPPERB2B
 where end_date =date'2099-12-31'  and record_deleted_flag = 0  ) 
 
 )  as A
 group by 1  having count(distinct order_no)  > 1  and max_pickup_date  > current_date - 15 
 and num_weeks > 100 
 
 order by  cnt_order desc  , avg_day asc 

 
 
 ---------Order information for the sample online customers  ---------
 
 SELECT  
	     ord.ShopperID as ShopperID  ,
 	       cast(a.pickup_dtime as date)  as pickup_dtime, 
	      CAST(OP.StockCode  AS VARCHAR(25))                                 AS ProdKeyCode ,
	       COALESCE( (CASE WHEN op.PricingUnit = 'Each' THEN 'EA' ELSE op.PricingUnit END )  ,'UNK')          AS UOM ,
	   sum(  COALESCE(OP.QUANTITY,0)    )                                       AS ProdQuantity ,
	  --   CASE WHEN op.PricingUnit = 'KG' THEN OP.QUANTITY ELSE (  COALESCE(HSM_PRODUCT.EACH_MULTIPLIER,0) * COALESCE(OP.QUANTITY,0) ) END AS Product_Measured_Quantity ,
	 --    CASE WHEN op.PricingUnit = 'KG' THEN 'KG' ELSE  HSM_PRODUCT.EACH_PRICING_UNIT   END    AS Measured_UOM ,
	  max(   case when OP.LineDiscount <> 0.00 or COALESCE(OP.LISTPRICE - OP.SALEPRICE,0) <> 0 then 'Y' else 'N' end) as PROMO_FLAG, 
     max(ECCPROD.mastersize) as mastersize ,
     max(ECCPROD.mastersizeUOM) as mastersizeUOM
	      
	 FROM
	     PROD_EDW_SIF.MOR_SMKT_ORD_ORDERPRODUCT OP
	   inner join 
	     PROD_EDW_SIF.MOR_SMKT_ECF_Order_header  a
           on 
            cast( a.ss_exp_tmstmp  as date) =date'2099-12-31'  
            and  cast(a.pickup_dtime as date) > current_date - 730 
            and a.Order_Status_Ind   in ('DIS','COL' ,'CLS' )  
            and  a.order_no = op.OrderID 
			and a.customer_no in  ( 1949715,
					2077943,
					2416522,
					252612,
					704339,
					557128,
					445495,
					383251,
					1964304,
					724627,
					555929,
					1854373,
					1605425,
					586780,
					299386,
					1805198,
					1902353,
					1898378,
					1804906,
					1538811)
	  LEFT JOIN PROD_EDW_sif.ECC_ARTICLE  ECCPROD
	 ON
	          ECCPROD.articlenumber = CAST(OP.StockCode AS VARCHAR(100))
	          and   ECCPROD.end_date =date'2099-12-31' and   ECCPROD.Record_Deleted_Flag = 0
	  INNER JOIN PROD_EDW_SIF.MOR_SMKT_ORD_ORDER ORD
	 ON
	     ORD.ID = OP.OrderID
	
	 LEFT JOIN PROD_EDW_SIF.MOR_SMKT_HSM_Product HSM_PRODUCT
	 ON
	     HSM_PRODUCT.REF_NO = OP.StockCode
	 AND HSM_PRODUCT.EACH_PRICING_UNIT = 'KG'
	 AND HSM_PRODUCT.Record_Deleted_Flag = 0
	 AND HSM_PRODUCT.End_Date = DATE '2099-12-31'
	 
	 LEFT JOIN PROD_EDW_SIF.MOR_SMKT_HSM_Product HSM_PRODUCT1
	 ON
	     HSM_PRODUCT1.REF_NO = OP.StockCode
	 --AND EACH_PRICING_UNIT = 'KG'
	 AND HSM_PRODUCT1.Record_Deleted_Flag = 0
	 AND HSM_PRODUCT1.End_Date = DATE '2099-12-31'
	 
	 WHERE 
	  OP.ss_exp_tmstmp = TIMESTAMP'2099-12-31 00:00:00'
	  and Shopperid in ( 1949715,
2077943,
2416522,
252612,
704339,
557128,
445495,
383251,
1964304,
724627,
555929,
1854373,
1605425,
586780,
299386,
1805198,
1902353,
1898378,
1804906,
1538811)
	 group by 1,2,3,4 
	 