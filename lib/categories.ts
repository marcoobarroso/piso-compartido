import { Utensils, Zap, PartyPopper, Home, Bus, Package, type LucideIcon } from "lucide-react";

export const EXPENSE_CATEGORIES = [
  "comida",
  "suministros",
  "ocio",
  "hogar",
  "transporte",
  "otros",
] as const;

export type ExpenseCategory = (typeof EXPENSE_CATEGORIES)[number];

export const CATEGORY_LABELS: Record<ExpenseCategory, string> = {
  comida: "Comida",
  suministros: "Suministros",
  ocio: "Ocio",
  hogar: "Hogar",
  transporte: "Transporte",
  otros: "Otros",
};

export const CATEGORY_ICONS: Record<ExpenseCategory, LucideIcon> = {
  comida: Utensils,
  suministros: Zap,
  ocio: PartyPopper,
  hogar: Home,
  transporte: Bus,
  otros: Package,
};

/** Same categorical palette used in Stats' charts, so a category reads as
 * the same color everywhere in the app (and in the exported spreadsheet). */
export const CATEGORY_HEX: Record<ExpenseCategory, string> = {
  comida: "#c2532c",
  suministros: "#1f74a8",
  ocio: "#8f7015",
  hogar: "#6142b8",
  transporte: "#457f3a",
  otros: "#7d3fa3",
};
