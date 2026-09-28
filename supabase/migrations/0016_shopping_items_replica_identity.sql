-- Con REPLICA IDENTITY por defecto, los eventos DELETE (y los UPDATE que no
-- cambian household_id) de replicación solo incluyen la clave primaria en la
-- fila "old". El canal de tiempo real de la compra filtra por
-- household_id=eq.<id>, así que Postgres no puede evaluar ese filtro y el
-- evento nunca llega al cliente: los artículos borrados se quedan visibles
-- hasta recargar la página. FULL incluye todas las columnas en "old".
alter table public.shopping_items replica identity full;
