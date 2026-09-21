"use client";

import { useState } from "react";
import { EXPENSE_CATEGORIES, CATEGORY_LABELS, CATEGORY_ICONS, type ExpenseCategory } from "@/lib/categories";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

export function CategoryPicker({
  defaultValue = "otros",
}: {
  defaultValue?: ExpenseCategory;
}) {
  const [category, setCategory] = useState<ExpenseCategory>(defaultValue);

  return (
    <div className="flex flex-col gap-2">
      <Label>Categoría</Label>
      <input type="hidden" name="category" value={category} />
      <div className="flex flex-wrap gap-1.5">
        {EXPENSE_CATEGORIES.map((c) => {
          const Icon = CATEGORY_ICONS[c];
          const active = c === category;
          return (
            <button
              key={c}
              type="button"
              onClick={() => setCategory(c)}
              className={cn(
                "flex items-center gap-1.5 rounded-full border px-3 py-2 text-sm transition-colors",
                active
                  ? "border-primary bg-primary/15 text-primary"
                  : "border-input text-muted-foreground hover:bg-muted"
              )}
            >
              <Icon className="size-3.5" />
              {CATEGORY_LABELS[c]}
            </button>
          );
        })}
      </div>
    </div>
  );
}
