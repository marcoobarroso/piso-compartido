import { requireHousehold } from "@/lib/household";
import { ThemeToggle } from "@/components/theme-toggle";
import { PushPrompt } from "@/components/push-prompt";
import { BottomNav } from "./bottom-nav";
import { NotificationBell } from "./notification-bell";

export default async function HouseholdLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const { supabase, user, household } = await requireHousehold();

  const { data: notifications } = await supabase
    .from("notifications")
    .select("id, message, link, is_read, created_at")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(20);

  return (
    <div className="flex flex-1 flex-col">
      <header className="sticky top-0 z-30 flex items-center justify-between border-b bg-background/95 px-4 py-3 backdrop-blur">
        <span className="font-semibold">{household.name}</span>
        <div className="flex items-center">
          <NotificationBell userId={user.id} initialNotifications={notifications ?? []} />
          <ThemeToggle />
        </div>
      </header>
      <main className="flex flex-1 flex-col pb-[calc(4rem+env(safe-area-inset-bottom))]">
        {children}
      </main>
      {/* No se ofrecen avisos push en la demo pública: los recibirían después
          los móviles de todos los visitantes que los activaran. */}
      {household.invite_code !== "DEMO01" && <PushPrompt userId={user.id} />}
      <BottomNav />
    </div>
  );
}
