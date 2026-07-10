create or replace function project.fill_sat_games_review ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.sat_games_review';
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
    from project.sat_games_review g
   where g.start_date >= lv_MinDate
   ;

  drop table if exists tmp_sat_games_review;

  create temporary table tmp_sat_games_review
  with (appendoptimized = true, orientation = column)
  on commit drop
  as 
  select md5(p.game_id::text) as game_key
       , replace(p.review_count, '.0', '')::integer as review_count
       , replace(p.positive_reviews, '.0', '')::integer as positive_reviews
       , replace(p.negative_reviews, '.0', '')::integer as negative_reviews
       , p.obs_date::date as start_date
    from project.stg_videogames_processed p
  distributed by (game_key)
  ;

  insert into project.sat_games_review (
      game_key
    , review_count
    , positive_reviews
    , negative_reviews
    , start_date
    , hash_value
  )
  with wt_hash_data as (
    select d.game_key
         , d.review_count
         , d.positive_reviews
         , d.negative_reviews
         , d.start_date
         , md5(coalesce(d.review_count::varchar, '-') || coalesce(d.positive_reviews::varchar, '-') || coalesce(d.negative_reviews::varchar, '-')) as hash_value
      from tmp_sat_games_review d
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
         , d.review_count
         , d.positive_reviews
         , d.negative_reviews
         , d.start_date
         , d.hash_value
         , max(d.start_date) over (partition by d.game_key) as max_start_date
      from (select d.game_key
                 , d.version_num
                 , min(d.review_count) as review_count
                 , min(d.positive_reviews) as positive_reviews
                 , min(d.negative_reviews) as negative_reviews
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
              from project.sat_games_review g
             where g.start_date < lv_MinDate) g
     where g.start_date = g.max_start_date
  )
  select d.game_key
       , d.review_count
       , d.positive_reviews
       , d.negative_reviews
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

comment on function project.fill_sat_games_review() is 'Функция загрузки данных в таблицу project.sat_games_review';
