// Edge Function que envía una notificación push real cada vez que se crea
// una fila en `notifications`. Se dispara desde un Database Webhook
// (Database -> Webhooks en el panel de Supabase), no hace falta llamarla
// a mano desde la app.
//
// Envía a dos sitios:
//   - Web Push (PWA / navegador): tabla push_subscriptions.
//   - APNs (app nativa de iOS de la App Store): tabla native_push_tokens.
//
// Variables de entorno necesarias (Edge Functions -> Secrets):
//   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY           (Web Push)
//   APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY   (iOS; si faltan, se omite)
//   APNS_BUNDLE_ID (opcional, por defecto com.marcobarroso.pisocompartido)
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY ya los inyecta Supabase solo.

import webpush from "npm:web-push@3.6.7";

const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY")!;
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID");
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID");
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY");
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") ?? "com.marcobarroso.pisocompartido";

webpush.setVapidDetails(
  "mailto:marcbarro.07@gmail.com",
  VAPID_PUBLIC_KEY,
  VAPID_PRIVATE_KEY
);

const restHeaders = {
  apikey: SERVICE_ROLE_KEY,
  Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
};

type PushSubscriptionRow = {
  id: string;
  endpoint: string;
  p256dh: string;
  auth: string;
};

type NativeTokenRow = { id: string; token: string };

type Message = { body: string; link: string };

// ---------------------------------------------------------------------------
// Web Push
// ---------------------------------------------------------------------------

async function sendWebPush(userId: string, message: Message) {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/push_subscriptions?user_id=eq.${userId}`,
    { headers: restHeaders }
  );
  const subscriptions: PushSubscriptionRow[] = await res.json();

  await Promise.all(
    subscriptions.map(async (sub) => {
      try {
        await webpush.sendNotification(
          {
            endpoint: sub.endpoint,
            keys: { p256dh: sub.p256dh, auth: sub.auth },
          },
          JSON.stringify({ title: "Piso Compartido", body: message.body, link: message.link })
        );
      } catch (err) {
        const statusCode = (err as { statusCode?: number }).statusCode;
        if (statusCode === 404 || statusCode === 410) {
          // La suscripción ya no es válida (el usuario desinstaló la app,
          // borró datos del navegador, etc.) — la limpiamos.
          await fetch(`${SUPABASE_URL}/rest/v1/push_subscriptions?id=eq.${sub.id}`, {
            method: "DELETE",
            headers: restHeaders,
          });
        }
      }
    })
  );
}

// ---------------------------------------------------------------------------
// APNs (iOS nativo)
// ---------------------------------------------------------------------------

function base64url(input: ArrayBuffer | string) {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

let cachedJwt: { token: string; issuedAt: number } | null = null;

// Apple pide renovar el JWT como mucho cada hora y no más de una vez cada 20 min.
async function apnsJwt() {
  const now = Math.floor(Date.now() / 1000);
  if (cachedJwt && now - cachedJwt.issuedAt < 50 * 60) return cachedJwt.token;

  // Acepta el .p8 tal cual (con saltos de línea o con "\n" escritos).
  const pem = APNS_PRIVATE_KEY!
    .replace(/\\n/g, "\n")
    .replace(/-----[^-]+-----/g, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const header = base64url(JSON.stringify({ alg: "ES256", kid: APNS_KEY_ID }));
  const claims = base64url(JSON.stringify({ iss: APNS_TEAM_ID, iat: now }));
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(`${header}.${claims}`)
  );

  const token = `${header}.${claims}.${base64url(signature)}`;
  cachedJwt = { token, issuedAt: now };
  return token;
}

async function postToApns(host: string, deviceToken: string, body: string) {
  const res = await fetch(`https://${host}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${await apnsJwt()}`,
      "apns-topic": APNS_BUNDLE_ID,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body,
  });
  const reason = res.ok ? "" : ((await res.json().catch(() => ({}))).reason ?? "");
  return { status: res.status, reason: String(reason) };
}

async function sendApns(userId: string, message: Message) {
  if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY) return;

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/native_push_tokens?user_id=eq.${userId}&select=id,token`,
    { headers: restHeaders }
  );
  if (!res.ok) return;
  const tokens: NativeTokenRow[] = await res.json();

  const body = JSON.stringify({
    aps: {
      alert: { title: "Piso Compartido", body: message.body },
      sound: "default",
    },
    link: message.link,
  });

  await Promise.all(
    tokens.map(async ({ id, token }) => {
      try {
        // Las builds de TestFlight/App Store usan el APNs de producción; las
        // que se instalan desde Xcode usan el de desarrollo (sandbox).
        let result = await postToApns("api.push.apple.com", token, body);
        if (result.status === 400 && result.reason === "BadDeviceToken") {
          result = await postToApns("api.sandbox.push.apple.com", token, body);
        }

        const invalid =
          result.status === 410 ||
          (result.status === 400 && result.reason === "BadDeviceToken");
        if (invalid) {
          await fetch(`${SUPABASE_URL}/rest/v1/native_push_tokens?id=eq.${id}`, {
            method: "DELETE",
            headers: restHeaders,
          });
        } else if (result.status !== 200) {
          console.error("APNs", result.status, result.reason);
        }
      } catch (err) {
        console.error("APNs", err);
      }
    })
  );
}

// ---------------------------------------------------------------------------

Deno.serve(async (req) => {
  const payload = await req.json();
  const record = payload.record;

  if (!record?.user_id) {
    return new Response("ignored", { status: 200 });
  }

  const message: Message = { body: record.message, link: record.link || "/household" };
  await Promise.all([sendWebPush(record.user_id, message), sendApns(record.user_id, message)]);

  return new Response("ok", { status: 200 });
});
