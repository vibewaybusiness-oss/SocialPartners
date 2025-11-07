"use client";

import { useEffect } from "react";
import { useRouter, useParams } from "next/navigation";

export default function DashboardCatchAll() {
  const router = useRouter();
  const params = useParams();

  useEffect(() => {
    // Immediately redirect any invalid dashboard routes to /dashboard
    router.replace("/dashboard");
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <p className="text-muted-foreground">Redirecting to dashboard...</p>
      </div>
    </div>
  );
}
