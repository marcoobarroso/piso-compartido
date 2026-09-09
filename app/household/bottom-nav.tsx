"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Home, Receipt, ListChecks, ShoppingCart, ChartColumn } from "lucide-react";
import { cn } from "@/lib/utils";

const tabs = [
  { href: "/household", label: "Inicio", icon: Home },
  { href: "/household/expenses", label: "Gastos", icon: Receipt },
  { href: "/household/chores", label: "Tareas", icon: ListChecks },
  { href: "/household/shopping", label: "Compra", icon: ShoppingCart },
  { href: "/household/stats", label: "Stats", icon: ChartColumn },
];

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed inset-x-0 bottom-0 z-40 border-t bg-background/95 pb-[env(safe-area-inset-bottom)] backdrop-blur">
      <div className="mx-auto flex max-w-md items-stretch justify-around">
        {tabs.map((tab) => {
          const active =
            tab.href === "/household"
              ? pathname === "/household"
              : pathname.startsWith(tab.href);
          const Icon = tab.icon;
          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={cn(
                "flex flex-1 flex-col items-center gap-1 py-2.5 text-xs transition-colors",
                active ? "text-primary" : "text-muted-foreground"
              )}
            >
              <Icon className="size-5" />
              {tab.label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
