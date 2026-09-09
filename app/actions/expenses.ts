"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { scaleShares, splitEqually, type ExpenseShareInput } from "@/lib/debt-simplify";
import { getHouseholdMembers } from "@/lib/household";
import { EXPENSE_CATEGORIES, type ExpenseCategory } from "@/lib/categories";

function parseCategory(formData: FormData): ExpenseCategory {
  const value = String(formData.get("category") ?? "otros");
  return (EXPENSE_CATEGORIES as readonly string[]).includes(value)
    ? (value as ExpenseCategory)
    : "otros";
}

export type ExpenseFormState = { error?: string } | undefined;

export async function addExpense(
  _prevState: ExpenseFormState,
  formData: FormData
): Promise<ExpenseFormState> {
  const householdId = String(formData.get("household_id") ?? "");
  const description = String(formData.get("description") ?? "").trim();
  const amountEuros = Number(formData.get("amount"));
  const splitMode = String(formData.get("split_mode") ?? "equal");

  if (!description) {
    return { error: "Ponle una descripción al gasto." };
  }
  if (!amountEuros || amountEuros <= 0) {
    return { error: "El importe no es válido." };
  }

  const amountCents = Math.round(amountEuros * 100);

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  let shares: ExpenseShareInput[];

  if (splitMode === "custom") {
    const members = await getHouseholdMembers(supabase, householdId);
    shares = members
      .map((m) => ({
        userId: m.userId,
        shareCents: Math.round(Number(formData.get(`share_${m.userId}`) || 0) * 100),
      }))
      .filter((s) => s.shareCents > 0);

    if (shares.length === 0) {
      return { error: "Reparte el importe entre al menos una persona." };
    }

    const sharesTotal = shares.reduce((sum, s) => sum + s.shareCents, 0);
    if (sharesTotal !== amountCents) {
      const diff = (amountCents - sharesTotal) / 100;
      return {
        error:
          diff > 0
            ? `Faltan ${diff.toFixed(2)} € por repartir para que cuadre con el importe total.`
            : `Sobran ${(-diff).toFixed(2)} € repartidos de más.`,
      };
    }
  } else {
    const participantIds = formData.getAll("participant_ids").map(String);
    if (participantIds.length === 0) {
      return { error: "Elige quién participa en este gasto." };
    }
    shares = splitEqually(amountCents, participantIds);
  }

  const { data: expense, error: expenseError } = await supabase
    .from("expenses")
    .insert({
      household_id: householdId,
      paid_by: user!.id,
      created_by: user!.id,
      description,
      amount_cents: amountCents,
      category: parseCategory(formData),
    })
    .select()
    .single();

  if (expenseError) {
    return { error: "No se ha podido guardar el gasto: " + expenseError.message };
  }

  const { error: sharesError } = await supabase.from("expense_shares").insert(
    shares.map((s) => ({
      household_id: householdId,
      expense_id: expense.id,
      user_id: s.userId,
      share_cents: s.shareCents,
    }))
  );

  if (sharesError) {
    // Sin el reparto, el gasto quedaría contando de más para quien lo pagó
    // sin que nadie más lo deba: mejor deshacerlo que dejarlo a medias.
    await supabase.from("expenses").delete().eq("id", expense.id);
    return { error: "No se ha podido repartir el gasto: " + sharesError.message };
  }

  revalidatePath("/household/expenses");
  revalidatePath("/household");
}

export async function updateExpense(
  _prevState: ExpenseFormState,
  formData: FormData
): Promise<ExpenseFormState> {
  const expenseId = String(formData.get("expense_id") ?? "");
  const description = String(formData.get("description") ?? "").trim();
  const amountEuros = Number(formData.get("amount"));

  if (!description) {
    return { error: "Ponle una descripción al gasto." };
  }
  if (!amountEuros || amountEuros <= 0) {
    return { error: "El importe no es válido." };
  }

  const amountCents = Math.round(amountEuros * 100);
  const supabase = await createClient();

  const { data: existingShares, error: fetchError } = await supabase
    .from("expense_shares")
    .select("user_id, share_cents")
    .eq("expense_id", expenseId);

  if (fetchError || !existingShares) {
    return { error: "No se ha podido cargar el reparto original." };
  }

  const { error: updateError } = await supabase
    .from("expenses")
    .update({ description, amount_cents: amountCents, category: parseCategory(formData) })
    .eq("id", expenseId);

  if (updateError) {
    return { error: "No se ha podido actualizar el gasto: " + updateError.message };
  }

  // Reescala cada reparto proporcionalmente al nuevo importe, en vez de
  // volver a repartir a partes iguales, para no romper un reparto por
  // importes exactos que ya tuviera el gasto.
  const newShares = scaleShares(
    existingShares.map((s) => ({ userId: s.user_id, shareCents: s.share_cents })),
    amountCents
  );

  for (const share of newShares) {
    const { error } = await supabase
      .from("expense_shares")
      .update({ share_cents: share.shareCents })
      .eq("expense_id", expenseId)
      .eq("user_id", share.userId);

    if (error) {
      return { error: "No se ha podido actualizar el reparto: " + error.message };
    }
  }

  revalidatePath("/household/expenses");
  revalidatePath("/household");
}

export async function deleteExpense(
  _prevState: ExpenseFormState,
  formData: FormData
): Promise<ExpenseFormState> {
  const expenseId = String(formData.get("expense_id") ?? "");
  const supabase = await createClient();

  const { error } = await supabase.from("expenses").delete().eq("id", expenseId);

  if (error) {
    return { error: "No se ha podido borrar el gasto: " + error.message };
  }

  revalidatePath("/household/expenses");
  revalidatePath("/household");
}

export type SettleFormState = { error?: string } | undefined;

export async function recordSettlement(
  _prevState: SettleFormState,
  formData: FormData
): Promise<SettleFormState> {
  const householdId = String(formData.get("household_id") ?? "");
  const fromUserId = String(formData.get("from_user_id") ?? "");
  const toUserId = String(formData.get("to_user_id") ?? "");
  const amountCents = Number(formData.get("amount_cents"));

  const supabase = await createClient();

  const { error } = await supabase.from("settlements").insert({
    household_id: householdId,
    from_user_id: fromUserId,
    to_user_id: toUserId,
    amount_cents: amountCents,
  });

  if (error) {
    return { error: "No se ha podido registrar el pago: " + error.message };
  }

  revalidatePath("/household/expenses");
  revalidatePath("/household");
}

export async function deleteSettlement(formData: FormData): Promise<SettleFormState> {
  const settlementId = String(formData.get("settlement_id") ?? "");

  const supabase = await createClient();
  const { error } = await supabase.from("settlements").delete().eq("id", settlementId);

  if (error) {
    return { error: "No se ha podido deshacer el pago: " + error.message };
  }

  revalidatePath("/household/expenses");
  revalidatePath("/household");
}

export type RecurringFormState = { error?: string } | undefined;

export async function addRecurringExpense(
  _prevState: RecurringFormState,
  formData: FormData
): Promise<RecurringFormState> {
  const householdId = String(formData.get("household_id") ?? "");
  const description = String(formData.get("description") ?? "").trim();
  const amountEuros = Number(formData.get("amount"));
  const dayOfMonth = Number(formData.get("day_of_month"));
  const paidBy = String(formData.get("paid_by") ?? "");

  if (!description) {
    return { error: "Ponle una descripción." };
  }
  if (!amountEuros || amountEuros <= 0) {
    return { error: "El importe no es válido." };
  }
  if (!dayOfMonth || dayOfMonth < 1 || dayOfMonth > 28) {
    return { error: "El día del mes debe estar entre 1 y 28." };
  }
  if (!paidBy) {
    return { error: "Elige quién lo paga." };
  }

  const supabase = await createClient();

  const { error } = await supabase.from("recurring_expenses").insert({
    household_id: householdId,
    description,
    amount_cents: Math.round(amountEuros * 100),
    category: parseCategory(formData),
    day_of_month: dayOfMonth,
    paid_by: paidBy,
    created_by: paidBy,
  });

  if (error) {
    return { error: "No se ha podido crear el gasto fijo: " + error.message };
  }

  revalidatePath("/household/expenses");
}

export async function toggleRecurringExpense(formData: FormData): Promise<RecurringFormState> {
  const id = String(formData.get("recurring_expense_id") ?? "");
  const active = formData.get("active") === "true";

  const supabase = await createClient();
  const { error } = await supabase.from("recurring_expenses").update({ active }).eq("id", id);

  if (error) {
    return { error: "No se ha podido actualizar: " + error.message };
  }

  revalidatePath("/household/expenses");
}

export async function deleteRecurringExpense(formData: FormData): Promise<RecurringFormState> {
  const id = String(formData.get("recurring_expense_id") ?? "");

  const supabase = await createClient();
  const { error } = await supabase.from("recurring_expenses").delete().eq("id", id);

  if (error) {
    return { error: "No se ha podido borrar el gasto fijo: " + error.message };
  }

  revalidatePath("/household/expenses");
}

export async function generateRecurringNow(): Promise<RecurringFormState> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("generate_recurring_expenses");

  if (error) {
    return { error: "No se han podido generar los gastos fijos: " + error.message };
  }

  revalidatePath("/household/expenses");
  revalidatePath("/household");
}
