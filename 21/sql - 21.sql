create table customer_order 
with (
    appendoptimized=true,
    orientation=column,
    compresstype=zstd,
    compresslevel=2
)
as
select s_o.o_orderstatus
     , s_o.o_totalprice
     , s_o.o_orderdate
     , s_o.o_orderpriority
     , s_o.o_clerk
     , s_o.o_shippriority 
     , s_o.o_comment
     , s_c.c_name 
     , s_c.c_address
     , s_c.c_phone
     , s_c.c_acctbal
     , s_c.c_mktsegment
     , s_c.c_comment  
  from Satellite_Order s_o
  join Link_Customer_Order l_c_o
    on l_c_o.Order_HashKey = s_o.Order_HashKey
  join Satellite_Customer s_c
    on s_c.Customer_HashKey = l_c_o.Customer_HashKey
distributed randomly
  ;

select * 
  from customer_order
  ;

create materialized view mv_sales_monthly 
as
select c_name
     , sum(o_totalprice) AS sum_totalprice
     , count(*) AS orders_cnt
  FROM customer_order
 GROUP BY c_name
distributed randomly
  ;

select * 
  from mv_sales_monthly
  ;

select c.c_name
     , c.o_orderdate
     , c.o_totalprice
     , sum(c.o_totalprice) over (partition by c.c_name order by c.o_orderdate)
  from customer_order c
  ;

select c.c_name
     , c.o_orderdate
     , c.o_totalprice
     , lag(c.o_totalprice) over (partition by c.c_name order by c.o_orderdate) as prev_totalprice
  from customer_order c
  ;


