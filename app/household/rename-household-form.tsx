"use client";

import { useActionState } from "react";
import { renameHousehold } from "@/app/actions/household";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function RenameHouseholdForm({
  householdId,
  name,
}: {
  householdId: string;
  name: string;
}) {
  const [state, action, pending] = useActionState(renameHousehold, undefined);

  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="household_id" value={householdId} />
      <div className="flex gap-2">
        <Input
          key={name}
          name="name"
          defaultValue={name}
          required
          aria-label="Nombre del piso"
          className="flex-1"
        />
        <Button type="submit" variant="outline" disabled={pending}>
          {pending ? "..." : "Renombrar"}
        </Button>
      </div>
      {state?.error && <p className="text-sm text-destructive">{state.error}</p>}
    </form>
  );
}
