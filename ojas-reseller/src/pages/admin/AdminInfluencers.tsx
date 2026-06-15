import { useState } from "react";
import { Link } from "wouter";
import { useAdminListInfluencers, useAdminUpdateInfluencerStatus, getAdminListInfluencersQueryKey, getAdminGetInfluencerQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";
import { formatCurrency, formatDate, getStatusColor } from "@/lib/utils";
import { Search, Users, ChevronRight } from "lucide-react";
import { toast } from "sonner";

const statusOptions = ["", "Active", "Pending", "Suspended"];

export default function AdminInfluencers() {
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState("");
  const { data: influencers, isLoading } = useAdminListInfluencers({ status: status || undefined, search: search || undefined });
  const qc = useQueryClient();
  const updateStatus = useAdminUpdateInfluencerStatus();

  const handleStatus = (id: number, newStatus: string) => {
    updateStatus.mutate({ id, data: { status: newStatus } }, {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: getAdminListInfluencersQueryKey() });
        toast.success(`Status updated to ${newStatus}`);
      }
    });
  };

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Influencer Management</h1>
        <p className="text-slate-500 text-sm mt-1">{influencers?.length ?? 0} influencers registered</p>
      </div>

      <div className="flex flex-col md:flex-row gap-3 mb-5">
        <div className="relative flex-1 max-w-sm">
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input value={search} onChange={e => setSearch(e.target.value)} className="w-full pl-9 border border-slate-200 rounded-xl bg-white px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500" placeholder="Search influencer..." />
        </div>
        <div className="flex flex-wrap gap-1 bg-white border border-slate-200 rounded-xl p-1 self-start">
          {statusOptions.map(s => (
            <button key={s} onClick={() => setStatus(s)} className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${status === s ? "bg-amber-500 text-white" : "text-slate-500 hover:bg-slate-100"}`}>
              {s || "All"}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto w-full">
          <table className="w-full min-w-[800px] text-sm">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Influencer</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Code</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Wallet</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Earnings</th>
                <th className="text-center px-5 py-3 text-slate-500 font-medium">Orders</th>
                <th className="text-center px-5 py-3 text-slate-500 font-medium">Status</th>
                <th className="text-center px-5 py-3 text-slate-500 font-medium">Actions</th>
                <th className="px-5 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i}><td colSpan={8} className="px-5 py-4"><div className="h-4 bg-slate-200 rounded animate-pulse w-full" /></td></tr>
                ))
              ) : !influencers?.length ? (
                <tr><td colSpan={8} className="text-center py-12 text-slate-400"><Users size={32} className="mx-auto mb-2 opacity-20" /><p>No influencers found</p></td></tr>
              ) : influencers.map(inf => (
                <tr key={inf.id} className="hover:bg-slate-50">
                  <td className="px-5 py-4">
                    <p className="font-medium text-slate-800">{inf.name}</p>
                    <p className="text-slate-400 text-xs">{inf.email}</p>
                  </td>
                  <td className="px-5 py-4 font-mono text-amber-600 text-xs font-semibold">{inf.influencerCode}</td>
                  <td className="px-5 py-4 text-right font-medium text-slate-700">{formatCurrency(inf.walletBalance)}</td>
                  <td className="px-5 py-4 text-right font-medium text-green-600">{formatCurrency(inf.totalEarnings)}</td>
                  <td className="px-5 py-4 text-center text-slate-600">{inf.totalOrders}</td>
                  <td className="px-5 py-4 text-center">
                    <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(inf.status)}`}>{inf.status}</span>
                  </td>
                  <td className="px-5 py-4 text-center">
                    <select
                      value={inf.status}
                      onChange={e => handleStatus(inf.id, e.target.value)}
                      className="text-xs border border-slate-200 rounded-lg px-2 py-1.5 focus:outline-none focus:ring-1 focus:ring-amber-500 animate-none"
                    >
                      {["Active", "Pending", "Suspended"].map(s => <option key={s}>{s}</option>)}
                    </select>
                  </td>
                  <td className="px-5 py-4">
                    <Link href={`/admin/influencers/${inf.id}`}>
                      <ChevronRight size={16} className="text-slate-400 hover:text-amber-500 cursor-pointer" />
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
