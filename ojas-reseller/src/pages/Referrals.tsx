import { useListReferralLinks, useGenerateReferralLink, getListReferralLinksQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";
import { formatDate } from "@/lib/utils";
import { Copy, Link2, Share2, MessageCircle, Send } from "lucide-react";
import { toast } from "sonner";

export default function Referrals() {
  const { data: links, isLoading } = useListReferralLinks();

  const getDisplayUrl = (url: string) => {
    if (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1") {
      return url.replace("https://ojasindia.com/product/", "http://ojasindia.com/#/product/");
    }
    return url;
  };

  const copy = (url: string) => { navigator.clipboard.writeText(getDisplayUrl(url)); toast.success("Link copied to clipboard!"); };

  const shareWhatsApp = (url: string, name: string) => {
    window.open(`https://wa.me/?text=Check out ${encodeURIComponent(name)} at ${encodeURIComponent(getDisplayUrl(url))}`, "_blank");
  };

  const shareTelegram = (url: string, name: string) => {
    window.open(`https://t.me/share/url?url=${encodeURIComponent(getDisplayUrl(url))}&text=${encodeURIComponent("Check out " + name)}`, "_blank");
  };

  if (isLoading) return (
    <div className="p-8"><div className="animate-pulse space-y-3">{[...Array(4)].map((_, i) => <div key={i} className="h-24 bg-slate-200 rounded-xl" />)}</div></div>
  );

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-slate-800 font-bold text-2xl">Referral Links</h1>
        <p className="text-slate-500 text-sm mt-1">Share these links to earn commission on every sale</p>
      </div>

      {!links?.length ? (
        <div className="text-center py-20 text-slate-400">
          <Link2 size={48} className="mx-auto mb-4 opacity-20" />
          <p className="font-medium">No referral links yet</p>
          <p className="text-sm mt-1">Add products to your reseller list and generate referral links</p>
        </div>
      ) : (
        <div className="space-y-4">
          {links.map(link => (
            <div key={link.id} className="bg-white rounded-xl border border-slate-200 p-5 hover:border-amber-200 transition-all">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <h3 className="font-semibold text-slate-800">{link.productName}</h3>
                  <div className="flex items-center gap-2 mt-2">
                    <div className="flex-1 bg-slate-50 border border-slate-200 rounded-lg px-3 py-2">
                      <p className="text-xs text-slate-500 mb-0.5">Referral URL</p>
                      <p className="text-sm font-mono text-slate-700 truncate">{getDisplayUrl(link.fullUrl)}</p>
                    </div>
                    <button onClick={() => copy(link.fullUrl)} className="p-2.5 bg-slate-100 hover:bg-amber-100 rounded-lg text-slate-500 hover:text-amber-600 transition-all" title="Copy link">
                      <Copy size={16} />
                    </button>
                  </div>
                  <div className="flex items-center gap-2 mt-3">
                    <span className="text-xs font-medium text-slate-500">Share:</span>
                    <button onClick={() => shareWhatsApp(link.fullUrl, link.productName)} className="flex items-center gap-1.5 text-xs bg-green-50 text-green-700 hover:bg-green-100 border border-green-200 px-3 py-1.5 rounded-lg font-medium transition-all">
                      <MessageCircle size={13} />
                      WhatsApp
                    </button>
                    <button onClick={() => shareTelegram(link.fullUrl, link.productName)} className="flex items-center gap-1.5 text-xs bg-blue-50 text-blue-700 hover:bg-blue-100 border border-blue-200 px-3 py-1.5 rounded-lg font-medium transition-all">
                      <Send size={13} />
                      Telegram
                    </button>
                    <button onClick={() => copy(link.fullUrl)} className="flex items-center gap-1.5 text-xs bg-slate-50 text-slate-700 hover:bg-slate-100 border border-slate-200 px-3 py-1.5 rounded-lg font-medium transition-all">
                      <Share2 size={13} />
                      Copy URL
                    </button>
                  </div>
                </div>
                <div className="text-right shrink-0">
                  <div className="grid grid-cols-2 gap-3">
                    <div className="text-center">
                      <p className="text-2xl font-bold text-slate-800">{link.clicks}</p>
                      <p className="text-xs text-slate-400">Clicks</p>
                    </div>
                    <div className="text-center">
                      <p className="text-2xl font-bold text-amber-600">{link.orders}</p>
                      <p className="text-xs text-slate-400">Orders</p>
                    </div>
                  </div>
                  <p className="text-xs text-slate-400 mt-2">{formatDate(link.createdAt)}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
