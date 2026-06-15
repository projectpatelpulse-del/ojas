import { useGetInfluencerDashboard, useGetInfluencerProfile } from "@/api-client";
import { formatCurrency, getStatusColor } from "@/lib/utils";
import { TrendingUp, ShoppingCart, Package, MousePointerClick, Percent, IndianRupee, Clock, CheckCircle2, XCircle } from "lucide-react";

function StatCard({ label, value, sub, icon: Icon, accent }: { label: string; value: string; sub?: string; icon: any; accent?: boolean }) {
  return (
    <div className={`bg-white rounded-xl border p-5 ${accent ? "border-amber-200 bg-amber-50" : "border-slate-200"}`}>
      <div className="flex items-start justify-between mb-3">
        <p className="text-slate-500 text-sm font-medium">{label}</p>
        <div className={`w-9 h-9 rounded-lg flex items-center justify-center ${accent ? "bg-amber-500" : "bg-slate-100"}`}>
          <Icon size={17} className={accent ? "text-white" : "text-slate-600"} />
        </div>
      </div>
      <p className={`text-2xl font-bold ${accent ? "text-amber-700" : "text-slate-800"}`}>{value}</p>
      {sub && <p className="text-xs text-slate-400 mt-1">{sub}</p>}
    </div>
  );
}

export default function Dashboard() {
  const { data: stats, isLoading } = useGetInfluencerDashboard();
  const { data: profile } = useGetInfluencerProfile();

  if (isLoading) {
    return (
      <div className="p-8">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-slate-200 rounded w-64" />
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {[...Array(5)].map((_, i) => <div key={i} className="h-28 bg-slate-200 rounded-xl" />)}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <div>
            <h1 className="text-slate-800 font-bold text-2xl">Welcome back, {profile?.name?.split(" ")[0] ?? "Influencer"}</h1>
            <p className="text-slate-500 text-sm mt-0.5">
              Code: <span className="font-mono font-semibold text-amber-600">{profile?.influencerCode}</span>
              <span className={`ml-3 px-2 py-0.5 rounded text-xs font-medium ${getStatusColor(profile?.status ?? "Active")}`}>{profile?.status}</span>
            </p>
          </div>
        </div>
      </div>

      {/* Earnings row */}
      <div className="mb-6">
        <h2 className="text-slate-600 text-xs font-semibold uppercase tracking-wider mb-3">Earnings Summary</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
          <StatCard label="Today's Earnings" value={formatCurrency(stats?.todayEarnings ?? 0)} icon={IndianRupee} accent />
          <StatCard label="This Month" value={formatCurrency(stats?.monthlyEarnings ?? 0)} icon={TrendingUp} />
          <StatCard label="Total Earnings" value={formatCurrency(stats?.totalEarnings ?? 0)} icon={TrendingUp} />
          <StatCard label="Available Balance" value={formatCurrency(stats?.availableBalance ?? 0)} icon={IndianRupee} accent />
          <StatCard label="Pending Balance" value={formatCurrency(stats?.pendingBalance ?? 0)} icon={Clock} />
        </div>
      </div>

      {/* Orders row */}
      <div className="mb-6">
        <h2 className="text-slate-600 text-xs font-semibold uppercase tracking-wider mb-3">Orders Summary</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard label="Total Orders" value={String(stats?.totalOrders ?? 0)} icon={ShoppingCart} />
          <StatCard label="Delivered" value={String(stats?.deliveredOrders ?? 0)} icon={CheckCircle2} />
          <StatCard label="Cancelled" value={String(stats?.cancelledOrders ?? 0)} icon={XCircle} />
          <StatCard label="Returned" value={String(stats?.returnedOrders ?? 0)} icon={XCircle} />
        </div>
      </div>

      {/* Product performance row */}
      <div>
        <h2 className="text-slate-600 text-xs font-semibold uppercase tracking-wider mb-3">Product Performance</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard label="Products Shared" value={String(stats?.productsShared ?? 0)} icon={Package} />
          <StatCard label="Total Clicks" value={String(stats?.totalClicks ?? 0)} icon={MousePointerClick} />
          <StatCard label="Conversions" value={String(stats?.totalConversions ?? 0)} icon={CheckCircle2} />
          <StatCard label="Conversion Rate" value={`${stats?.conversionRate ?? 0}%`} icon={Percent} />
        </div>
      </div>
    </div>
  );
}
