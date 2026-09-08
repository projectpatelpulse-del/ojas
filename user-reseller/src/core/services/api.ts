const API_SERVERS = [
  'http://localhost:5001/api',
  'https://api.ojasindia.com/api'
];

export const requestApi = async (path: string, options: RequestInit = {}): Promise<any> => {
  const token = localStorage.getItem('ojas_user_token');
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    ...options.headers,
  };

  let lastError: any = null;

  for (const baseUrl of API_SERVERS) {
    try {
      const response = await fetch(`${baseUrl}${path}`, {
        ...options,
        headers,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || `Server returned status: ${response.status}`);
      }

      return await response.json();
    } catch (err: any) {
      lastError = err;
    }
  }

  throw lastError || new Error('Network error connecting to API servers');
};
