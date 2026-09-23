"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

const STALE_AFTER_MS = 2 * 60 * 1000;

/** Al volver a la app (o a la pestaña) tras un rato en segundo plano, vuelve
 * a pedir los datos al servidor: saldos, tareas, etc. no se quedan antiguos,
 * y si mientras tanto se ha publicado una versión nueva en Vercel, Next.js la
 * detecta en esta petición y recarga la app con ella. */
export function RefreshOnResume() {
  const router = useRouter();

  useEffect(() => {
    let hiddenAt: number | null = null;

    function onVisibilityChange() {
      if (document.visibilityState === "hidden") {
        hiddenAt = Date.now();
      } else if (hiddenAt !== null && Date.now() - hiddenAt > STALE_AFTER_MS) {
        hiddenAt = null;
        router.refresh();
      }
    }

    document.addEventListener("visibilitychange", onVisibilityChange);
    return () => document.removeEventListener("visibilitychange", onVisibilityChange);
  }, [router]);

  return null;
}
