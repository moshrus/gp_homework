from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

default_args = {
    'owner': 'airflow'
}

dag = DAG(
    dag_id='dag_run_all',
    default_args=default_args,
    max_active_tasks=3,
    max_active_runs=1
)

task_fill_stg_videogames_processed = SQLExecuteQueryOperator(
    task_id="project.fill_stg_videogames_processed",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_stg_videogames_processed()"
)

task_fill_h_games = SQLExecuteQueryOperator(
    task_id="project.fill_h_games",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_h_games()"
)

task_fill_h_platform = SQLExecuteQueryOperator(
    task_id="project.fill_h_platform",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_h_platform()"
)

task_fill_h_developer = SQLExecuteQueryOperator(
    task_id="project.fill_h_developer",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_h_developer()"
)

task_fill_h_publisher = SQLExecuteQueryOperator(
    task_id="project.fill_h_publisher",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_h_publisher()"
)

task_fill_lnk_game_platform = SQLExecuteQueryOperator(
    task_id="project.fill_lnk_game_platform",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_lnk_game_platform()"
)

task_fill_lnk_game_developer = SQLExecuteQueryOperator(
    task_id="project.fill_lnk_game_developer",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_lnk_game_developer()"
)

task_fill_lnk_game_publisher = SQLExecuteQueryOperator(
    task_id="project.fill_lnk_game_publisher",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_lnk_game_publisher()"
)

task_fill_sat_games = SQLExecuteQueryOperator(
    task_id="project.fill_sat_games",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_sat_games()"
)

task_fill_sat_games_review = SQLExecuteQueryOperator(
    task_id="project.fill_sat_games_review",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_sat_games_review()"
)

task_fill_sat_lnk_game_platform_price = SQLExecuteQueryOperator(
    task_id="project.fill_sat_lnk_game_platform_price",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_sat_lnk_game_platform_price()"
)

task_fill_dm_videogames_processed = SQLExecuteQueryOperator(
    task_id="project.fill_dm_videogames_processed",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_dm_videogames_processed()"
)

task_fill_dm_platform_price = SQLExecuteQueryOperator(
    task_id="project.fill_dm_platform_price",
    dag=dag,
    conn_id='project',
    autocommit=True,
    sql="select project.fill_dm_platform_price()"
)

task_fill_stg_videogames_processed >> [task_fill_h_games, task_fill_h_platform, task_fill_h_developer, task_fill_h_publisher, task_fill_lnk_game_platform, task_fill_lnk_game_developer, task_fill_lnk_game_publisher, task_fill_sat_games, task_fill_sat_games_review, task_fill_sat_lnk_game_platform_price] >> task_fill_dm_videogames_processed >> task_fill_dm_platform_price