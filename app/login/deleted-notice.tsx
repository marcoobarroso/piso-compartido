"use client";

import { useSearchParams } from "next/navigation";

export function DeletedNotice() {
  const deleted = useSearchParams().get("deleted");
  if (!deleted) return null;

  return (
    <p className="w-full max-w-sm rounded-xl border bg-muted p-3 text-center text-sm">
      Tu cuenta se ha borrado correctamente.
    </p>
  );
}
