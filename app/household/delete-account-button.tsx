"use client";

import { useState, useTransition } from "react";
import { deleteAccount } from "@/app/actions/auth";
import { Button } from "@/components/ui/button";

export function DeleteAccountButton() {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleClick() {
    const ok = confirm(
      "¿Borrar tu cuenta para siempre? Saldrás de tu piso, se eliminará tu correo y no podrás recuperarla. Tus compañeros conservarán el historial de gastos, con tu nombre anonimizado."
    );
    if (!ok) return;

    setError(null);
    startTransition(async () => {
      const result = await deleteAccount();
      if (result?.error) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-2">
      <Button
        type="button"
        variant="ghost"
        className="w-full text-destructive hover:text-destructive"
        disabled={pending}
        onClick={handleClick}
      >
        {pending ? "Borrando cuenta..." : "Borrar mi cuenta"}
      </Button>
      {error && <p className="text-center text-sm text-destructive">{error}</p>}
    </div>
  );
}
