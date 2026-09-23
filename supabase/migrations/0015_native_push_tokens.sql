-- Tokens de notificaciones push nativas (APNs) de la app de iOS. La app de la
-- App Store no puede usar Web Push (el WebView no lo soporta), así que guarda
-- aquí el token del dispositivo y la Edge Function send-push le envía los
-- avisos directamente por APNs.

create table if not exists public.native_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null unique,
  platform text not null default 'ios',
  created_at timestamptz not null default now()
);

alter table public.native_push_tokens enable row level security;

drop policy if exists "native_push_tokens_select_own" on public.native_push_tokens;
create policy "native_push_tokens_select_own" on public.native_push_tokens
  for select to authenticated using (user_id = auth.uid());

-- El token es del dispositivo, no de la persona: si en el mismo iPhone entra
-- otra cuenta, el token pasa a ser suyo. Por eso se registra con una función
-- en vez de con un insert directo (RLS no dejaría "robar" la fila anterior).
create or replace function public.register_native_push_token(_token text, _platform text default 'ios')
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'No has iniciado sesión';
  end if;

  delete from public.native_push_tokens where token = _token;
  insert into public.native_push_tokens (user_id, token, platform)
  values (auth.uid(), _token, coalesce(_platform, 'ios'));
end;
$$;

create or replace function public.unregister_native_push_token(_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.native_push_tokens where token = _token and user_id = auth.uid();
$$;

revoke all on function public.register_native_push_token(text, text) from public, anon;
revoke all on function public.unregister_native_push_token(text) from public, anon;
grant execute on function public.register_native_push_token(text, text) to authenticated;
grant execute on function public.unregister_native_push_token(text) to authenticated;

-- Borrar la cuenta también debe dar de baja los iPhones de esa persona.
alter table public.profiles drop constraint if exists profiles_id_fkey;

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid uuid := auth.uid();
  _household record;
begin
  if _uid is null then
    raise exception 'No has iniciado sesión';
  end if;

  -- La cuenta de demostración es compartida por todos los visitantes.
  if exists (
    select 1
    from public.household_members m
    join public.households h on h.id = m.household_id
    where m.user_id = _uid and h.invite_code = 'DEMO01'
  ) then
    raise exception 'La cuenta de demostración no se puede borrar';
  end if;

  for _household in
    select household_id from public.household_members where user_id = _uid
  loop
    perform public.leave_household(_household.household_id);
  end loop;

  delete from public.push_subscriptions where user_id = _uid;
  delete from public.native_push_tokens where user_id = _uid;
  delete from public.notifications where user_id = _uid;

  update public.profiles
  set display_name = 'Usuario eliminado', avatar_url = null
  where id = _uid;

  delete from auth.users where id = _uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
