"use client";

import { useState } from "react";
import { useSearchParams } from "next/navigation";
import { Home, Mail, KeyRound } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { safeNextPath } from "@/lib/safe-redirect";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { toast } from "sonner";

// Longitud del código que envía Supabase (Authentication -> configuración de
// OTP). Si se cambia ahí, solo hay que tocar este número.
const OTP_LENGTH = 8;

export function LoginForm() {
  const searchParams = useSearchParams();
  const next = safeNextPath(searchParams.get("next"));
  const [step, setStep] = useState<"email" | "code">("email");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [loading, setLoading] = useState(false);

  async function sendCode(e: React.SyntheticEvent) {
    e.preventDefault();
    const cleanEmail = email.trim().toLowerCase();
    setEmail(cleanEmail);
    setLoading(true);

    const supabase = createClient();
    const callbackUrl = new URL("/auth/callback", window.location.origin);
    callbackUrl.searchParams.set("next", next);

    const { error } = await supabase.auth.signInWithOtp({
      email: cleanEmail,
      options: {
        emailRedirectTo: callbackUrl.toString(),
      },
    });

    setLoading(false);

    if (error) {
      const tooSoon = /seconds|rate limit/i.test(error.message);
      toast.error(
        tooSoon
          ? "Espera un minuto antes de pedir otro código."
          : "No se ha podido enviar el código: " + error.message
      );
      return;
    }

    if (step === "code") toast.success("Código reenviado. Revisa tu correo.");
    setStep("code");
  }

  async function verifyCode(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    const supabase = createClient();
    const { error } = await supabase.auth.verifyOtp({
      email,
      token: code,
      type: "email",
    });

    if (error) {
      setLoading(false);
      toast.error("Código incorrecto o caducado.");
      return;
    }

    window.location.href = next;
  }

  return (
    <div className="flex w-full max-w-sm flex-col items-center gap-4">
      <div className="flex size-12 items-center justify-center rounded-2xl bg-primary/15 text-primary">
        <Home className="size-6" />
      </div>
      <Card className="w-full">
        <CardHeader>
          <CardTitle>Piso Compartido</CardTitle>
          <CardDescription>
            {step === "email"
              ? "Escribe tu email y te mandamos un código para entrar, sin contraseña."
              : `Escribe el código que le hemos mandado a ${email}.`}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {step === "email" ? (
            <form onSubmit={sendCode} className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="tucorreo@ejemplo.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  autoFocus
                />
              </div>
              <Button type="submit" disabled={loading || !email}>
                <Mail className="size-4" />
                {loading ? "Enviando..." : "Enviar código"}
              </Button>
            </form>
          ) : (
            <form onSubmit={verifyCode} className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="code">Código</Label>
                <Input
                  id="code"
                  type="text"
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  placeholder={"1".repeat(OTP_LENGTH)}
                  maxLength={OTP_LENGTH}
                  className="text-center text-xl tracking-[0.35em]"
                  value={code}
                  onChange={(e) =>
                    setCode(e.target.value.replace(/\D/g, "").slice(0, OTP_LENGTH))
                  }
                  required
                  autoFocus
                />
              </div>
              <Button type="submit" disabled={loading || code.length !== OTP_LENGTH}>
                <KeyRound className="size-4" />
                {loading ? "Comprobando..." : "Entrar"}
              </Button>
              <div className="flex justify-between text-sm">
                <button
                  type="button"
                  className="text-muted-foreground hover:underline"
                  onClick={() => {
                    setStep("email");
                    setCode("");
                  }}
                >
                  Cambiar email
                </button>
                <button
                  type="button"
                  className="text-primary hover:underline"
                  onClick={sendCode}
                  disabled={loading}
                >
                  Reenviar código
                </button>
              </div>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
