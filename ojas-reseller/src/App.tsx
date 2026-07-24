import { Switch, Route, Router as WouterRouter, Redirect, useLocation } from "wouter";
import { QueryClientProvider, useQueryClient } from "@tanstack/react-query";
import { queryClient } from "@/lib/queryClient";
import { Toaster } from "sonner";
import { useAuth } from "@/hooks/useAuth";
import { Layout } from "@/components/Layout";
import { useGetInfluencerProfile, logoutInfluencer } from "@/api-client";

import Login from "@/pages/Login";
import Dashboard from "@/pages/Dashboard";
import Products from "@/pages/Products";
import MyProducts from "@/pages/MyProducts";
import Referrals from "@/pages/Referrals";
import Orders from "@/pages/Orders";
import Wallet from "@/pages/Wallet";
import Withdrawals from "@/pages/Withdrawals";
import Analytics from "@/pages/Analytics";
import Profile from "@/pages/Profile";
import Register from "@/pages/Register";
import AdminDashboard from "@/pages/admin/AdminDashboard";
import AdminInfluencers from "@/pages/admin/AdminInfluencers";
import AdminInfluencerDetail from "@/pages/admin/AdminInfluencerDetail";
import AdminWithdrawals from "@/pages/admin/AdminWithdrawals";
import AdminAnalytics from "@/pages/admin/AdminAnalytics";
import AdminTopInfluencers from "@/pages/admin/AdminTopInfluencers";
import VendorOrders from "@/pages/vendor/VendorOrders";

function PendingScreen({ status }: { status: string }) {
  const qc = useQueryClient();
  const handleLogout = async () => {
    try {
      await logoutInfluencer();
      qc.clear();
      localStorage.removeItem("auth_token");
      window.location.href = "/login";
    } catch (e) {
      console.error(e);
      localStorage.removeItem("auth_token");
      window.location.href = "/login";
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center px-4 py-8">
      <div className="w-full max-w-md bg-slate-800 rounded-2xl p-8 border border-slate-700 shadow-2xl text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-amber-500/10 text-amber-500 mb-6 border border-amber-500/20">
          <svg className="w-8 h-8 animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h1 className="text-white font-bold text-2xl mb-3">Application Pending</h1>
        <p className="text-slate-400 text-sm mb-6 leading-relaxed">
          Your reseller application status is currently <span className="text-amber-500 font-semibold uppercase">{status}</span>. 
          Our administration is reviewing your registration details. You will get full platform access once approved.
        </p>
        <button
          onClick={handleLogout}
          className="w-full bg-slate-700 hover:bg-slate-600 text-white font-semibold py-2.5 rounded-lg transition-all text-sm"
        >
          Sign Out
        </button>
      </div>
    </div>
  );
}

function ProtectedRoute({ component: Component, roles }: { component: React.ComponentType; roles?: string[] }) {
  const { user, isLoading: isAuthLoading, isAuthenticated, role } = useAuth();
  const { data: profile, isLoading: isProfileLoading } = useGetInfluencerProfile({
    query: {
      enabled: isAuthenticated && (role === "influencer" || role === "reseller"),
    } as any
  });

  if (isAuthLoading || (isAuthenticated && (role === "influencer" || role === "reseller") && isProfileLoading)) {
    return (
      <div className="flex h-screen items-center justify-center bg-slate-900">
        <div className="w-8 h-8 border-3 border-amber-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated) return <Redirect to="/login" />;
  if (roles && role && !roles.includes(role)) return <Redirect to={role === "admin" ? "/admin" : role === "vendor" ? "/vendor/orders" : "/dashboard"} />;

  if (role === "influencer" || role === "reseller") {
    const status = profile?.status?.toLowerCase();
    if (status && status !== "approved" && status !== "active") {
      return <PendingScreen status={profile?.status || "pending"} />;
    }
  }

  return <Layout><Component /></Layout>;
}

function PublicRoute({ component: Component }: { component: React.ComponentType }) {
  const { isAuthenticated, isLoading, role } = useAuth();
  if (isLoading) return null;
  if (isAuthenticated) {
    if (role === "admin") return <Redirect to="/admin" />;
    if (role === "vendor") return <Redirect to="/vendor/orders" />;
    return <Redirect to="/dashboard" />;
  }
  return <Component />;
}

function Router() {
  return (
    <Switch>
      {/* Public routes */}
      <Route path="/login" component={() => <PublicRoute component={Login} />} />
      <Route path="/register" component={() => <PublicRoute component={Register} />} />

      {/* Influencer/Reseller routes */}
      <Route path="/dashboard" component={() => <ProtectedRoute component={Dashboard} roles={["influencer", "reseller"]} />} />
      <Route path="/products" component={() => <ProtectedRoute component={Products} roles={["influencer", "reseller"]} />} />
      <Route path="/my-products" component={() => <ProtectedRoute component={MyProducts} roles={["influencer", "reseller"]} />} />
      <Route path="/referrals" component={() => <ProtectedRoute component={Referrals} roles={["influencer", "reseller"]} />} />
      <Route path="/orders" component={() => <ProtectedRoute component={Orders} roles={["influencer", "reseller"]} />} />
      <Route path="/wallet" component={() => <ProtectedRoute component={Wallet} roles={["influencer", "reseller"]} />} />
      <Route path="/withdrawals" component={() => <ProtectedRoute component={Withdrawals} roles={["influencer", "reseller"]} />} />
      <Route path="/analytics" component={() => <ProtectedRoute component={Analytics} roles={["influencer", "reseller"]} />} />
      <Route path="/profile" component={() => <ProtectedRoute component={Profile} roles={["influencer", "reseller"]} />} />

      {/* Admin routes */}
      <Route path="/admin" component={() => <ProtectedRoute component={AdminDashboard} roles={["admin"]} />} />
      <Route path="/admin/influencers/:id" component={() => <ProtectedRoute component={AdminInfluencerDetail} roles={["admin"]} />} />
      <Route path="/admin/influencers" component={() => <ProtectedRoute component={AdminInfluencers} roles={["admin"]} />} />
      <Route path="/admin/withdrawals" component={() => <ProtectedRoute component={AdminWithdrawals} roles={["admin"]} />} />
      <Route path="/admin/analytics" component={() => <ProtectedRoute component={AdminAnalytics} roles={["admin"]} />} />
      <Route path="/admin/top-influencers" component={() => <ProtectedRoute component={AdminTopInfluencers} roles={["admin"]} />} />

      {/* Vendor routes */}
      <Route path="/vendor/orders" component={() => <ProtectedRoute component={VendorOrders} roles={["vendor"]} />} />

      {/* Default redirect */}
      <Route path="/" component={() => <Redirect to="/login" />} />
      <Route component={() => <Redirect to="/login" />} />
    </Switch>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, "")}>
        <Router />
      </WouterRouter>
      <Toaster richColors position="top-right" />
    </QueryClientProvider>
  );
}

export default App;
