import { useState, useEffect } from "react";
import { formatCurrency } from "@/lib/utils";
import { Package, Plus, X, FolderOpen, Copy, Trash2, Edit3, CheckCircle, Share2, Info } from "lucide-react";
import { toast } from "sonner";

interface Product {
  id: string;
  productName: string;
  category: string;
  productImageUrl?: string;
  sellingPrice: number;
}

interface Collection {
  _id: string;
  name: string;
  description: string;
  shareCode: string;
  products: any[];
}

export default function Collections() {
  const [collections, setCollections] = useState<Collection[]>([]);
  const [resellerProducts, setResellerProducts] = useState<Product[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  // Form State
  const [editingId, setEditingId] = useState<string | null>(null);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [selectedProducts, setSelectedProducts] = useState<string[]>([]);
  
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const apiBase = import.meta.env.DEV ? "http://localhost:5001" : "https://api.ojasindia.com";

  const getHeaders = () => {
    const token = localStorage.getItem("auth_token");
    return {
      "Content-Type": "application/json",
      "Authorization": token ? `Bearer ${token}` : ""
    };
  };

  const fetchCollections = () => {
    setIsLoading(true);
    fetch(`${apiBase}/api/reseller/collections`, { 
      headers: getHeaders(),
      credentials: "include"
    })
      .then(res => {
        if (!res.ok) throw new Error("Failed to fetch collections");
        return res.json();
      })
      .then(data => {
        setCollections(data);
        setIsLoading(false);
      })
      .catch(err => {
        console.error(err);
        toast.error("Failed to load collections");
        setIsLoading(false);
      });
  };

  const fetchResellerProducts = () => {
    fetch(`${apiBase}/api/reseller/products`, { 
      headers: getHeaders(),
      credentials: "include"
    })
      .then(res => {
        if (!res.ok) throw new Error("Failed to fetch products");
        return res.json();
      })
      .then(data => {
        setResellerProducts(data);
      })
      .catch(err => {
        console.error(err);
      });
  };

  useEffect(() => {
    fetchCollections();
    fetchResellerProducts();
  }, []);

  const handleOpenCreate = () => {
    setEditingId(null);
    setName("");
    setDescription("");
    setSelectedProducts([]);
    setIsModalOpen(true);
  };

  const handleOpenEdit = (col: Collection) => {
    setEditingId(col._id);
    setName(col.name);
    setDescription(col.description);
    setSelectedProducts(col.products.map(p => p._id));
    setIsModalOpen(true);
  };

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      toast.error("Please enter a collection name");
      return;
    }

    const payload = {
      name: name.trim(),
      description: description.trim(),
      products: selectedProducts
    };

    const url = editingId 
      ? `${apiBase}/api/reseller/collections/${editingId}`
      : `${apiBase}/api/reseller/collections`;
    
    const method = editingId ? "PUT" : "POST";

    fetch(url, {
      method,
      headers: getHeaders(),
      body: JSON.stringify(payload),
      credentials: "include"
    })
      .then(res => {
        if (!res.ok) throw new Error("Failed to save collection");
        return res.json();
      })
      .then(() => {
        toast.success(editingId ? "Collection updated!" : "Collection created!");
        setIsModalOpen(false);
        fetchCollections();
      })
      .catch(err => {
        console.error(err);
        toast.error("Failed to save collection");
      });
  };

  const handleDelete = (id: string) => {
    if (!confirm("Are you sure you want to delete this collection?")) return;

    fetch(`${apiBase}/api/reseller/collections/${id}`, {
      method: "DELETE",
      headers: getHeaders(),
      credentials: "include"
    })
      .then(res => {
        if (!res.ok) throw new Error("Failed to delete");
        toast.success("Collection deleted successfully");
        fetchCollections();
      })
      .catch(err => {
        console.error(err);
        toast.error("Failed to delete collection");
      });
  };

  const copyCollectionLink = (shareCode: string, id: string) => {
    const isLocalhost = window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1";
    const url = isLocalhost 
      ? `http://localhost:5173/collection/${shareCode}` 
      : `https://mycollectionsforyou.com/collection/${shareCode}`;
    navigator.clipboard.writeText(url);
    setCopiedId(id);
    toast.success("Collection shared link copied!");
    setTimeout(() => setCopiedId(null), 2000);
  };

  const toggleProductSelection = (prodId: string) => {
    setSelectedProducts(prev => 
      prev.includes(prodId) 
        ? prev.filter(id => id !== prodId) 
        : [...prev, prodId]
    );
  };

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-slate-800 font-extrabold text-3xl tracking-tight">My Collections</h1>
          <p className="text-slate-500 text-sm mt-1">
            Group multiple reseller products into shareable collections to share as single links.
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="flex items-center gap-2 bg-amber-500 hover:bg-amber-400 text-white font-bold px-5 py-3 rounded-xl shadow-md transition-all self-start md:self-auto"
        >
          <Plus size={18} />
          Create Collection
        </button>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-64 bg-slate-100 rounded-2xl animate-pulse" />
          ))}
        </div>
      ) : !collections.length ? (
        <div className="text-center py-20 bg-slate-50/50 border border-dashed border-slate-200 rounded-2xl max-w-2xl mx-auto">
          <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4 border border-slate-200">
            <FolderOpen size={28} className="text-slate-400" />
          </div>
          <h3 className="font-bold text-slate-800 text-lg">No collections created yet</h3>
          <p className="text-slate-400 text-sm mt-1 max-w-md mx-auto px-4">
            Group multiple products together (like "Home Accents", "Festival Gifts") and share them with a single link to increase sales!
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {collections.map(col => (
            <div key={col._id} className="bg-white rounded-2xl border border-slate-200/80 shadow-sm hover:shadow-md transition-all flex flex-col justify-between overflow-hidden group">
              <div className="p-5">
                <div className="flex justify-between items-start gap-4 mb-3">
                  <h3 className="font-extrabold text-slate-800 text-xl tracking-tight leading-snug group-hover:text-amber-700 transition-colors">
                    {col.name}
                  </h3>
                  <div className="flex gap-1">
                    <button
                      onClick={() => handleOpenEdit(col)}
                      className="p-1.5 hover:bg-slate-100 text-slate-400 hover:text-slate-700 rounded-lg transition-colors"
                      title="Edit Collection"
                    >
                      <Edit3 size={15} />
                    </button>
                    <button
                      onClick={() => handleDelete(col._id)}
                      className="p-1.5 hover:bg-rose-50 text-slate-400 hover:text-rose-600 rounded-lg transition-colors"
                      title="Delete Collection"
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </div>

                <p className="text-slate-500 text-sm mb-4 line-clamp-2 leading-relaxed">
                  {col.description || "No description provided."}
                </p>

                {/* Products Preview */}
                <div className="border-t border-slate-100 pt-4">
                  <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">
                    Products ({col.products?.length || 0})
                  </p>
                  
                  {col.products && col.products.length > 0 ? (
                    <div className="flex flex-wrap gap-2 max-h-24 overflow-y-auto pr-1">
                      {col.products.map((item, idx) => {
                        if (!item) return null;
                        const name = item.productName || item.product?.name || "Product";
                        const imageUrl = item.productImageUrl || item.product?.image;
                        return (
                          <div key={idx} className="flex items-center gap-2 bg-slate-50 border border-slate-200/60 rounded-lg p-1.5 text-xs text-slate-600 font-medium">
                            {imageUrl && (
                              <img src={imageUrl} alt={name} className="w-5 h-5 rounded object-cover" />
                            )}
                            <span className="truncate max-w-[120px]">{name}</span>
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <p className="text-xs text-slate-400 italic">No products added yet.</p>
                  )}
                </div>
              </div>

              {/* Action Bar */}
              <div className="bg-slate-50/50 border-t border-slate-100 p-4 flex items-center justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <p className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider mb-1">Share Code</p>
                  <code className="text-xs bg-white border border-slate-200/80 px-2.5 py-1.5 rounded font-mono text-slate-600 block truncate font-medium">
                    {col.shareCode}
                  </code>
                </div>

                <button
                  onClick={() => copyCollectionLink(col.shareCode, col._id)}
                  className={`shrink-0 flex items-center gap-1.5 px-4.5 py-2.5 rounded-xl text-xs font-bold transition-all border shadow-sm ${
                    copiedId === col._id
                      ? "bg-emerald-500 border-emerald-500 text-white shadow-emerald-100"
                      : "bg-amber-500 border-amber-500 hover:bg-amber-400 hover:border-amber-400 text-white shadow-amber-100"
                  }`}
                >
                  {copiedId === col._id ? (
                    <>
                      <CheckCircle size={14} />
                      Copied!
                    </>
                  ) : (
                    <>
                      <Share2 size={14} />
                      Share Link
                    </>
                  )}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create / Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center px-4" onClick={e => e.target === e.currentTarget && setIsModalOpen(false)}>
          <div className="bg-white rounded-3xl p-6 w-full max-w-lg shadow-2xl flex flex-col max-h-[85vh]">
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-extrabold text-slate-800 text-xl tracking-tight">
                {editingId ? "Edit Collection" : "Create New Collection"}
              </h3>
              <button onClick={() => setIsModalOpen(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSave} className="space-y-4 flex-1 overflow-y-auto pr-1">
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">Collection Name *</label>
                <input
                  type="text"
                  value={name}
                  onChange={e => setName(e.target.value)}
                  required
                  placeholder="e.g. Summer Specials, Living Room Decor"
                  className="w-full border border-slate-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">Description</label>
                <textarea
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  placeholder="Describe your collection..."
                  rows={2}
                  className="w-full border border-slate-300 rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                />
              </div>

              {/* Multi-Select Reseller Products */}
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  Select Products to Include
                </label>
                <p className="text-xs text-slate-400 mb-2 flex items-center gap-1">
                  <Info size={12} />
                  Choose products from your Reseller List to bundle together
                </p>

                {!resellerProducts.length ? (
                  <div className="text-center py-6 bg-slate-50 border border-dashed rounded-xl text-slate-400 text-xs">
                    Please add some products to "My Products" first.
                  </div>
                ) : (
                  <div className="border border-slate-200 rounded-xl divide-y max-h-48 overflow-y-auto">
                    {resellerProducts.map(p => {
                      const isSelected = selectedProducts.includes(p.id);
                      return (
                        <div
                          key={p.id}
                          onClick={() => toggleProductSelection(p.id)}
                          className={`flex items-center justify-between p-3 cursor-pointer hover:bg-slate-50 transition-colors ${
                            isSelected ? "bg-amber-50/40" : ""
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <input
                              type="checkbox"
                              checked={isSelected}
                              onChange={() => {}} // Handled by div onClick
                              className="rounded text-amber-500 focus:ring-amber-500 border-slate-300"
                            />
                            {p.productImageUrl && (
                              <img src={p.productImageUrl} alt={p.productName} className="w-8 h-8 rounded object-cover" />
                            )}
                            <div>
                              <p className="text-xs font-semibold text-slate-800 line-clamp-1">{p.productName}</p>
                              <p className="text-[10px] text-slate-400">{p.category}</p>
                            </div>
                          </div>
                          <span className="text-xs font-bold text-slate-600">{formatCurrency(p.sellingPrice)}</span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

              <div className="flex gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="flex-1 py-3 border border-slate-300 rounded-xl text-slate-600 text-sm font-semibold hover:bg-slate-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 py-3 bg-amber-500 hover:bg-amber-400 text-white rounded-xl text-sm font-extrabold shadow-md transition-colors"
                >
                  {editingId ? "Save Changes" : "Create Collection"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
