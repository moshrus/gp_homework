create or replace function project.fill_h_platform ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.h_platform';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);
  
  insert into project.h_platform (
      platform_key 
    , platform
    , load_date
  )
  with wt_data as (
    select distinct md5(p.platform::text) as platform_key
         , p.platform
      from project.stg_videogames_processed p
  )
  select d.platform_key
       , d.platform
       , current_timestamp as load_date
    from wt_data d
    left
    join project.h_platform g
      on d.platform_key = g.platform_key
   where g.platform_key is null
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

comment on function project.fill_h_platform() is 'Функция загрузки данных в таблицу project.h_platform';
