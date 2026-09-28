import { ViewTransition } from "react";
import Link from "next/link";
import { Receipt, ListChecks, ShoppingCart, ChevronRight } from "lucide-react";
import { getHouseholdMembers, requireHousehold } from "@/lib/household";
import { computeBalances } from "@/lib/debt-simplify";
import { formatCents, formatDate, isOverdue, isToday } from "@/lib/format";
import { cn } from "@/lib/utils";
import { InviteCode } from "./invite-code";
import { RenameHouseholdForm } from "./rename-household-form";
import { RemoveMemberButton } from "./remove-member-button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { LeaveHouseholdButton } from "./leave-household-button";
import { SignOutButton } from "./sign-out-button";
import { DeleteAccountButton } from "./delete-account-button";

const DEMO_INVITE_CODE = "DEMO01";

export default async function HouseholdPage({
  searchParams,
}: {
  searchParams: Promise<{ joinError?: string }>;
}) {
  const { joinError } = await searchParams;
  const { supabase, user, household } = await requireHousehold();

  const [
    members,
    { data: expenses },
    { data: shares },
    { data: settlements },
    { data: nextChore },
    { count: pendingShoppingCount },
  ] = await Promise.all([
      getHouseholdMembers(supabase, household.id),
      supabase
        .from("expenses")
        .select("paid_by, amount_cents")
        .eq("household_id", household.id),
      supabase
        .from("expense_shares")
        .select("user_id, share_cents")
        .eq("household_id", household.id),
      supabase
        .from("settlements")
        .select("from_user_id, to_user_id, amount_cents")
        .eq("household_id", household.id),
      supabase
        .from("chore_assignments")
        .select("due_date, chores(name)")
        .eq("household_id", household.id)
        .eq("status", "pending")
        .eq("assigned_to", user.id)
        .order("due_date", { ascending: true })
        .limit(1)
        .maybeSingle(),
      supabase
        .from("shopping_items")
        .select("id", { count: "exact", head: true })
        .eq("household_id", household.id)
        .eq("is_checked", false),
    ]);

  const balances = computeBalances(
    (expenses ?? []).map((e) => ({ paidBy: e.paid_by, amountCents: e.amount_cents })),
    (shares ?? []).map((s) => ({ userId: s.user_id, shareCents: s.share_cents })),
    (settlements ?? []).map((s) => ({
      fromUserId: s.from_user_id,
      toUserId: s.to_user_id,
      amountCents: s.amount_cents,
    }))
  );
  const myBalance = balances.get(user.id) ?? 0;

  const chore = nextChore?.chores as unknown as { name: string } | null;
  // En el piso de demostración pública no se dejan las acciones destructivas
  // (echar gente, salir, regenerar código, renombrar) para no romperle la
  // demo al siguiente visitante.
  const isDemo = household.invite_code === DEMO_INVITE_CODE;
  const isAdmin =
    members.find((m) => m.userId === user.id)?.role === "admin" && !isDemo;

  return (
    <ViewTransition enter="page-enter" exit="page-exit" default="none">
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 p-4">
        {joinError === "other" && (
          <p className="rounded-xl border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">
            No te has podido unir a ese piso porque ya perteneces a otro. Sal de tu piso actual
            primero si quieres cambiar.
          </p>
        )}
        <div className="flex flex-col gap-2">
          <StatCard
            href="/household/expenses"
            icon={<Receipt className="size-4" />}
            label="Gastos"
            value={
              myBalance === 0
                ? "Estás al día"
                : myBalance > 0
                  ? `Te deben ${formatCents(myBalance)}`
                  : `Debes ${formatCents(-myBalance)}`
            }
            tone={myBalance > 0 ? "positive" : myBalance < 0 ? "negative" : "neutral"}
          />
          <StatCard
            href="/household/chores"
            icon={<ListChecks className="size-4" />}
            label="Tareas"
            value={
              !chore
                ? "Nada pendiente para ti"
                : `${chore.name} · ${
                    isOverdue(nextChore!.due_date)
                      ? "atrasada"
                      : isToday(nextChore!.due_date)
                        ? "hoy"
                        : formatDate(nextChore!.due_date)
                  }`
            }
            tone={chore && isOverdue(nextChore!.due_date) ? "negative" : "neutral"}
          />
          <StatCard
            href="/household/shopping"
            icon={<ShoppingCart className="size-4" />}
            label="Compra"
            value={
              !pendingShoppingCount
                ? "Lista vacía"
                : `${pendingShoppingCount} artículo${pendingShoppingCount === 1 ? "" : "s"} pendiente${pendingShoppingCount === 1 ? "" : "s"}`
            }
            tone="neutral"
          />
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Invita a tus compañeros</CardTitle>
            <CardDescription>Comparte este código o el enlace</CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-3">
            <InviteCode
              code={household.invite_code}
              householdId={household.id}
              householdName={household.name}
              isAdmin={isAdmin}
            />
            {isAdmin && (
              <RenameHouseholdForm householdId={household.id} name={household.name} />
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Compañeros de piso</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-3">
            {members.map((m) => (
              <div key={m.userId} className="flex items-center gap-3">
                <Avatar>
                  <AvatarFallback className="bg-primary/15 text-primary">
                    {m.displayName.slice(0, 2).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                <span className="flex-1 text-sm">{m.displayName}</span>
                {m.role === "admin" && <Badge variant="secondary">admin</Badge>}
                {isAdmin && m.userId !== user.id && (
                  <RemoveMemberButton
                    householdId={household.id}
                    userId={m.userId}
                    displayName={m.displayName}
                  />
                )}
              </div>
            ))}
          </CardContent>
        </Card>

        {isDemo ? (
          <p className="text-center text-xs text-muted-foreground">
            Estás viendo un piso de demostración: puedes probar gastos, tareas y compra, pero no
            salir ni echar a nadie.
          </p>
        ) : (
          <LeaveHouseholdButton householdId={household.id} isLastMember={members.length === 1} />
        )}

        <SignOutButton />

        {!isDemo && <DeleteAccountButton />}

        <Link
          href="/privacy"
          className="text-center text-xs text-muted-foreground hover:underline"
        >
          Política de privacidad
        </Link>
      </div>
    </ViewTransition>
  );
}

function StatCard({
  href,
  icon,
  label,
  value,
  tone,
}: {
  href: string;
  icon: React.ReactNode;
  label: string;
  value: string;
  tone: "positive" | "negative" | "neutral";
}) {
  return (
    <Link
      href={href}
      className="flex items-center gap-3 rounded-xl border bg-card p-3 transition-colors hover:bg-muted/50"
    >
      <div
        className={cn(
          "flex size-10 shrink-0 items-center justify-center rounded-full",
          tone === "positive" && "bg-green-600/15 text-green-600",
          tone === "negative" && "bg-destructive/15 text-destructive",
          tone === "neutral" && "bg-primary/15 text-primary"
        )}
      >
        {icon}
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-xs text-muted-foreground">{label}</p>
        <p className="truncate text-sm font-medium">{value}</p>
      </div>
      <ChevronRight className="size-4 shrink-0 text-muted-foreground" />
    </Link>
  );
}
