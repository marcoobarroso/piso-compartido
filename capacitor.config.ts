import type { CapacitorConfig } from "@capacitor/cli";

// La app es 100% dinámica (Server Components, Server Actions, RLS) y ya
// está desplegada en Vercel, así que Capacitor no empaqueta un build
// estático: carga la web en producción dentro de un WebView nativo. webDir
// es obligatorio para el CLI pero no se usa en este modo.
const config: CapacitorConfig = {
  appId: "com.marcobarroso.pisocompartido",
  appName: "Piso Compartido",
  webDir: "public",
  server: {
    url: "https://piso-compartido.vercel.app",
    cleartext: false,
  },
  ios: {
    contentInset: "automatic",
  },
};

export default config;
