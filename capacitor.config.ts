import type { CapacitorConfig } from "@capacitor/cli";

// La app es 100% dinámica (Server Components, Server Actions, RLS) y ya
// está desplegada en Vercel, así que Capacitor no empaqueta un build
// estático: carga la web en producción dentro de un WebView nativo. Por eso
// cada despliegue en Vercel llega al instante a la app sin pasar por Apple.
// De webDir solo se usa public/offline.html (errorPath), que se muestra si
// no hay conexión en vez de dejar la pantalla en blanco.
const config: CapacitorConfig = {
  appId: "com.marcobarroso.pisocompartido",
  appName: "Piso Compartido",
  webDir: "public",
  backgroundColor: "#0a0a0a",
  server: {
    url: "https://piso-compartido.vercel.app",
    cleartext: false,
    errorPath: "offline.html",
  },
  ios: {
    contentInset: "automatic",
    backgroundColor: "#0a0a0a",
  },
  plugins: {
    PushNotifications: {
      // Con la app abierta también se muestra el aviso arriba.
      presentationOptions: ["badge", "sound", "alert"],
    },
  },
};

export default config;
