"use client";

import { useEffect, useRef, useState } from "react";
import { Plus, Users, User, X, Pencil, Check } from "lucide-react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { groceryEmoji } from "@/lib/emoji-match";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { cn } from "@/lib/utils";

type ShoppingItem = {
  id: string;
  name: string;
  quantity: string | null;
  is_checked: boolean;
  added_by: string;
  checked_by: string | null;
  owner_user_id: string | null;
};

export function ShoppingList({
  householdId,
  currentUserId,
  memberNames,
  initialItems,
}: {
  householdId: string;
  currentUserId: string;
  memberNames: Record<string, string>;
  initialItems: ShoppingItem[];
}) {
  const [items, setItems] = useState<ShoppingItem[]>(initialItems);
  const [name, setName] = useState("");
  const [quantity, setQuantity] = useState("");
  const [scope, setScope] = useState<"shared" | "personal">("shared");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editName, setEditName] = useState("");
  const [editQuantity, setEditQuantity] = useState("");

  useEffect(() => {
    const supabase = createClient();
    const channel = supabase
      .channel(`shopping-${householdId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "shopping_items",
          filter: `household_id=eq.${householdId}`,
        },
        (payload) => {
          setItems((current) => {
            if (payload.eventType === "INSERT") {
              const newItem = payload.new as ShoppingItem;
              if (current.some((i) => i.id === newItem.id)) return current;
              return [...current, newItem];
            }
            if (payload.eventType === "UPDATE") {
              const updated = payload.new as ShoppingItem;
              return current.map((i) => (i.id === updated.id ? updated : i));
            }
            if (payload.eventType === "DELETE") {
              const oldItem = payload.old as { id: string };
              return current.filter((i) => i.id !== oldItem.id);
            }
            return current;
          });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [householdId]);

  async function addItem(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) return;

    const supabase = createClient();
    const { error } = await supabase.from("shopping_items").insert({
      household_id: householdId,
      name: trimmed,
      quantity: quantity.trim() || null,
      added_by: currentUserId,
      owner_user_id: scope === "personal" ? currentUserId : null,
    });
    if (error) {
      toast.error("No se ha podido añadir: " + error.message);
      return;
    }

    setName("");
    setQuantity("");
  }

  async function toggleItem(item: ShoppingItem) {
    const supabase = createClient();
    const checked = !item.is_checked;
    const { error } = await supabase
      .from("shopping_items")
      .update({
        is_checked: checked,
        checked_by: checked ? currentUserId : null,
        checked_at: checked ? new Date().toISOString() : null,
      })
      .eq("id", item.id);
    if (error) toast.error("No se ha podido actualizar: " + error.message);
  }

  async function deleteItem(id: string) {
    const supabase = createClient();
    const { error } = await supabase.from("shopping_items").delete().eq("id", id);
    if (error) toast.error("No se ha podido quitar: " + error.message);
  }

  function startEditing(item: ShoppingItem) {
    setEditingId(item.id);
    setEditName(item.name);
    setEditQuantity(item.quantity ?? "");
  }

  function cancelEditing() {
    setEditingId(null);
  }

  async function saveEditing(id: string) {
    const trimmed = editName.trim();
    if (!trimmed) return;

    const supabase = createClient();
    const { error } = await supabase
      .from("shopping_items")
      .update({ name: trimmed, quantity: editQuantity.trim() || null })
      .eq("id", id);
    if (error) {
      toast.error("No se ha podido guardar: " + error.message);
      return;
    }

    setEditingId(null);
  }

  const shared = items.filter((i) => !i.owner_user_id);
  const mine = items.filter((i) => i.owner_user_id === currentUserId);
  const others = items.filter(
    (i) => i.owner_user_id && i.owner_user_id !== currentUserId
  );
  const othersByOwner = others.reduce<Record<string, ShoppingItem[]>>((acc, item) => {
    const key = item.owner_user_id!;
    acc[key] = acc[key] ?? [];
    acc[key].push(item);
    return acc;
  }, {});

  const editingProps = {
    editingId,
    editName,
    editQuantity,
    onEditNameChange: setEditName,
    onEditQuantityChange: setEditQuantity,
    onStartEdit: startEditing,
    onSaveEdit: saveEditing,
    onCancelEdit: cancelEditing,
  };

  return (
    <div className="flex flex-col gap-5">
      <form onSubmit={addItem} className="flex flex-col gap-2">
        <div className="flex gap-2">
          <Input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Leche"
            className="flex-1"
          />
          <Input
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            placeholder="2L"
            className="w-20"
          />
          <Button type="submit" size="icon" aria-label="Añadir">
            <Plus className="size-4" />
          </Button>
        </div>
        <div className="flex gap-2">
          <Button
            type="button"
            size="sm"
            variant={scope === "shared" ? "default" : "outline"}
            onClick={() => setScope("shared")}
            className="flex-1"
          >
            <Users className="size-4" />
            Compartido
          </Button>
          <Button
            type="button"
            size="sm"
            variant={scope === "personal" ? "default" : "outline"}
            onClick={() => setScope("personal")}
            className="flex-1"
          >
            <User className="size-4" />
            Solo para mí
          </Button>
        </div>
      </form>

      <ShoppingGroup
        title="Compartido"
        items={shared}
        editable
        onToggle={toggleItem}
        onDelete={deleteItem}
        {...editingProps}
      />

      <ShoppingGroup
        title="Mi comida"
        items={mine}
        editable
        onToggle={toggleItem}
        onDelete={deleteItem}
        {...editingProps}
      />

      {Object.entries(othersByOwner).map(([ownerId, ownerItems]) => (
        <ShoppingGroup
          key={ownerId}
          title={`Comida de ${memberNames[ownerId] ?? "—"}`}
          items={ownerItems}
          editable={false}
        />
      ))}
    </div>
  );
}

function ShoppingGroup({
  title,
  items,
  editable,
  onToggle,
  onDelete,
  editingId,
  editName,
  editQuantity,
  onEditNameChange,
  onEditQuantityChange,
  onStartEdit,
  onSaveEdit,
  onCancelEdit,
}: {
  title: string;
  items: ShoppingItem[];
  editable: boolean;
  onToggle?: (item: ShoppingItem) => void;
  onDelete?: (id: string) => void;
  editingId?: string | null;
  editName?: string;
  editQuantity?: string;
  onEditNameChange?: (value: string) => void;
  onEditQuantityChange?: (value: string) => void;
  onStartEdit?: (item: ShoppingItem) => void;
  onSaveEdit?: (id: string) => void;
  onCancelEdit?: () => void;
}) {
  if (items.length === 0) return null;

  return (
    <div className="flex flex-col gap-2">
      <p className="text-xs font-medium text-muted-foreground">{title}</p>
      {items.map((item) => {
        const isEditing = editable && editingId === item.id;

        if (isEditing) {
          return (
            <EditingRow
              key={item.id}
              name={editName ?? ""}
              quantity={editQuantity ?? ""}
              onNameChange={(v) => onEditNameChange?.(v)}
              onQuantityChange={(v) => onEditQuantityChange?.(v)}
              onSave={() => onSaveEdit?.(item.id)}
              onCancel={() => onCancelEdit?.()}
            />
          );
        }

        return (
          <div key={item.id} className="flex items-center gap-2 text-sm">
            <Checkbox
              checked={item.is_checked}
              disabled={!editable}
              onCheckedChange={() => editable && onToggle?.(item)}
            />
            <span className={cn("flex-1", item.is_checked && "text-muted-foreground line-through")}>
              {groceryEmoji(item.name)} {item.name}
              {item.quantity ? ` (${item.quantity})` : ""}
            </span>
            {editable && (
              <>
                <button
                  type="button"
                  onClick={() => onStartEdit?.(item)}
                  aria-label="Editar"
                  className="text-muted-foreground hover:text-foreground"
                >
                  <Pencil className="size-3.5" />
                </button>
                <button
                  type="button"
                  onClick={() => onDelete?.(item.id)}
                  aria-label="Quitar"
                  className="text-muted-foreground hover:text-destructive"
                >
                  <X className="size-4" />
                </button>
              </>
            )}
          </div>
        );
      })}
    </div>
  );
}

function EditingRow({
  name,
  quantity,
  onNameChange,
  onQuantityChange,
  onSave,
  onCancel,
}: {
  name: string;
  quantity: string;
  onNameChange: (value: string) => void;
  onQuantityChange: (value: string) => void;
  onSave: () => void;
  onCancel: () => void;
}) {
  const nameRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    nameRef.current?.focus();
  }, []);

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === "Enter") {
      e.preventDefault();
      onSave();
    } else if (e.key === "Escape") {
      onCancel();
    }
  }

  return (
    <div className="flex items-center gap-2">
      <Input
        ref={nameRef}
        value={name}
        onChange={(e) => onNameChange(e.target.value)}
        onKeyDown={handleKeyDown}
        className="h-8 flex-1"
      />
      <Input
        value={quantity}
        onChange={(e) => onQuantityChange(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder="Cantidad"
        className="h-8 w-20"
      />
      <button
        type="button"
        onClick={onSave}
        aria-label="Guardar"
        className="text-primary hover:text-primary/80"
      >
        <Check className="size-4" />
      </button>
      <button
        type="button"
        onClick={onCancel}
        aria-label="Cancelar"
        className="text-muted-foreground hover:text-destructive"
      >
        <X className="size-4" />
      </button>
    </div>
  );
}
