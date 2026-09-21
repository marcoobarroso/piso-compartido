export type MonthColumn = {
  label: string;
  value: number;
  formattedValue: string;
};

export function MonthlyBarChart({
  columns,
  emptyMessage,
}: {
  columns: MonthColumn[];
  emptyMessage: string;
}) {
  if (columns.every((c) => c.value === 0)) {
    return <p className="py-4 text-center text-sm text-muted-foreground">{emptyMessage}</p>;
  }

  const max = Math.max(...columns.map((c) => c.value), 1);

  return (
    <div className="flex items-end justify-between gap-2 border-b border-chart-grid pt-4">
      {columns.map((col) => (
        <div
          key={col.label}
          className="group flex flex-1 flex-col items-center gap-1"
          title={`${col.label}: ${col.formattedValue}`}
        >
          <span className="text-[10px] font-medium text-muted-foreground">
            {col.value > 0 ? col.formattedValue : ""}
          </span>
          <div
            className="w-full max-w-6 rounded-t-[4px] bg-chart-1 transition-[filter] group-hover:brightness-110"
            style={{ height: `${Math.max((col.value / max) * 96, col.value > 0 ? 4 : 0)}px` }}
          />
          <span className="pb-1 text-xs text-muted-foreground">{col.label}</span>
        </div>
      ))}
    </div>
  );
}
