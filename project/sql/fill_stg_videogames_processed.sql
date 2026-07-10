create or replace function project.fill_stg_videogames_processed ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.stg_videogames_processed';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
  lv_Sql                     text;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);

  lv_Sql = 'truncate table project.stg_videogames_processed;';

  execute lv_Sql;

  insert into project.stg_videogames_processed
  select * 
    from project.ext_videogames_processed 
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

comment on function project.fill_stg_videogames_processed() is 'Функция загрузки данных в таблицу project.stg_videogames_processed';
