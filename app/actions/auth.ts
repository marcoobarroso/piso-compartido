"use server";

import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export async function deleteAccount(): Promise<{ error: string }> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("delete_my_account");
  if (error) {
    return { error: "No se ha podido borrar la cuenta: " + error.message };
  }

  // El usuario ya no existe: signOut solo limpia las cookies de sesión.
  await supabase.auth.signOut().catch(() => {});
  redirect("/login?deleted=1");
}

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
