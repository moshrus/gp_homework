--Query 1: Retrieve Customer Orders with Order and Customer Details
select o.o_orderkey
     , o.o_orderstatus
     , o.o_totalprice
     , o.o_orderdate
     , o.o_orderpriority
     , o.o_clerk
     , o.o_shippriority 
     , o.o_comment
     , c.c_custkey
     , c.c_name 
     , c.c_address
     , c.c_phone
     , c.c_acctbal
     , c.c_mktsegment
     , c.c_comment  
  from orders o 
  join customer c 
    on o.o_custkey = c.c_custkey
  ;

select h_o.o_orderkey
     , s_o.o_orderstatus
     , s_o.o_totalprice
     , s_o.o_orderdate
     , s_o.o_orderpriority
     , s_o.o_clerk
     , s_o.o_shippriority 
     , s_o.o_comment
     , h_c.c_custkey
     , s_c.c_name 
     , s_c.c_address
     , s_c.c_phone
     , s_c.c_acctbal
     , s_c.c_mktsegment
     , s_c.c_comment  
  from Hub_Order h_o 
  join Satellite_Order s_o
    on h_o.Order_HashKey = s_o.Order_HashKey
  join Link_Customer_Order l_c_o
    on l_c_o.Order_HashKey = h_o.Order_HashKey
  join Hub_Customer h_c 
    on h_c.Customer_HashKey = l_c_o.Customer_HashKey
  join Satellite_Customer s_c
    on s_c.Customer_HashKey = h_c.Customer_HashKey
  ;

--Query 2: Retrieve Detailed Order Information with Line Items
select o.o_orderkey 
     , o.o_orderstatus
     , o.o_totalprice
     , o.o_orderdate
     , o.o_orderpriority
     , o.o_clerk
     , o.o_shippriority
     , o.o_comment
     , l.l_linenumber
     , l.l_quantity
     , l.l_extendedprice
     , l.l_discount 
     , l.l_tax
     , l.l_returnflag
     , l.l_linestatus
     , l.l_shipdate
     , l.l_commitdate
     , l.l_receiptdate
     , l.l_shipinstruct
     , l.l_shipmode
     , l.l_comment
  from lineitem l 
  join orders o
    on l.l_orderkey = o.o_orderkey
    ;

select h_o.o_orderkey 
     , s_o.o_orderstatus
     , s_o.o_totalprice
     , s_o.o_orderdate
     , s_o.o_orderpriority
     , s_o.o_clerk
     , s_o.o_shippriority
     , s_o.o_comment
     , h_l.l_linenumber
     , s_l.l_quantity
     , s_l.l_extendedprice
     , s_l.l_discount 
     , s_l.l_tax
     , s_l.l_returnflag
     , s_l.l_linestatus
     , s_l.l_shipdate
     , s_l.l_commitdate
     , s_l.l_receiptdate
     , s_l.l_shipinstruct
     , s_l.l_shipmode
     , s_l.l_comment
  from Hub_Order h_o 
  join Satellite_Order s_o
    on h_o.Order_HashKey = s_o.Order_HashKey
  join Link_Order_LineItem l_o_l
    on l_o_l.Order_HashKey = h_o.Order_HashKey
  join Hub_LineItem h_l
    on h_l.LineItem_HashKey = l_o_l.LineItem_HashKey
  join Satellite_LineItem s_l
    on s_l.LineItem_HashKey = h_l.LineItem_HashKey
    ;

--Query 3: Retrieve Supplier and Part Information for Each Supplier-Part Relationship
select s.s_name
     , s.s_address
     , s.s_comment
     , p.p_name
     , p.p_mfgr
     , p.p_brand
     , p.p_type
     , p.p_comment 
  from supplier s 
  join partsupp ps
    on s.s_suppkey = ps.ps_suppkey
  join part p 
    on ps.ps_partkey = p.p_partkey
    ;

select s_s.s_name
     , s_s.s_address
     , s_s.s_comment
     , s_p.p_name
     , s_p.p_mfgr
     , s_p.p_brand
     , s_p.p_type
     , s_p.p_comment 
  from Satellite_Supplier s_s
  join Link_Supplier_Part l_s_p
    on l_s_p.Supplier_HashKey = s_s.Supplier_HashKey
  join Satellite_Part s_p
    on s_p.Part_HashKey = l_s_p.Part_HashKey
    ;
  
--Query 4: Retrieve Comprehensive Customer Order and Line Item Details
select l_linenumber
	 , l_quantity
	 , l_extendedprice
	 , l_discount
	 , l_tax
	 , l_returnflag
	 , l_linestatus
	 , l_shipdate
	 , l_commitdate
	 , l_receiptdate
	 , l_shipinstruct
	 , l_shipmode
	 , o.o_orderstatus
	 , o.o_totalprice
	 , o.o_orderdate
	 , o.o_orderpriority
	 , o.o_clerk
	 , o.o_shippriority
	 , o.o_comment
  from lineitem l 
  join orders o 
    on l.l_orderkey = o.o_orderkey
    ;

select h_l.l_linenumber
	 , s_l.l_quantity
	 , s_l.l_extendedprice
	 , s_l.l_discount
	 , s_l.l_tax
	 , s_l.l_returnflag
	 , s_l.l_linestatus
	 , s_l.l_shipdate
	 , s_l.l_commitdate
	 , s_l.l_receiptdate
	 , s_l.l_shipinstruct
	 , s_l.l_shipmode
	 , s_o.o_orderstatus
	 , s_o.o_totalprice
	 , s_o.o_orderdate
	 , s_o.o_orderpriority
	 , s_o.o_clerk
	 , s_o.o_shippriority
	 , s_o.o_comment
  from Hub_LineItem h_l
  join Satellite_LineItem s_l
    on h_l.LineItem_HashKey = s_l.LineItem_HashKey
  join Link_Order_LineItem l_o_l
    on l_o_l.LineItem_HashKey = s_l.LineItem_HashKey
  join Satellite_Order s_o
    on s_o.Order_HashKey = l_o_l.Order_HashKey
    ;
