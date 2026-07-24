import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";
import { setBaseUrl, setAuthTokenGetter } from "@/api-client";

// Parse token from URL query or hash query
const getUrlToken = (): string | null => {
  // Check standard query string
  const urlParams = new URLSearchParams(window.location.search);
  let token = urlParams.get("token");

  // Check hash query string (since wouter/hash routers often use hash like /#/?token=...)
  if (!token) {
    const hash = window.location.hash;
    const hashParamsIndex = hash.indexOf("?");
    if (hashParamsIndex !== -1) {
      const hashParams = new URLSearchParams(hash.substring(hashParamsIndex));
      token = hashParams.get("token");
    }
  }
  return token;
};

console.log("Current URL in Reseller Panel:", window.location.href);
const urlToken = getUrlToken();
console.log("Parsed token in Reseller Panel:", urlToken);
if (urlToken) {
  localStorage.setItem("auth_token", urlToken);
  // Clean up URL to prevent token from leaking in browser history
  const url = new URL(window.location.href);
  url.searchParams.delete("token");
  if (window.location.hash.includes("token")) {
    const cleanHash = window.location.hash.split("?")[0];
    window.history.replaceState({}, document.title, `${url.pathname}${url.search}${cleanHash}`);
  } else {
    window.history.replaceState({}, document.title, `${url.pathname}${url.search}${window.location.hash}`);
  }
}

// Register auth token getter to supply token in headers
setAuthTokenGetter(() => {
  return localStorage.getItem("auth_token");
});

setBaseUrl(import.meta.env.DEV ? "http://localhost:5001" : "https://api.ojasindia.com");
createRoot(document.getElementById("root")!).render(<App />);
