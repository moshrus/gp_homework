create or replace function project.fill_h_developer ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.h_developer';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);
  
  insert into project.h_developer (
      developer_key 
    , developer
    , load_date
  )
  with wt_data as (
    select distinct md5(p.developer::text) as developer_key
         , p.developer
      from project.stg_videogames_processed p
  )
  select d.developer_key
       , d.developer
       , current_timestamp as load_date
    from wt_data d
    left
    join project.h_developer g
      on d.developer_key = g.developer_key
   where g.developer_key is null
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

comment on function project.fill_h_developer() is 'Функция загрузки данных в таблицу project.h_developer';
