"use client";

import { useState } from "react";
import { Check, Copy, RefreshCw, MessageCircle } from "lucide-react";
import { regenerateInviteCode } from "@/app/actions/household";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

export function InviteCode({
  code: initialCode,
  householdId,
  householdName,
  isAdmin,
}: {
  code: string;
  householdId: string;
  householdName: string;
  isAdmin: boolean;
}) {
  const [code, setCode] = useState(initialCode);
  const [copied, setCopied] = useState(false);
  const [regenerating, setRegenerating] = useState(false);

  function inviteLink() {
    return `${window.location.origin}/join/${code}`;
  }

  async function copyLink() {
    try {
      await navigator.clipboard.writeText(inviteLink());
    } catch {
      toast.error("No se ha podido copiar. Usa el botón de WhatsApp o copia el código a mano.");
      return;
    }
    setCopied(true);
    toast.success("Enlace de invitación copiado");
    setTimeout(() => setCopied(false), 2000);
  }

  function shareOnWhatsapp() {
    // El enlace se abre en el navegador; quien tenga la app de iOS instalada
    // se une metiendo el código en la pantalla de unirse a un piso.
    const message = `Únete a nuestro piso "${householdName}" en Piso Compartido para llevar gastos, tareas y la compra: ${inviteLink()}\n\nSi usas la app, entra y únete con el código ${code}`;
    window.open(`https://wa.me/?text=${encodeURIComponent(message)}`, "_blank");
  }

  async function regenerate() {
    if (!confirm("¿Generar un código nuevo? El anterior dejará de funcionar.")) return;
    setRegenerating(true);
    const formData = new FormData();
    formData.set("household_id", householdId);
    const result = await regenerateInviteCode(undefined, formData);
    setRegenerating(false);
    if (result?.error) {
      toast.error(result.error);
      return;
    }
    if (result?.code) {
      setCode(result.code);
      toast.success("Código regenerado");
    }
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center gap-2 rounded-md border bg-muted/40 p-3">
        <span className="font-mono text-lg tracking-widest text-primary">{code}</span>
        <div className="ml-auto flex gap-2">
          {isAdmin && (
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={regenerate}
              disabled={regenerating}
              aria-label="Regenerar código"
            >
              <RefreshCw className="size-4" />
            </Button>
          )}
          <Button type="button" size="sm" variant="outline" onClick={copyLink}>
            {copied ? <Check className="size-4" /> : <Copy className="size-4" />}
            {copied ? "Copiado" : "Copiar"}
          </Button>
        </div>
      </div>
      <Button
        type="button"
        onClick={shareOnWhatsapp}
        className="w-full bg-[#25D366] text-white hover:bg-[#25D366]/90"
      >
        <MessageCircle className="size-4" />
        Invitar por WhatsApp
      </Button>
    </div>
  );
}
