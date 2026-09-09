import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { resolveCurrentUser } from "@/lib/household";

export default async function Home() {
  const supabase = await createClient();
  const { displayName, household } = await resolveCurrentUser(supabase);

  if (!displayName) {
    redirect("/profile/setup");
  }

  redirect(household ? "/household" : "/onboarding");
}
