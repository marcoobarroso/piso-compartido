"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Pencil, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { deleteExpense, updateExpense } from "@/app/actions/expenses";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { CategoryPicker } from "@/components/category-picker";
import type { ExpenseCategory } from "@/lib/categories";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

export function ExpenseRowActions({
  expenseId,
  description,
  amountCents,
  category,
}: {
  expenseId: string;
  description: string;
  amountCents: number;
  category: ExpenseCategory;
}) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | undefined>();
  const [deleting, setDeleting] = useState(false);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setPending(true);
    setError(undefined);
    const formData = new FormData(e.currentTarget);
    const result = await updateExpense(undefined, formData);
    setPending(false);
    if (result?.error) {
      setError(result.error);
      return;
    }
    setOpen(false);
    router.refresh();
  }

  async function handleDelete() {
    if (!confirm("¿Borrar este gasto? No se puede deshacer.")) return;
    setDeleting(true);
    const formData = new FormData();
    formData.set("expense_id", expenseId);
    const result = await deleteExpense(undefined, formData);
    setDeleting(false);
    if (result?.error) {
      toast.error(result.error);
      return;
    }
    router.refresh();
  }

  return (
    <div className="flex shrink-0 gap-1">
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogTrigger
          render={<Button type="button" variant="ghost" size="icon-sm" aria-label="Editar gasto" />}
        >
          <Pencil className="size-3.5" />
        </DialogTrigger>
        <DialogContent>
          <form onSubmit={handleSubmit}>
            <input type="hidden" name="expense_id" value={expenseId} />
            <DialogHeader>
              <DialogTitle>Editar gasto</DialogTitle>
              <DialogDescription>
                El reparto se recalcula igual entre las mismas personas.
              </DialogDescription>
            </DialogHeader>
            <div className="flex flex-col gap-3 py-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="edit-description">Descripción</Label>
                <Input
                  id="edit-description"
                  name="description"
                  defaultValue={description}
                  required
                />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="edit-amount">Importe (€)</Label>
                <Input
                  id="edit-amount"
                  name="amount"
                  type="number"
                  step="0.01"
                  min="0.01"
                  defaultValue={(amountCents / 100).toFixed(2)}
                  required
                />
              </div>
              <CategoryPicker defaultValue={category} />
              {error && <p className="text-sm text-destructive">{error}</p>}
            </div>
            <DialogFooter>
              <Button type="submit" disabled={pending}>
                {pending ? "Guardando..." : "Guardar cambios"}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
      <Button
        type="button"
        variant="ghost"
        size="icon-sm"
        onClick={handleDelete}
        disabled={deleting}
        aria-label="Borrar gasto"
      >
        <Trash2 className="size-3.5" />
      </Button>
    </div>
  );
}
