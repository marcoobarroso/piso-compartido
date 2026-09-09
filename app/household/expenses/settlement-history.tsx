"use client";

import { useTransition } from "react";
import { ArrowRight, Undo2 } from "lucide-react";
import { deleteSettlement } from "@/app/actions/expenses";
import { formatCents, formatRelativeTime } from "@/lib/format";
import { Button } from "@/components/ui/button";

type Settlement = {
  id: string;
  fromName: string;
  toName: string;
  amount_cents: number;
  settled_at: string;
};

export function SettlementHistory({ settlements }: { settlements: Settlement[] }) {
  const [isPending, startTransition] = useTransition();

  if (settlements.length === 0) {
    return <p className="text-sm text-muted-foreground">Todavía no hay pagos registrados.</p>;
  }

  return (
    <div className="flex flex-col gap-3">
      {settlements.map((s) => (
        <div key={s.id} className="flex items-center gap-2 text-sm">
          <span className="flex-1">
            {s.fromName} <ArrowRight className="inline size-3 text-muted-foreground" />{" "}
            {s.toName} · {formatCents(s.amount_cents)}
          </span>
          <span className="text-xs text-muted-foreground">{formatRelativeTime(s.settled_at)}</span>
          <Button
            type="button"
            variant="ghost"
            size="icon-sm"
            disabled={isPending}
            aria-label="Deshacer este pago"
            onClick={() => {
              if (!confirm("¿Deshacer este pago? Se ajustará el saldo.")) return;
              const formData = new FormData();
              formData.set("settlement_id", s.id);
              startTransition(() => deleteSettlement(formData));
            }}
          >
            <Undo2 className="size-3.5" />
          </Button>
        </div>
      ))}
    </div>
  );
}
