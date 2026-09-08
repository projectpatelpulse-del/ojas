import { useState, useEffect } from "react";
import { useListProducts, useAddResellerProduct, useListResellerProducts, getListResellerProductsQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";
import { formatCurrency } from "@/lib/utils";
import { Search, Plus, X, Package, CheckCircle2 } from "lucide-react";

function AddModal({ product, onClose }: { product: any; onClose: () => void }) {
  const [markup, setMarkup] = useState("");
  const qc = useQueryClient();
  const add = useAddResellerProduct();
  const markupNum = parseFloat(markup) || 0;
  const sellingPrice = product.platformPrice + markupNum;
  const valid = markupNum > 0;

  const handleAdd = () => {
    add.mutate({ data: { productId: product.id, markupAmount: markupNum } }, {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: getListResellerProductsQueryKey() });
        onClose();
      }
    });
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center px-4" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="bg-white rounded-2xl p-6 w-full max-w-md shadow-2xl">
        <div className="flex justify-between items-center mb-4">
          <h3 className="font-bold text-slate-800 text-lg">Add to Reseller List</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600"><X size={20} /></button>
        </div>
        <div className="mb-4 p-3 bg-slate-50 rounded-lg">
          <p className="font-semibold text-slate-800 text-sm">{product.name}</p>
          <p className="text-slate-500 text-xs mt-1">{product.category}</p>
        </div>
        <div className="space-y-3 mb-5">
          <div className="flex justify-between text-sm">
            <span className="text-slate-500">Platform Price (Base)</span>
            <span className="font-semibold text-slate-800">{formatCurrency(product.platformPrice)}</span>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Your Markup (must be &gt; 0)</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-medium">₹</span>
              <input
                type="number"
                value={markup}
                onChange={e => setMarkup(e.target.value)}
                className="w-full pl-7 pr-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm"
                placeholder="Enter markup amount"
                min="1"
              />
            </div>
          </div>
          <div className="flex justify-between text-sm border-t pt-3">
            <span className="text-slate-500">Your Selling Price</span>
            <span className={`font-bold text-lg ${valid ? "text-amber-600" : "text-slate-400"}`}>{formatCurrency(sellingPrice)}</span>
          </div>
          {valid && (
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Your Profit per Sale</span>
              <span className="font-semibold text-green-600">+ {formatCurrency(markupNum)}</span>
            </div>
          )}
        </div>
        {add.error && <p className="text-red-500 text-xs mb-3">{(add.error as any)?.data?.error}</p>}
        <div className="flex gap-3">
          <button onClick={onClose} className="flex-1 py-2.5 border border-slate-300 rounded-lg text-slate-600 text-sm font-medium hover:bg-slate-50">Cancel</button>
          <button onClick={handleAdd} disabled={!valid || add.isPending} className="flex-1 py-2.5 bg-amber-500 hover:bg-amber-400 disabled:opacity-60 text-white rounded-lg text-sm font-semibold">
            {add.isPending ? "Adding..." : "Add to My List"}
          </button>
        </div>
      </div>
    </div>
  );
}

function ProductDetailsModal({ product, isAdded, onAddClick, onClose }: { product: any; isAdded: boolean; onAddClick: () => void; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center px-4 transition-opacity" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="bg-white rounded-3xl overflow-hidden w-full max-w-2xl shadow-2xl flex flex-col md:flex-row max-h-[85vh] md:max-h-[70vh]">
        {/* Left Side: Product Image */}
        <div className="md:w-1/2 bg-slate-50 flex items-center justify-center p-6 relative">
          <button onClick={onClose} className="md:hidden absolute top-4 right-4 bg-white/80 backdrop-blur p-1.5 rounded-full text-slate-500 hover:text-slate-700 hover:scale-105 shadow-sm transition-all"><X size={18} /></button>
          {product.imageUrl ? (
            <img src={product.imageUrl} alt={product.name} className="max-w-full max-h-[35vh] md:max-h-[55vh] object-contain rounded-xl" />
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
            
            <h3 className="font-extrabold text-slate-800 text-xl leading-tight mb-2">{product.name}</h3>
            
            <div className="flex items-center gap-4 mb-4 text-xs font-semibold text-slate-500">
              {product.vendorName && <span>Seller: <strong className="text-slate-700">{product.vendorName}</strong></span>}
              <span>Stock: <strong className={product.stock > 0 ? "text-emerald-600" : "text-rose-500"}>{product.stock > 0 ? `${product.stock} units` : "Out of stock"}</strong></span>
              {(product as any).moq > 1 && <span>MOQ: <strong className="text-amber-600">{(product as any).moq} units</strong></span>}
            </div>

            <div className="border-t border-slate-100 pt-4 mb-4">
              <h4 className="font-bold text-slate-700 text-sm mb-2">Description</h4>
              <p className="text-slate-600 text-sm leading-relaxed whitespace-pre-line max-h-[25vh] overflow-y-auto pr-1">
                {product.description || "No description available for this product."}
              </p>
            </div>
          </div>

          <div className="border-t border-slate-100 pt-4 flex items-center justify-between gap-4 mt-auto">
            <div>
              <p className="text-xs text-slate-400 font-medium">Platform Price</p>
              <p className="text-slate-800 font-extrabold text-2xl tracking-tight">{formatCurrency(product.platformPrice)}</p>
            </div>
            
            {isAdded ? (
              <span className="flex items-center gap-1.5 bg-green-50 text-green-700 text-sm font-bold px-5 py-3 rounded-xl border border-green-200 shadow-sm">
                <CheckCircle2 size={16} />
                Added
              </span>
            ) : (
              <button
                onClick={() => {
                  onClose();
                  onAddClick();
                }}
                className="flex items-center gap-2 bg-amber-500 hover:bg-amber-400 text-white text-sm font-bold px-6 py-3 rounded-xl shadow-md transition-all"
              >
                <Plus size={16} />
                Add
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function Products() {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<any>(null);
  const [detailsProduct, setDetailsProduct] = useState<any>(null);
  const [page, setPage] = useState(1);
  const [categories, setCategories] = useState<string[]>(["All"]);
  const [selectedCategory, setSelectedCategory] = useState("All");

  useEffect(() => {
    fetch("/api/home/categories")
      .then(res => res.json())
      .then(res => {
        if (res && Array.isArray(res.data)) {
          const names = res.data.map((c: any) => c.name).filter(Boolean);
          setCategories(["All", ...names]);
        }
      })
      .catch(err => console.error("Error fetching categories:", err));
  }, []);

  const { data, isLoading } = useListProducts({ 
    search: search || undefined, 
    category: selectedCategory === "All" ? undefined : selectedCategory,
    page, 
    limit: 12 
  });
  const { data: myProducts } = useListResellerProducts();
  const addedProductIds = new Set((myProducts ?? []).map((rp: any) => rp.productId));

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Product Catalog</h1>
        <p className="text-slate-500 text-sm mt-1">Browse and add products to your reseller list</p>
      </div>

      <div className="flex flex-col md:flex-row gap-4 items-stretch md:items-center justify-between mb-6">
        {/* Search */}
        <div className="relative w-full max-w-md">
          <Search size={17} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
            className="w-full pl-10 pr-4 py-2.5 border border-slate-200 rounded-xl bg-white focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm"
            placeholder="Search products..."
          />
        </div>
      </div>

      {/* Category Filters */}
      {categories.length > 1 && (
        <div className="flex gap-2 mb-6 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-slate-200">
          {categories.map(cat => (
            <button
              key={cat}
              onClick={() => { setSelectedCategory(cat); setPage(1); }}
              className={`px-4.5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap transition-all border ${
                selectedCategory === cat
                  ? "bg-amber-500 border-amber-500 text-white shadow-sm"
                  : "bg-white border-slate-200 text-slate-600 hover:border-slate-300 hover:bg-slate-50"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      )}

      {isLoading ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          {[...Array(8)].map((_, i) => <div key={i} className="h-52 bg-slate-200 rounded-xl animate-pulse" />)}
        </div>
      ) : (
        <>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {data?.products.map(p => (
              <div key={p.id} className="bg-white rounded-xl border border-slate-200 overflow-hidden hover:shadow-md hover:border-amber-200 transition-all group flex flex-col justify-between">
                <div onClick={() => setDetailsProduct(p)} className="cursor-pointer">
                  <div className="aspect-square bg-slate-100 flex items-center justify-center overflow-hidden">
                    {p.imageUrl ? (
                      <img src={p.imageUrl} alt={p.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                    ) : (
                      <Package size={36} className="text-slate-300" />
                    )}
                  </div>
                  <div className="p-4 pb-0">
                    <div className="flex gap-2 items-center">
                      <span className="text-xs text-amber-600 font-medium bg-amber-50 px-2 py-0.5 rounded">{p.category}</span>
                      {(p as any).moq > 1 && (
                        <span className="text-[10px] text-slate-500 font-bold bg-slate-100 px-2 py-0.5 rounded-full">MOQ: {(p as any).moq}</span>
                      )}
                    </div>
                    <h3 className="text-slate-800 font-semibold text-sm mt-1.5 leading-tight line-clamp-2 hover:text-amber-600 transition-colors">{p.name}</h3>
                  </div>
                </div>
                <div className="p-4 pt-0">
                  <div className="mt-3 flex items-center justify-between">
                    <div>
                      <p className="text-xs text-slate-400 font-medium">Platform Price</p>
                      <p className="text-slate-800 font-bold">{formatCurrency(p.platformPrice)}</p>
                    </div>
                    {addedProductIds.has(p.id) ? (
                      <span className="flex items-center gap-1.5 bg-green-50 text-green-700 text-xs font-semibold px-3 py-1.5 rounded-lg border border-green-200">
                        <CheckCircle2 size={13} />
                        Added
                      </span>
                    ) : (
                      <button
                        onClick={() => setSelected(p)}
                        className="flex items-center gap-1.5 bg-amber-500 hover:bg-amber-400 text-white text-xs font-semibold px-3 py-1.5 rounded-lg transition-all"
                      >
                        <Plus size={13} />
                        Add
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
          {!data?.products.length && (
            <div className="text-center py-16 text-slate-400">
              <Package size={40} className="mx-auto mb-3 opacity-30" />
              <p>No products found</p>
            </div>
          )}
          {data && data.total > 12 && (
            <div className="flex justify-center gap-3 mt-6">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="px-4 py-2 border rounded-lg text-sm disabled:opacity-40">Previous</button>
              <span className="px-4 py-2 text-sm text-slate-600">Page {page} of {Math.ceil(data.total / 12)}</span>
              <button onClick={() => setPage(p => p + 1)} disabled={page >= Math.ceil(data.total / 12)} className="px-4 py-2 border rounded-lg text-sm disabled:opacity-40">Next</button>
            </div>
          )}
        </>
      )}

      {selected && <AddModal product={selected} onClose={() => setSelected(null)} />}
      {detailsProduct && (
        <ProductDetailsModal
          product={detailsProduct}
          isAdded={addedProductIds.has(detailsProduct.id)}
          onAddClick={() => setSelected(detailsProduct)}
          onClose={() => setDetailsProduct(null)}
        />
      )}
    </div>
  );
}
