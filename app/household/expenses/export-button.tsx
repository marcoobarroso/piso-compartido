"use client";

import { useState } from "react";
import { Download } from "lucide-react";
import { toast } from "sonner";
import { Capacitor } from "@capacitor/core";
import { Button } from "@/components/ui/button";

const EXPORT_URL = "/household/expenses/export";

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).split(",")[1] ?? "");
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });
}

/** En la web basta con un enlace de descarga; el WebView de la app de iOS no
 * sabe descargar ficheros, así que ahí se genera el Excel, se guarda en la
 * caché de la app y se abre la hoja de compartir (Guardar en Archivos,
 * WhatsApp, Mail…). */
async function shareOnNative() {
  const res = await fetch(EXPORT_URL, { credentials: "include" });
  if (!res.ok) throw new Error(String(res.status));
  const disposition = res.headers.get("Content-Disposition") ?? "";
  const filename = /filename="([^"]+)"/.exec(disposition)?.[1] ?? "gastos.xlsx";
  const data = await blobToBase64(await res.blob());

  const [{ Filesystem, Directory }, { Share }] = await Promise.all([
    import("@capacitor/filesystem"),
    import("@capacitor/share"),
  ]);
  const { uri } = await Filesystem.writeFile({
    path: filename,
    data,
    directory: Directory.Cache,
  });
  await Share.share({ title: filename, files: [uri] });
}

export function ExportButton() {
  const [pending, setPending] = useState(false);

  return (
    <Button
      variant="outline"
      size="sm"
      nativeButton={false}
      disabled={pending}
      render={
        <a
          href={EXPORT_URL}
          download
          onClick={(e) => {
            if (!Capacitor.isNativePlatform()) return;
            e.preventDefault();
            setPending(true);
            shareOnNative()
              .catch((err: unknown) => {
                // Cerrar la hoja de compartir sin elegir nada no es un error.
                if (String(err).toLowerCase().includes("cancel")) return;
                toast.error("No se ha podido exportar el Excel. Inténtalo de nuevo.");
              })
              .finally(() => setPending(false));
          }}
        />
      }
    >
      <Download className="size-3.5" />
      {pending ? "Generando..." : "Excel"}
    </Button>
  );
}
