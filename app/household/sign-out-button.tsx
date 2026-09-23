"use client";

import { useTransition } from "react";
import { signOut } from "@/app/actions/auth";
import { createClient } from "@/lib/supabase/client";
import { disableNativePush } from "@/lib/native-push";
import { Button } from "@/components/ui/button";

/** Antes de cerrar sesión se da de baja este dispositivo de los avisos push;
 * si no, seguiría recibiendo los avisos de la cuenta que acaba de salir (y la
 * siguiente persona que entrase aquí no podría registrarse). */
async function removePushSubscription() {
  try {
    await disableNativePush();
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) return;
    const registration = await navigator.serviceWorker.getRegistration();
    const subscription = await registration?.pushManager.getSubscription();
    if (!subscription) return;
    const supabase = createClient();
    await supabase.from("push_subscriptions").delete().eq("endpoint", subscription.endpoint);
    await subscription.unsubscribe();
  } catch {
    // Cerrar sesión no debe fallar por esto.
  }
}

export function SignOutButton() {
  const [pending, startTransition] = useTransition();

  return (
    <Button
      type="button"
      variant="ghost"
      className="w-full"
      disabled={pending}
      onClick={() =>
        startTransition(async () => {
          await removePushSubscription();
          await signOut();
        })
      }
    >
      {pending ? "Cerrando sesión..." : "Cerrar sesión"}
    </Button>
  );
}
