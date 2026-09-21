"use client";

import { useState, useTransition } from "react";
import { Plus, RefreshCw, Trash2 } from "lucide-react";
import { toast } from "sonner";
import {
  addRecurringExpense,
  deleteRecurringExpense,
  generateRecurringNow,
  toggleRecurringExpense,
} from "@/app/actions/expenses";
import { CATEGORY_ICONS, type ExpenseCategory } from "@/lib/categories";
import { formatCents } from "@/lib/format";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { CategoryPicker } from "@/components/category-picker";
import { cn } from "@/lib/utils";

type Member = { userId: string; displayName: string };

type Recurring = {
  id: string;
  description: string;
  amount_cents: number;
  category: string;
  day_of_month: number;
  paid_by: string;
  active: boolean;
};

export function RecurringExpenses({
  householdId,
  members,
  recurring,
}: {
  householdId: string;
  members: Member[];
  recurring: Recurring[];
}) {
  const [addError, setAddError] = useState<string | undefined>();
  const [payerId, setPayerId] = useState(members[0]?.userId ?? "");
  const [isPending, startTransition] = useTransition();
  const [pending, startAddTransition] = useTransition();
  // Cambia al guardar con éxito para vaciar el formulario.
  const [formKey, setFormKey] = useState(0);
  const nameOf = (id: string) =>
    members.find((m) => m.userId === id)?.displayName ?? "un excompañero";

  function handleAdd(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    setAddError(undefined);
    startAddTransition(async () => {
      const result = await addRecurringExpense(undefined, formData);
      if (result?.error) {
        // Se conserva todo lo escrito para poder corregirlo.
        setAddError(result.error);
        return;
      }
      setFormKey((k) => k + 1);
    });
  }

  return (
    <div className="flex flex-col gap-4">
      {recurring.length > 0 && (
        <div className="flex flex-col gap-2">
          {recurring.map((r) => {
            const Icon = CATEGORY_ICONS[(r.category as ExpenseCategory) ?? "otros"];
            return (
              <div key={r.id} className="flex items-center gap-2 text-sm">
                <div className="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary">
                  <Icon className="size-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className={cn("truncate font-medium", !r.active && "text-muted-foreground line-through")}>
                    {r.description}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    día {r.day_of_month} · paga {nameOf(r.paid_by)}
                  </p>
                </div>
                <span className="shrink-0 font-medium">{formatCents(r.amount_cents)}</span>
                <Checkbox
                  checked={r.active}
                  onCheckedChange={(checked) => {
                    const formData = new FormData();
                    formData.set("recurring_expense_id", r.id);
                    formData.set("active", String(checked));
                    startTransition(async () => {
                      const result = await toggleRecurringExpense(formData);
                      if (result?.error) toast.error(result.error);
                    });
                  }}
                  aria-label={r.active ? "Pausar" : "Activar"}
                />
                <button
                  type="button"
                  onClick={() => {
                    if (!confirm(`¿Borrar "${r.description}"? No se generará más.`)) return;
                    const formData = new FormData();
                    formData.set("recurring_expense_id", r.id);
                    startTransition(async () => {
                      const result = await deleteRecurringExpense(formData);
                      if (result?.error) toast.error(result.error);
                    });
                  }}
                  aria-label="Borrar gasto fijo"
                  className="text-muted-foreground hover:text-destructive"
                >
                  <Trash2 className="size-3.5" />
                </button>
              </div>
            );
          })}
          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={isPending}
            onClick={() =>
              startTransition(async () => {
                const result = await generateRecurringNow();
                if (result?.error) toast.error(result.error);
              })
            }
            className="self-start"
          >
            <RefreshCw className="size-3.5" />
            Generar ahora
          </Button>
        </div>
      )}

      <form
        key={formKey}
        onSubmit={handleAdd}
        className="flex flex-col gap-3 border-t pt-3"
      >
        <input type="hidden" name="household_id" value={householdId} />
        <input type="hidden" name="paid_by" value={payerId} />
        <div className="flex gap-2">
          <Input name="description" placeholder="Alquiler" className="flex-1" required />
          <Input
            name="amount"
            type="number"
            step="0.01"
            min="0.01"
            placeholder="450"
            className="w-24"
            required
          />
        </div>
        <div className="flex items-center gap-2">
          <Label htmlFor="day_of_month" className="text-xs text-muted-foreground">
            Cada día
          </Label>
          <Input
            id="day_of_month"
            name="day_of_month"
            type="number"
            min="1"
            max="28"
            defaultValue="1"
            className="w-16"
            required
          />
          <span className="text-xs text-muted-foreground">del mes</span>
        </div>
        <CategoryPicker />
        <div className="flex flex-col gap-2">
          <Label className="text-xs text-muted-foreground">¿Quién lo paga?</Label>
          <div className="flex flex-wrap gap-1.5">
            {members.map((m) => (
              <button
                key={m.userId}
                type="button"
                onClick={() => setPayerId(m.userId)}
                className={cn(
                  "rounded-full border px-3 py-2 text-sm transition-colors",
                  payerId === m.userId
                    ? "border-primary bg-primary/15 text-primary"
                    : "border-input text-muted-foreground hover:bg-muted"
                )}
              >
                {m.displayName}
              </button>
            ))}
          </div>
        </div>
        {addError && <p className="text-sm text-destructive">{addError}</p>}
        <Button type="submit" variant="outline" disabled={pending}>
          <Plus className="size-4" />
          {pending ? "Guardando..." : "Añadir gasto fijo"}
        </Button>
      </form>
    </div>
  );
}
