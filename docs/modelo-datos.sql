-- =====================================================================
-- Modelo de datos — Steam Offers Tracker v2
-- Borrador de diseño probado en PostgreSQL 18.6 con datos reales de Steam.
-- No es una migración final: Drizzle generará las tablas simples; lo que
-- Drizzle no modela (particionado, PK temporal, funciones, triggers,
-- procedimientos) irá en migraciones SQL escritas a mano.
-- =====================================================================

create extension if not exists pg_trgm;     -- búsqueda por nombre (GIN trigram)
create extension if not exists btree_gist;  -- PK temporal WITHOUT OVERLAPS con columnas escalares

-- ---------------------------------------------------------------------
-- Tipos
-- ---------------------------------------------------------------------
create type event_type as enum (
  'impression', 'open_detail', 'dwell', 'click_store',
  'save', 'unsave', 'dismiss', 'undismiss', 'purchase_mark', 'notification_open'
);
create type sweep_status as enum ('running', 'ok', 'failed', 'anomaly');
create type notification_status as enum ('queued', 'sent', 'failed', 'opened', 'skipped');

-- Trigger genérico para updated_at
create function set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- =====================================================================
-- Catálogo global (compartido por todos los usuarios)
-- =====================================================================

create table games (
  appid                  integer primary key,
  name                   text not null,
  content_descriptor_ids smallint[] not null default '{}',
  -- 3 = contenido sexual solo para adultos, 4 = desnudez o contenido sexual frecuente
  is_adult               boolean generated always as (content_descriptor_ids && '{3,4}'::smallint[]) stored,
  review_percent         smallint,
  review_count           integer,
  short_description      text,
  developers             text[] not null default '{}',
  publishers             text[] not null default '{}',
  tag_norm               real,          -- norma L2 del vector de tags, para la similitud coseno
  tags_refreshed_at      timestamptz,
  first_seen_at          timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);
create index games_name_trgm on games using gin (name gin_trgm_ops);
create trigger games_updated_at before update on games
  for each row execute function set_updated_at();

create table tags (
  tag_id  integer primary key,
  name_es text not null,
  name_en text not null
);

create table game_tags (
  appid  integer not null references games on delete cascade,
  tag_id integer not null references tags,
  weight real not null check (weight > 0 and weight <= 1),  -- votos del tag / votos del tag más votado del juego
  primary key (appid, tag_id)
);
create index game_tags_tag on game_tags (tag_id) include (appid, weight);

-- Ofertas vigentes: una fila por juego y país
create table offers (
  country         char(2)  not null,
  appid           integer  not null references games on delete cascade,
  currency        char(3)  not null,
  discount_pct    smallint not null check (discount_pct between 1 and 100),
  original_cents  integer  not null,
  final_cents     integer  not null,
  discount_end_at timestamptz,
  first_seen_at   timestamptz not null default now(),
  last_seen_at    timestamptz not null default now(),
  primary key (country, appid)
);
create index offers_country_end on offers (country, discount_end_at);
create index offers_country_pct on offers (country, discount_pct desc);

-- Historial de precios como intervalos [desde, hasta). PK temporal de PG 18:
-- impide que dos intervalos del mismo juego y país se solapen.
create table price_history (
  appid           integer  not null references games on delete cascade,
  country         char(2)  not null,
  currency        char(3)  not null,
  discount_pct    smallint not null,
  original_cents  integer  not null,
  final_cents     integer  not null,
  discount_end_at timestamptz,
  valid           tstzrange not null,
  primary key (appid, country, valid without overlaps)
);
create index price_history_country_start on price_history (country, lower(valid));

-- Registro de cada barrido (sirve de monitoreo)
create table sweeps (
  id             bigint generated always as identity primary key,
  country        char(2) not null,
  started_at     timestamptz not null default now(),
  finished_at    timestamptz,
  status         sweep_status not null default 'running',
  total_reported integer,   -- total_matching_records que informó Steam
  items_seen     integer,
  new_offers     integer,
  changed_offers integer,
  ended_offers   integer,
  error          text
);
create index sweeps_country_started on sweeps (country, started_at desc);

-- Staging del barrido: UNLOGGED (sin WAL), se vacía después de aplicar
create unlogged table sweep_items (
  sweep_id               bigint  not null,
  appid                  integer not null,
  name                   text    not null,
  currency               char(3) not null,
  discount_pct           smallint not null,
  original_cents         integer not null,
  final_cents            integer not null,
  discount_end_at        timestamptz,
  review_percent         smallint,
  review_count           integer,
  content_descriptor_ids jsonb,
  short_description      text,
  developers             jsonb,
  publishers             jsonb,
  tags                   jsonb      -- [{"tagid": n, "weight": n}, ...]
);
create index sweep_items_sweep on sweep_items (sweep_id);

-- =====================================================================
-- Usuarios e identidad
-- =====================================================================

create table users (
  id           uuid primary key default uuidv7(),   -- uuidv7(): nativo en PG 18, ordenable por tiempo
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create trigger users_updated_at before update on users
  for each row execute function set_updated_at();

-- Cuentas vinculadas: hoy solo Steam; mañana Apple o Google sin reestructurar
create table auth_identities (
  id               uuid primary key default uuidv7(),
  user_id          uuid not null references users on delete cascade,
  provider         text not null check (provider in ('steam', 'apple', 'google')),
  provider_user_id text not null,             -- SteamID64 para Steam
  created_at       timestamptz not null default now(),
  last_login_at    timestamptz,
  unique (provider, provider_user_id)
);
create index auth_identities_user on auth_identities (user_id);

create table devices (
  id           uuid primary key default uuidv7(),
  user_id      uuid not null references users on delete cascade,
  platform     text not null check (platform in ('android', 'ios', 'web')),
  push_token   text not null unique,
  created_at   timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  disabled_at  timestamptz
);
create index devices_user on devices (user_id);

create table sessions (
  id           uuid primary key default uuidv7(),
  user_id      uuid not null references users on delete cascade,
  device_id    uuid references devices on delete set null,
  refresh_hash bytea not null unique,         -- SHA-256 del refresh token; nunca el token en claro
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null,
  revoked_at   timestamptz
);
create index sessions_user on sessions (user_id);

create table user_settings (
  user_id          uuid primary key references users on delete cascade,
  country          char(2)  not null,
  language         text     not null default 'es',
  timezone         text     not null default 'America/Caracas',
  min_discount_pct smallint not null default 50 check (min_discount_pct between 1 and 100),
  max_price_cents  integer,
  exclude_adult    boolean  not null default true,
  notify_enabled   boolean  not null default true,
  daily_cap        smallint not null default 5,
  quiet_start      time     not null default '23:00',
  quiet_end        time     not null default '08:00',
  updated_at       timestamptz not null default now()
);
create index user_settings_country on user_settings (country) where notify_enabled;
create trigger user_settings_updated_at before update on user_settings
  for each row execute function set_updated_at();

-- Importado de Steam (sin FK a games: la biblioteca trae juegos que nunca estuvieron en oferta)
create table user_library (
  user_id          uuid    not null references users on delete cascade,
  appid            integer not null,
  playtime_minutes integer not null default 0,
  last_played_at   timestamptz,
  imported_at      timestamptz not null default now(),
  primary key (user_id, appid)
);

create table user_steam_wishlist (
  user_id     uuid    not null references users on delete cascade,
  appid       integer not null,
  priority    integer,
  added_at    timestamptz,
  imported_at timestamptz not null default now(),
  primary key (user_id, appid)
);

-- =====================================================================
-- Comportamiento: eventos (crece con los usuarios) y su resumen
-- =====================================================================

-- Particionada por mes: borrar meses viejos es un DROP, no un DELETE masivo
create table events (
  id          bigint generated always as identity,
  user_id     uuid not null references users on delete cascade,
  appid       integer,
  type        event_type not null,
  value       integer,                -- ms de lectura en 'dwell', posición en el feed en 'impression'
  occurred_at timestamptz not null,   -- hora del dispositivo, acotada al ingresar
  received_at timestamptz not null default now(),
  device_id   uuid,
  context     jsonb,
  primary key (id, occurred_at)
) partition by range (occurred_at);
create index events_user_time on events (user_id, occurred_at desc);
create index events_time_brin on events using brin (occurred_at);

-- Estado por usuario y juego, mantenido por trigger desde events
create table user_game_state (
  user_id       uuid    not null references users on delete cascade,
  appid         integer not null,
  saved_at      timestamptz,
  dismissed_at  timestamptz,
  purchased_at  timestamptz,
  views         integer not null default 0,
  dwell_ms      bigint  not null default 0,
  store_clicks  integer not null default 0,
  last_event_at timestamptz not null,
  primary key (user_id, appid)
);
create index user_game_state_saved on user_game_state (user_id, saved_at desc)
  where saved_at is not null;

-- Perfil de gustos: vector disperso de tags por usuario
create table user_tag_profile (
  user_id uuid    not null references users on delete cascade,
  tag_id  integer not null references tags,
  score   real    not null,
  primary key (user_id, tag_id)
);

create index user_tag_profile_tag on user_tag_profile (tag_id) include (user_id, score);

create table user_profiles (
  user_id     uuid primary key references users on delete cascade,
  norm        real not null,
  computed_at timestamptz not null default now()
);

create table notifications (
  id              uuid primary key default uuidv7(),
  user_id         uuid not null references users on delete cascade,
  appid           integer not null references games on delete cascade,
  country         char(2) not null,
  discount_pct    smallint not null,
  final_cents     integer not null,
  discount_end_at timestamptz,
  score           real not null,
  status          notification_status not null default 'queued',
  created_at      timestamptz not null default now(),
  send_after      timestamptz not null default now(),  -- corrida por el horario de silencio
  sent_at         timestamptz,
  opened_at       timestamptz,
  unique nulls not distinct (user_id, appid, discount_end_at)  -- no avisar dos veces la misma oferta
);
create index notifications_queue on notifications (send_after) where status = 'queued';
create index notifications_user_time on notifications (user_id, created_at desc);

-- =====================================================================
-- Trigger: events -> user_game_state (a nivel sentencia, con tabla de transición)
-- Un lote de 200 eventos dispara el trigger una sola vez.
-- =====================================================================
create function events_to_state() returns trigger
language plpgsql as $$
begin
  -- 1) contadores
  insert into user_game_state as s (user_id, appid, views, dwell_ms, store_clicks, last_event_at)
  select user_id, appid,
         count(*) filter (where type = 'open_detail'),
         coalesce(sum(value) filter (where type = 'dwell'), 0),
         count(*) filter (where type = 'click_store'),
         max(occurred_at)
  from new_events
  where appid is not null
  group by user_id, appid
  on conflict (user_id, appid) do update set
    views         = s.views + excluded.views,
    dwell_ms      = s.dwell_ms + excluded.dwell_ms,
    store_clicks  = s.store_clicks + excluded.store_clicks,
    last_event_at = greatest(s.last_event_at, excluded.last_event_at);

  -- 2) estados: gana el evento más reciente (guardar/quitar, descartar/restaurar)
  update user_game_state s set
    saved_at = case
      when a.last_save is not null and (a.last_unsave is null or a.last_save > a.last_unsave) then a.last_save
      when a.last_unsave is not null then null
      else s.saved_at end,
    dismissed_at = case
      when a.last_dismiss is not null and (a.last_undismiss is null or a.last_dismiss > a.last_undismiss) then a.last_dismiss
      when a.last_undismiss is not null then null
      else s.dismissed_at end,
    purchased_at = coalesce(a.last_purchase, s.purchased_at)
  from (
    select user_id, appid,
           max(occurred_at) filter (where type = 'save')          as last_save,
           max(occurred_at) filter (where type = 'unsave')        as last_unsave,
           max(occurred_at) filter (where type = 'dismiss')       as last_dismiss,
           max(occurred_at) filter (where type = 'undismiss')     as last_undismiss,
           max(occurred_at) filter (where type = 'purchase_mark') as last_purchase
    from new_events
    where appid is not null
      and type in ('save', 'unsave', 'dismiss', 'undismiss', 'purchase_mark')
    group by user_id, appid
  ) a
  where s.user_id = a.user_id and s.appid = a.appid;

  return null;
end $$;

create trigger events_state after insert on events
  referencing new table as new_events
  for each statement execute function events_to_state();

-- =====================================================================
-- Funciones
-- =====================================================================

-- Crea las particiones mensuales que falten (la llama el worker todos los días).
-- Incluye meses anteriores: un teléfono que estuvo sin conexión sube eventos atrasados.
create function ensure_event_partitions(months_ahead int default 2, months_back int default 1)
returns int
language plpgsql as $$
declare
  base    date := date_trunc('month', now())::date;
  created int  := 0;
  part    text;
  m       date;
begin
  for i in -months_back..months_ahead loop
    m := (base + make_interval(months => i))::date;
    part := format('events_%s', to_char(m, 'YYYY_MM'));
    if to_regclass(part) is null then
      execute format('create table %I partition of events for values from (%L) to (%L)',
                     part, m, (m + interval '1 month')::date);
      created := created + 1;
    end if;
  end loop;
  return created;
end $$;

-- Borra las particiones de meses más viejos que keep_months
create function drop_old_event_partitions(keep_months int default 12)
returns int
language plpgsql as $$
declare
  cutoff  date := (date_trunc('month', now()) - make_interval(months => keep_months))::date;
  dropped int  := 0;
  r       record;
begin
  for r in
    select c.relname
    from pg_inherits i
    join pg_class c on c.oid = i.inhrelid
    where i.inhparent = 'events'::regclass
      and c.relname ~ '^events_\d{4}_\d{2}$'
      and to_date(substr(c.relname, 8), 'YYYY_MM') < cutoff
  loop
    execute format('drop table %I', r.relname);
    dropped := dropped + 1;
  end loop;
  return dropped;
end $$;

-- Aplica un barrido: detecta ofertas nuevas, cambiadas y terminadas, mantiene el
-- historial y las ofertas vigentes. Si el barrido vino incompleto, no toca nada.
create function apply_sweep(p_sweep_id bigint)
returns table (status sweep_status, new_offers int, changed_offers int, ended_offers int, items int)
language plpgsql as $$
declare
  v_country  char(2);
  v_reported integer;
  v_now      timestamptz := now();
  v_prev     integer;
  v_items    integer;
  v_new      integer;
  v_changed  integer;
  v_ended    integer;
begin
  select s.country, s.total_reported into v_country, v_reported
  from sweeps s where s.id = p_sweep_id for update;

  create temp table cur on commit drop as
    select distinct on (appid) *
    from sweep_items si
    where si.sweep_id = p_sweep_id
    order by appid;
  get diagnostics v_items = row_count;

  -- Defensa contra respuestas incompletas de Steam
  select s.items_seen into v_prev
  from sweeps s
  where s.country = v_country and s.status = 'ok' and s.id <> p_sweep_id
  order by s.started_at desc limit 1;

  if v_items < 0.9 * coalesce(v_reported, v_items) or v_items < 0.5 * coalesce(v_prev, v_items) then
    update sweeps s set status = 'anomaly', items_seen = v_items, finished_at = v_now
    where s.id = p_sweep_id;
    delete from sweep_items si where si.sweep_id = p_sweep_id;
    return query select 'anomaly'::sweep_status, 0, 0, 0, v_items;
    return;
  end if;

  -- 1) Juegos
  insert into games as g (appid, name, content_descriptor_ids, review_percent, review_count,
                          short_description, developers, publishers)
  select c.appid, c.name,
         coalesce(array(select jsonb_array_elements_text(c.content_descriptor_ids))::smallint[], '{}'),
         c.review_percent, c.review_count, c.short_description,
         coalesce(array(select jsonb_array_elements_text(c.developers)), '{}'),
         coalesce(array(select jsonb_array_elements_text(c.publishers)), '{}')
  from cur c
  on conflict (appid) do update set
    name = excluded.name,
    content_descriptor_ids = excluded.content_descriptor_ids,
    review_percent = excluded.review_percent,
    review_count = excluded.review_count,
    short_description = coalesce(excluded.short_description, g.short_description);

  -- 2) Tags: solo de juegos nuevos o con tags de más de 7 días
  create temp table refresh on commit drop as
    select c.appid, c.tags
    from cur c join games g using (appid)
    where c.tags is not null
      and (g.tags_refreshed_at is null or g.tags_refreshed_at < v_now - interval '7 days');

  insert into tags (tag_id, name_es, name_en)
  select distinct (t ->> 'tagid')::int, '#' || (t ->> 'tagid'), '#' || (t ->> 'tagid')
  from refresh r, jsonb_array_elements(r.tags) t
  on conflict do nothing;

  delete from game_tags gt using refresh r where gt.appid = r.appid;

  insert into game_tags (appid, tag_id, weight)
  select x.appid, x.tag_id, x.w / max(x.w) over (partition by x.appid)
  from (
    select r.appid, (t ->> 'tagid')::int as tag_id, (t ->> 'weight')::real as w
    from refresh r, jsonb_array_elements(r.tags) t
  ) x
  where x.w > 0;

  update games g set
    tag_norm = n.norm,
    tags_refreshed_at = v_now
  from (
    select gt.appid, sqrt(sum(gt.weight * gt.weight))::real as norm
    from game_tags gt join refresh r using (appid)
    group by gt.appid
  ) n
  where g.appid = n.appid;

  -- 3) Diferencias contra las ofertas vigentes
  select count(*) into v_new
  from cur c
  where not exists (select 1 from offers o where o.country = v_country and o.appid = c.appid);

  select count(*) into v_changed
  from cur c join offers o on o.country = v_country and o.appid = c.appid
  where (c.discount_pct, c.final_cents, c.discount_end_at)
        is distinct from (o.discount_pct, o.final_cents, o.discount_end_at);

  select count(*) into v_ended
  from offers o
  where o.country = v_country
    and not exists (select 1 from cur c where c.appid = o.appid);

  -- 4) Historial: cerrar intervalos de ofertas terminadas o cambiadas
  update price_history ph set valid = tstzrange(lower(ph.valid), v_now)
  from offers o
  left join cur c on c.appid = o.appid
  where o.country = v_country
    and ph.appid = o.appid and ph.country = v_country
    and upper_inf(ph.valid)
    and (c.appid is null
         or (c.discount_pct, c.final_cents, c.discount_end_at)
            is distinct from (o.discount_pct, o.final_cents, o.discount_end_at));

  --    y abrir intervalos para ofertas nuevas o cambiadas
  insert into price_history (appid, country, currency, discount_pct, original_cents, final_cents,
                             discount_end_at, valid)
  select c.appid, v_country, c.currency, c.discount_pct, c.original_cents, c.final_cents,
         c.discount_end_at, tstzrange(v_now, null)
  from cur c
  left join offers o on o.country = v_country and o.appid = c.appid
  where o.appid is null
     or (c.discount_pct, c.final_cents, c.discount_end_at)
        is distinct from (o.discount_pct, o.final_cents, o.discount_end_at);

  -- 5) Ofertas vigentes
  delete from offers o
  where o.country = v_country
    and not exists (select 1 from cur c where c.appid = o.appid);

  insert into offers as o (country, appid, currency, discount_pct, original_cents, final_cents,
                           discount_end_at, first_seen_at, last_seen_at)
  select v_country, c.appid, c.currency, c.discount_pct, c.original_cents, c.final_cents,
         c.discount_end_at, v_now, v_now
  from cur c
  on conflict (country, appid) do update set
    currency = excluded.currency,
    discount_pct = excluded.discount_pct,
    original_cents = excluded.original_cents,
    final_cents = excluded.final_cents,
    discount_end_at = excluded.discount_end_at,
    last_seen_at = v_now;

  update sweeps s set
    status = 'ok', items_seen = v_items, new_offers = v_new,
    changed_offers = v_changed, ended_offers = v_ended, finished_at = clock_timestamp()
  where s.id = p_sweep_id;

  delete from sweep_items si where si.sweep_id = p_sweep_id;

  return query select 'ok'::sweep_status, v_new, v_changed, v_ended, v_items;
end $$;

-- Recalcula el perfil de gustos de un usuario con decaimiento temporal (tau = 75 días)
create function recompute_profile(p_user uuid)
returns int
language plpgsql as $$
declare
  v_tags int;
begin
  delete from user_tag_profile where user_id = p_user;

  insert into user_tag_profile (user_id, tag_id, score)
  select p_user, gt.tag_id, sum(s.w * gt.weight)
  from (
    select x.appid, sum(x.w) as w
    from (
      select e.appid,
             case e.type
               when 'impression'    then -0.1
               when 'open_detail'   then 0.5
               when 'dwell'         then least(ln(1 + e.value / 1000.0) / 3, 1)
               when 'click_store'   then 1.5
               when 'save'          then 3
               when 'unsave'        then -3
               when 'dismiss'       then -2
               when 'undismiss'     then 2
               when 'purchase_mark' then 4
               else 0
             end * exp(-extract(epoch from now() - e.occurred_at) / (75 * 86400.0)) as w
      from events e
      where e.user_id = p_user
        and e.appid is not null
        and e.occurred_at > now() - interval '365 days'
      union all
      select l.appid, ln(1 + l.playtime_minutes / 60.0)
      from user_library l where l.user_id = p_user
      union all
      select w.appid, 2.0
      from user_steam_wishlist w where w.user_id = p_user
    ) x
    group by x.appid
  ) s
  join game_tags gt using (appid)
  group by gt.tag_id
  having sum(s.w * gt.weight) <> 0;
  get diagnostics v_tags = row_count;

  insert into user_profiles (user_id, norm, computed_at)
  select p_user, coalesce(sqrt(sum(score * score)), 0), now()
  from user_tag_profile where user_id = p_user
  on conflict (user_id) do update set norm = excluded.norm, computed_at = excluded.computed_at;

  return v_tags;
end $$;

-- Feed personalizado: ofertas del país del usuario, filtradas por sus ajustes y
-- ordenadas por similitud coseno (70 %), descuento (15 %) y reseñas (15 %).
-- Paginación por cursor (score, appid).
create function feed_for_user(
  p_user        uuid,
  p_limit       int  default 30,
  p_after_score real default null,
  p_after_appid int  default null
)
returns table (
  appid int, name text, discount_pct smallint, original_cents int, final_cents int,
  currency char(3), discount_end_at timestamptz, review_percent smallint, score real
)
language sql stable as $$
  with s as (
    select * from user_settings where user_id = p_user
  ),
  cand as (
    select o.appid, g.name, o.discount_pct, o.original_cents, o.final_cents, o.currency,
           o.discount_end_at, g.review_percent, g.tag_norm
    from s
    join offers o on o.country = s.country
    join games g on g.appid = o.appid
    where o.discount_pct >= s.min_discount_pct
      and (s.max_price_cents is null or o.final_cents <= s.max_price_cents)
      and not (s.exclude_adult and g.is_adult)
      and not exists (select 1 from user_library l
                      where l.user_id = p_user and l.appid = o.appid)
      and not exists (select 1 from user_game_state st
                      where st.user_id = p_user and st.appid = o.appid
                        and (st.dismissed_at is not null or st.purchased_at is not null))
  ),
  sim as (
    select gt.appid, sum(p.score * gt.weight) as dot
    from cand c
    join game_tags gt on gt.appid = c.appid
    join user_tag_profile p on p.user_id = p_user and p.tag_id = gt.tag_id
    group by gt.appid
  ),
  scored as (
    select c.*,
           (0.70 * coalesce(si.dot / nullif(c.tag_norm * up.norm, 0), 0)
          + 0.15 * c.discount_pct / 100.0
          + 0.15 * coalesce(c.review_percent, 50) / 100.0)::real as score
    from cand c
    left join sim si on si.appid = c.appid
    left join user_profiles up on up.user_id = p_user
  )
  select appid, name, discount_pct, original_cents, final_cents, currency,
         discount_end_at, review_percent, score
  from scored
  where p_after_score is null or (score, appid) < (p_after_score, p_after_appid)
  order by score desc, appid desc
  limit p_limit;
$$;

-- Candidatos a notificación tras un barrido: ofertas nuevas o con 10+ puntos más de
-- descuento, cruzadas con los usuarios de ese país que superan el umbral de afinidad.
-- Parte de los tags de las ofertas nuevas y busca los usuarios por tag; la versión que
-- cruzaba usuarios x ofertas primero tardaba más de 10 min con 1000 usuarios (ahora ~1,3 s).
create function notification_candidates(p_sweep_id bigint, p_min_affinity real default 0.35)
returns table (user_id uuid, appid int, discount_pct smallint, final_cents int,
               discount_end_at timestamptz, affinity real)
language sql stable as $$
  with sw as materialized (
    select country, started_at from sweeps where id = p_sweep_id
  ),
  -- ofertas nuevas o con 10+ puntos más de descuento en este barrido (decenas o cientos)
  fresh as materialized (
    select n.appid, n.discount_pct, n.final_cents, n.discount_end_at
    from sw
    join price_history n on n.country = sw.country and lower(n.valid) >= sw.started_at
    left join price_history p
      on p.appid = n.appid and p.country = n.country and upper(p.valid) = lower(n.valid)
    where p.appid is null or n.discount_pct >= p.discount_pct + 10
  ),
  fresh_tags as materialized (
    select f.appid, gt.tag_id, gt.weight from fresh f join game_tags gt using (appid)
  ),
  -- se parte de los tags de las ofertas nuevas y se buscan los usuarios por tag
  dots as (
    select p.user_id, ft.appid, sum(p.score * ft.weight) as dot
    from fresh_tags ft
    join user_tag_profile p on p.tag_id = ft.tag_id
    group by p.user_id, ft.appid
  )
  select d.user_id, f.appid, f.discount_pct, f.final_cents, f.discount_end_at,
         (d.dot / nullif(g.tag_norm * up.norm, 0))::real as affinity
  from dots d
  join fresh f using (appid)
  join games g on g.appid = f.appid
  join user_profiles up on up.user_id = d.user_id
  join user_settings s on s.user_id = d.user_id
  join sw on s.country = sw.country
  where s.notify_enabled
    and f.discount_pct >= s.min_discount_pct
    and not (s.exclude_adult and g.is_adult)
    and d.dot / nullif(g.tag_norm * up.norm, 0) >= p_min_affinity
    and not exists (select 1 from user_library l where l.user_id = d.user_id and l.appid = f.appid)
    and not exists (select 1 from user_game_state st
                    where st.user_id = d.user_id and st.appid = f.appid and st.dismissed_at is not null)
    and not exists (select 1 from notifications nt
                    where nt.user_id = d.user_id and nt.appid = f.appid
                      and nt.discount_end_at is not distinct from f.discount_end_at)
  order by d.user_id, affinity desc;
$$;

-- =====================================================================
-- Procedimiento: mantenimiento diario con COMMIT entre pasos, para que un
-- fallo en un paso no deshaga los anteriores. Se llama con CALL.
-- =====================================================================
create procedure run_maintenance(keep_months int default 12)
language plpgsql as $$
declare
  u record;
begin
  perform ensure_event_partitions(2);
  commit;

  for u in select id from users loop
    perform recompute_profile(u.id);
    commit;
  end loop;

  perform drop_old_event_partitions(keep_months);
  commit;
end $$;

-- Vista para la API: oferta vigente con datos del juego
create view v_offers as
select o.country, o.appid, g.name, o.currency, o.discount_pct, o.original_cents, o.final_cents,
       o.discount_end_at, g.review_percent, g.review_count, g.is_adult, o.first_seen_at
from offers o
join games g using (appid);
