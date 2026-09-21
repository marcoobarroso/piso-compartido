-- Borrado de cuenta desde la propia app (requisito de la App Store, 5.1.1(v)).
--
-- Se elimina el usuario de auth.users (correo y credenciales), pero la fila de
-- public.profiles se conserva anonimizada: gastos, repartos y liquidaciones de
-- los compañeros la referencian y borrarla rompería su historial. Para poder
-- borrar el usuario de auth sin arrastrar el perfil, se quita la FK
-- profiles.id -> auth.users (era solo de integridad; on delete cascade).

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
  delete from public.notifications where user_id = _uid;

  update public.profiles
  set display_name = 'Usuario eliminado', avatar_url = null
  where id = _uid;

  delete from auth.users where id = _uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
