import { useGetCurrentUser } from "@/api-client";

export function useAuth() {
  const { data: user, isLoading, error } = useGetCurrentUser();

  // If loading finished and user is not authenticated or there is an error, clear invalid token
  if (!isLoading && (!user || error)) {
    if (localStorage.getItem("auth_token")) {
      localStorage.removeItem("auth_token");
    }
  }

  return {
    user,
    isLoading,
    isAuthenticated: !!user,
    role: user?.role,
  };
}
