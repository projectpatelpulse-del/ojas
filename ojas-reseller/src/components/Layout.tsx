import { Link, useLocation } from "wouter";
import { useAuth } from "@/hooks/useAuth";
import { useLogoutInfluencer, getGetCurrentUserQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";
import { cn } from "@/lib/utils";
import { useState, useEffect } from "react";
import {
  LayoutDashboard, Package, ShoppingBag, Link2, Wallet, ArrowDownToLine,
  BarChart2, User, ChevronRight, LogOut, Settings, Users, CreditCard,
  TrendingUp, ShoppingCart, Award, Menu, X
} from "lucide-react";

const influencerNav = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/products", label: "Browse Products", icon: Package },
  { href: "/my-products", label: "My Products", icon: ShoppingBag },
  { href: "/referrals", label: "Referral Links", icon: Link2 },
  { href: "/orders", label: "Orders", icon: ShoppingCart },
  { href: "/wallet", label: "Wallet", icon: Wallet },
  { href: "/withdrawals", label: "Withdrawals", icon: ArrowDownToLine },
  { href: "/analytics", label: "Analytics", icon: BarChart2 },
  { href: "/profile", label: "Profile", icon: User },
];

const adminNav = [
  { href: "/admin", label: "Dashboard", icon: LayoutDashboard },
  { href: "/admin/influencers", label: "Influencers", icon: Users },
  { href: "/admin/withdrawals", label: "Withdrawals", icon: CreditCard },
  { href: "/admin/analytics", label: "Analytics", icon: TrendingUp },
  { href: "/admin/top-influencers", label: "Top Performers", icon: Award },
];

const vendorNav = [
  { href: "/vendor/orders", label: "Orders", icon: ShoppingCart },
];

function NavItem({ href, label, icon: Icon }: { href: string; label: string; icon: any }) {
  const [location] = useLocation();
  const active = location === href || (href !== "/" && href !== "/admin" && location.startsWith(href));
  return (
    <Link href={href}>
      <div className={cn(
        "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all cursor-pointer",
        active
          ? "bg-amber-500/20 text-amber-400"
          : "text-slate-400 hover:text-white hover:bg-white/5"
      )}>
        <Icon size={17} className={active ? "text-amber-400" : ""} />
        <span>{label}</span>
        {active && <ChevronRight size={14} className="ml-auto text-amber-400" />}
      </div>
    </Link>
  );
}

export function Layout({ children }: { children: React.ReactNode }) {
  const { user, role } = useAuth();
  const qc = useQueryClient();
  const logout = useLogoutInfluencer();
  const [location, navigate] = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Close mobile menu when location changes
  useEffect(() => {
    setIsMobileMenuOpen(false);
  }, [location]);

  const navItems = role === "admin" ? adminNav : role === "vendor" ? vendorNav : influencerNav;
  const panelLabel = role === "admin" ? "Admin Panel" : role === "vendor" ? "Vendor Panel" : "Influencer Panel";

  const handleLogout = () => {
    logout.mutate(undefined, {
      onSuccess: () => {
        qc.clear();
        navigate("/login");
      }
    });
  };

  const SidebarContent = () => (
    <>
      {/* Brand */}
      <div className="px-5 pt-6 pb-4 border-b border-slate-800">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center">
            <span className="text-slate-900 font-black text-sm">O</span>
          </div>
          <div>
            <div className="text-white font-bold text-sm leading-tight">Ojas India</div>
            <div className="text-amber-400 text-xs font-medium">{panelLabel}</div>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 overflow-y-auto space-y-0.5">
        {navItems.map(item => (
          <NavItem key={item.href} {...item} />
        ))}
      </nav>

      {/* User section */}
      <div className="px-3 pb-4 border-t border-slate-800 pt-3 space-y-1">
        {role === "influencer" && (
          <Link href="/profile">
            <div className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-white/5 cursor-pointer">
              <div className="w-8 h-8 rounded-full bg-amber-500/20 border border-amber-500/30 flex items-center justify-center">
                <span className="text-amber-400 text-xs font-bold">{user?.name?.charAt(0) ?? "U"}</span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-white text-xs font-medium truncate">{user?.name}</div>
                <div className="text-slate-500 text-xs truncate">{user?.email}</div>
              </div>
            </div>
          </Link>
        )}
        {role !== "influencer" && (
          <div className="flex items-center gap-3 px-3 py-2">
            <div className="w-8 h-8 rounded-full bg-slate-700 flex items-center justify-center">
              <span className="text-slate-300 text-xs font-bold">{user?.name?.charAt(0) ?? "A"}</span>
            </div>
            <div className="flex-1 min-w-0">
              <div className="text-white text-xs font-medium truncate">{user?.name}</div>
              <div className="text-slate-500 text-xs">{role}</div>
            </div>
          </div>
        )}
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-slate-400 hover:text-red-400 hover:bg-red-400/10 transition-all text-sm"
        >
          <LogOut size={16} />
          Sign out
        </button>
      </div>
    </>
  );

  return (
    <div className="flex flex-col lg:flex-row h-screen bg-slate-50 overflow-hidden">
      {/* Mobile Header */}
      <header className="lg:hidden flex items-center justify-between px-4 py-3 bg-slate-900 border-b border-slate-800 text-white z-30 shrink-0">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center">
            <span className="text-slate-900 font-black text-sm">O</span>
          </div>
          <div>
            <div className="text-white font-bold text-sm leading-tight">Ojas India</div>
            <div className="text-amber-400 text-xs font-medium">{panelLabel}</div>
          </div>
        </div>
        <button
          onClick={() => setIsMobileMenuOpen(true)}
          className="p-1.5 text-slate-400 hover:text-white rounded-lg border border-slate-800 bg-slate-800/50 cursor-pointer"
        >
          <Menu size={20} />
        </button>
      </header>

      {/* Mobile Drawer Backdrop */}
      {isMobileMenuOpen && (
        <div
          className="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-xs lg:hidden"
          onClick={() => setIsMobileMenuOpen(false)}
        />
      )}

      {/* Mobile Drawer Sidebar */}
      <aside className={cn(
        "fixed top-0 bottom-0 left-0 z-50 w-60 bg-slate-900 flex flex-col border-r border-slate-800 transition-transform duration-300 ease-in-out lg:hidden",
        isMobileMenuOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="flex justify-end p-3 border-b border-slate-800">
          <button
            onClick={() => setIsMobileMenuOpen(false)}
            className="p-1 text-slate-400 hover:text-white rounded-lg cursor-pointer"
          >
            <X size={20} />
          </button>
        </div>
        <SidebarContent />
      </aside>

      {/* Desktop Sidebar (Permanent) */}
      <aside className="hidden lg:flex w-60 flex-shrink-0 bg-slate-900 flex-col border-r border-slate-800">
        <SidebarContent />
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-y-auto">
        {children}
      </main>
    </div>
  );
}

