import { Download } from "lucide-react";
import { Button } from "@/components/ui/button";

const EXPORT_URL = "/household/expenses/export";

export function ExportButton() {
  return (
    <Button
      variant="outline"
      size="sm"
      nativeButton={false}
      render={<a href={EXPORT_URL} download />}
    >
      <Download className="size-3.5" />
      Excel
    </Button>
  );
}
