"use client";

import { useActionState } from "react";
import { leaveHousehold } from "@/app/actions/household";
import { Button } from "@/components/ui/button";

export function LeaveHouseholdButton({
  householdId,
  isLastMember,
}: {
  householdId: string;
  isLastMember: boolean;
}) {
  const [state, action, pending] = useActionState(leaveHousehold, undefined);

  return (
    <form
      action={action}
      onSubmit={(e) => {
        const message = isLastMember
          ? "Eres la única persona del piso: si sales, el piso y todos sus datos se borrarán para siempre. ¿Seguro?"
          : "¿Seguro que quieres salir del piso? Tus compañeros conservarán el historial de gastos.";
        if (!confirm(message)) e.preventDefault();
      }}
      className="flex flex-col gap-2"
    >
      <input type="hidden" name="household_id" value={householdId} />
      <Button type="submit" variant="outline" className="w-full" disabled={pending}>
        {pending ? "Saliendo..." : "Salir del piso"}
      </Button>
      {state?.error && <p className="text-center text-sm text-destructive">{state.error}</p>}
    </form>
  );
}
