import { Receipt, Repeat, History, Download } from "lucide-react";
import { requireHousehold, getHouseholdMembers, resolveNames } from "@/lib/household";
import { computeBalances, simplifyDebts } from "@/lib/debt-simplify";
import { formatCents, formatDate } from "@/lib/format";
import { cn } from "@/lib/utils";
import { CATEGORY_ICONS, type ExpenseCategory } from "@/lib/categories";
import { AddExpenseForm } from "./add-expense-form";
import { SettleButton } from "./settle-button";
import { ExpenseRowActions } from "./expense-row-actions";
import { RecurringExpenses } from "./recurring-expenses";
import { SettlementHistory } from "./settlement-history";
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";

export default async function ExpensesPage() {
  const { supabase, user, household } = await requireHousehold();

  const [members, { data: expensesWithShares }, { data: settlements }, { data: recurring }] =
    await Promise.all([
      getHouseholdMembers(supabase, household.id),
      // expense_shares viene anidado en la misma consulta (está relacionado
      // por clave foránea) en vez de pedirlo aparte.
      supabase
        .from("expenses")
        .select(
          "id, description, amount_cents, paid_by, expense_date, category, expense_shares(user_id, share_cents)"
        )
        .eq("household_id", household.id)
        .order("expense_date", { ascending: false })
        .order("created_at", { ascending: false }),
      supabase
        .from("settlements")
        .select("id, from_user_id, to_user_id, amount_cents, settled_at")
        .eq("household_id", household.id)
        .order("settled_at", { ascending: false }),
      supabase
        .from("recurring_expenses")
        .select("id, description, amount_cents, category, day_of_month, paid_by, active")
        .eq("household_id", household.id)
        .order("created_at", { ascending: true }),
    ]);

  const expenses = expensesWithShares;
  const shares = (expensesWithShares ?? []).flatMap((e) => {
    const expenseShares =
      (e.expense_shares as unknown as { user_id: string; share_cents: number }[] | null) ?? [];
    return expenseShares.map((s) => ({ ...s, expense_id: e.id }));
  });

  const referencedIds = [
    ...(expenses ?? []).map((e) => e.paid_by),
    ...(shares ?? []).map((s) => s.user_id),
    ...(settlements ?? []).flatMap((s) => [s.from_user_id, s.to_user_id]),
  ];
  const nameOf = await resolveNames(supabase, members, referencedIds);

  const balances = computeBalances(
    (expenses ?? []).map((e) => ({ paidBy: e.paid_by, amountCents: e.amount_cents })),
    (shares ?? []).map((s) => ({ userId: s.user_id, shareCents: s.share_cents })),
    (settlements ?? []).map((s) => ({
      fromUserId: s.from_user_id,
      toUserId: s.to_user_id,
      amountCents: s.amount_cents,
    }))
  );

  const transactions = simplifyDebts(balances);

  const participantsByExpense = (shares ?? []).reduce<Record<string, string[]>>((acc, s) => {
    acc[s.expense_id] = acc[s.expense_id] ?? [];
    acc[s.expense_id].push(nameOf(s.user_id));
    return acc;
  }, {});

  return (
    <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 p-4">
      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <Receipt className="size-4" />
          </div>
          <CardTitle className="text-base">Añadir gasto</CardTitle>
          <CardDescription>A partes iguales o por importes exactos</CardDescription>
        </CardHeader>
        <CardContent>
          <AddExpenseForm householdId={household.id} members={members} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <Repeat className="size-4" />
          </div>
          <CardTitle className="text-base">Gastos fijos</CardTitle>
          <CardDescription>Alquiler, wifi, luz... se crean solos cada mes</CardDescription>
        </CardHeader>
        <CardContent>
          <RecurringExpenses
            householdId={household.id}
            members={members}
            recurring={recurring ?? []}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Saldos del piso</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
          {members.map((m) => {
            const amount = balances.get(m.userId) ?? 0;
            return (
              <div key={m.userId} className="flex items-center gap-3 text-sm">
                <Avatar className="size-8">
                  <AvatarFallback className="bg-primary/15 text-xs text-primary">
                    {m.displayName.slice(0, 2).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                <span className="flex-1">
                  {m.displayName}
                  {m.userId === user.id && (
                    <span className="text-muted-foreground"> (tú)</span>
                  )}
                </span>
                <span
                  className={cn(
                    "text-sm font-medium",
                    amount > 0 && "text-green-600",
                    amount < 0 && "text-destructive",
                    amount === 0 && "text-muted-foreground"
                  )}
                >
                  {amount === 0
                    ? "al día"
                    : amount > 0
                      ? `le deben ${formatCents(amount)}`
                      : `debe ${formatCents(-amount)}`}
                </span>
              </div>
            );
          })}
        </CardContent>
      </Card>

      {transactions.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Para saldar cuentas</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-3">
            {transactions.map((t) => (
              <div
                key={`${t.from}-${t.to}`}
                className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"
              >
                <span className="text-sm">
                  {nameOf(t.from)} debe {formatCents(t.amountCents)} a {nameOf(t.to)}
                </span>
                {(t.from === user.id || t.to === user.id) && (
                  <SettleButton
                    householdId={household.id}
                    fromUserId={t.from}
                    fromName={nameOf(t.from)}
                    toUserId={t.to}
                    toName={nameOf(t.to)}
                    amountCents={t.amountCents}
                    perspective={t.from === user.id ? "debtor" : "creditor"}
                  />
                )}
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <History className="size-4" />
          </div>
          <CardTitle className="text-base">Historial de pagos</CardTitle>
          <CardDescription>Si un pago se queda descuadrado, puedes deshacerlo aquí</CardDescription>
        </CardHeader>
        <CardContent>
          <SettlementHistory
            settlements={(settlements ?? []).map((s) => ({
              id: s.id,
              fromName: nameOf(s.from_user_id),
              toName: nameOf(s.to_user_id),
              amount_cents: s.amount_cents,
              settled_at: s.settled_at,
            }))}
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Gastos recientes</CardTitle>
          <CardAction>
            <Button
              variant="outline"
              size="sm"
              nativeButton={false}
              render={<a href="/household/expenses/export" download />}
            >
              <Download className="size-3.5" />
              Excel
            </Button>
          </CardAction>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
          {(expenses ?? []).length === 0 && (
            <div className="flex flex-col items-center gap-2 py-6 text-center">
              <Receipt className="size-8 text-muted-foreground/50" />
              <p className="text-sm text-muted-foreground">
                Todavía no hay gastos. Añade el primero arriba.
              </p>
            </div>
          )}
          {(expenses ?? []).map((e) => {
            const category = (e.category ?? "otros") as ExpenseCategory;
            const CategoryIcon = CATEGORY_ICONS[category];
            const participants = participantsByExpense[e.id] ?? [];
            const participantsLabel =
              participants.length === members.length ? "entre todos" : `entre ${participants.join(", ")}`;
            return (
              <div key={e.id} className="flex items-center gap-3 text-sm">
                <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary">
                  <CategoryIcon className="size-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="font-medium">{e.description}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    Pagó {nameOf(e.paid_by)} · {participantsLabel} · {formatDate(e.expense_date)}
                  </p>
                </div>
                <span className="shrink-0 font-medium">{formatCents(e.amount_cents)}</span>
                <ExpenseRowActions
                  expenseId={e.id}
                  description={e.description}
                  amountCents={e.amount_cents}
                  category={category}
                />
              </div>
            );
          })}
        </CardContent>
      </Card>
    </div>
  );
}
