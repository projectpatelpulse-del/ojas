import { useGetInfluencerAnalytics } from "@/api-client";
import { formatCurrency } from "@/lib/utils";
import { BarChart2, MousePointerClick, ShoppingCart, Percent, TrendingUp, IndianRupee } from "lucide-react";

export default function Analytics() {
  const { data, isLoading } = useGetInfluencerAnalytics();

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Analytics</h1>
        <p className="text-slate-500 text-sm mt-1">Track your referral performance and earnings</p>
      </div>

      {isLoading ? (
        <div className="animate-pulse space-y-4">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">{[...Array(6)].map((_, i) => <div key={i} className="h-24 bg-slate-200 rounded-xl" />)}</div>
          <div className="h-64 bg-slate-200 rounded-xl" />
        </div>
      ) : (
        <>
          {/* Overall Metrics */}
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-8">
            {[
              { label: "Total Clicks", value: String(data?.totalClicks ?? 0), icon: MousePointerClick },
              { label: "Total Orders", value: String(data?.totalOrders ?? 0), icon: ShoppingCart },
              { label: "Conversion Rate", value: `${data?.conversionRate ?? 0}%`, icon: Percent },
              { label: "Revenue Generated", value: formatCurrency(data?.revenueGenerated ?? 0), icon: TrendingUp },
              { label: "Profit Earned", value: formatCurrency(data?.profitEarned ?? 0), icon: IndianRupee },
              { label: "Products Tracked", value: String(data?.productPerformance.length ?? 0), icon: BarChart2 },
            ].map(m => (
              <div key={m.label} className="bg-white rounded-xl border border-slate-200 p-4">
                <div className="flex items-center gap-2 mb-2">
                  <m.icon size={15} className="text-amber-500" />
                  <p className="text-xs text-slate-500 font-medium">{m.label}</p>
                </div>
                <p className="text-xl font-bold text-slate-800">{m.value}</p>
              </div>
            ))}
          </div>

          {/* Product Performance Table */}
          <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
            <div className="px-5 py-4 border-b border-slate-200">
              <h2 className="font-semibold text-slate-800">Product Performance</h2>
            </div>
            {!data?.productPerformance.length ? (
              <div className="text-center py-12 text-slate-400">
                <BarChart2 size={36} className="mx-auto mb-3 opacity-20" />
                <p>No data yet — share referral links to see analytics</p>
              </div>
            ) : (
              <div className="overflow-x-auto w-full">
                <table className="w-full min-w-[800px] text-sm">
                  <thead className="bg-slate-50 border-b border-slate-100">
                    <tr>
                      <th className="text-left px-5 py-3 text-slate-500 font-medium">Product</th>
                      <th className="text-right px-5 py-3 text-slate-500 font-medium">Clicks</th>
                      <th className="text-right px-5 py-3 text-slate-500 font-medium">Orders</th>
                      <th className="text-right px-5 py-3 text-slate-500 font-medium">Conv. Rate</th>
                      <th className="text-right px-5 py-3 text-slate-500 font-medium">Revenue</th>
                      <th className="text-right px-5 py-3 text-slate-500 font-medium">Profit</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {data.productPerformance.map(p => (
                      <tr key={p.productId} className="hover:bg-slate-50">
                        <td className="px-5 py-4 font-medium text-slate-800">{p.productName}</td>
                        <td className="px-5 py-4 text-right text-slate-600">{p.clicks}</td>
                        <td className="px-5 py-4 text-right text-slate-600">{p.orders}</td>
                        <td className="px-5 py-4 text-right text-slate-600">
                          {p.clicks > 0 ? `${Math.round(p.orders / p.clicks * 100)}%` : "0%"}
                        </td>
                        <td className="px-5 py-4 text-right font-medium text-slate-700">{formatCurrency(p.revenue)}</td>
                        <td className="px-5 py-4 text-right font-bold text-green-600">+{formatCurrency(p.profit)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
