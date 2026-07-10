create or replace function project.fill_dm_videogames_processed ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.dm_videogames_processed';
  lc_MaxDate        constant date    := date'2999-12-31';
  lv_InsertedRows            integer := 0;
  lv_ErrorState              text;
  lv_ErrorMessage            text;
  lv_MinDate                 date;
  lv_MaxDate                 date;
begin
  perform project.write_log(lc_TableName, 'Start loading ' || lc_TableName);

  --greatest(min(p.obs_date), date'2022-12-31'), least(max(p.obs_date), date'2024-01-01')
  select min(p.obs_date), max(p.obs_date)
    into lv_MinDate, lv_MaxDate
    from (select distinct p.obs_date::date
            from project.stg_videogames_processed p) p
    ;

  delete 
    from project.dm_videogames_processed g
   where g.on_date >= lv_MinDate
   ;

if lv_MinDate = lv_MaxDate then 
--если необходимо пересчитывать один день:
 drop table if exists tmp_all_data;

 create temporary table tmp_all_data
 with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
 on commit drop
 as
  with wt_sat_lnk_game_platform_price as (
    select lnk_game_platform_key
         , price_usd
         , discount_pct
         , sale_event_name
         , start_date
         , cast(lead(start_date, 1, date'2999-12-31') over (partition by lnk_game_platform_key order by start_date) - interval'1 day' as date) as end_date
      from project.sat_lnk_game_platform_price
  )
  , wt_sat_games_review as (
    select game_key
         , review_count
         , positive_reviews
         , negative_reviews
         , start_date
         , cast(lead(start_date, 1, date'2999-12-31') over (partition by game_key order by start_date) - interval'1 day' as date) as end_date
      from project.sat_games_review 
  )
  , wt_sat_games as (
    select game_key
         , game_name
         , genre
         , age_rating
         , release_date
         , start_date
         , cast(lead(start_date, 1, date'2999-12-31') over (partition by game_key order by start_date) - interval'1 day' as date) as end_date
      from project.sat_games
  )
  , wt_all_data as (
    select g.game_id
         , p.platform
         , gpp.price_usd
         , gpp.discount_pct
         , gpp.sale_event_name
         , gpp.start_date as gpp_start_date
         , gpp.end_date as gpp_end_date
         , gr.review_count
         , gr.positive_reviews
         , gr.negative_reviews
         , gr.start_date as gr_start_date
         , gr.end_date as gr_end_date
         , sg.game_name
         , sg.genre
         , sg.age_rating
         , sg.release_date
         , sg.start_date as sg_start_date
         , sg.end_date as sg_end_date
         , d.developer
         , pr.publisher
      from project.h_games g
      join project.lnk_game_platform gp
        on g.game_key = gp.game_key
      join project.h_platform p
        on p.platform_key = gp.platform_key
      join wt_sat_lnk_game_platform_price gpp
        on gp.lnk_game_platform_key = gpp.lnk_game_platform_key
       and lv_MaxDate between gpp.start_date and gpp.end_date
      join wt_sat_games_review gr
        on gr.game_key = g.game_key
       and lv_MaxDate between gr.start_date and gr.end_date
      join wt_sat_games sg
        on sg.game_key = g.game_key
       and lv_MaxDate between sg.start_date and sg.end_date
      join project.lnk_game_developer gd
        on gd.game_key = g.game_key
      join project.h_developer d
        on d.developer_key = gd.developer_key
      join project.lnk_game_publisher gpr
        on gpr.game_key = g.game_key
      join project.h_publisher pr
        on pr.publisher_key = gpr.publisher_key
  )
  select *
    from wt_all_data
  distributed randomly
  ;

  perform project.write_log(lc_TableName, 'Step 1 end ');
  
  insert into project.dm_videogames_processed (
      on_date
    , game_id
    , platform
    , price_usd
    , discount_pct
    , sale_event_name
    , review_count
    , positive_reviews
    , negative_reviews
    , game_name
    , genre
    , age_rating
    , release_date
    , developer
    , publisher
  )
  select lv_MinDate as on_date
       , d.game_id
       , d.platform
       , d.price_usd
       , d.discount_pct
       , d.sale_event_name
       , d.review_count
       , d.positive_reviews
       , d.negative_reviews
       , d.game_name
       , d.genre
       , d.age_rating
       , d.release_date
       , d.developer
       , d.publisher
    from tmp_all_data d
  ;

--если необходимо пересчитывать несколько дней, то быстрее так:
else 

 drop table if exists tmp_all_data;

 create temporary table tmp_all_data
 with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
 on commit drop
 as
  with wt_sat_lnk_game_platform_price as (
    select lnk_game_platform_key
         , price_usd
         , discount_pct
         , sale_event_name
         , start_date
         , cast(lead(start_date, 1, date'2999-12-31') over (partition by lnk_game_platform_key order by start_date) - interval'1 day' as date) as end_date
      from project.sat_lnk_game_platform_price
  )
  , wt_sat_games_review as (
    select game_key
         , review_count
         , positive_reviews
         , negative_reviews
         , start_date
         , cast(lead(start_date, 1, date'2999-12-31') over (partition by game_key order by start_date) - interval'1 day' as date) as end_date
      from project.sat_games_review 
  )
  , wt_sat_games as (
    select game_key
         , game_name
         , genre
         , age_rating
         , release_date
         , start_date
         , cast(lead(start_date, 1, date'2999-12-31') over (partition by game_key order by start_date) - interval'1 day' as date) as end_date
      from project.sat_games
  )
  , wt_all_data as (
    select g.game_id
         , p.platform
         , gpp.price_usd
         , gpp.discount_pct
         , gpp.sale_event_name
         , gpp.start_date as gpp_start_date
         , gpp.end_date as gpp_end_date
         , gr.review_count
         , gr.positive_reviews
         , gr.negative_reviews
         , gr.start_date as gr_start_date
         , gr.end_date as gr_end_date
         , sg.game_name
         , sg.genre
         , sg.age_rating
         , sg.release_date
         , sg.start_date as sg_start_date
         , sg.end_date as sg_end_date
         , d.developer
         , pr.publisher
      from project.h_games g
      join project.lnk_game_platform gp
        on g.game_key = gp.game_key
      join project.h_platform p
        on p.platform_key = gp.platform_key
      join wt_sat_lnk_game_platform_price gpp
        on gp.lnk_game_platform_key = gpp.lnk_game_platform_key
      join wt_sat_games_review gr
        on gr.game_key = g.game_key
      join wt_sat_games sg
        on sg.game_key = g.game_key
      join project.lnk_game_developer gd
        on gd.game_key = g.game_key
      join project.h_developer d
        on d.developer_key = gd.developer_key
      join project.lnk_game_publisher gpr
        on gpr.game_key = g.game_key
      join project.h_publisher pr
        on pr.publisher_key = gpr.publisher_key
     where gpp.start_date <= gr.end_date
       and gpp.end_date >= gr.start_date
       and gpp.start_date <= sg.end_date
       and gpp.end_date >= sg.start_date
       and gr.start_date <= sg.end_date
       and gr.end_date >= sg.start_date
  )
  select *
    from wt_all_data
  distributed randomly
  ;

  perform project.write_log(lc_TableName, 'Step 1 end ');
  
  insert into project.dm_videogames_processed (
      on_date
    , game_id
    , platform
    , price_usd
    , discount_pct
    , sale_event_name
    , review_count
    , positive_reviews
    , negative_reviews
    , game_name
    , genre
    , age_rating
    , release_date
    , developer
    , publisher
  )
  with wt_dates as (
    select generate_series(lv_MinDate, lv_MaxDate, '1 day'::interval) as on_date
  )
  select dt.on_date
       , d.game_id
       , d.platform
       , d.price_usd
       , d.discount_pct
       , d.sale_event_name
       , d.review_count
       , d.positive_reviews
       , d.negative_reviews
       , d.game_name
       , d.genre
       , d.age_rating
       , d.release_date
       , d.developer
       , d.publisher
    from wt_dates dt
    join tmp_all_data d
      on dt.on_date between d.gpp_start_date and d.gpp_end_date
     and dt.on_date between d.gr_start_date and d.gr_end_date
     and dt.on_date between d.sg_start_date and d.sg_end_date
  ;

end if;

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
