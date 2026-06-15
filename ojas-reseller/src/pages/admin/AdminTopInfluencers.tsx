import { useAdminGetTopInfluencers } from "@/api-client";
import { formatCurrency } from "@/lib/utils";
import { Award } from "lucide-react";

export default function AdminTopInfluencers() {
  const { data: influencers, isLoading } = useAdminGetTopInfluencers();

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Top Performers</h1>
        <p className="text-slate-500 text-sm mt-1">Leaderboard ranked by total earnings</p>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto w-full">
          <table className="w-full min-w-[800px] text-sm">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Rank</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Influencer</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Total Earnings</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Orders</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Clicks</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Conv. Rate</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                [...Array(5)].map((_, i) => <tr key={i}><td colSpan={6} className="px-5 py-4"><div className="h-4 bg-slate-200 rounded animate-pulse" /></td></tr>)
              ) : !influencers?.length ? (
                <tr><td colSpan={6} className="text-center py-12 text-slate-400"><Award size={36} className="mx-auto mb-2 opacity-20" /><p>No influencers yet</p></td></tr>
              ) : influencers.map((inf, i) => (
                <tr key={inf.id} className={`hover:bg-slate-50 ${i < 3 ? "bg-amber-50/30" : ""}`}>
                  <td className="px-5 py-4">
                    <div className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs ${i === 0 ? "bg-amber-400 text-white" : i === 1 ? "bg-slate-300 text-slate-700" : i === 2 ? "bg-orange-300 text-white" : "bg-slate-100 text-slate-500"}`}>
                      {i + 1}
                    </div>
                  </td>
                  <td className="px-5 py-4">
                    <p className="font-semibold text-slate-800">{inf.name}</p>
                    <p className="text-slate-400 text-xs font-mono">{inf.influencerCode}</p>
                  </td>
                  <td className="px-5 py-4 text-right font-bold text-amber-600">{formatCurrency(inf.totalEarnings)}</td>
                  <td className="px-5 py-4 text-right text-slate-700 font-medium">{inf.totalOrders}</td>
                  <td className="px-5 py-4 text-right text-slate-600">{inf.totalClicks}</td>
                  <td className="px-5 py-4 text-right text-slate-600">{inf.conversionRate}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
