create or replace function project.fill_dm_platform_price ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.dm_platform_price';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
  lv_MinDate                 date;
  lv_MaxDate                 date;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);

  select min(p.obs_date), max(p.obs_date)
    into lv_MinDate, lv_MaxDate
    from (select distinct p.obs_date::date
            from project.stg_videogames_processed p) p
    ;

  delete 
    from project.dm_platform_price g
   where g.on_date >= lv_MinDate
   ;

  insert into project.dm_platform_price (
      on_date
    , platform
    , avg_price_usd
  )
  select p.on_date
       , p.platform
       , avg(p.price_usd) as avg_price_usd
    from project.dm_videogames_processed p
   where p.on_date between lv_MinDate and lv_MaxDate
   group by p.on_date
       , p.platform
  ;

  GET DIAGNOSTICS lv_InsertedRows = ROW_COUNT;   

  perform project.write_log(lc_TableName, 'End loading ' || lc_TableName || ', insert ' || lv_InsertedRows::varchar || ' rows');

exception
when others then 
  get stacked diagnostics
    lv_ErrorState       = RETURNED_SQLSTATE
  , lv_ErrorMessage     = MESSAGE_TEXT;

  perform project.write_log(lc_TableName, 'Error ' || lv_ErrorState || ', ' || lv_ErrorMessage);

end;
$body$;

comment on function project.fill_dm_videogames_processed() is 'Функция загрузки данных в таблицу project.dm_videogames_processed';
