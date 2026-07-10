create or replace function project.write_log (
    i_ObjectName   in varchar
  , i_EventMessage in varchar
)
returns void
language plpgsql
as $body$
declare
  lc_Connect  constant text  := 'LOGGER_PID_' || PG_BACKEND_PID()::TEXT;
  lv_Sql               text;
  lv_ConnectExsts      boolean;
  lv_DbLinkConnect     varchar;
begin
  select s.settings_value
    into lv_DbLinkConnect  --получим параметры соединения из настройки
    from project.settings s
   where s.settings_name = 'dblink_connect'
   ;

  select 
    into lv_ConnectExsts coalesce(lc_Connect = any(dblink_get_connections()), false);
  if not lv_ConnectExsts
    then
      perform dblink_connect(lc_Connect, lv_DbLinkConnect);
  end if;

  lv_Sql = 'insert into project.log_table (object_name, event_message) values (''' || i_ObjectName || ''', ''' || i_EventMessage || '''); commit;';

  PERFORM dblink_exec(lc_Connect, lv_Sql);

end;
$body$;

comment on function project.write_log(varchar, varchar) is 'Функция записи в таблицу логов';
