"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Button } from "@/components/ui/button";
import {
  Home,
  Settings,
  Menu,
  X,
  LogOut,
  User,
  MessageSquare,
  Users
} from "lucide-react";
import { SidebarThemeToggle } from "@/components/ui/sidebar-theme-toggle";
import { ProtectedRoute } from "@/components/layout/protected-route";
import { LoadingProvider, useLoading } from "@/contexts/loading-context";
import { ClipizyLoadingOverlay } from "@/components/ui/clipizy-loading";
import { useNavigationLoading } from "@/hooks/utils/use-navigation-loading";
import { useAuth } from "@/contexts/auth-context";
import { useCredits } from "@/hooks/business/use-credits";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ClipizyLogo } from "@/components/common/clipizy-logo";

const navigation = [
  { name: "Overview", href: "/dashboard", icon: Home },
  { name: "Messaging", href: "/dashboard/messaging", icon: MessageSquare },
  { name: "Find Collaborators", href: "/dashboard/collaborators", icon: Users },
  { name: "Settings", href: "/dashboard/settings", icon: Settings },
];

function DashboardLayoutContent({
  children,
}: {
  children: React.ReactNode;
}) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const pathname = usePathname();
  const { isLoading, loadingMessage } = useLoading();
  const { user, signOut } = useAuth();
  const { balance } = useCredits();
  
  // Automatically handle loading states for navigation
  useNavigationLoading();

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-background">
        {isLoading && (
          <ClipizyLoadingOverlay message={loadingMessage} />
        )}
        {/* MOBILE SIDEBAR OVERLAY */}
        {sidebarOpen && (
          <div
            className="fixed inset-0 z-40 bg-black/50 md:hidden"
            onClick={() => setSidebarOpen(false)}
          />
        )}

        {/* SIDEBAR */}
        <div className={`fixed inset-y-0 left-0 z-[60] w-64 bg-gray-900 transform transition-transform duration-200 ease-in-out md:translate-x-0 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        }`}>
          <div className="flex flex-col h-full">
            {/* SIDEBAR HEADER */}
            <div className="flex items-center justify-between p-4 border-b border-gray-800">
              <Link 
                href="/" 
                className="flex items-center gap-2 hover:opacity-80 transition-opacity"
                onClick={() => setSidebarOpen(false)}
              >
                <ClipizyLogo className="w-8 h-8 text-white" />
                <span className="text-white font-semibold text-lg">Clipizy</span>
              </Link>
              <Button
                variant="ghost"
                size="sm"
                className="md:hidden text-white hover:bg-white/10"
                onClick={() => setSidebarOpen(false)}
              >
                <X className="h-4 w-4" />
              </Button>
            </div>

            {/* NAVIGATION */}
            <nav className="flex-1 px-3 py-4 overflow-y-auto">
              <ul className="space-y-1">
                {navigation.map((item) => {
                  const Icon = item.icon;
                  const isActive = pathname === item.href;

                  return (
                    <li key={item.name}>
                      <Link
                        href={item.href}
                        className={`flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all duration-200 ${
                          isActive
                            ? "bg-white/20 text-white"
                            : "text-white/70 hover:text-white hover:bg-white/10"
                        }`}
                        onClick={() => setSidebarOpen(false)}
                      >
                        <Icon className="w-5 h-5 flex-shrink-0" />
                        <span className="font-medium">{item.name}</span>
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </nav>

            {/* CREDITS DISPLAY */}
            <div className="px-3 py-3 border-t border-gray-800">
              <div className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-white/10 text-white">
                <div className="flex items-center justify-center w-8 h-8 rounded bg-white/20">
                  <span className="text-xs font-bold">$</span>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-xs text-white/70">Credits</div>
                  <div className="text-sm font-bold truncate">
                    {balance?.current_balance || 0}
                  </div>
                </div>
              </div>
            </div>

            {/* THEME TOGGLE */}
            <div className="px-3 py-2 border-t border-gray-800">
              <SidebarThemeToggle />
            </div>

            {/* PROFILE SECTION */}
            <div className="px-3 py-3 border-t border-gray-800">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    className="w-full justify-start gap-3 px-3 py-2.5 rounded-lg hover:bg-white/10 transition-all duration-200 h-auto"
                  >
                    <Avatar className="w-8 h-8">
                      <AvatarImage src={user?.avatar} />
                      <AvatarFallback className="bg-white/20 text-white text-sm">
                        {user?.name?.charAt(0) || user?.email?.charAt(0) || <User className="w-4 h-4" />}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex-1 min-w-0 text-left">
                      <div className="text-sm font-medium text-white truncate">
                        {user?.name || "User"}
                      </div>
                      <div className="text-xs text-white/70 truncate">
                        {user?.email}
                      </div>
                    </div>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent 
                  align="end" 
                  side="top" 
                  className="w-56 z-[70] md:ml-64"
                  sideOffset={8}
                >
                  <div className="flex items-center justify-start gap-2 p-2">
                    <Avatar className="w-10 h-10">
                      <AvatarImage src={user?.avatar} />
                      <AvatarFallback className="bg-muted text-sm">
                        {user?.name?.charAt(0) || user?.email?.charAt(0) || <User className="w-4 h-4" />}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex flex-col space-y-1 leading-none">
                      {user?.name && (
                        <p className="font-medium">{user.name}</p>
                      )}
                      <p className="w-[200px] truncate text-sm text-muted-foreground">
                        {user?.email}
                      </p>
                    </div>
                  </div>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem asChild>
                    <Link href="/dashboard/settings" className="flex items-center">
                      <Settings className="mr-2 h-4 w-4" />
                      <span>Settings</span>
                    </Link>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem 
                    onClick={() => signOut()}
                    className="text-red-600 focus:text-red-600"
                  >
                    <LogOut className="mr-2 h-4 w-4" />
                    <span>Log out</span>
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

          </div>
        </div>

        {/* MAIN CONTENT */}
        <div className="md:ml-64">
          {/* MOBILE MENU BUTTON */}
          <div className="md:hidden fixed top-4 left-4 z-40">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setSidebarOpen(true)}
              className="bg-gray-900/80 backdrop-blur border border-gray-700 text-white hover:bg-gray-800"
            >
              <Menu className="h-5 w-5" />
            </Button>
          </div>

          {/* PAGE CONTENT */}
          <main className="flex-1 min-h-screen bg-background">
            {children}
          </main>
        </div>
      </div>
    </ProtectedRoute>
  );
}

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <LoadingProvider>
      <DashboardLayoutContent>
        {children}
      </DashboardLayoutContent>
    </LoadingProvider>
  );
}
