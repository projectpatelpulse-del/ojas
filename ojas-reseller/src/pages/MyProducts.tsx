import { useState } from "react";
import { useListResellerProducts, useUpdateResellerProduct, useRemoveResellerProduct, getListResellerProductsQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";
import { formatCurrency } from "@/lib/utils";
import { Package, Edit2, Trash2, Check, Copy, TrendingUp, ShoppingCart, MousePointerClick, CheckCircle } from "lucide-react";
import { toast } from "sonner";

function MarkupEditor({ product }: { product: any }) {
  const [editing, setEditing] = useState(false);
  const [markup, setMarkup] = useState(String(product.markupAmount));
  const qc = useQueryClient();
  const update = useUpdateResellerProduct();

  const save = () => {
    const m = parseFloat(markup);
    if (isNaN(m) || m <= 0) {
      toast.error("Please enter a valid markup greater than 0");
      return;
    }
    update.mutate({ id: product.id, data: { markupAmount: m } }, {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: getListResellerProductsQueryKey() });
        setEditing(false);
        toast.success("Markup updated successfully!");
      }
    });
  };

  if (!editing) {
    return (
      <div className="flex items-center gap-2 bg-amber-50/50 border border-amber-100 rounded-lg px-2.5 py-1">
        <span className="text-amber-700 font-bold text-base">{formatCurrency(product.sellingPrice)}</span>
        <span className="text-amber-500 text-xs font-medium">(+{formatCurrency(product.markupAmount)} profit)</span>
        <button onClick={() => setEditing(true)} className="text-slate-400 hover:text-amber-600 transition-colors ml-1" title="Edit Markup">
          <Edit2 size={13} />
        </button>
      </div>
    );
  }
  return (
    <div className="flex flex-col gap-1.5 p-2 bg-slate-50 border border-slate-200 rounded-lg">
      <div className="flex items-center gap-1">
        <span className="text-slate-400 text-xs font-semibold">₹</span>
        <input 
          type="number"
          value={markup} 
          onChange={e => setMarkup(e.target.value)} 
          className="w-24 px-2 py-1 border border-slate-300 rounded text-xs focus:outline-none focus:ring-1 focus:ring-amber-500 font-semibold"
          placeholder="Markup"
          min="1"
        />
        <button onClick={save} disabled={update.isPending} className="p-1 bg-emerald-500 hover:bg-emerald-600 text-white rounded transition-colors" title="Save">
          <Check size={13} />
        </button>
        <button onClick={() => setEditing(false)} className="p-1 text-slate-400 hover:text-slate-600 transition-colors"><span className="text-xs">✕</span></button>
      </div>
      <span className="text-[10px] text-slate-400">Base price: {formatCurrency(product.basePrice)}</span>
    </div>
  );
}

export default function MyProducts() {
  const { data: products, isLoading } = useListResellerProducts();
  const qc = useQueryClient();
  const remove = useRemoveResellerProduct();
  const [copiedId, setCopiedId] = useState<number | null>(null);

  const copyLink = (code: string, productId: string, id: number) => {
    const url = `https://ojasindia.com/product/${productId}?ref=${code}`;
    navigator.clipboard.writeText(url);
    setCopiedId(id);
    toast.success("Referral URL copied to clipboard!");
    setTimeout(() => setCopiedId(null), 2000);
  };

  if (isLoading) {
    return (
      <div className="p-8 max-w-7xl mx-auto">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-slate-200 rounded-lg w-64" />
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="h-48 bg-slate-200 rounded-2xl" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-slate-800 font-extrabold text-3xl tracking-tight">My Reseller Products</h1>
          <p className="text-slate-500 text-sm mt-1">
            Manage your custom pricing, track links, and monitor earnings per product.
          </p>
        </div>
        <div className="bg-slate-100/80 border border-slate-200/60 rounded-xl px-4 py-2 text-slate-600 text-sm font-semibold self-start md:self-auto shadow-sm">
          Total Products: <span className="text-amber-600 font-bold">{products?.length ?? 0}</span>
        </div>
      </div>

      {!products?.length ? (
        <div className="text-center py-20 bg-slate-50/50 border border-dashed border-slate-200 rounded-2xl max-w-2xl mx-auto shadow-sm">
          <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4 border border-slate-200">
            <Package size={28} className="text-slate-400" />
          </div>
          <h3 className="font-bold text-slate-800 text-lg">No reseller products yet</h3>
          <p className="text-slate-400 text-sm mt-1 max-w-md mx-auto px-4">
            Browse the product catalog, add markup to your favorite products, and get your unique referral links to start reselling!
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {products.map(p => (
            <div key={p.id} className="bg-white rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md hover:border-amber-200/80 transition-all duration-300 flex flex-col justify-between overflow-hidden group">
              
              {/* Product Header Info */}
              <div className="p-5 flex-1">
                <div className="flex items-start justify-between gap-3 mb-3">
                  <span className="text-[10px] uppercase font-bold tracking-wider text-amber-600 bg-amber-50 border border-amber-100 rounded-full px-2.5 py-0.5">
                    {p.category}
                  </span>
                  <button 
                    onClick={() => {
                      if (confirm("Are you sure you want to remove this product from your list?")) {
                        remove.mutate({ id: p.id }, { onSuccess: () => qc.invalidateQueries({ queryKey: getListResellerProductsQueryKey() }) });
                      }
                    }}
                    className="text-slate-400 hover:text-rose-500 p-1.5 hover:bg-rose-50 rounded-lg transition-all"
                    title="Remove Product"
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
                
                <h3 className="font-bold text-slate-800 text-base leading-snug line-clamp-2 mb-4 group-hover:text-amber-700 transition-colors">
                  {p.productName}
                </h3>

                {/* Metrics Row */}
                <div className="grid grid-cols-2 gap-3 mb-5 border-t border-slate-100 pt-4">
                  <div className="bg-slate-50/80 border border-slate-100 rounded-xl p-2.5 flex items-center gap-2.5">
                    <div className="w-8 h-8 bg-blue-50 border border-blue-100 rounded-lg flex items-center justify-center text-blue-500">
                      <MousePointerClick size={16} />
                    </div>
                    <div>
                      <p className="text-[10px] text-slate-400 font-medium uppercase tracking-wider">Clicks</p>
                      <p className="text-base font-bold text-slate-700">{p.clicks || 0}</p>
                    </div>
                  </div>
                  <div className="bg-slate-50/80 border border-slate-100 rounded-xl p-2.5 flex items-center gap-2.5">
                    <div className="w-8 h-8 bg-amber-50 border border-amber-100 rounded-lg flex items-center justify-center text-amber-500">
                      <ShoppingCart size={16} />
                    </div>
                    <div>
                      <p className="text-[10px] text-slate-400 font-medium uppercase tracking-wider">Orders</p>
                      <p className="text-base font-bold text-slate-700">{p.orders || 0}</p>
                    </div>
                  </div>
                </div>

                {/* Pricing / Markup */}
                <div className="space-y-1">
                  <p className="text-xs text-slate-400 font-medium">Your Reseller Price:</p>
                  <MarkupEditor product={p} />
                </div>
              </div>

              {/* Action Footer */}
              {/* <div className="bg-slate-50/80 border-t border-slate-100 p-4 flex items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <p className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider mb-1">Referral Code</p>
                  <code className="text-xs bg-white border border-slate-200 px-2 py-1 rounded font-mono text-slate-600 block truncate font-medium">
                    {p.referralCode}
                  </code>
                </div>
                
                <button 
                  onClick={() => copyLink(p.referralCode!, String(p.productId!), p.id)}
                  className={`shrink-0 flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold transition-all border shadow-sm ${
                    copiedId === p.id 
                    ? "bg-emerald-500 border-emerald-500 text-white shadow-emerald-100" 
                    : "bg-amber-500 border-amber-500 hover:bg-amber-400 hover:border-amber-400 text-white shadow-amber-100"
                  }`}
                >
                  {copiedId === p.id ? (
                    <>
                      <CheckCircle size={14} />
                      Copied!
                    </>
                  ) : (
                    <>
                      <Copy size={14} />
                      Copy Link
                    </>
                  )}
                </button>
              </div> */}

            </div>
          ))}
        </div>
      )}
    </div>
  );
}
