"use client";

import { useEffect, useState } from "react";
import { Bell } from "lucide-react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/");
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);
  for (let i = 0; i < rawData.length; i++) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

async function saveSubscription(userId: string) {
  const vapidPublicKey = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY;
  if (!vapidPublicKey) throw new Error("Falta la clave VAPID");

  const registration = await navigator.serviceWorker.ready;
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(vapidPublicKey) as BufferSource,
  });

  const json = subscription.toJSON();
  const supabase = createClient();
  const { error } = await supabase.from("push_subscriptions").upsert(
    {
      user_id: userId,
      endpoint: json.endpoint!,
      p256dh: json.keys!.p256dh,
      auth: json.keys!.auth,
    },
    { onConflict: "endpoint" }
  );
  if (error) throw error;
}

export function PushPrompt({ userId }: { userId: string }) {
  const [visible, setVisible] = useState(false);
  const [subscribing, setSubscribing] = useState(false);

  useEffect(() => {
    const supported =
      "Notification" in window && "serviceWorker" in navigator && "PushManager" in window;
    if (!supported) return;

    // El permiso ya estaba concedido de una vez anterior (p.ej. porque en su
    // momento fallara el guardado en Supabase): reintenta en silencio en vez
    // de esperar a que el usuario pulse "Activar" otra vez.
    if (Notification.permission === "granted") {
      saveSubscription(userId).catch(() => {});
      return;
    }

    const dismissed = localStorage.getItem("push-prompt-dismissed");
    if (!dismissed && Notification.permission === "default") {
      setVisible(true);
    }
  }, [userId]);

  async function subscribe() {
    setSubscribing(true);
    try {
      const permission = await Notification.requestPermission();
      if (permission === "granted") {
        await saveSubscription(userId);
        toast.success("Avisos activados");
      }
      setVisible(false);
    } catch {
      toast.error("No se han podido activar los avisos. Inténtalo de nuevo más tarde.");
    } finally {
      setSubscribing(false);
    }
  }

  function dismiss() {
    localStorage.setItem("push-prompt-dismissed", "1");
    setVisible(false);
  }

  if (!visible) return null;

  return (
    <div className="fixed inset-x-0 bottom-[calc(4rem+env(safe-area-inset-bottom))] z-40 flex items-center justify-between gap-3 border-t bg-background p-3 shadow-lg">
      <div className="flex items-center gap-2">
        <Bell className="size-4 shrink-0 text-primary" />
        <span className="text-sm">Activa avisos para enterarte al momento</span>
      </div>
      <div className="flex shrink-0 gap-2">
        <Button size="sm" variant="ghost" onClick={dismiss}>
          Ahora no
        </Button>
        <Button size="sm" onClick={subscribe} disabled={subscribing}>
          {subscribing ? "..." : "Activar"}
        </Button>
      </div>
    </div>
  );
}
