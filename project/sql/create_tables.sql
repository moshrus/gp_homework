CREATE EXTENSION dblink;

CREATE SCHEMA project;

--таблица логов
create table project.log_table (
    log_id         bigserial
  , event_dt       timestamp default statement_timestamp()
  , object_name    varchar
  , event_message  varchar
)
with (appendoptimized = false)
distributed by (log_id);

--таблица настроек
create table project.settings(
    settings_name         varchar(25)
  , settings_value        varchar(100)
)
with(appendoptimized = false)
distributed replicated;

--вставка в таблицу настроек для записи логов
insert into project.settings(settings_name, settings_value)
values ('dblink_connect', 'host=127.0.0.1 dbname=test user=XXX password=XXX');  --проставить свои значения

--внешняя таблица источник
create external table project.ext_videogames_processed (
    game_id text,
    platform text,
    platform_code text,
    storefront text,
    obs_date text,
    days_since_release text,
    current_price_usd text,
    original_price_usd text,
    discount_pct text,
    is_on_sale text,
    sale_event_name text,
    lowest_price_usd text,
    decay_factor text,
    price_vs_launch text,
    concurrent_players text,
    peak_ccu_alltime text,
    review_count text,
    positive_reviews text,
    negative_reviews text,
    steam_rating_pct text,
    user_score text,
    metacritic_score text,
    wishlist_count text,
    twitch_viewers_proxy text,
    youtube_views_proxy text,
    reddit_mentions text,
    social_hype_index text,
    has_controversy text,
    controversy_day text,
    estimated_units_sold text,
    estimated_revenue_usd text,
    revenue_per_review text,
    revenue_per_player text,
    price_na text,
    price_eu text,
    price_gb text,
    price_jp text,
    price_br text,
    price_au text,
    game_name text,
    developer text,
    publisher text,
    publisher_tier text,
    franchise text,
    genre text,
    genre_code text,
    subgenre text,
    tags text,
    age_rating text,
    release_date text,
    release_year text,
    release_month text,
    release_quarter text,
    base_price_usd text,
    dlc_count text,
    expansion_count text,
    achievement_count text,
    supported_languages text,
    is_free_to_play text,
    is_indie text,
    is_early_access text,
    is_multiplayer text,
    is_online text,
    is_franchise text,
    is_sequel text,
    is_remaster text,
    is_remake text,
    is_crossplay text,
    has_crossbuy text,
    publisher_market_share text,
    publisher_avg_budget text,
    subscription_service text,
    discount_intensity text,
    affordability_index text,
    launch_price_decay text,
    price_change_abs text,
    price_change_pct text,
    price_7obs_avg text,
    price_30obs_avg text,
    price_volatility text,
    price_all_time_low text,
    is_all_time_low text,
    discount_frequency_proxy text,
    revenue_cumulative text,
    units_cumulative text,
    monetisation_intensity text,
    revenue_momentum_4w text,
    review_velocity text,
    review_growth_rate text,
    player_growth_rate text,
    ccu_7obs_avg text,
    ccu_30obs_avg text,
    hype_score text,
    virality_score text,
    influencer_boost_proxy text,
    popularity_momentum text,
    engagement_to_price text,
    review_times_rating text,
    critic_user_gap text,
    sentiment_stability text,
    controversy_score text,
    community_health_score text,
    tier_label text,
    is_aaa text,
    holiday_release_flag text,
    q4_release_flag text,
    launch_phase text,
    is_new_release text,
    days_since_release_log text,
    obs_month text,
    obs_year text,
    obs_quarter text,
    obs_dow text,
    is_q4 text,
    is_summer text,
    is_weekend_obs text,
    rating_drop_flag text,
    fake_discount_flag text,
    player_spike_flag text,
    review_inflation_flag text,
    genre_popularity_rank text,
    platform_popularity_rank text,
    target_ccu_next_4w text,
    target_revenue_next_4w text,
    target_price_next_4w text,
    target_review_count_next_4w text,
    target_is_on_sale_next_obs text,
    target_breakout_hit text,
    target_sleeper_hit text,
    target_long_tail text
    )
LOCATION('gpfdist://gpfdist_server:8080/videogames_processed.csv')
FORMAT 'CSV' (HEADER DELIMITER ';');

--промежуточная таблица загрузки
create table project.stg_videogames_processed (
    game_id text,
    platform text,
    platform_code text,
    storefront text,
    obs_date text,
    days_since_release text,
    current_price_usd text,
    original_price_usd text,
    discount_pct text,
    is_on_sale text,
    sale_event_name text,
    lowest_price_usd text,
    decay_factor text,
    price_vs_launch text,
    concurrent_players text,
    peak_ccu_alltime text,
    review_count text,
    positive_reviews text,
    negative_reviews text,
    steam_rating_pct text,
    user_score text,
    metacritic_score text,
    wishlist_count text,
    twitch_viewers_proxy text,
    youtube_views_proxy text,
    reddit_mentions text,
    social_hype_index text,
    has_controversy text,
    controversy_day text,
    estimated_units_sold text,
    estimated_revenue_usd text,
    revenue_per_review text,
    revenue_per_player text,
    price_na text,
    price_eu text,
    price_gb text,
    price_jp text,
    price_br text,
    price_au text,
    game_name text,
    developer text,
    publisher text,
    publisher_tier text,
    franchise text,
    genre text,
    genre_code text,
    subgenre text,
    tags text,
    age_rating text,
    release_date text,
    release_year text,
    release_month text,
    release_quarter text,
    base_price_usd text,
    dlc_count text,
    expansion_count text,
    achievement_count text,
    supported_languages text,
    is_free_to_play text,
    is_indie text,
    is_early_access text,
    is_multiplayer text,
    is_online text,
    is_franchise text,
    is_sequel text,
    is_remaster text,
    is_remake text,
    is_crossplay text,
    has_crossbuy text,
    publisher_market_share text,
    publisher_avg_budget text,
    subscription_service text,
    discount_intensity text,
    affordability_index text,
    launch_price_decay text,
    price_change_abs text,
    price_change_pct text,
    price_7obs_avg text,
    price_30obs_avg text,
    price_volatility text,
    price_all_time_low text,
    is_all_time_low text,
    discount_frequency_proxy text,
    revenue_cumulative text,
    units_cumulative text,
    monetisation_intensity text,
    revenue_momentum_4w text,
    review_velocity text,
    review_growth_rate text,
    player_growth_rate text,
    ccu_7obs_avg text,
    ccu_30obs_avg text,
    hype_score text,
    virality_score text,
    influencer_boost_proxy text,
    popularity_momentum text,
    engagement_to_price text,
    review_times_rating text,
    critic_user_gap text,
    sentiment_stability text,
    controversy_score text,
    community_health_score text,
    tier_label text,
    is_aaa text,
    holiday_release_flag text,
    q4_release_flag text,
    launch_phase text,
    is_new_release text,
    days_since_release_log text,
    obs_month text,
    obs_year text,
    obs_quarter text,
    obs_dow text,
    is_q4 text,
    is_summer text,
    is_weekend_obs text,
    rating_drop_flag text,
    fake_discount_flag text,
    player_spike_flag text,
    review_inflation_flag text,
    genre_popularity_rank text,
    platform_popularity_rank text,
    target_ccu_next_4w text,
    target_revenue_next_4w text,
    target_price_next_4w text,
    target_review_count_next_4w text,
    target_is_on_sale_next_obs text,
    target_breakout_hit text,
    target_sleeper_hit text,
    target_long_tail text
    )
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed randomly;

--Hubs
create table project.h_games (
    game_key  char(32)
  , game_id   varchar(32)
  , load_date timestamp
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (game_key);

create table project.h_platform (
    platform_key    char(32)
  , platform        varchar(32)
  , load_date       timestamp
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (platform_key);

create table project.h_developer (
    developer_key     char(32)
  , developer         varchar(32)
  , load_date         timestamp
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (developer_key);

create table project.h_publisher (
    publisher_key     char(32)
  , publisher         varchar(32)
  , load_date         timestamp
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (publisher_key);

--Links
create table project.lnk_game_platform (
    lnk_game_platform_key  char(32)
  , game_key                     char(32)
  , platform_key                 char(32)
  , load_date                    timestamp
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (lnk_game_platform_key);

create table project.lnk_game_developer (
    lnk_game_developer_key  char(32)
  , game_key                char(32)
  , developer_key           char(32)
  --, start_date              date
  , load_date               timestamp
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (lnk_game_developer_key);

create table project.lnk_game_publisher (
    lnk_game_publisher_key  char(32)
  , game_key                char(32)
  , publisher_key           char(32)
  , load_date               timestamp
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (lnk_game_publisher_key);

--Satellites - Hubs
create table project.sat_games (
    game_key     char(32)
  , game_name    varchar(50)
  , genre        varchar(32)
  , age_rating   varchar(20)
  , release_date date
  , start_date   date
  , hash_value   char(32)
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (game_key);

create table project.sat_games_review (
    game_key            char(32)
  , review_count        integer
  , positive_reviews    integer
  , negative_reviews    integer
  , start_date          date
  , hash_value          char(32)
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (game_key);

--Satellites - Links
create table project.sat_lnk_game_platform_price (
    lnk_game_platform_key        char(32)
  , price_usd                    numeric(8, 2)
  , discount_pct                 numeric(8, 2)
  , sale_event_name              varchar(32)
  , start_date                   date
  , hash_value                   char(32)
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed by (lnk_game_platform_key);

--marts
create table project.dm_videogames_processed (
    on_date             date
  , game_id             varchar(32)
  , platform            varchar(32)
  , price_usd           numeric(8, 2)
  , discount_pct        numeric(8, 2)
  , sale_event_name     varchar(32)
  , review_count	      integer
  , positive_reviews	  integer
  , negative_reviews    integer
  , game_name	          varchar(50)
  , developer	          varchar(32)
  , publisher           varchar(32)
  , genre               varchar(32)
  , age_rating	        varchar(20)
  , release_date        date
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed randomly
partition by range (on_date) (
    start (date '2019-01-01') inclusive
      end (date '2027-01-01') exclusive
    every (interval '1 MONTH')
);

create table project.dm_platform_price (
    on_date             date
  , platform            varchar(32)
  , avg_price_usd       numeric(8, 2)
)
with (appendoptimized = true, orientation = column, compresstype = zstd, compresslevel = 2)
distributed randomly
;




