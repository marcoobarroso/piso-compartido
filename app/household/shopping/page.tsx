import { ShoppingCart } from "lucide-react";
import { requireHousehold, getHouseholdMembers, resolveNames } from "@/lib/household";
import { ShoppingList } from "./shopping-list";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export default async function ShoppingPage() {
  const { supabase, user, household } = await requireHousehold();
  const members = await getHouseholdMembers(supabase, household.id);

  const { data: items } = await supabase
    .from("shopping_items")
    .select("id, name, quantity, is_checked, added_by, checked_by, owner_user_id")
    .eq("household_id", household.id)
    .order("created_at", { ascending: true });

  // Un artículo "personal" puede seguir apuntando a alguien que ya no está
  // en el piso: resolvemos su nombre real en vez de mostrar "—".
  const ownerIds = (items ?? [])
    .map((i) => i.owner_user_id)
    .filter((id): id is string => !!id);
  const nameOf = await resolveNames(supabase, members, ownerIds);
  const memberNames = Object.fromEntries(
    [...members.map((m) => m.userId), ...ownerIds].map((id) => [id, nameOf(id)])
  );

  return (
    <div className="mx-auto flex w-full max-w-md flex-1 flex-col gap-4 p-4">
      <Card>
        <CardHeader>
          <div className="mb-1 flex size-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <ShoppingCart className="size-4" />
          </div>
          <CardTitle className="text-base">Lista de la compra</CardTitle>
          <CardDescription>Se actualiza al momento para todos</CardDescription>
        </CardHeader>
        <CardContent>
          <ShoppingList
            householdId={household.id}
            currentUserId={user.id}
            memberNames={memberNames}
            initialItems={items ?? []}
          />
        </CardContent>
      </Card>
    </div>
  );
}
