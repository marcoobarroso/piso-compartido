"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Eye } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { safeNextPath } from "@/lib/safe-redirect";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";

const DEMO_EMAIL = "demo1@example.com";
const DEMO_PASSWORD = "DemoPiso2026!";

export function DemoLoginButton() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const next = safeNextPath(searchParams.get("next"));
  const [loading, setLoading] = useState(false);

  async function handleClick() {
    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({
      email: DEMO_EMAIL,
      password: DEMO_PASSWORD,
    });

    if (error) {
      setLoading(false);
      toast.error("No se ha podido entrar a la demo. Inténtalo de nuevo.");
      return;
    }

    router.push(next);
    router.refresh();
  }

  return (
    <Button
      type="button"
      variant="outline"
      onClick={handleClick}
      disabled={loading}
      className="w-full max-w-sm"
    >
      <Eye className="size-4" />
      {loading ? "Entrando..." : "Ver demo (sin registro)"}
    </Button>
  );
}
