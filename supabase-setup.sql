-- 후쿠오카 여행 대시보드 V2: 새 Supabase 프로젝트에서만 실행하세요.
-- 기존에 쓰던 Supabase 프로젝트에 실행하면 예기치 않은 충돌이 있을 수 있습니다.
-- 새 익명 사용자도 'authenticated' 역할로 RLS에 접근합니다.

begin;
create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  invite_code text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  version integer not null default 0 check (version >= 0),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create table if not exists public.trip_members (
  trip_id uuid not null references public.trips(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (trip_id, user_id)
);
create index if not exists idx_trip_members_user_id on public.trip_members(user_id);

alter table public.trips enable row level security;
alter table public.trip_members enable row level security;

-- 기존 정책 이름을 포함해 반복 실행 가능하도록 작성
DROP POLICY IF EXISTS "member reads trip" ON public.trips;
DROP POLICY IF EXISTS "member updates trip" ON public.trips;
DROP POLICY IF EXISTS "self reads membership" ON public.trip_members;

create policy "self reads membership" on public.trip_members
 for select to authenticated using (user_id = (select auth.uid()));

create policy "member reads trip" on public.trips
 for select to authenticated using (
   exists (select 1 from public.trip_members m
     where m.trip_id = trips.id and m.user_id = (select auth.uid()))
 );
create policy "member updates trip" on public.trips
 for update to authenticated
 using (exists (select 1 from public.trip_members m
   where m.trip_id = trips.id and m.user_id = (select auth.uid())))
 with check (exists (select 1 from public.trip_members m
   where m.trip_id = trips.id and m.user_id = (select auth.uid())));

-- 브라우저에는 secret/service_role 키를 절대 쓰지 않습니다.
-- 일반 사용자는 초대코드와 소유권을 직접 수정할 수 없습니다.
revoke all on public.trips from anon, authenticated;
revoke all on public.trip_members from anon, authenticated;
grant select on public.trips to authenticated;
grant update (payload, version, updated_at) on public.trips to authenticated;
grant select on public.trip_members to authenticated;

create or replace function public.create_trip_room()
returns public.trips
language plpgsql
security definer
set search_path = ''
as $$
declare
  room public.trips;
  attempt int := 0;
begin
  if (select auth.uid()) is null then
    raise exception '로그인이 필요합니다';
  end if;
  loop
    attempt := attempt + 1;
    if attempt > 5 then raise exception '초대코드 생성에 실패했습니다'; end if;
    begin
      insert into public.trips (invite_code, created_by, payload)
      values (upper(substr(replace(pg_catalog.gen_random_uuid()::text,'-',''),1,10)),
              (select auth.uid()), '{}'::jsonb)
      returning * into room;
      exit;
    exception when unique_violation then null;
    end;
  end loop;
  insert into public.trip_members (trip_id, user_id)
  values (room.id, (select auth.uid()));
  return room;
end;
$$;

create or replace function public.join_trip_room(p_code text)
returns public.trips
language plpgsql
security definer
set search_path = ''
as $$
declare
  room public.trips;
begin
  if (select auth.uid()) is null then
    raise exception '로그인이 필요합니다';
  end if;
  if p_code is null or length(btrim(p_code)) <> 10 then
    raise exception '초대코드 형식이 올바르지 않습니다';
  end if;
  select * into room from public.trips t
  where t.invite_code = upper(btrim(p_code)) limit 1;
  if room.id is null then
    raise exception '해당 초대코드의 여행방이 없습니다';
  end if;
  insert into public.trip_members (trip_id, user_id)
  values (room.id, (select auth.uid()))
  on conflict (trip_id,user_id) do nothing;
  return room;
end;
$$;

revoke execute on function public.create_trip_room() from PUBLIC, anon;
revoke execute on function public.join_trip_room(text) from PUBLIC, anon;
grant execute on function public.create_trip_room() to authenticated;
grant execute on function public.join_trip_room(text) to authenticated;

-- 선택사항: 실시간 변경 알림. 없더라도 다른 기기에서 탭을 다시 열면 새 데이터를 읽습니다.
do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime')
     and not exists(select 1 from pg_publication_tables
       where pubname='supabase_realtime' and schemaname='public' and tablename='trips') then
    alter publication supabase_realtime add table public.trips;
  end if;
end $$;
commit;
