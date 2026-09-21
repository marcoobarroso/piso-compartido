"use client";

import { useState, useTransition } from "react";
import { Plus } from "lucide-react";
import { addChore } from "@/app/actions/chores";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";

export function AddChoreForm({
  householdId,
  members,
}: {
  householdId: string;
  members: { userId: string; displayName: string }[];
}) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | undefined>();
  // Cambia al guardar con éxito para volver a los valores por defecto.
  const [formKey, setFormKey] = useState(0);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    setError(undefined);
    startTransition(async () => {
      const result = await addChore(undefined, formData);
      if (result?.error) {
        // Se conserva todo lo escrito para poder corregirlo.
        setError(result.error);
        return;
      }
      setFormKey((k) => k + 1);
    });
  }

  return (
    <form key={formKey} onSubmit={handleSubmit} className="flex flex-col gap-3">
      <input type="hidden" name="household_id" value={householdId} />
      <div className="flex flex-col gap-2">
        <Label htmlFor="name">Tarea</Label>
        <Input id="name" name="name" placeholder="Sacar la basura" required />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="recurrence_days">Cada cuántos días</Label>
        <Input
          id="recurrence_days"
          name="recurrence_days"
          type="number"
          inputMode="numeric"
          min="1"
          step="1"
          defaultValue="7"
          required
        />
      </div>
      <div className="flex flex-col gap-2">
        <Label>¿Quién entra en la rotación?</Label>
        <div className="flex flex-col gap-2">
          {members.map((m) => (
            <label key={m.userId} className="flex items-center gap-2 text-sm">
              <Checkbox name="rotation_order" value={m.userId} defaultChecked />
              {m.displayName}
            </label>
          ))}
        </div>
      </div>
      {error && <p className="text-sm text-destructive">{error}</p>}
      <Button type="submit" disabled={pending}>
        <Plus className="size-4" />
        {pending ? "Creando..." : "Añadir tarea"}
      </Button>
    </form>
  );
}
