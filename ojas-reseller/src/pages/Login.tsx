import { useState } from "react";
import { Link, useLocation } from "wouter";
import { useLoginInfluencer, getGetCurrentUserQueryKey } from "@/api-client";
import { useQueryClient } from "@tanstack/react-query";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [, navigate] = useLocation();
  const qc = useQueryClient();
  const login = useLoginInfluencer();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login.mutate({ data: { email, password } }, {
      onSuccess: (data) => {
        qc.invalidateQueries({ queryKey: getGetCurrentUserQueryKey() });
        const role = data.user.role;
        if (role === "admin") navigate("/admin");
        else if (role === "vendor") navigate("/vendor/orders");
        else navigate("/dashboard");
      }
    });
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center px-4">
      <div className="w-full max-w-md">
        {/* Brand */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-amber-500 mb-4">
            <span className="text-slate-900 font-black text-2xl">O</span>
          </div>
          <h1 className="text-white font-bold text-2xl">Ojas India</h1>
          <p className="text-slate-400 text-sm mt-1">Reseller & Influencer Platform</p>
        </div>

        <div className="bg-slate-800 rounded-2xl p-8 border border-slate-700 shadow-2xl">
          <h2 className="text-white font-semibold text-lg mb-6">Sign in to your account</h2>

          {login.error && (
            <div className="mb-4 px-4 py-3 bg-red-500/10 border border-red-500/30 rounded-lg text-red-400 text-sm">
              {(login.error as any)?.data?.error ?? "Invalid credentials"}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-slate-300 text-sm font-medium mb-1.5">Email address</label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
                className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent text-sm"
                placeholder="you@example.com"
              />
            </div>
            <div>
              <label className="block text-slate-300 text-sm font-medium mb-1.5">Password</label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
                className="w-full bg-slate-700 border border-slate-600 rounded-lg px-4 py-2.5 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent text-sm"
                placeholder="••••••••"
              />
            </div>
            <button
              type="submit"
              disabled={login.isPending}
              className="w-full bg-amber-500 hover:bg-amber-400 disabled:opacity-60 text-slate-900 font-semibold py-2.5 rounded-lg transition-all text-sm"
            >
              {login.isPending ? "Signing in..." : "Sign in"}
            </button>
          </form>

          <div className="mt-6 pt-5 border-t border-slate-700 text-center">
            <p className="text-slate-400 text-sm">
              New reseller?{" "}
              <Link href="/register" className="text-amber-400 hover:text-amber-300 font-medium">
                Create account
              </Link>
            </p>
          </div>

          {/* <div className="mt-4 p-3 bg-slate-700/50 rounded-lg text-xs text-slate-400 space-y-1">
            <p className="font-medium text-slate-300">Demo accounts:</p>
            <p>Admin: admin@ojasindia.com / admin123</p>
            <p>Influencer: priya@demo.com / demo123</p>
          </div> */}
        </div>
      </div>
    </div>
  );
}
