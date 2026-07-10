create or replace function project.fill_sat_games ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.sat_games';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
  lv_MinDate                 date;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);

  select min(p.obs_date)
    into lv_MinDate
    from project.stg_videogames_processed p
    ;

  delete 
    from project.sat_games g
   where g.start_date >= lv_MinDate
   ;

  drop table if exists tmp_sat_games;

  create temporary table tmp_sat_games
  with (appendoptimized = true, orientation = column)
  on commit drop
  as 
  select md5(p.game_id::text) as game_key
       , p.game_name
       , p.genre
       , p.age_rating
       , p.release_date::date as release_date
       , p.obs_date::date as start_date
    from project.stg_videogames_processed p
  distributed by (game_key)
  ;

  insert into project.sat_games (
      game_key
    , game_name
    , genre
    , age_rating
    , release_date
    , start_date
    , hash_value
  )
  with wt_hash_data as (
    select d.game_key
         , d.game_name
         , d.genre
         , d.age_rating
         , d.release_date
         , d.start_date
         , md5(coalesce(d.game_name, '-') || coalesce(d.genre, '-') || coalesce(d.age_rating, '-') ||
               coalesce(d.release_date::varchar, '-')) as hash_value
      from tmp_sat_games d
  )
  , wt_prev_hash_data as (
    select d.*
         , lag(d.hash_value, 1, '-') over (partition by d.game_key order by d.start_date) as prev_hash_value
      from wt_hash_data d
  )
  , wt_versioned_data as (
    select d.*
         , sum(case when hash_value = prev_hash_value then 0 else 1 end) over (partition by d.game_key order by d.start_date) as version_num
      from wt_prev_hash_data d
  )
  , wt_grouped_data as (
    select d.game_key
         , d.version_num
         , d.game_name
         , d.genre
         , d.age_rating
         , d.release_date
         , d.start_date
         , d.hash_value
         , max(d.start_date) over (partition by d.game_key) as max_start_date
      from (select d.game_key
                 , d.version_num
                 , min(d.game_name) as game_name
                 , min(d.genre) as genre
                 , min(d.age_rating) as age_rating
                 , min(d.release_date) as release_date
                 , min(d.start_date) as start_date
                 , min(d.hash_value) as hash_value
              from wt_versioned_data d
             group by d.game_key
                 , d.version_num) d
  )
  , wt_trg_data as (
    select g.game_key
         , g.hash_value 
      from (select g.game_key
                 , g.start_date
                 , g.hash_value 
                 , max(g.start_date) over (partition by g.game_key) as max_start_date
              from project.sat_games g
             where g.start_date < lv_MinDate) g
     where g.start_date = g.max_start_date
  )
  select d.game_key
       , d.game_name
       , d.genre
       , d.age_rating
       , d.release_date
       , d.start_date
       , d.hash_value
    from wt_grouped_data d
    left 
    join wt_trg_data trg 
      on d.game_key = trg.game_key
     and d.hash_value = trg.hash_value
     and d.start_date = d.max_start_date
   where trg.game_key is null
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

comment on function project.fill_sat_games() is 'Функция загрузки данных в таблицу project.sat_games';
