create or replace function project.fill_lnk_game_publisher ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.lnk_game_publisher';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);

  insert into project.lnk_game_publisher (
      lnk_game_publisher_key 
    , game_key
    , publisher_key
    , load_date
  )
  with wt_data as (
    select distinct md5(md5(p.game_id::text || md5(p.publisher::text))) as lnk_game_publisher_key
         , md5(p.game_id::text) as game_key
         , md5(p.publisher::text) as publisher_key
      from project.stg_videogames_processed p
  )
  select d.lnk_game_publisher_key
       , d.game_key
       , d.publisher_key
       , current_timestamp as load_date
    from wt_data d
    left
    join project.lnk_game_publisher l
      on d.lnk_game_publisher_key = l.lnk_game_publisher_key
   where l.lnk_game_publisher_key is null
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

comment on function project.fill_lnk_game_publisher() is 'Функция загрузки данных в таблицу project.lnk_game_publisher';
