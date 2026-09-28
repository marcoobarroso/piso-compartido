"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { Capacitor } from "@capacitor/core";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { usePushPromptVisible } from "@/lib/bottom-banner-stack";

type BeforeInstallPromptEvent = Event & {
  prompt: () => void;
  userChoice: Promise<{ outcome: "accepted" | "dismissed" }>;
};

export function InstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(
    null
  );
  const [dismissed, setDismissed] = useState(false);
  const pathname = usePathname();
  // /household/* tiene su propia barra de navegación fija abajo (BottomNav):
  // sin este hueco, este banner la tapaba por completo (mismos inset-x-0
  // bottom-0), dejando Inicio/Gastos/Tareas/Compra/Stats inalcanzables hasta
  // descartarlo.
  const hasBottomNav = pathname?.startsWith("/household");
  // El banner de avisos push vive justo encima de BottomNav (mismo hueco de
  // 4rem); si los dos están visibles a la vez este sube un piso más.
  const pushPromptVisible = usePushPromptVisible();

  useEffect(() => {
    // Ya es una app instalada de verdad dentro de Capacitor: no tiene
    // sentido ofrecer "instalarla" a mayores.
    if (Capacitor.isNativePlatform()) return;

    function handler(e: Event) {
      e.preventDefault();
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    }
    window.addEventListener("beforeinstallprompt", handler);
    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  if (Capacitor.isNativePlatform() || !deferredPrompt || dismissed) return null;

  return (
    <div
      className={cn(
        "fixed inset-x-0 z-50 flex items-center justify-between gap-3 border-t bg-background p-3 shadow-lg",
        !hasBottomNav && "bottom-0 pb-[calc(0.75rem+env(safe-area-inset-bottom))]",
        hasBottomNav &&
          (pushPromptVisible
            ? "bottom-[calc(8rem+env(safe-area-inset-bottom))]"
            : "bottom-[calc(4rem+env(safe-area-inset-bottom))]")
      )}
    >
      <span className="text-sm">Instala esta app para acceso rápido desde el móvil</span>
      <div className="flex shrink-0 gap-2">
        <Button size="sm" variant="ghost" onClick={() => setDismissed(true)}>
          Ahora no
        </Button>
        <Button
          size="sm"
          onClick={async () => {
            deferredPrompt.prompt();
            await deferredPrompt.userChoice;
            setDeferredPrompt(null);
          }}
        >
          Instalar
        </Button>
      </div>
    </div>
  );
}
