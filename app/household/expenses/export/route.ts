import ExcelJS from "exceljs";
import { createClient as createServerClient } from "@supabase/supabase-js";
import { requireHousehold, getHouseholdMembers, resolveNames, type Household } from "@/lib/household";
import {
  CATEGORY_HEX,
  CATEGORY_LABELS,
  EXPENSE_CATEGORIES,
  type ExpenseCategory,
} from "@/lib/categories";

/**
 * The native iOS app authenticates directly against Supabase (no Next.js
 * session cookie), so it calls this route with `Authorization: Bearer
 * <access_token>` instead. Web requests are unaffected — they keep going
 * through the cookie-based requireHousehold() below.
 */
async function resolveFromBearerToken(request: Request) {
  const auth = request.headers.get("authorization");
  if (!auth?.startsWith("Bearer ")) return null;

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { global: { headers: { Authorization: auth } } }
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data } = await supabase
    .from("household_members")
    .select("joined_at, households(id, name, invite_code)")
    .eq("user_id", user.id)
    .order("joined_at", { ascending: true })
    .limit(1)
    .maybeSingle();

  const household = (data?.households as unknown as Household | null) ?? null;
  if (!household) return null;

  return { supabase, user, household };
}

const HEADER_FILL: ExcelJS.Fill = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: "FF1F2933" },
};
const STRIPE_FILL: ExcelJS.Fill = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: "FFF3F4F6" },
};

function hexToArgb(hex: string): string {
  return "FF" + hex.replace("#", "").toUpperCase();
}

export async function GET(request: Request) {
  const { supabase, household } = (await resolveFromBearerToken(request)) ?? (await requireHousehold());
  const members = await getHouseholdMembers(supabase, household.id);

  const [{ data: expenses }, { data: shares }] = await Promise.all([
    supabase
      .from("expenses")
      .select("id, description, amount_cents, paid_by, expense_date, category")
      .eq("household_id", household.id)
      .order("expense_date", { ascending: true })
      .order("created_at", { ascending: true }),
    supabase
      .from("expense_shares")
      .select("expense_id, user_id, share_cents")
      .eq("household_id", household.id),
  ]);

  const referencedIds = [
    ...(expenses ?? []).map((e) => e.paid_by),
    ...(shares ?? []).map((s) => s.user_id),
  ];
  const nameOf = await resolveNames(supabase, members, referencedIds);

  const participantsByExpense = (shares ?? []).reduce<Record<string, string[]>>((acc, s) => {
    acc[s.expense_id] = acc[s.expense_id] ?? [];
    acc[s.expense_id].push(nameOf(s.user_id));
    return acc;
  }, {});

  const workbook = new ExcelJS.Workbook();
  workbook.creator = "Rumis";
  workbook.created = new Date();

  // ---- Hoja "Gastos": una fila por gasto, fácil de escanear de un vistazo ----
  const sheet = workbook.addWorksheet("Gastos", { views: [{ state: "frozen", ySplit: 1 }] });
  sheet.columns = [
    { header: "Fecha", key: "date", width: 12 },
    { header: "Descripción", key: "description", width: 32 },
    { header: "Categoría", key: "category", width: 16 },
    { header: "Importe", key: "amount", width: 14 },
    { header: "Pagado por", key: "paidBy", width: 22 },
    { header: "Repartido entre", key: "participants", width: 36 },
  ];
  sheet.getRow(1).font = { bold: true, color: { argb: "FFFFFFFF" } };
  sheet.getRow(1).fill = HEADER_FILL;
  sheet.getRow(1).alignment = { vertical: "middle" };
  sheet.autoFilter = { from: "A1", to: "F1" };

  let total = 0;
  for (const e of expenses ?? []) {
    const category = (e.category ?? "otros") as ExpenseCategory;
    total += e.amount_cents;

    const row = sheet.addRow({
      date: new Date(e.expense_date + "T00:00:00"),
      description: e.description,
      category: CATEGORY_LABELS[category],
      amount: e.amount_cents / 100,
      paidBy: nameOf(e.paid_by),
      participants: (participantsByExpense[e.id] ?? []).join(", "),
    });

    row.getCell("date").numFmt = "dd/mm/yyyy";
    row.getCell("amount").numFmt = "#,##0.00 €";
    row.getCell("amount").alignment = { horizontal: "right" };
    row.getCell("category").font = { color: { argb: hexToArgb(CATEGORY_HEX[category]) }, bold: true };

    if (row.number % 2 === 0) {
      row.eachCell({ includeEmpty: true }, (cell) => {
        cell.fill = STRIPE_FILL;
      });
    }
  }

  if ((expenses ?? []).length === 0) {
    sheet.addRow({ description: "Todavía no hay gastos en este piso." });
  } else {
    const totalRow = sheet.addRow({ description: "Total", amount: total / 100 });
    totalRow.font = { bold: true };
    totalRow.getCell("amount").numFmt = "#,##0.00 €";
    totalRow.getCell("amount").alignment = { horizontal: "right" };
  }

  // ---- Hoja "Resumen": totales por categoría y por persona ----
  const summary = workbook.addWorksheet("Resumen");
  summary.columns = [
    { key: "label", width: 28 },
    { key: "value", width: 16 },
  ];

  const titleRow = summary.addRow(["Total gastado por el piso", total / 100]);
  titleRow.font = { bold: true, size: 13 };
  titleRow.getCell(2).numFmt = "#,##0.00 €";
  summary.addRow([]);

  summary.addRow(["Por categoría"]).font = { bold: true };
  const byCategory = new Map<ExpenseCategory, number>();
  for (const e of expenses ?? []) {
    const category = (e.category ?? "otros") as ExpenseCategory;
    byCategory.set(category, (byCategory.get(category) ?? 0) + e.amount_cents);
  }
  for (const category of EXPENSE_CATEGORIES) {
    const amount = byCategory.get(category) ?? 0;
    if (amount === 0) continue;
    const row = summary.addRow([CATEGORY_LABELS[category], amount / 100]);
    row.getCell(1).font = { color: { argb: hexToArgb(CATEGORY_HEX[category]) }, bold: true };
    row.getCell(2).numFmt = "#,##0.00 €";
  }
  summary.addRow([]);

  summary.addRow(["Por persona (total pagado)"]).font = { bold: true };
  const paidByPerson = new Map<string, number>();
  for (const e of expenses ?? []) {
    paidByPerson.set(e.paid_by, (paidByPerson.get(e.paid_by) ?? 0) + e.amount_cents);
  }
  for (const [userId, amount] of paidByPerson) {
    const row = summary.addRow([nameOf(userId), amount / 100]);
    row.getCell(2).numFmt = "#,##0.00 €";
  }

  const buffer = await workbook.xlsx.writeBuffer();
  const slug = household.name
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  const filename = `gastos-${slug || "piso"}.xlsx`;

  return new Response(buffer, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename="${filename}"`,
    },
  });
}
