import { ChartColumn, Receipt, ListChecks, Tag } from "lucide-react";
import { requireHousehold, getHouseholdMembers } from "@/lib/household";
import { formatCents, parseDateOnly } from "@/lib/format";
import { CATEGORY_LABELS, EXPENSE_CATEGORIES, type ExpenseCategory } from "@/lib/categories";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { StatTile } from "./stat-tile";
import { BarRowChart, type BarRow } from "./bar-row-chart";
import { MonthlyBarChart, type MonthColumn } from "./monthly-bar-chart";

const MONTH_LABELS = [
  "ene",
  "feb",
  "mar",
  "abr",
  "may",
  "jun",
  "jul",
  "ago",
  "sep",
  "oct",
  "nov",
  "dic",
];

/** YYYY-MM-DD con los componentes locales (toISOString() convertiría a UTC y
 * podría dar el día anterior). */
function toDateStr(d: Date): string {
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${d.getFullYear()}-${month}-${day}`;
}

export default async function StatsPage() {
  const { supabase, household } = await requireHousehold();

  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);

  const [members, { data: monthExpenses }, { data: doneThisMonth }, { data: sixMonthExpenses }] =
    await Promise.all([
      getHouseholdMembers(supabase, household.id),
      supabase
        .from("expenses")
        .select("paid_by, amount_cents, category")
        .eq("household_id", household.id)
        .gte("expense_date", toDateStr(startOfMonth)),
      supabase
        .from("chore_assignments")
        .select("completed_by")
        .eq("household_id", household.id)
        .eq("status", "done")
        .gte("completed_at", startOfMonth.toISOString()),
      supabase
        .from("expenses")
        .select("amount_cents, expense_date")
        .eq("household_id", household.id)
        .gte("expense_date", toDateStr(sixMonthsAgo)),
    ]);

  const totalThisMonth = (monthExpenses ?? []).reduce((sum, e) => sum + e.amount_cents, 0);
  const choresThisMonth = (doneThisMonth ?? []).length;

  const expenseRows: BarRow[] = members
    .map((m) => {
      const value = (monthExpenses ?? [])
        .filter((e) => e.paid_by === m.userId)
        .reduce((sum, e) => sum + e.amount_cents, 0);
      return { label: m.displayName, value, formattedValue: formatCents(value) };
    })
    .sort((a, b) => b.value - a.value);

  const categoryRows: BarRow[] = EXPENSE_CATEGORIES.map((category) => {
    const value = (monthExpenses ?? [])
      .filter((e) => ((e.category as ExpenseCategory) ?? "otros") === category)
      .reduce((sum, e) => sum + e.amount_cents, 0);
    return { label: CATEGORY_LABELS[category], value, formattedValue: formatCents(value) };
  })
    .filter((row) => row.value > 0)
    .sort((a, b) => b.value - a.value);

  const choreRows: BarRow[] = members
    .map((m) => {
      const value = (doneThisMonth ?? []).filter((c) => c.completed_by === m.userId).length;
      return { label: m.displayName, value, formattedValue: String(value) };
    })
    .sort((a, b) => b.value - a.value);

  const monthlyColumns: MonthColumn[] = Array.from({ length: 6 }).map((_, i) => {
    const monthDate = new Date(sixMonthsAgo.getFullYear(), sixMonthsAgo.getMonth() + i, 1);
    const value = (sixMonthExpenses ?? [])
      .filter((e) => {
        const d = parseDateOnly(e.expense_date);
        return d.getFullYear() === monthDate.getFullYear() && d.getMonth() === monthDate.getMonth();
      })
      .reduce((sum, e) => sum + e.amount_cents, 0);
    return {
      label: MONTH_LABELS[monthDate.getMonth()],
      value,
      formattedValue: formatCents(value),
    };
  });

  return (
    <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 p-4">
      <div className="flex gap-2">
        <StatTile label="Gastado este mes" value={formatCents(totalThisMonth)} />
        <StatTile label="Tareas hechas este mes" value={String(choresThisMonth)} />
      </div>

      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <ChartColumn className="size-4" />
          </div>
          <CardTitle className="text-base">Gasto del piso por mes</CardTitle>
        </CardHeader>
        <CardContent>
          <MonthlyBarChart columns={monthlyColumns} emptyMessage="Todavía no hay gastos registrados." />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <Receipt className="size-4" />
          </div>
          <CardTitle className="text-base">Quién ha pagado más (este mes)</CardTitle>
        </CardHeader>
        <CardContent>
          <BarRowChart rows={expenseRows} emptyMessage="Nadie ha pagado nada todavía este mes." />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <Tag className="size-4" />
          </div>
          <CardTitle className="text-base">Gasto por categoría (este mes)</CardTitle>
        </CardHeader>
        <CardContent>
          <BarRowChart rows={categoryRows} emptyMessage="Todavía no hay gastos categorizados este mes." />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <ListChecks className="size-4" />
          </div>
          <CardTitle className="text-base">Tareas completadas (este mes)</CardTitle>
        </CardHeader>
        <CardContent>
          <BarRowChart rows={choreRows} emptyMessage="Nadie ha completado tareas todavía este mes." />
        </CardContent>
      </Card>
    </div>
  );
}
