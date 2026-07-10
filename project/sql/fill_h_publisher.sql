create or replace function project.fill_h_publisher ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.h_publisher';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);
  
  insert into project.h_publisher (
      publisher_key 
    , publisher
    , load_date
  )
  with wt_data as (
    select distinct md5(p.publisher::text) as publisher_key
         , p.publisher
      from project.stg_videogames_processed p
  )
  select d.publisher_key
       , d.publisher
       , current_timestamp as load_date
    from wt_data d
    left
    join project.h_publisher g
      on d.publisher_key = g.publisher_key
   where g.publisher_key is null
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

comment on function project.fill_h_publisher() is 'Функция загрузки данных в таблицу project.h_publisher';
