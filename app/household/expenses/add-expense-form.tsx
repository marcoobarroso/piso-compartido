"use client";

import { useRef, useState, useTransition } from "react";
import { Plus } from "lucide-react";
import { addExpense } from "@/app/actions/expenses";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { CategoryPicker } from "@/components/category-picker";
import { cn } from "@/lib/utils";

export function AddExpenseForm({
  householdId,
  members,
}: {
  householdId: string;
  members: { userId: string; displayName: string }[];
}) {
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | undefined>();
  const formRef = useRef<HTMLFormElement>(null);
  const [splitMode, setSplitMode] = useState<"equal" | "custom">("equal");
  const [amount, setAmount] = useState("");
  const [customShares, setCustomShares] = useState<Record<string, string>>({});
  // Cambia al guardar con éxito para vaciar también los campos de reparto.
  const [formKey, setFormKey] = useState(0);

  const totalCents = Math.round((Number(amount) || 0) * 100);
  const enteredCents = Object.values(customShares).reduce(
    (sum, v) => sum + Math.round((Number(v) || 0) * 100),
    0
  );
  const remainingCents = totalCents - enteredCents;
  const customInvalid = splitMode === "custom" && (totalCents === 0 || remainingCents !== 0);

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    setError(undefined);
    startTransition(async () => {
      const result = await addExpense(undefined, formData);
      if (result?.error) {
        // Se conserva todo lo escrito para poder corregirlo.
        setError(result.error);
        return;
      }
      formRef.current?.reset();
      setSplitMode("equal");
      setAmount("");
      setCustomShares({});
      setFormKey((k) => k + 1);
    });
  }

  return (
    <form
      key={formKey}
      ref={formRef}
      onSubmit={handleSubmit}
      className="flex flex-col gap-3"
    >
      <input type="hidden" name="household_id" value={householdId} />
      <input type="hidden" name="split_mode" value={splitMode} />
      <div className="flex flex-col gap-2">
        <Label htmlFor="description">Descripción</Label>
        <Input id="description" name="description" placeholder="Compra Mercadona" required />
      </div>
      <div className="flex flex-col gap-2">
        <Label htmlFor="amount">Importe (€)</Label>
        <Input
          id="amount"
          name="amount"
          type="number"
          inputMode="decimal"
          step="0.01"
          min="0.01"
          placeholder="24.50"
          required
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />
      </div>
      <CategoryPicker />

      <div className="flex flex-col gap-2">
        <Label>¿Cómo se reparte?</Label>
        <div className="flex gap-2">
          <Button
            type="button"
            size="sm"
            variant={splitMode === "equal" ? "default" : "outline"}
            onClick={() => setSplitMode("equal")}
          >
            Partes iguales
          </Button>
          <Button
            type="button"
            size="sm"
            variant={splitMode === "custom" ? "default" : "outline"}
            onClick={() => setSplitMode("custom")}
          >
            Importes exactos
          </Button>
        </div>
      </div>

      {splitMode === "equal" ? (
        <div className="flex flex-col gap-2">
          <Label>¿Quién participa?</Label>
          <div className="flex flex-col gap-2">
            {members.map((m) => (
              <label key={m.userId} className="flex items-center gap-2 text-sm">
                <Checkbox name="participant_ids" value={m.userId} defaultChecked />
                {m.displayName}
              </label>
            ))}
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          <Label>¿Cuánto paga cada uno?</Label>
          <div className="flex flex-col gap-2">
            {members.map((m) => (
              <div key={m.userId} className="flex items-center gap-2">
                <span className="flex-1 text-sm">{m.displayName}</span>
                <Input
                  name={`share_${m.userId}`}
                  type="number"
                  inputMode="decimal"
                  step="0.01"
                  min="0"
                  placeholder="0.00"
                  className="w-24"
                  value={customShares[m.userId] ?? ""}
                  onChange={(e) =>
                    setCustomShares((prev) => ({ ...prev, [m.userId]: e.target.value }))
                  }
                />
              </div>
            ))}
          </div>
          <p
            className={cn(
              "text-xs",
              remainingCents === 0 ? "text-muted-foreground" : "text-destructive"
            )}
          >
            {totalCents === 0
              ? "Pon primero el importe total."
              : remainingCents === 0
                ? "Cuadra con el importe total."
                : remainingCents > 0
                  ? `Faltan ${(remainingCents / 100).toFixed(2)} € por repartir.`
                  : `Sobran ${(-remainingCents / 100).toFixed(2)} € repartidos de más.`}
          </p>
        </div>
      )}

      {error && <p className="text-sm text-destructive">{error}</p>}
      <Button type="submit" disabled={pending || customInvalid}>
        <Plus className="size-4" />
        {pending ? "Guardando..." : "Añadir gasto"}
      </Button>
    </form>
  );
}
