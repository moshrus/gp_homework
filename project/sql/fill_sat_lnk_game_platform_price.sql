create or replace function project.fill_sat_lnk_game_platform_price ()
returns void
language plpgsql
as $body$
declare
  lc_TableName      constant varchar := 'project.sat_lnk_game_platform_price';
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
    from project.sat_lnk_game_platform_price g
   where g.start_date >= lv_MinDate
   ;

  drop table if exists tmp_sat_lnk_game_platform_price;

  create temporary table tmp_sat_lnk_game_platform_price
  with (appendoptimized = true, orientation = column)
  on commit drop
  as 
  select distinct md5(md5(p.game_id::text || md5(p.platform::text))) as lnk_game_platform_key
       , p.current_price_usd::numeric as price_usd
       , p.discount_pct::numeric as discount_pct
       , case 
           when p.sale_event_name = 'none'
             then null
           else p.sale_event_name
         end as sale_event_name
       , p.obs_date::date as start_date
    from project.stg_videogames_processed p
  distributed by (lnk_game_platform_key)
  ;

  insert into project.sat_lnk_game_platform_price (
      lnk_game_platform_key
    , price_usd
    , discount_pct
    , sale_event_name
    , start_date
    , hash_value
  )
  with wt_hash_data as (
    select d.lnk_game_platform_key
         , d.price_usd
         , d.discount_pct
         , d.sale_event_name
         , d.start_date
         , md5(coalesce(d.price_usd::varchar, '-') || coalesce(d.discount_pct::varchar, '-') || coalesce(d.sale_event_name, '-')) as hash_value
      from tmp_sat_lnk_game_platform_price d
  )
  , wt_prev_hash_data as (
    select d.*
         , lag(d.hash_value, 1, '-') over (partition by d.lnk_game_platform_key order by d.start_date) as prev_hash_value
      from wt_hash_data d
  )
  , wt_versioned_data as (
    select d.*
         , sum(case when hash_value = prev_hash_value then 0 else 1 end) over (partition by d.lnk_game_platform_key order by d.start_date) as version_num
      from wt_prev_hash_data d
  )
  , wt_grouped_data as (
    select d.lnk_game_platform_key
         , d.price_usd
         , d.discount_pct
         , d.sale_event_name
         , d.start_date
         , d.hash_value
         , max(d.start_date) over (partition by d.lnk_game_platform_key) as max_start_date
      from (select d.lnk_game_platform_key
                 , d.version_num
                 , min(d.price_usd) as price_usd
                 , min(d.discount_pct) as discount_pct
                 , min(d.sale_event_name) as sale_event_name
                 , min(d.start_date) as start_date
                 , min(d.hash_value) as hash_value
              from wt_versioned_data d
             group by d.lnk_game_platform_key
                 , d.version_num) d
  )
  , wt_trg_data as (
    select g.lnk_game_platform_key
         , g.hash_value 
      from (select g.lnk_game_platform_key
                 , g.start_date
                 , g.hash_value 
                 , max(g.start_date) over (partition by g.lnk_game_platform_key) as max_start_date
              from project.sat_lnk_game_platform_price g
             where g.start_date < lv_MinDate) g
     where g.start_date = g.max_start_date
  )
  select d.lnk_game_platform_key
       , d.price_usd
       , d.discount_pct
       , d.sale_event_name
       , d.start_date
       , d.hash_value
    from wt_grouped_data d
    left 
    join wt_trg_data trg 
      on d.lnk_game_platform_key = trg.lnk_game_platform_key
     and d.hash_value = trg.hash_value
     and d.start_date = d.max_start_date
   where trg.lnk_game_platform_key is null
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

comment on function project.fill_sat_lnk_game_platform_price() is 'Функция загрузки данных в таблицу project.sat_lnk_game_platform_price';
