import { useState } from "react";
import { useAdminListWithdrawals, useAdminUpdateWithdrawal, getAdminListWithdrawalsQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";
import { formatCurrency, formatDate, getStatusColor } from "@/lib/utils";
import { CreditCard } from "lucide-react";
import { toast } from "sonner";

const statusFilters = ["", "Pending", "Approved", "Rejected", "Paid"];

export default function AdminWithdrawals() {
  const [status, setStatus] = useState("Pending");
  const { data: withdrawals, isLoading } = useAdminListWithdrawals({ status: status || undefined });
  const qc = useQueryClient();
  const update = useAdminUpdateWithdrawal();

  const handleAction = (id: number, newStatus: string) => {
    update.mutate({ id, data: { status: newStatus } }, {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: getAdminListWithdrawalsQueryKey() });
        toast.success(`Withdrawal ${newStatus.toLowerCase()}`);
      }
    });
  };

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Withdrawal Requests</h1>
        <p className="text-slate-500 text-sm mt-1">Review and process influencer withdrawal requests</p>
      </div>

      <div className="flex flex-wrap gap-1 bg-white border border-slate-200 rounded-xl p-1 mb-5 w-fit">
        {statusFilters.map(s => (
          <button key={s} onClick={() => setStatus(s)} className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-all ${status === s ? "bg-amber-500 text-white" : "text-slate-500 hover:bg-slate-100"}`}>
            {s || "All"}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto w-full">
          <table className="w-full min-w-[800px] text-sm">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Influencer</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Amount</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Bank Details</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Requested</th>
                <th className="text-center px-5 py-3 text-slate-500 font-medium">Status</th>
                <th className="text-center px-5 py-3 text-slate-500 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                [...Array(3)].map((_, i) => <tr key={i}><td colSpan={6} className="px-5 py-4"><div className="h-4 bg-slate-200 rounded animate-pulse" /></td></tr>)
              ) : !withdrawals?.length ? (
                <tr><td colSpan={6} className="text-center py-12 text-slate-400"><CreditCard size={32} className="mx-auto mb-2 opacity-20" /><p>No {status.toLowerCase()} withdrawals</p></td></tr>
              ) : withdrawals.map(w => (
                <tr key={w.id} className="hover:bg-slate-50">
                  <td className="px-5 py-4">
                    <p className="font-medium text-slate-800">{w.influencerName ?? "Influencer #" + w.influencerId}</p>
                    <p className="text-slate-400 text-xs">ID: #{w.influencerId}</p>
                  </td>
                  <td className="px-5 py-4 text-right font-bold text-slate-800 text-base">{formatCurrency(Number(w.amount))}</td>
                  <td className="px-5 py-4">
                    <p className="text-slate-700 font-medium text-xs">{w.bankName}</p>
                    <p className="text-slate-400 text-xs">IFSC: {w.ifsc}</p>
                    {w.upiId && <p className="text-slate-400 text-xs">UPI: {w.upiId}</p>}
                  </td>
                  <td className="px-5 py-4 text-slate-500 text-xs">{formatDate(w.requestedAt)}</td>
                  <td className="px-5 py-4 text-center">
                    <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(w.status)}`}>{w.status}</span>
                  </td>
                  <td className="px-5 py-4 text-center">
                    <div className="flex justify-center gap-1.5">
                      {w.status === "Pending" && (
                        <>
                          <button onClick={() => handleAction(w.id, "Approved")} className="px-3 py-1.5 bg-blue-50 text-blue-600 border border-blue-200 hover:bg-blue-100 text-xs font-medium rounded-lg transition-all cursor-pointer">Approve</button>
                          <button onClick={() => handleAction(w.id, "Rejected")} className="px-3 py-1.5 bg-red-50 text-red-600 border border-red-200 hover:bg-red-100 text-xs font-medium rounded-lg transition-all cursor-pointer">Reject</button>
                        </>
                      )}
                      {w.status === "Approved" && (
                        <button onClick={() => handleAction(w.id, "Paid")} className="px-3 py-1.5 bg-green-50 text-green-600 border border-green-200 hover:bg-green-100 text-xs font-medium rounded-lg transition-all cursor-pointer">Mark Paid</button>
                      )}
                      {(w.status === "Paid" || w.status === "Rejected") && (
                        <span className="text-slate-300 text-xs">Done</span>
                      )}
                    </div>
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
