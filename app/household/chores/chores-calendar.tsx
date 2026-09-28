"use client";

import { useMemo, useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { projectChoreOccurrences } from "@/lib/chore-rotation";
import { chartColor } from "@/lib/chart-colors";
import { choreEmoji } from "@/lib/emoji-match";
import { cn } from "@/lib/utils";

type ChoreForCalendar = {
  id: string;
  name: string;
  recurrenceDays: number;
  rotationOrder: string[];
  currentAssignedTo: string;
  currentDueDate: Date;
};

type CalendarEvent = {
  choreId: string;
  choreName: string;
  assignedTo: string;
  isReal: boolean;
};

const WEEKDAY_LABELS = ["L", "M", "X", "J", "V", "S", "D"];
const MONTH_LABELS = [
  "enero", "febrero", "marzo", "abril", "mayo", "junio",
  "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
];

function dateKey(d: Date): string {
  return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}

function startOfGrid(monthDate: Date): Date {
  const first = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1);
  const offset = (first.getDay() + 6) % 7; // Monday = 0
  const start = new Date(first);
  start.setDate(first.getDate() - offset);
  return start;
}

function isSameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

export function ChoresCalendar({
  chores,
  memberIndex,
  memberNames,
}: {
  chores: ChoreForCalendar[];
  memberIndex: Record<string, number>;
  memberNames: Record<string, string>;
}) {
  const today = useMemo(() => {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
  }, []);
  const [month, setMonth] = useState(() => new Date(today.getFullYear(), today.getMonth(), 1));
  const [selectedDate, setSelectedDate] = useState(today);

  const { gridDays, gridStart, gridEnd } = useMemo(() => {
    const start = startOfGrid(month);
    const days = Array.from({ length: 42 }, (_, i) => {
      const d = new Date(start);
      d.setDate(start.getDate() + i);
      return d;
    });
    return { gridDays: days, gridStart: start, gridEnd: days[days.length - 1] };
  }, [month]);

  const eventsByDay = useMemo(() => {
    const map = new Map<string, CalendarEvent[]>();
    for (const chore of chores) {
      const occurrences = projectChoreOccurrences(
        chore.rotationOrder,
        chore.recurrenceDays,
        chore.currentAssignedTo,
        chore.currentDueDate,
        gridEnd
      );
      occurrences.forEach((occ, i) => {
        if (occ.date < gridStart) return;
        const key = dateKey(occ.date);
        const list = map.get(key) ?? [];
        list.push({
          choreId: chore.id,
          choreName: chore.name,
          assignedTo: occ.assignedTo,
          isReal: i === 0,
        });
        map.set(key, list);
      });
    }
    return map;
  }, [chores, gridStart, gridEnd]);

  const selectedEvents = eventsByDay.get(dateKey(selectedDate)) ?? [];

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <button
          type="button"
          onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() - 1, 1))}
          aria-label="Mes anterior"
          className="flex size-10 items-center justify-center rounded-md text-muted-foreground hover:bg-muted"
        >
          <ChevronLeft className="size-5" />
        </button>
        <p className="text-sm font-medium capitalize">
          {MONTH_LABELS[month.getMonth()]} {month.getFullYear()}
        </p>
        <button
          type="button"
          onClick={() => setMonth(new Date(month.getFullYear(), month.getMonth() + 1, 1))}
          aria-label="Mes siguiente"
          className="flex size-10 items-center justify-center rounded-md text-muted-foreground hover:bg-muted"
        >
          <ChevronRight className="size-5" />
        </button>
      </div>

      <div className="grid grid-cols-7 gap-1 text-center text-xs text-muted-foreground">
        {WEEKDAY_LABELS.map((w) => (
          <span key={w}>{w}</span>
        ))}
      </div>

      <div className="grid grid-cols-7 gap-1">
        {gridDays.map((day) => {
          const events = eventsByDay.get(dateKey(day)) ?? [];
          const inMonth = day.getMonth() === month.getMonth();
          const isToday = isSameDay(day, today);
          const isSelected = isSameDay(day, selectedDate);

          return (
            <button
              key={dateKey(day)}
              type="button"
              onClick={() => setSelectedDate(day)}
              className={cn(
                "flex flex-col items-center gap-0.5 rounded-md py-1.5 text-xs",
                !inMonth && "opacity-30",
                isSelected && "bg-primary/15",
                !isSelected && isToday && "ring-1 ring-primary/50"
              )}
            >
              <span>{day.getDate()}</span>
              <div className="flex gap-0.5 text-[10px] leading-none">
                {events.slice(0, 3).map((e, i) => (
                  <span key={i}>{choreEmoji(e.choreName)}</span>
                ))}
                {events.length > 3 && (
                  <span className="text-muted-foreground">+{events.length - 3}</span>
                )}
              </div>
            </button>
          );
        })}
      </div>

      <div className="flex flex-col gap-2 border-t pt-3">
        <p className="text-xs font-medium text-muted-foreground">
          {selectedDate.toLocaleDateString("es-ES", { weekday: "long", day: "numeric", month: "long" })}
        </p>
        {selectedEvents.length === 0 && (
          <p className="text-sm text-muted-foreground">Nada programado este día.</p>
        )}
        {selectedEvents.map((e, i) => (
          <div key={i} className="flex items-center gap-2 text-sm">
            <span
              className="flex size-7 shrink-0 items-center justify-center rounded-full text-sm"
              style={{ backgroundColor: `color-mix(in oklch, ${chartColor(memberIndex[e.assignedTo] ?? 0)} 20%, transparent)` }}
            >
              {choreEmoji(e.choreName)}
            </span>
            <span className="flex-1">
              {e.choreName} · {memberNames[e.assignedTo] ?? "—"}
            </span>
            {!e.isReal && <span className="text-xs text-muted-foreground">estimado</span>}
          </div>
        ))}
      </div>
    </div>
  );
}
