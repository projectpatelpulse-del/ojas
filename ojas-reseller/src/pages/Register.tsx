import { useState } from "react";
import { Link, useLocation } from "wouter";
import { useRegisterInfluencer, getGetCurrentUserQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";

export default function Register() {
  const [form, setForm] = useState({ 
    name: "", 
    email: "", 
    mobile: "", 
    password: "", 
    pan: "", 
    gst: "",
    bankName: "",
    accountNumber: "",
    ifsc: "",
    accountHolderName: "",
    upiId: "",
    acceptTerms: false 
  });
  const [, navigate] = useLocation();
  const qc = useQueryClient();
  const register = useRegisterInfluencer();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.acceptTerms) {
      alert("Please accept the Terms & Conditions.");
      return;
    }
    register.mutate({ 
      data: {
        ...form,
        bankDetails: {
          bankName: form.bankName,
          accountNumber: form.accountNumber,
          ifsc: form.ifsc,
          accountHolderName: form.accountHolderName
        },
        upiDetails: {
          upiId: form.upiId
        },
        panNumber: form.pan,
        gstNumber: form.gst
      } as any
    }, {
      onSuccess: () => {
        qc.invalidateQueries({ queryKey: getGetCurrentUserQueryKey() });
        navigate("/dashboard");
      }
    });
  };

  const set = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.type === "checkbox" ? e.target.checked : e.target.value;
    setForm(f => ({ ...f, [k]: value }));
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center px-4 py-8">
      <div className="w-full max-w-lg">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-500 mb-4">
            <span className="text-slate-900 font-black text-2xl">O</span>
          </div>
          <h1 className="text-white font-bold text-2xl">Join as Reseller</h1>
          <p className="text-slate-400 text-sm mt-1">Start earning commission by promoting products</p>
        </div>

        <div className="bg-slate-800 rounded-2xl p-8 border border-slate-700 shadow-2xl">
          {register.error && (
            <div className="mb-4 px-4 py-3 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-sm">
              {(register.error as any)?.data?.error ?? "Registration failed"}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2">
                <label className="block text-slate-300 text-sm font-medium mb-1.5">Full Name *</label>
                <input value={form.name} onChange={set("name")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="Your full name" />
              </div>
              <div>
                <label className="block text-slate-300 text-sm font-medium mb-1.5">Email *</label>
                <input type="email" value={form.email} onChange={set("email")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="you@example.com" />
              </div>
              <div>
                <label className="block text-slate-300 text-sm font-medium mb-1.5">Mobile *</label>
                <input
                  type="tel"
                  pattern="[0-9]{10}"
                  maxLength={10}
                  value={form.mobile}
                  onChange={(e) => {
                    const val = e.target.value.replace(/\D/g, "");
                    setForm(f => ({ ...f, mobile: val }));
                  }}
                  required
                  className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm"
                  placeholder="10-digit number"
                />
              </div>
              <div className="col-span-2">
                <label className="block text-slate-300 text-sm font-medium mb-1.5">Password *</label>
                <input type="password" value={form.password} onChange={set("password")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="Choose a strong password" />
              </div>
            </div>

            <div className="border-t border-slate-700 pt-4">
              <p className="text-slate-400 text-xs font-medium uppercase tracking-wider mb-3">Bank Details & UPI *</p>
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <label className="block text-slate-300 text-sm font-medium mb-1.5">Account Holder Name *</label>
                  <input value={form.accountHolderName} onChange={set("accountHolderName")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="Name on bank account" />
                </div>
                <div>
                  <label className="block text-slate-300 text-sm font-medium mb-1.5">Bank Name *</label>
                  <input value={form.bankName} onChange={set("bankName")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="e.g. HDFC Bank" />
                </div>
                <div>
                  <label className="block text-slate-300 text-sm font-medium mb-1.5">Account Number *</label>
                  <input value={form.accountNumber} onChange={set("accountNumber")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="Account Number" />
                </div>
                <div>
                  <label className="block text-slate-300 text-sm font-medium mb-1.5">IFSC Code *</label>
                  <input value={form.ifsc} onChange={set("ifsc")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="IFSC" />
                </div>
                <div>
                  <label className="block text-slate-300 text-sm font-medium mb-1.5">UPI ID *</label>
                  <input value={form.upiId} onChange={set("upiId")} required className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="username@bank" />
                </div>
              </div>
            </div>

            <div className="border-t border-slate-700 pt-4">
              <p className="text-slate-400 text-xs font-medium uppercase tracking-wider mb-3">Optional - Tax Information</p>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-slate-300 text-sm font-medium mb-1.5">PAN Number</label>
                  <input value={form.pan} onChange={set("pan")} className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="ABCDE1234F" />
                </div>
                <div>
                  <label className="block text-slate-300 text-sm font-medium mb-1.5">GST Number</label>
                  <input value={form.gst} onChange={set("gst")} className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 text-sm" placeholder="22AAAAA0000A1Z5" />
                </div>
              </div>
            </div>

            <div className="flex items-start mt-2">
              <input id="acceptTerms" type="checkbox" checked={form.acceptTerms} onChange={(e) => setForm(f => ({ ...f, acceptTerms: e.target.checked }))} className="mt-1 mr-2 accent-amber-500" />
              <label htmlFor="acceptTerms" className="text-slate-400 text-xs leading-normal">
                I accept the Reseller Agreement Terms & Conditions and authorize Ojas India to process payments to my bank/UPI details.
              </label>
            </div>

            <button type="submit" disabled={register.isPending} className="w-full bg-amber-500 hover:bg-amber-400 disabled:opacity-60 text-slate-900 font-semibold py-2.5 rounded-lg transition-all text-sm mt-2">
              {register.isPending ? "Submitting application..." : "Apply as Reseller"}
            </button>
          </form>

          <p className="text-center text-slate-400 text-sm mt-4">
            Already have an account?{" "}
            <Link href="/login" className="text-amber-400 hover:text-amber-300 font-medium">Sign in</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
