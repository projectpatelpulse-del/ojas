import { useState, useEffect } from "react";
import { useListResellerOrders } from "@/api-client";
import { formatCurrency, formatDate, getStatusColor } from "@/lib/utils";
import { ShoppingCart, Eye, X } from "lucide-react";

export default function Orders() {
  const { data: orders, isLoading } = useListResellerOrders();
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [orderDetail, setOrderDetail] = useState<any | null>(null);
  const [isDetailLoading, setIsDetailLoading] = useState(false);

  useEffect(() => {
    if (!selectedOrderId) {
      setOrderDetail(null);
      return;
    }
    setIsDetailLoading(true);
    const token = localStorage.getItem("auth_token");
    fetch(`http://localhost:5001/api/Reseller/orders/${selectedOrderId}`, {
      headers: {
        "Content-Type": "application/json",
        "Authorization": token ? `Bearer ${token}` : ""
      },
      credentials: "include"
    })
      .then(res => {
        if (!res.ok) throw new Error("Failed to fetch order detail");
        return res.json();
      })
      .then(data => {
        setOrderDetail(data);
        setIsDetailLoading(false);
      })
      .catch(err => {
        console.error(err);
        setIsDetailLoading(false);
      });
  }, [selectedOrderId]);

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
                  <th className="text-center px-5 py-3 text-slate-500 font-medium">Action</th>
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
                    <td className="px-5 py-4 text-center">
                      <button
                        onClick={() => setSelectedOrderId(String(o.id))}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-amber-600 hover:text-amber-700 bg-amber-50 hover:bg-amber-100 border border-amber-200/50 rounded-lg transition-colors"
                      >
                        <Eye size={13} />
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Order Details Modal */}
      {selectedOrderId && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center px-4" onClick={e => e.target === e.currentTarget && setSelectedOrderId(null)}>
          <div className="bg-white rounded-3xl p-6 w-full max-w-lg shadow-2xl flex flex-col max-h-[85vh]">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-extrabold text-slate-800 text-xl tracking-tight">
                Order Details
              </h3>
              <button onClick={() => setSelectedOrderId(null)} className="text-slate-400 hover:text-slate-600 transition-colors">
                <X size={20} />
              </button>
            </div>

            {isDetailLoading ? (
              <div className="flex flex-col items-center justify-center py-12">
                <div className="w-8 h-8 border-3 border-amber-500 border-t-transparent rounded-full animate-spin" />
                <p className="text-xs text-slate-400 mt-2">Loading details...</p>
              </div>
            ) : orderDetail ? (
              <div className="space-y-4 overflow-y-auto pr-1 text-slate-700 text-sm">
                <div className="grid grid-cols-2 gap-4 bg-slate-50 p-4 rounded-xl">
                  <div>
                    <p className="text-xs text-slate-400 font-semibold uppercase">Order ID</p>
                    <p className="font-mono text-slate-700 font-medium">#{orderDetail.orderId}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-semibold uppercase">Status</p>
                    <span className={`px-2.5 py-0.5 rounded-full text-xs font-semibold ${getStatusColor(orderDetail.status)}`}>
                      {orderDetail.status}
                    </span>
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-semibold uppercase">Payment Method</p>
                    <p className="font-semibold text-slate-700">{orderDetail.paymentMethod}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-semibold uppercase">Payment Status</p>
                    <p className="font-semibold text-slate-700">{orderDetail.paymentStatus}</p>
                  </div>
                </div>

                <div className="border-t border-slate-100 pt-4">
                  <h4 className="font-bold text-slate-800 mb-2">Customer Info</h4>
                  <div className="space-y-1">
                    <p><span className="text-slate-400 font-medium">Name:</span> {orderDetail.shippingAddress?.fullName || orderDetail.user?.name || "N/A"}</p>
                    {/* <p><span className="text-slate-400 font-medium">Phone:</span> {orderDetail.shippingAddress?.phone || orderDetail.user?.mobile || "N/A"}</p> */}
                    {/* <p><span className="text-slate-400 font-medium">Email:</span> {orderDetail.user?.email || "N/A"}</p> */}
                  </div>
                </div>

                <div className="border-t border-slate-100 pt-4">
                  <h4 className="font-bold text-slate-800 mb-2">Shipping Address</h4>
                  <p className="text-slate-600 leading-relaxed bg-slate-50 p-3 rounded-lg border border-slate-100">
                    {orderDetail.shippingAddress?.addressLine1 ? (
                      <>
                        {orderDetail.shippingAddress.addressLine1}
                        {orderDetail.shippingAddress.addressLine2 && `, ${orderDetail.shippingAddress.addressLine2}`}
                        <br />
                        {orderDetail.shippingAddress.city}, {orderDetail.shippingAddress.state} - {orderDetail.shippingAddress.pincode}
                      </>
                    ) : (
                      "No shipping address provided"
                    )}
                  </p>
                </div>

                <div className="border-t border-slate-100 pt-4">
                  <h4 className="font-bold text-slate-800 mb-2">Order Items</h4>
                  <div className="space-y-2 max-h-40 overflow-y-auto pr-1">
                    {orderDetail.items?.map((item: any, idx: number) => {
                      const basePrice = item.originalPrice || item.price;
                      const profitPerQty = item.price - basePrice;
                      return (
                        <div key={idx} className="flex justify-between items-center bg-slate-50 p-2.5 rounded-lg border border-slate-100/60">
                          <div>
                            <p className="font-semibold text-slate-800">{item.name}</p>
                            <p className="text-xs text-slate-400">
                              Qty: {item.quantity} × {formatCurrency(item.price)}
                            </p>
                          </div>
                          <div className="text-right">
                            <p className="font-bold text-slate-800">{formatCurrency(item.price * item.quantity)}</p>
                            {profitPerQty > 0 && (
                              <p className="text-[10px] text-green-600 font-bold">
                                Profit: +{formatCurrency(profitPerQty * item.quantity)}
                              </p>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                <div className="border-t border-slate-100 pt-4 flex justify-between items-center font-bold text-base">
                  <span className="text-slate-800">Total Order Value:</span>
                  <span className="text-slate-900">{formatCurrency(orderDetail.totalAmount)}</span>
                </div>
              </div>
            ) : (
              <div className="text-center py-6 text-slate-400">Failed to load order details.</div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
