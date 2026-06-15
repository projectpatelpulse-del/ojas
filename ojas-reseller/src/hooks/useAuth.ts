import { useGetCurrentUser } from "@/api-client";

export function useAuth() {
  const { data: user, isLoading } = useGetCurrentUser();
  return {
    user,
    isLoading,
    isAuthenticated: !!user,
    role: user?.role,
  };
}
