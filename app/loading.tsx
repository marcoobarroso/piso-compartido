import { Skeleton } from "@/components/ui/skeleton";

export default function Loading() {
  return (
    <div className="loading-delayed flex flex-1 items-center justify-center p-4">
      <Skeleton className="h-8 w-8 rounded-full" />
    </div>
  );
}
