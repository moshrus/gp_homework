--Hub 
   
       CREATE TABLE Hub_Customer (
        Customer_HashKey CHAR(32),
        c_custkey INTEGER NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Customer_HashKey);

    insert into Hub_Customer (Customer_HashKey, c_custkey, LoadDate, RecordSource)
    select distinct  
        md5(c_custkey::text),
        c_custkey,
        now(),
        'source_hw2'
    from customer;
    
       CREATE TABLE Hub_Order (
        Order_HashKey CHAR(32),
        o_orderkey INTEGER NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Order_HashKey);

    insert into Hub_Order (Order_HashKey, o_orderkey, LoadDate, RecordSource)
    select distinct
        md5(O_ORDERKEY::text),
        O_ORDERKEY,
        now(),
        'source_hw2'
    from orders;
    
       CREATE TABLE Hub_Supplier (
        Supplier_HashKey CHAR(32),
        S_SUPPKEY INTEGER NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Supplier_HashKey);
    
    insert into Hub_Supplier (Supplier_HashKey, S_SUPPKEY, LoadDate, RecordSource)
    select distinct  
        md5(S_SUPPKEY::text),
        S_SUPPKEY,
        now(),
        'source_hw2'
    from supplier;
    
       CREATE TABLE Hub_Part (
        Part_HashKey CHAR(32),
        P_PARTKEY INTEGER NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Part_HashKey);

    insert into Hub_Part (Part_HashKey, P_PARTKEY, LoadDate, RecordSource)
    select distinct
        md5(P_PARTKEY::text),
        P_PARTKEY,
        now(),
        'source_hw2'
    from part;
    
    drop table Hub_LineItem
       CREATE TABLE Hub_LineItem (
        LineItem_HashKey CHAR(32) NOT NULL,
        L_LINENUMBER INTEGER NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (LineItem_HashKey);
    
    insert into Hub_LineItem (LineItem_HashKey, L_LINENUMBER, LoadDate, RecordSource)
    select distinct
        md5(L_LINENUMBER::text) as LineItem_HashKey,
        L_LINENUMBER,
        now(),
        'source_hw2'
    from lineitem;
    
--Links
       CREATE TABLE Link_Customer_Order (
        Link_HashKey CHAR(32) NOT NULL,
        Customer_HashKey CHAR(32) NOT NULL,
        Order_HashKey CHAR(32) NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Link_HashKey);

    insert into Link_Customer_Order (
        Link_HashKey, Customer_HashKey, Order_HashKey,
        LoadDate, RecordSource
    )
    select  
        MD5(CONCAT(MD5(CAST(o_custkey AS TEXT)), MD5(CAST(o_orderkey AS TEXT)))) AS Link_HashKey,
        MD5(CAST(o_custkey AS TEXT)) AS Customer_HashKey,
        MD5(CAST(o_orderkey AS TEXT)) AS Order_HashKey,
        now(),
        'source_hw2'
    from orders;
    
       CREATE TABLE Link_Order_LineItem (
        Link_HashKey CHAR(32) NOT NULL,
        Order_HashKey CHAR(32) NOT NULL,
        LineItem_HashKey CHAR(32) NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Link_HashKey);

    insert into Link_Order_LineItem (
        Link_HashKey, Order_HashKey, LineItem_HashKey,
        LoadDate, RecordSource
    )
    select MD5(CONCAT(MD5(CAST(l_orderkey AS TEXT)), MD5(CAST(l_linenumber AS TEXT)))) AS Link_HashKey,
        MD5(CAST(l_orderkey AS TEXT)) AS Order_HashKey,
        MD5(CAST(l_linenumber AS TEXT)) AS LineItem_HashKey,
        now(),
        'source_hw2'
    from LINEITEM;
    
       CREATE TABLE Link_Supplier_Part (
        Link_HashKey CHAR(32) NOT NULL,
        Supplier_HashKey CHAR(32) NOT NULL,
        Part_HashKey CHAR(32) NOT NULL,
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=row, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Link_HashKey);

    insert into Link_Supplier_Part (
        Link_HashKey, Supplier_HashKey, Part_HashKey,
        LoadDate, RecordSource
    )
    select MD5(CONCAT(MD5(CAST(ps_suppkey AS TEXT)), MD5(CAST(ps_partkey AS TEXT)))) AS Link_HashKey,
        MD5(CAST(ps_suppkey AS TEXT)) AS Supplier_HashKey,
        MD5(CAST(ps_partkey AS TEXT)) AS Part_HashKey,
        now(),
        'source_hw2'
    from PARTSUPP;
    
--Satellites
       CREATE TABLE Satellite_Customer (
        Customer_HashKey CHAR(32) NOT NULL,
        c_name VARCHAR(25), 
        c_address VARCHAR(40), 
        c_phone VARCHAR(15),
        c_acctbal NUMERIC(15,2), 
        c_mktsegment VARCHAR(10), 
        c_comment VARCHAR(117),
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Customer_HashKey);

    INSERT INTO Satellite_Customer (Customer_HashKey,c_name, 
        c_address, c_phone,c_acctbal, c_mktsegment, c_comment, LoadDate, RecordSource)
    SELECT 
        MD5(CAST(c_custkey AS TEXT)) AS Customer_HashKey,
        c_name, 
        c_address, 
        c_phone,
        c_acctbal, 
        c_mktsegment, 
        c_comment,
        now(),
        'source_hw2'
    FROM CUSTOMER;
    
       CREATE TABLE Satellite_Order (
        Order_HashKey CHAR(32) NOT NULL,
        o_orderstatus VARCHAR(1), 
        o_totalprice NUMERIC(15,2), 
        o_orderdate DATE,
        o_orderpriority VARCHAR(15), 
        o_clerk VARCHAR(15), 
        o_shippriority INT, 
        o_comment VARCHAR(79),
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Order_HashKey);

    INSERT INTO Satellite_Order (Order_HashKey, o_orderstatus, o_totalprice, o_orderdate,
        o_orderpriority, o_clerk, o_shippriority, o_comment, LoadDate, RecordSource)
    SELECT 
        MD5(CAST(o_orderkey AS TEXT)) AS Order_HashKey,
        o_orderstatus,
        o_totalprice,
        o_orderdate,
        o_orderpriority,
        o_clerk,
        o_shippriority,
        o_comment,
        now(),
        'source_hw2'
    FROM ORDERS;
    
       CREATE TABLE Satellite_Supplier (
        Supplier_HashKey CHAR(32) NOT NULL,
        s_name VARCHAR(25), 
        s_address VARCHAR(40), 
        s_phone VARCHAR(15),
        s_acctbal NUMERIC(15,2), 
        s_comment VARCHAR(101),
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Supplier_HashKey);

    INSERT INTO Satellite_Supplier (Supplier_HashKey, s_name, s_address,
        s_phone, s_acctbal, s_comment, LoadDate, RecordSource)
    SELECT 
        MD5(CAST(s_suppkey AS TEXT)) AS Supplier_HashKey,
        s_name,
        s_address,
        s_phone,
        s_acctbal,
        s_comment,
        now(),
        'source_hw2'
    FROM SUPPLIER;
    
       CREATE TABLE Satellite_Part (
        Part_HashKey CHAR(32) NOT NULL,
        p_name VARCHAR(55), 
        p_mfgr VARCHAR(25), 
        p_brand VARCHAR(10),
        p_type VARCHAR(25), 
        p_size INT, 
        p_container VARCHAR(10),
        p_retailprice NUMERIC(15,2), 
        p_comment VARCHAR(23),
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (Part_HashKey);

    INSERT INTO Satellite_Part (Part_HashKey, p_name, p_mfgr,p_brand, p_type, p_size,
        p_container, p_retailprice, p_comment, LoadDate, RecordSource)
    SELECT 
        MD5(CAST(p_partkey AS TEXT)) AS Part_HashKey,
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_size,
        p_container,
        p_retailprice,
        p_comment,
        now(),
        'source_hw2'
    FROM PART;
    
       CREATE TABLE Satellite_LineItem (
        LineItem_HashKey CHAR(32) NOT NULL,
        l_quantity NUMERIC(15,2), 
        l_extendedprice NUMERIC(15,2), 
        l_discount NUMERIC(15,2),
        l_tax NUMERIC(15,2), 
        l_returnflag VARCHAR(1), 
        l_linestatus VARCHAR(1),
        l_shipdate DATE,
        l_commitdate DATE,
        l_receiptdate DATE,
        l_shipinstruct VARCHAR(25),
        l_shipmode VARCHAR(10),
        l_comment VARCHAR(44),
        LoadDate TIMESTAMP NOT NULL,
        RecordSource VARCHAR(50) NOT NULL
        )
       WITH (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=2)
       DISTRIBUTED BY (LineItem_HashKey);

    INSERT INTO Satellite_LineItem (LineItem_HashKey, l_quantity, l_extendedprice, l_discount,l_tax,
        l_returnflag, l_linestatus, l_shipdate, l_commitdate, l_receiptdate, l_shipinstruct,
        l_shipmode, l_comment, LoadDate, RecordSource)
    SELECT 
        MD5(CAST(l_linenumber AS TEXT)) AS LineItem_HashKey,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_returnflag,
        l_linestatus,
        l_shipdate,
        l_commitdate,
        l_receiptdate,
        l_shipinstruct,
        l_shipmode,
        l_comment,
        now(),
        'source_hw2'
    FROM LINEITEM;
    
select * 
  from Hub_Customer;
select * 
  from Hub_Order;
select * 
  from Hub_Supplier;
select * 
  from Hub_Part;
select * 
  from Hub_LineItem;
select * 
  from Link_Customer_Order;
select * 
  from Link_Order_LineItem;
select * 
  from Link_Supplier_Part;
select * 
  from Satellite_Customer;
select * 
  from Satellite_Order;
select * 
  from Satellite_Supplier;
select * 
  from Satellite_Part;
select * 
  from Satellite_LineItem;


