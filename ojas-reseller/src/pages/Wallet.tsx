import { useGetWallet, useListWalletTransactions } from "@/api-client";
import { formatCurrency, formatDate, getStatusColor } from "@/lib/utils";
import { Wallet as WalletIcon, TrendingUp, ArrowDownToLine, IndianRupee, ArrowUpRight, ArrowDownLeft } from "lucide-react";

function BalanceCard({ label, value, icon: Icon, accent }: { label: string; value: number; icon: any; accent?: boolean }) {
  return (
    <div className={`rounded-xl border p-6 ${accent ? "bg-amber-500 border-amber-400" : "bg-white border-slate-200"}`}>
      <div className="flex items-center justify-between mb-4">
        <p className={`text-sm font-medium ${accent ? "text-amber-100" : "text-slate-500"}`}>{label}</p>
        <Icon size={20} className={accent ? "text-amber-200" : "text-slate-400"} />
      </div>
      <p className={`text-3xl font-bold ${accent ? "text-white" : "text-slate-800"}`}>{formatCurrency(value)}</p>
    </div>
  );
}

export default function Wallet() {
  const { data: wallet } = useGetWallet();
  const { data: transactions } = useListWalletTransactions();

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Wallet</h1>
        <p className="text-slate-500 text-sm mt-1">Your earnings and transaction history</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <BalanceCard label="Available Balance" value={wallet?.availableBalance ?? 0} icon={IndianRupee} accent />
        <BalanceCard label="Pending Earnings" value={wallet?.pendingEarnings ?? 0} icon={WalletIcon} />
        <BalanceCard label="Withdrawn Amount" value={wallet?.withdrawnAmount ?? 0} icon={ArrowDownToLine} />
        <BalanceCard label="Lifetime Earnings" value={wallet?.lifetimeEarnings ?? 0} icon={TrendingUp} />
      </div>

      <div className="bg-white rounded-xl border border-slate-200">
        <div className="px-5 py-4 border-b border-slate-200">
          <h2 className="font-semibold text-slate-800">Transaction Ledger</h2>
        </div>
        {!transactions?.length ? (
          <div className="text-center py-12 text-slate-400">
            <p>No transactions yet</p>
          </div>
        ) : (
        <div className="overflow-x-auto w-full">
          <table className="w-full min-w-[800px] text-sm">
            <thead className="bg-slate-50 border-b border-slate-100">
              <tr>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Date</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Type</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Remarks</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Credit</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Debit</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Balance</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {transactions.map(t => (
                <tr key={t.id} className="hover:bg-slate-50">
                  <td className="px-5 py-3.5 text-slate-500 text-xs">{formatDate(t.createdAt)}</td>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-2">
                      {t.credit ? <ArrowDownLeft size={14} className="text-green-500" /> : <ArrowUpRight size={14} className="text-red-400" />}
                      <span className="text-slate-700 font-medium">{t.transactionType}</span>
                    </div>
                  </td>
                  <td className="px-5 py-3.5 text-slate-500 text-xs">{t.remarks ?? "—"}</td>
                  <td className="px-5 py-3.5 text-right font-medium text-green-600">{t.credit ? formatCurrency(t.credit) : "—"}</td>
                  <td className="px-5 py-3.5 text-right font-medium text-red-500">{t.debit ? formatCurrency(t.debit) : "—"}</td>
                  <td className="px-5 py-3.5 text-right font-bold text-slate-800">{formatCurrency(t.balance)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        )}
      </div>
    </div>
  );
}
