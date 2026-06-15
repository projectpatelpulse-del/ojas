import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(amount);
}

export function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

export function getStatusColor(status: string): string {
  switch (status) {
    case "Active": return "bg-green-100 text-green-800";
    case "Pending": return "bg-yellow-100 text-yellow-800";
    case "Suspended": return "bg-red-100 text-red-800";
    case "Approved": return "bg-blue-100 text-blue-800";
    case "Rejected": return "bg-red-100 text-red-800";
    case "Paid": return "bg-green-100 text-green-800";
    case "Delivered": return "bg-green-100 text-green-800";
    case "Cancelled": return "bg-red-100 text-red-800";
    case "Returned": return "bg-orange-100 text-orange-800";
    case "Processing": return "bg-blue-100 text-blue-800";
    default: return "bg-gray-100 text-gray-800";
  }
}
