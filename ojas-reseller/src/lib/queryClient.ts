import { QueryClient } from "@tanstack/react-query";
import { apiFetch } from "./api";

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      queryFn: async ({ queryKey }) => {
        const [url] = queryKey as [string, ...unknown[]];
        return apiFetch(url);
      },
      retry: false,
      staleTime: 30_000,
    },
  },
});
