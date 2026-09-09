import "server-only";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export type Household = {
  id: string;
  name: string;
  invite_code: string;
};

export type HouseholdMember = {
  userId: string;
  role: "admin" | "member";
  displayName: string;
};

/**
 * Resolves the profile's display name and household in one round trip
 * (instead of two separate queries) by selecting household_members as a
 * nested relation of profiles.
 */
export async function resolveCurrentUser(
  supabase: Awaited<ReturnType<typeof createClient>>
) {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select(
      "display_name, household_members(household_id, joined_at, households(id, name, invite_code))"
    )
    .eq("id", user.id)
    .maybeSingle();

  const memberships = (profile?.household_members ?? []) as unknown as {
    household_id: string;
    joined_at: string;
    households: Household;
  }[];
  memberships.sort((a, b) => a.joined_at.localeCompare(b.joined_at));

  return {
    user,
    displayName: profile?.display_name ?? null,
    household: memberships[0]?.households ?? null,
  };
}

/**
 * Loads the current user's household, redirecting to /profile/setup or
 * /onboarding if either step isn't done yet. Every page under a household
 * should start here instead of re-querying membership itself.
 */
export async function requireHousehold() {
  const supabase = await createClient();
  const { user, displayName, household } = await resolveCurrentUser(supabase);

  if (!displayName) {
    redirect("/profile/setup");
  }
  if (!household) {
    redirect("/onboarding");
  }

  return { supabase, user, household };
}

export async function getHouseholdMembers(
  supabase: Awaited<ReturnType<typeof createClient>>,
  householdId: string
): Promise<HouseholdMember[]> {
  const { data } = await supabase
    .from("household_members")
    .select("user_id, role, profiles(display_name)")
    .eq("household_id", householdId)
    .order("joined_at", { ascending: true });

  return (data ?? []).map((m) => {
    const profile = m.profiles as unknown as { display_name: string | null } | null;
    return {
      userId: m.user_id as string,
      role: m.role as "admin" | "member",
      displayName: profile?.display_name || "Sin nombre",
    };
  });
}

/**
 * Builds a name lookup covering both current members and anyone who shows
 * up in userIds but has since left/been removed (resolved from profiles
 * directly), so historical expenses/settlements still show a real name
 * instead of "—".
 */
export async function resolveNames(
  supabase: Awaited<ReturnType<typeof createClient>>,
  members: HouseholdMember[],
  userIds: Iterable<string>
): Promise<(userId: string) => string> {
  const memberIds = new Set(members.map((m) => m.userId));
  const missingIds = new Set<string>();
  for (const id of userIds) {
    if (!memberIds.has(id)) missingIds.add(id);
  }

  const departedNames: Record<string, string> = {};
  if (missingIds.size > 0) {
    const { data } = await supabase
      .from("profiles")
      .select("id, display_name")
      .in("id", Array.from(missingIds));
    for (const p of data ?? []) {
      departedNames[p.id] = (p.display_name || "Sin nombre") + " (ya no está en el piso)";
    }
  }

  return (userId: string) =>
    members.find((m) => m.userId === userId)?.displayName ?? departedNames[userId] ?? "—";
}
