-- expense_shares nunca tuvo política de UPDATE: al editar el importe de un
-- gasto con reparto personalizado, el reescalado de cada expense_shares.share_cents
-- se filtraba en silencio por RLS (0 filas afectadas, sin error), dejando los
-- repartos desincronizados del nuevo importe total.
create policy "expense_shares_update_members" on public.expense_shares
  for update to authenticated
  using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));

-- generate_recurring_expenses() recorría TODOS los hogares, y cualquier
-- usuario autenticado podía dispararla vía RPC directa desde el botón
-- "Generar ahora" (que solo debería afectar a su propio hogar). Se extrae
-- la lógica a una función interna parametrizable por hogar, y se expone una
-- versión de ámbito de hogar (comprobando membresía) para el botón; la
-- global queda solo para pg_cron.
create function public.generate_recurring_expenses_scoped(_household_id uuid default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  _expense_id uuid;
  _members uuid[];
  _n int;
  _base int;
  _remainder int;
begin
  for r in
    select * from public.recurring_expenses
    where active = true
      and day_of_month <= extract(day from current_date)::int
      and (last_generated_month is null or last_generated_month < date_trunc('month', current_date)::date)
      and (_household_id is null or household_id = _household_id)
  loop
    select array_agg(user_id order by joined_at) into _members
    from public.household_members
    where household_id = r.household_id;

    if _members is null or array_length(_members, 1) = 0 then
      continue;
    end if;

    insert into public.expenses
      (household_id, paid_by, created_by, description, amount_cents, category, expense_date)
    values
      (r.household_id, r.paid_by, r.paid_by, r.description, r.amount_cents, r.category, current_date)
    returning id into _expense_id;

    _n := array_length(_members, 1);
    _base := r.amount_cents / _n;
    _remainder := r.amount_cents % _n;

    insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
    select
      r.household_id,
      _expense_id,
      _members[i],
      _base + case when i <= _remainder then 1 else 0 end
    from generate_series(1, _n) as i;

    update public.recurring_expenses
    set last_generated_month = date_trunc('month', current_date)::date
    where id = r.id;
  end loop;
end;
$$;

create function public.generate_recurring_expenses_for_household(_household_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_household_member(_household_id) then
    raise exception 'not a member of this household';
  end if;

  perform public.generate_recurring_expenses_scoped(_household_id);
end;
$$;

create or replace function public.generate_recurring_expenses()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.generate_recurring_expenses_scoped(null);
end;
$$;

revoke execute on function public.generate_recurring_expenses() from authenticated;
grant execute on function public.generate_recurring_expenses_for_household(uuid) to authenticated;
