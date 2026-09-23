"use client";

import { Capacitor, type PluginListenerHandle } from "@capacitor/core";
import { PushNotifications } from "@capacitor/push-notifications";
import { createClient } from "@/lib/supabase/client";

// Notificaciones push de la app nativa de iOS (APNs). En la web/PWA se usa
// Web Push (components/push-prompt.tsx); dentro del WebView de la app nativa
// Web Push no existe, así que se usa el plugin nativo de Capacitor.

const TOKEN_KEY = "native-push-token";

export function isNativeApp() {
  return Capacitor.isNativePlatform();
}

export async function nativePushPermission() {
  const { receive } = await PushNotifications.checkPermissions();
  return receive; // "granted" | "denied" | "prompt" | "prompt-with-rationale"
}

/** Pide permiso (si hace falta), registra el iPhone en APNs y guarda el token
 * para el usuario actual. Devuelve false si el usuario no concede permiso. */
export async function enableNativePush(): Promise<boolean> {
  let { receive } = await PushNotifications.checkPermissions();
  if (receive === "prompt" || receive === "prompt-with-rationale") {
    ({ receive } = await PushNotifications.requestPermissions());
  }
  if (receive !== "granted") return false;

  const handles: PluginListenerHandle[] = [];
  let timeout: ReturnType<typeof setTimeout> | undefined;
  try {
    const token = await new Promise<string>((resolve, reject) => {
      timeout = setTimeout(() => reject(new Error("APNs no ha respondido")), 15000);
      Promise.all([
        PushNotifications.addListener("registration", ({ value }) => resolve(value)),
        PushNotifications.addListener("registrationError", ({ error }) =>
          reject(new Error(error))
        ),
      ])
        .then((h) => {
          handles.push(...h);
          return PushNotifications.register();
        })
        .catch(reject);
    });

    const supabase = createClient();
    const { error } = await supabase.rpc("register_native_push_token", {
      _token: token,
      _platform: Capacitor.getPlatform(),
    });
    if (error) throw error;

    try {
      localStorage.setItem(TOKEN_KEY, token);
    } catch {}
    return true;
  } finally {
    clearTimeout(timeout);
    handles.forEach((h) => h.remove());
  }
}

/** Al cerrar sesión: este iPhone deja de recibir los avisos de esta cuenta. */
export async function disableNativePush() {
  if (!isNativeApp()) return;
  let token: string | null = null;
  try {
    token = localStorage.getItem(TOKEN_KEY);
    localStorage.removeItem(TOKEN_KEY);
  } catch {}
  if (!token) return;
  const supabase = createClient();
  await supabase.rpc("unregister_native_push_token", { _token: token });
}

/** Al tocar una notificación, abre la pantalla a la que se refiere. */
export function handleNativePushTaps(navigate: (path: string) => void) {
  const handle = PushNotifications.addListener(
    "pushNotificationActionPerformed",
    ({ notification }) => {
      const link = notification.data?.link;
      const safe = typeof link === "string" && link.startsWith("/") && !link.startsWith("//");
      navigate(safe ? link : "/household");
    }
  );
  return () => {
    handle.then((h) => h.remove());
  };
}
