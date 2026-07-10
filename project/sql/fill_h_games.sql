create or replace function project.fill_h_games ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.h_games';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);

  
  insert into project.h_games (
      game_key 
    , game_id
    , load_date
  )
  with wt_data as (
    select distinct md5(p.game_id::text) as game_key
         , p.game_id
      from project.stg_videogames_processed p
  )
  select d.game_key
       , d.game_id
       , current_timestamp as load_date
    from wt_data d
    left
    join project.h_games g
      on d.game_key = g.game_key
   where g.game_key is null
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

comment on function project.fill_h_games() is 'Функция загрузки данных в таблицу project.h_games';
