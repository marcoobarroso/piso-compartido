export function formatCents(amountCents: number): string {
  return (amountCents / 100).toLocaleString("es-ES", {
    style: "currency",
    currency: "EUR",
  });
}

/** Parses a "YYYY-MM-DD" date column as a local date, avoiding the UTC
 * midnight shift that `new Date("YYYY-MM-DD")` introduces. */
export function parseDateOnly(dateStr: string): Date {
  const [year, month, day] = dateStr.split("-").map(Number);
  return new Date(year, month - 1, day);
}

export function formatDate(dateStr: string): string {
  return parseDateOnly(dateStr).toLocaleDateString("es-ES", {
    day: "numeric",
    month: "short",
  });
}

export function isOverdue(dateStr: string): boolean {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return parseDateOnly(dateStr) < today;
}

export function isToday(dateStr: string): boolean {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return parseDateOnly(dateStr).getTime() === today.getTime();
}

/** How many days late a chore was completed: 0 or negative means on time
 * (completed on or before its due date), positive means that many days
 * late. */
export function daysLate(dueDateStr: string, completedAtIso: string): number {
  const due = parseDateOnly(dueDateStr);
  const completed = new Date(completedAtIso);
  completed.setHours(0, 0, 0, 0);
  return Math.round((completed.getTime() - due.getTime()) / 86_400_000);
}

export function formatRelativeTime(isoString: string): string {
  const diffMs = Date.now() - new Date(isoString).getTime();
  const diffMinutes = Math.round(diffMs / 60000);

  if (diffMinutes < 1) return "ahora mismo";
  if (diffMinutes < 60) return `hace ${diffMinutes} min`;

  const diffHours = Math.round(diffMinutes / 60);
  if (diffHours < 24) return `hace ${diffHours} h`;

  const diffDays = Math.round(diffHours / 24);
  if (diffDays < 7) return `hace ${diffDays} d`;

  return new Date(isoString).toLocaleDateString("es-ES", { day: "numeric", month: "short" });
}
