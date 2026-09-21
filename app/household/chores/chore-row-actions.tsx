"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Pencil, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { deleteChore, updateChore } from "@/app/actions/chores";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

export function ChoreRowActions({
  choreId,
  householdId,
  name,
  recurrenceDays,
  rotationOrder,
  members,
}: {
  choreId: string;
  householdId: string;
  name: string;
  recurrenceDays: number;
  rotationOrder: string[];
  members: { userId: string; displayName: string }[];
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
    const result = await updateChore(undefined, formData);
    setPending(false);
    if (result?.error) {
      setError(result.error);
      return;
    }
    setOpen(false);
    router.refresh();
  }

  async function handleDelete() {
    if (!confirm("¿Borrar esta tarea? Se borra también su historial. No se puede deshacer.")) {
      return;
    }
    setDeleting(true);
    const formData = new FormData();
    formData.set("chore_id", choreId);
    const result = await deleteChore(undefined, formData);
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
          render={<Button type="button" variant="ghost" size="icon-sm" aria-label="Editar tarea" />}
        >
          <Pencil className="size-3.5" />
        </DialogTrigger>
        <DialogContent>
          <form onSubmit={handleSubmit}>
            <input type="hidden" name="chore_id" value={choreId} />
            <input type="hidden" name="household_id" value={householdId} />
            <DialogHeader>
              <DialogTitle>Editar tarea</DialogTitle>
              <DialogDescription>
                El nuevo intervalo se aplica a partir del próximo turno.
              </DialogDescription>
            </DialogHeader>
            <div className="flex flex-col gap-3 py-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="edit-chore-name">Tarea</Label>
                <Input id="edit-chore-name" name="name" defaultValue={name} required />
              </div>
              <div className="flex flex-col gap-2">
                <Label htmlFor="edit-chore-recurrence">Cada cuántos días</Label>
                <Input
                  id="edit-chore-recurrence"
                  name="recurrence_days"
                  type="number"
                  min="1"
                  defaultValue={recurrenceDays}
                  required
                />
              </div>
              <div className="flex flex-col gap-2">
                <Label>¿Quién entra en la rotación?</Label>
                <div className="flex flex-col gap-2">
                  {members.map((m) => (
                    <label key={m.userId} className="flex items-center gap-2 text-sm">
                      <Checkbox
                        name="rotation_order"
                        value={m.userId}
                        defaultChecked={rotationOrder.includes(m.userId)}
                      />
                      {m.displayName}
                    </label>
                  ))}
                </div>
              </div>
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
        aria-label="Borrar tarea"
      >
        <Trash2 className="size-3.5" />
      </Button>
    </div>
  );
}
