import { useState } from "react";
import { useListResellerProducts, useUpdateResellerProduct, useRemoveResellerProduct, getListResellerProductsQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";
import { formatCurrency } from "@/lib/utils";
import { Package, Edit2, Trash2, Check, Copy, TrendingUp, ShoppingCart, MousePointerClick, CheckCircle, X } from "lucide-react";
import { toast } from "sonner";

function ProductDetailsModal({ product, onClose }: { product: any; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center px-4 transition-opacity" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="bg-white rounded-3xl overflow-hidden w-full max-w-2xl shadow-2xl flex flex-col md:flex-row max-h-[85vh] md:max-h-[70vh]">
        {/* Left Side: Product Image */}
        <div className="md:w-1/2 bg-slate-50 flex items-center justify-center p-6 relative">
          <button onClick={onClose} className="md:hidden absolute top-4 right-4 bg-white/80 backdrop-blur p-1.5 rounded-full text-slate-500 hover:text-slate-700 hover:scale-105 shadow-sm transition-all"><X size={18} /></button>
          {product.imageUrl ? (
            <img src={product.imageUrl} alt={product.productName} className="max-w-full max-h-[35vh] md:max-h-[55vh] object-contain rounded-xl" />
          ) : (
            <Package size={80} className="text-slate-300" />
          )}
        </div>
        
        {/* Right Side: Product Information */}
        <div className="md:w-1/2 p-6 flex flex-col justify-between overflow-y-auto">
          <div>
            <div className="hidden md:flex justify-between items-start mb-4">
              <span className="text-[10px] uppercase font-bold tracking-wider text-amber-600 bg-amber-50 border border-amber-100 rounded-full px-3 py-1">
                {product.category}
              </span>
              <button onClick={onClose} className="text-slate-400 hover:text-slate-600 hover:scale-105 transition-all"><X size={20} /></button>
            </div>
            
            <h3 className="font-extrabold text-slate-800 text-xl leading-tight mb-2">{product.productName}</h3>
            
            <div className="flex items-center gap-4 mb-4 text-xs font-semibold text-slate-500">
              <span>Stock: <strong className="text-emerald-600">In Stock</strong></span>
              {(product as any).moq > 1 && <span>MOQ: <strong className="text-amber-600">{(product as any).moq} units</strong></span>}
            </div>

            <div className="border-t border-slate-100 pt-4 mb-4">
              <h4 className="font-bold text-slate-700 text-sm mb-2">Description</h4>
              <p className="text-slate-600 text-sm leading-relaxed whitespace-pre-line max-h-[25vh] overflow-y-auto pr-1">
                {product.description || "No description available for this product."}
              </p>
            </div>
          </div>

          <div className="border-t border-slate-100 pt-4 space-y-2 mt-auto">
            <div className="flex justify-between text-xs text-slate-500">
              <span>Base Price</span>
              <span>{formatCurrency(product.basePrice)}</span>
            </div>
            <div className="flex justify-between text-xs text-slate-500">
              <span>Your Markup</span>
              <span className="text-emerald-600 font-semibold">+{formatCurrency(product.markupAmount)}</span>
            </div>
            <div className="flex justify-between items-center border-t border-dashed pt-2">
              <span className="text-sm font-bold text-slate-700">Your Selling Price</span>
              <span className="font-extrabold text-2xl text-amber-600 tracking-tight">{formatCurrency(product.sellingPrice)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

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
  const [detailsProduct, setDetailsProduct] = useState<any>(null);

  const copyLink = (code: string, productId: string, id: number) => {
    const isLocalhost = window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1";
    const url = isLocalhost 
      ? `http://localhost:5173/product/${productId}?ref=${code}` 
      : `https://mycollectionsforyou.com/product/${productId}?ref=${code}`;
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
                    <div className="flex gap-2 items-center">
                      <span className="text-[10px] uppercase font-bold tracking-wider text-amber-600 bg-amber-50 border border-amber-100 rounded-full px-2.5 py-0.5">
                        {p.category}
                      </span>
                      {(p as any).moq > 1 && (
                        <span className="text-[10px] text-slate-500 font-bold bg-slate-100 px-2 py-0.5 rounded-full">MOQ: {(p as any).moq}</span>
                      )}
                    </div>
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
                
                <h3 onClick={() => setDetailsProduct(p)} className="cursor-pointer font-bold text-slate-800 text-base leading-snug line-clamp-2 mb-4 group-hover:text-amber-700 transition-colors">
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
      {detailsProduct && (
        <ProductDetailsModal
          product={detailsProduct}
          onClose={() => setDetailsProduct(null)}
        />
      )}
    </div>
  );
}
