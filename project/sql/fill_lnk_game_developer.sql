create or replace function project.fill_lnk_game_developer ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.lnk_game_developer';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);

  insert into project.lnk_game_developer (
      lnk_game_developer_key 
    , game_key
    , developer_key
    , load_date
  )
  with wt_data as (
    select distinct md5(md5(p.game_id::text || md5(p.developer::text))) as lnk_game_developer_key
         , md5(p.game_id::text) as game_key
         , md5(p.developer::text) as developer_key
      from project.stg_videogames_processed p
  )
  select d.lnk_game_developer_key
       , d.game_key
       , d.developer_key
       , current_timestamp as load_date
    from wt_data d
    left
    join project.lnk_game_developer l
      on d.lnk_game_developer_key = l.lnk_game_developer_key
   where l.lnk_game_developer_key is null
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

comment on function project.fill_lnk_game_developer() is 'Функция загрузки данных в таблицу project.lnk_game_developer';
