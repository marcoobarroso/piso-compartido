import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { resolveCurrentUser } from "@/lib/household";
import { OnboardingForms } from "./onboarding-forms";

export default async function OnboardingPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  const supabase = await createClient();
  const { displayName, household } = await resolveCurrentUser(supabase);

  if (!displayName) {
    redirect("/profile/setup");
  }
  if (household) {
    redirect("/household");
  }

  return (
    <div className="flex flex-1 flex-col items-center justify-center gap-4 p-4">
      {error === "invite" && (
        <p className="text-sm text-destructive">
          Ese código de invitación no es válido. Pide uno nuevo a un compañero
          o crea tu propio piso.
        </p>
      )}
      <OnboardingForms />
    </div>
  );
}
