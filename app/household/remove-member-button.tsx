"use client";

import { useState } from "react";
import { UserX } from "lucide-react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { removeMember } from "@/app/actions/household";
import { Button } from "@/components/ui/button";

export function RemoveMemberButton({
  householdId,
  userId,
  displayName,
}: {
  householdId: string;
  userId: string;
  displayName: string;
}) {
  const router = useRouter();
  const [pending, setPending] = useState(false);

  async function handleClick() {
    if (!confirm(`¿Echar a ${displayName} del piso?`)) return;
    setPending(true);
    const formData = new FormData();
    formData.set("household_id", householdId);
    formData.set("user_id", userId);
    const result = await removeMember(undefined, formData);
    setPending(false);
    if (result?.error) {
      toast.error(result.error);
      return;
    }
    router.refresh();
  }

  return (
    <Button
      type="button"
      variant="ghost"
      size="icon-sm"
      onClick={handleClick}
      disabled={pending}
      aria-label={`Echar a ${displayName}`}
    >
      <UserX className="size-3.5" />
    </Button>
  );
}
