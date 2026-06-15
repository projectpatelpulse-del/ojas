import { useAdminGetDashboard } from "@/api-client";
import { formatCurrency } from "@/lib/utils";
import { Users, TrendingUp, IndianRupee, ShoppingCart, MousePointerClick, Clock, CreditCard, Percent } from "lucide-react";

function StatCard({ label, value, icon: Icon, accent }: { label: string; value: string; icon: any; accent?: boolean }) {
  return (
    <div className={`rounded-xl border p-5 ${accent ? "bg-amber-50 border-amber-200" : "bg-white border-slate-200"}`}>
      <div className="flex justify-between items-start mb-3">
        <p className="text-slate-500 text-sm font-medium">{label}</p>
        <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${accent ? "bg-amber-500" : "bg-slate-100"}`}>
          <Icon size={15} className={accent ? "text-white" : "text-slate-500"} />
        </div>
      </div>
      <p className={`text-2xl font-bold ${accent ? "text-amber-700" : "text-slate-800"}`}>{value}</p>
    </div>
  );
}

export default function AdminDashboard() {
  const { data: stats, isLoading } = useAdminGetDashboard();

  if (isLoading) {
    return <div className="p-8"><div className="animate-pulse grid grid-cols-4 gap-4">{[...Array(12)].map((_, i) => <div key={i} className="h-24 bg-slate-200 rounded-xl" />)}</div></div>;
  }

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-slate-800 font-bold text-2xl">Admin Dashboard</h1>
        <p className="text-slate-500 text-sm mt-1">Platform overview and key metrics</p>
      </div>

      <div className="mb-6">
        <h2 className="text-slate-500 text-xs font-semibold uppercase tracking-wider mb-3">Influencer Overview</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard label="Total Influencers" value={String(stats?.totalInfluencers ?? 0)} icon={Users} />
          <StatCard label="Active" value={String(stats?.activeInfluencers ?? 0)} icon={Users} accent />
          <StatCard label="Pending Approval" value={String(stats?.pendingInfluencers ?? 0)} icon={Clock} />
          <StatCard label="Conversion Rate" value={`${stats?.conversionRate ?? 0}%`} icon={Percent} />
        </div>
      </div>

      <div className="mb-6">
        <h2 className="text-slate-500 text-xs font-semibold uppercase tracking-wider mb-3">Earnings & Revenue</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard label="Earnings Paid" value={formatCurrency(stats?.totalEarningsPaid ?? 0)} icon={IndianRupee} accent />
          <StatCard label="Earnings Pending" value={formatCurrency(stats?.totalEarningsPending ?? 0)} icon={IndianRupee} />
          <StatCard label="Total Revenue" value={formatCurrency(stats?.totalRevenue ?? 0)} icon={TrendingUp} accent />
          <StatCard label="Total Orders" value={String(stats?.totalOrders ?? 0)} icon={ShoppingCart} />
        </div>
      </div>

      <div>
        <h2 className="text-slate-500 text-xs font-semibold uppercase tracking-wider mb-3">Withdrawals & Clicks</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard label="Pending Withdrawals" value={String(stats?.totalWithdrawalsPending ?? 0)} icon={CreditCard} />
          <StatCard label="Withdrawal Amount" value={formatCurrency(stats?.totalWithdrawalsAmount ?? 0)} icon={IndianRupee} />
          <StatCard label="Total Clicks" value={String(stats?.totalClicks ?? 0)} icon={MousePointerClick} />
          <div className="bg-white rounded-xl border border-slate-200 p-5 flex items-center justify-center">
            <p className="text-slate-400 text-sm">More stats coming</p>
          </div>
        </div>
      </div>
    </div>
  );
}
