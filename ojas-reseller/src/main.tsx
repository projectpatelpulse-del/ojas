import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";
import { setBaseUrl } from "@/api-client";


setBaseUrl(import.meta.env.DEV ? "http://localhost:5001" : "https://api.ojasindia.com");
createRoot(document.getElementById("root")!).render(<App />);
