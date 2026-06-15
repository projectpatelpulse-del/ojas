import { useRoute } from "wouter";
import { useAdminGetInfluencer } from "@/api-client";
import { formatCurrency, formatDate, getStatusColor } from "@/lib/utils";
import { ArrowLeft, User } from "lucide-react";
import { Link } from "wouter";

export default function AdminInfluencerDetail() {
  const [, params] = useRoute("/admin/influencers/:id");
  const id = parseInt(params?.id ?? "0", 10);
  const { data: inf, isLoading } = useAdminGetInfluencer(id);

  if (isLoading) return <div className="p-8"><div className="animate-pulse space-y-4"><div className="h-8 bg-slate-200 rounded w-48" /><div className="h-32 bg-slate-200 rounded-xl" /></div></div>;
  if (!inf) return <div className="p-8 text-slate-500">Influencer not found</div>;

  return (
    <div className="p-8 max-w-3xl">
      <Link href="/admin/influencers">
        <div className="flex items-center gap-2 text-slate-500 hover:text-amber-500 text-sm mb-6 cursor-pointer">
          <ArrowLeft size={16} />
          Back to Influencers
        </div>
      </Link>

      <div className="bg-white rounded-xl border border-slate-200 p-6 mb-6">
        <div className="flex items-center gap-4 mb-5">
          <div className="w-14 h-14 rounded-xl bg-amber-100 border-2 border-amber-200 flex items-center justify-center">
            <span className="text-amber-600 font-black text-xl">{inf.name.charAt(0)}</span>
          </div>
          <div>
            <h1 className="text-slate-800 font-bold text-xl">{inf.name}</h1>
            <p className="text-slate-500 text-sm">{inf.email} • {inf.mobile}</p>
            <div className="flex items-center gap-2 mt-1">
              <span className="font-mono text-amber-600 text-xs font-semibold bg-amber-50 border border-amber-200 px-2 py-0.5 rounded">{inf.influencerCode}</span>
              <span className={`text-xs font-medium px-2 py-0.5 rounded ${getStatusColor(inf.status)}`}>{inf.status}</span>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 border-t pt-5">
          {[
            { label: "Wallet Balance", value: formatCurrency(inf.walletBalance) },
            { label: "Total Earnings", value: formatCurrency(inf.totalEarnings) },
            { label: "Total Withdrawn", value: formatCurrency(inf.totalWithdrawn) },
            { label: "Total Orders", value: String(inf.totalOrders) },
          ].map(s => (
            <div key={s.label} className="text-center">
              <p className="text-slate-500 text-xs font-medium">{s.label}</p>
              <p className="text-slate-800 font-bold text-lg mt-1">{s.value}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 p-5">
        <h2 className="font-semibold text-slate-800 mb-3">Account Information</h2>
        <dl className="grid grid-cols-2 gap-3 text-sm">
          <div><dt className="text-slate-400">Member Since</dt><dd className="font-medium text-slate-700 mt-0.5">{formatDate(inf.createdAt)}</dd></div>
          <div><dt className="text-slate-400">Products Shared</dt><dd className="font-medium text-slate-700 mt-0.5">{inf.productsShared}</dd></div>
          <div><dt className="text-slate-400">Influencer ID</dt><dd className="font-mono text-slate-700 mt-0.5">#{inf.id}</dd></div>
          <div><dt className="text-slate-400">User ID</dt><dd className="font-mono text-slate-700 mt-0.5">#{inf.userId}</dd></div>
        </dl>
      </div>
    </div>
  );
}
