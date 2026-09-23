"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";

/** Vuelve a la pantalla anterior (login o la pestaña Piso). Si se ha abierto
 * la política directamente, sin historial, va al inicio. */
export function BackLink() {
  const router = useRouter();

  return (
    <Link
      href="/login"
      onClick={(e) => {
        if (window.history.length > 1) {
          e.preventDefault();
          router.back();
        }
      }}
      className="inline-flex min-h-11 items-center text-sm text-primary hover:underline"
    >
      ← Volver
    </Link>
  );
}
