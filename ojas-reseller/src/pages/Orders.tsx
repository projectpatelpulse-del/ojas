import { useListInfluencerOrders } from "@/api-client";
import { formatCurrency, formatDate, getStatusColor } from "@/lib/utils";
import { ShoppingCart } from "lucide-react";

export default function Orders() {
  const { data: orders, isLoading } = useListInfluencerOrders();

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">My Orders</h1>
        <p className="text-slate-500 text-sm mt-1">Orders placed through your referral links</p>
      </div>

      {isLoading ? (
        <div className="animate-pulse space-y-2">{[...Array(5)].map((_, i) => <div key={i} className="h-16 bg-slate-200 rounded-xl" />)}</div>
      ) : !orders?.length ? (
        <div className="text-center py-20 text-slate-400">
          <ShoppingCart size={48} className="mx-auto mb-4 opacity-20" />
          <p className="font-medium">No orders yet</p>
          <p className="text-sm mt-1">Share your referral links to start getting orders</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
          <div className="overflow-x-auto w-full">
            <table className="w-full min-w-[800px] text-sm">
              <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="text-left px-5 py-3 text-slate-500 font-medium">Order #</th>
                  <th className="text-left px-5 py-3 text-slate-500 font-medium">Product</th>
                  <th className="text-right px-5 py-3 text-slate-500 font-medium">Base Price</th>
                  <th className="text-right px-5 py-3 text-slate-500 font-medium">Selling Price</th>
                  <th className="text-right px-5 py-3 text-slate-500 font-medium">Your Profit</th>
                  <th className="text-center px-5 py-3 text-slate-500 font-medium">Status</th>
                  <th className="text-left px-5 py-3 text-slate-500 font-medium">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {orders.map(o => (
                  <tr key={o.id} className="hover:bg-slate-50">
                    <td className="px-5 py-4 font-mono text-slate-600 text-xs">#{o.orderId}</td>
                    <td className="px-5 py-4 font-medium text-slate-800">{o.productName}</td>
                    <td className="px-5 py-4 text-right text-slate-600">{formatCurrency(o.basePrice)}</td>
                    <td className="px-5 py-4 text-right text-slate-700 font-medium">{formatCurrency(o.sellingPrice)}</td>
                    <td className="px-5 py-4 text-right font-bold text-green-600">+{formatCurrency(o.profitAmount)}</td>
                    <td className="px-5 py-4 text-center">
                      <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(o.status)}`}>{o.status}</span>
                    </td>
                    <td className="px-5 py-4 text-slate-500 text-xs">{formatDate(o.createdAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
