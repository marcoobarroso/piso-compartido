-- Datos de ejemplo para el modo demo público ("Ver demo" en el login).
-- Requiere que ya existan 3 usuarios creados a mano en Authentication ->
-- Users (con "Auto Confirm User" marcado):
--   demo1@example.com -> Ana
--   demo2@example.com -> Pablo
--   demo3@example.com -> Sara
--
-- Se puede volver a ejecutar entero cuando haga falta "resetear" la demo:
-- borra el piso demo anterior (por su invite_code fijo) y lo vuelve a crear
-- desde cero con datos frescos.
--
-- Pensado para que la cuenta demo (siempre entra como Ana) se vea bien en
-- capturas de pantalla: balance positivo, "este mes" con datos reales en
-- todas las categorías, lista de la compra con items pendientes, y tareas
-- con una próxima a corto plazo (ni vencida ni muy lejana). Las fechas de
-- octubre usan CURRENT_DATE para que "este mes" siempre tenga datos sea
-- cual sea el día en que se ejecute.

do $$
declare
  _ana uuid;
  _pablo uuid;
  _sara uuid;
  _household_id uuid;
  _chore1 uuid;
  _chore2 uuid;
  _chore3 uuid;
  _e uuid;
begin
  select id into _ana from auth.users where email = 'demo1@example.com';
  select id into _pablo from auth.users where email = 'demo2@example.com';
  select id into _sara from auth.users where email = 'demo3@example.com';

  if _ana is null or _pablo is null or _sara is null then
    raise exception 'Crea primero los 3 usuarios demo en Authentication -> Users antes de correr este script.';
  end if;

  update public.profiles set display_name = 'Ana' where id = _ana;
  update public.profiles set display_name = 'Pablo' where id = _pablo;
  update public.profiles set display_name = 'Sara' where id = _sara;

  delete from public.households where invite_code = 'DEMO01';

  insert into public.households (name, invite_code, created_by)
  values ('Piso Demo', 'DEMO01', _ana)
  returning id into _household_id;

  insert into public.household_members (household_id, user_id, role, joined_at)
  values
    (_household_id, _ana, 'admin', now() - interval '90 days'),
    (_household_id, _pablo, 'member', now() - interval '60 days'),
    (_household_id, _sara, 'member', now() - interval '30 days');

  -- ===== Gastos =====
  -- Un gasto de hace 2 meses y dos del mes pasado (para que el gráfico de
  -- 6 meses no esté vacío), y seis de hoy cubriendo las 6 categorías (para
  -- que "Gasto por categoría" y "Quién ha pagado más" tengan datos reales).

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _ana, _ana, 'Finde con amigos, nevera llena', 9600, 'ocio', current_date - 47)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 3200), (_household_id, _e, _pablo, 3200), (_household_id, _e, _sara, 3200);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _sara, _sara, 'Reparaciones cocina', 7200, 'hogar', current_date - 21)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 2400), (_household_id, _e, _pablo, 2400), (_household_id, _e, _sara, 2400);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _pablo, _pablo, 'Super grande del mes', 5400, 'comida', current_date - 11)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 1800), (_household_id, _e, _pablo, 1800), (_household_id, _e, _sara, 1800);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _ana, _ana, 'Compra semanal Mercadona', 7200, 'comida', current_date)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 2400), (_household_id, _e, _pablo, 2400), (_household_id, _e, _sara, 2400);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _pablo, _pablo, 'Factura de la luz', 6840, 'suministros', current_date)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 2280), (_household_id, _e, _pablo, 2280), (_household_id, _e, _sara, 2280);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _sara, _sara, 'Cena para celebrar cumpleaños', 5400, 'ocio', current_date)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 1800), (_household_id, _e, _pablo, 1800), (_household_id, _e, _sara, 1800);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _ana, _ana, 'Productos de limpieza', 2490, 'hogar', current_date)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 830), (_household_id, _e, _pablo, 830), (_household_id, _e, _sara, 830);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _pablo, _pablo, 'Gasolina compartida', 3000, 'transporte', current_date)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 1000), (_household_id, _e, _pablo, 1000), (_household_id, _e, _sara, 1000);

  insert into public.expenses (id, household_id, paid_by, created_by, description, amount_cents, category, expense_date)
  values (gen_random_uuid(), _household_id, _sara, _sara, 'Suscripción streaming compartida', 1599, 'otros', current_date)
  returning id into _e;
  insert into public.expense_shares (household_id, expense_id, user_id, share_cents)
  values (_household_id, _e, _ana, 533), (_household_id, _e, _pablo, 533), (_household_id, _e, _sara, 533);

  -- Liquidaciones ya hechas, para que se vea el historial de pagos y Ana
  -- (con quien se entra siempre en la demo) tenga un balance a su favor.
  insert into public.settlements (household_id, from_user_id, to_user_id, amount_cents, settled_at)
  values
    (_household_id, _pablo, _ana, 1000, now() - interval '5 days'),
    (_household_id, _sara, _ana, 500, now() - interval '2 days');

  -- Gastos fijos
  insert into public.recurring_expenses (household_id, description, amount_cents, category, day_of_month, paid_by, created_by)
  values
    (_household_id, 'Wifi', 3500, 'suministros', 5, _pablo, _pablo),
    (_household_id, 'Netflix', 1299, 'otros', 1, _sara, _sara);

  -- ===== Tareas =====
  -- Tres tareas con rotación, cada una con una pendiente a corto plazo y
  -- al menos una completada hoy (para que "este mes" en Stats no esté
  -- vacío) más una completada hace semanas (para el Historial).

  insert into public.chores (id, household_id, name, recurrence_days, rotation_order, created_by)
  values (gen_random_uuid(), _household_id, 'Sacar la basura', 3, array[_ana, _pablo, _sara], _ana)
  returning id into _chore1;
  insert into public.chore_assignments (chore_id, household_id, assigned_to, due_date, status)
  values (_chore1, _household_id, _ana, current_date + 1, 'pending');
  insert into public.chore_assignments
    (chore_id, household_id, assigned_to, due_date, status, completed_at, completed_by)
  values
    (_chore1, _household_id, _pablo, current_date, 'done', now(), _pablo),
    (_chore1, _household_id, _sara, current_date - 3, 'done', now() - interval '2 days', _sara);

  insert into public.chores (id, household_id, name, recurrence_days, rotation_order, created_by)
  values (gen_random_uuid(), _household_id, 'Limpiar la cocina', 7, array[_pablo, _sara, _ana], _pablo)
  returning id into _chore2;
  insert into public.chore_assignments (chore_id, household_id, assigned_to, due_date, status)
  values (_chore2, _household_id, _pablo, current_date + 4, 'pending');
  insert into public.chore_assignments
    (chore_id, household_id, assigned_to, due_date, status, completed_at, completed_by)
  values
    (_chore2, _household_id, _ana, current_date, 'done', now(), _ana),
    (_chore2, _household_id, _sara, current_date - 7, 'done', now() - interval '7 days', _sara);

  insert into public.chores (id, household_id, name, recurrence_days, rotation_order, created_by)
  values (gen_random_uuid(), _household_id, 'Pasar la aspiradora', 7, array[_ana, _sara, _pablo], _sara)
  returning id into _chore3;
  insert into public.chore_assignments (chore_id, household_id, assigned_to, due_date, status)
  values (_chore3, _household_id, _sara, current_date + 6, 'pending');
  insert into public.chore_assignments
    (chore_id, household_id, assigned_to, due_date, status, completed_at, completed_by)
  values
    (_chore3, _household_id, _pablo, current_date, 'done', now(), _pablo);

  -- ===== Lista de la compra =====
  -- Compartidos (algunos pendientes, algunos ya tachados) + comida
  -- personal de cada uno, para que las tres secciones tengan contenido.
  insert into public.shopping_items
    (household_id, name, quantity, added_by, owner_user_id, is_checked, checked_by, checked_at)
  values
    (_household_id, 'Leche', '2L', _ana, null, false, null, null),
    (_household_id, 'Papel higiénico', null, _pablo, null, false, null, null),
    (_household_id, 'Detergente lavadora', null, _sara, null, false, null, null),
    (_household_id, 'Huevos', 'docena', _pablo, null, true, _pablo, now() - interval '1 day'),
    (_household_id, 'Pan', null, _ana, null, true, _ana, now() - interval '2 days'),
    (_household_id, 'Café molido', null, _ana, _ana, false, null, null),
    (_household_id, 'Proteína en polvo', null, _pablo, _pablo, false, null, null),
    (_household_id, 'Infusiones', null, _sara, _sara, false, null, null);
end $$;
