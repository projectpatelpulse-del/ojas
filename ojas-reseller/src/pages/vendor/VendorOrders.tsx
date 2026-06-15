import { useListVendorOrders } from "@/api-client";
import { formatCurrency, formatDate, getStatusColor } from "@/lib/utils";
import { ShoppingCart } from "lucide-react";

export default function VendorOrders() {
  const { data: orders, isLoading } = useListVendorOrders();

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Vendor Orders</h1>
        <p className="text-slate-500 text-sm mt-1">All orders with source information</p>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto w-full">
          <table className="w-full min-w-[800px] text-sm">
            <thead className="bg-slate-50 border-b border-slate-200">
              <tr>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Order #</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Customer</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Product</th>
                <th className="text-right px-5 py-3 text-slate-500 font-medium">Amount</th>
                <th className="text-center px-5 py-3 text-slate-500 font-medium">Status</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Source</th>
                <th className="text-left px-5 py-3 text-slate-500 font-medium">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                [...Array(5)].map((_, i) => <tr key={i}><td colSpan={7} className="px-5 py-4"><div className="h-4 bg-slate-200 rounded animate-pulse" /></td></tr>)
              ) : !orders?.length ? (
                <tr><td colSpan={7} className="text-center py-12 text-slate-400"><ShoppingCart size={36} className="mx-auto mb-2 opacity-20" /><p>No orders found</p></td></tr>
              ) : orders.map(o => (
                <tr key={o.id} className="hover:bg-slate-50">
                  <td className="px-5 py-4 font-mono text-xs text-slate-500">#{o.id}</td>
                  <td className="px-5 py-4 font-medium text-slate-800">{o.customerName}</td>
                  <td className="px-5 py-4 text-slate-700">{o.productName}</td>
                  <td className="px-5 py-4 text-right font-bold text-slate-800">{formatCurrency(Number(o.amount))}</td>
                  <td className="px-5 py-4 text-center">
                    <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(o.status)}`}>{o.status}</span>
                  </td>
                  <td className="px-5 py-4">
                    {o.source === "Influencer Order" ? (
                      <div>
                        <span className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700 border border-amber-200">{o.source}</span>
                        {o.influencerName && <p className="text-xs text-slate-400 mt-0.5">{o.influencerName} ({o.influencerCode})</p>}
                      </div>
                    ) : (
                      <span className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600">{o.source}</span>
                    )}
                  </td>
                  <td className="px-5 py-4 text-slate-500 text-xs">{formatDate(o.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
