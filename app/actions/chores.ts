"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getHouseholdMembers } from "@/lib/household";
import { nextAssignee, nextDueDate } from "@/lib/chore-rotation";

export type ChoreFormState = { error?: string } | undefined;

export async function addChore(
  _prevState: ChoreFormState,
  formData: FormData
): Promise<ChoreFormState> {
  const householdId = String(formData.get("household_id") ?? "");
  const name = String(formData.get("name") ?? "").trim();
  const recurrenceDays = Number(formData.get("recurrence_days"));
  const requestedRotation = formData.getAll("rotation_order").map(String);

  if (!name) {
    return { error: "Ponle un nombre a la tarea." };
  }
  if (!Number.isInteger(recurrenceDays) || recurrenceDays <= 0) {
    return { error: "Indica cada cuántos días se repite (un número entero)." };
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const members = await getHouseholdMembers(supabase, householdId);
  if (members.length === 0) {
    return { error: "No hay compañeros en este piso todavía." };
  }

  // No confiamos en la lista que manda el cliente: solo entran en la
  // rotación miembros que de verdad están en el piso ahora mismo.
  const memberIds = new Set(members.map((m) => m.userId));
  const rotationOrder = requestedRotation.filter((id) => memberIds.has(id));

  if (rotationOrder.length === 0) {
    return { error: "Elige quién forma parte de la rotación." };
  }

  const { data: chore, error: choreError } = await supabase
    .from("chores")
    .insert({
      household_id: householdId,
      name,
      recurrence_days: recurrenceDays,
      rotation_order: rotationOrder,
      created_by: user!.id,
    })
    .select()
    .single();

  if (choreError) {
    return { error: "No se ha podido crear la tarea: " + choreError.message };
  }

  const { error: assignmentError } = await supabase.from("chore_assignments").insert({
    chore_id: chore.id,
    household_id: householdId,
    assigned_to: rotationOrder[0],
    due_date: new Date().toISOString().slice(0, 10),
  });

  if (assignmentError) {
    // Sin una asignación, la tarea quedaría creada pero invisible (nunca
    // aparecería en la lista de pendientes): mejor deshacerla.
    await supabase.from("chores").delete().eq("id", chore.id);
    return { error: "No se ha podido asignar la tarea: " + assignmentError.message };
  }

  revalidatePath("/household/chores");
  revalidatePath("/household");
}

export async function updateChore(
  _prevState: ChoreFormState,
  formData: FormData
): Promise<ChoreFormState> {
  const choreId = String(formData.get("chore_id") ?? "");
  const householdId = String(formData.get("household_id") ?? "");
  const name = String(formData.get("name") ?? "").trim();
  const recurrenceDays = Number(formData.get("recurrence_days"));
  const rotationOrder = formData.getAll("rotation_order").map(String);

  if (!name) {
    return { error: "Ponle un nombre a la tarea." };
  }
  if (!Number.isInteger(recurrenceDays) || recurrenceDays <= 0) {
    return { error: "Indica cada cuántos días se repite (un número entero)." };
  }
  if (rotationOrder.length === 0) {
    return { error: "Elige quién forma parte de la rotación." };
  }

  const supabase = await createClient();

  // No confiamos en la lista que manda el cliente: solo se pueden incluir
  // en la rotación miembros que de verdad están en el piso ahora mismo.
  const members = await getHouseholdMembers(supabase, householdId);
  const memberIds = new Set(members.map((m) => m.userId));
  const validRotationOrder = rotationOrder.filter((id) => memberIds.has(id));

  if (validRotationOrder.length === 0) {
    return { error: "Elige quién forma parte de la rotación." };
  }

  const { error } = await supabase
    .from("chores")
    .update({ name, recurrence_days: recurrenceDays, rotation_order: validRotationOrder })
    .eq("id", choreId);

  if (error) {
    return { error: "No se ha podido actualizar la tarea: " + error.message };
  }

  revalidatePath("/household/chores");
  revalidatePath("/household");
}

export async function deleteChore(
  _prevState: ChoreFormState,
  formData: FormData
): Promise<ChoreFormState> {
  const choreId = String(formData.get("chore_id") ?? "");
  const supabase = await createClient();

  const { error } = await supabase.from("chores").delete().eq("id", choreId);

  if (error) {
    return { error: "No se ha podido borrar la tarea: " + error.message };
  }

  revalidatePath("/household/chores");
  revalidatePath("/household");
}

export async function completeChore(
  _prevState: ChoreFormState,
  formData: FormData
): Promise<ChoreFormState> {
  const assignmentId = String(formData.get("assignment_id") ?? "");
  const choreId = String(formData.get("chore_id") ?? "");
  const householdId = String(formData.get("household_id") ?? "");
  const currentAssigneeId = String(formData.get("assigned_to") ?? "");

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: chore, error: choreFetchError } = await supabase
    .from("chores")
    .select("rotation_order, recurrence_days")
    .eq("id", choreId)
    .single();

  if (choreFetchError || !chore) {
    return { error: "No se ha encontrado la tarea." };
  }

  const { error: completeError } = await supabase
    .from("chore_assignments")
    .update({
      status: "done",
      completed_at: new Date().toISOString(),
      completed_by: user!.id,
    })
    .eq("id", assignmentId);

  if (completeError) {
    return { error: "No se ha podido marcar como hecha: " + completeError.message };
  }

  const rotationOrder = chore.rotation_order as string[];
  const nextUserId = nextAssignee(rotationOrder, currentAssigneeId);
  const dueDate = nextDueDate(new Date(), chore.recurrence_days);

  const { error: nextError } = await supabase.from("chore_assignments").insert({
    chore_id: choreId,
    household_id: householdId,
    assigned_to: nextUserId,
    due_date: dueDate.toISOString().slice(0, 10),
  });

  if (nextError) {
    return { error: "No se ha podido asignar el siguiente turno: " + nextError.message };
  }

  revalidatePath("/household/chores");
  revalidatePath("/household");
}
