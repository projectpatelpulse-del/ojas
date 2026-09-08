export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0
  }).format(amount);
};

export const formatImageUrl = (url?: string): string => {
  if (!url) return 'https://via.placeholder.com/500?text=No+Image';
  if (url.startsWith('http')) return url;
  const cleanUrl = url.startsWith('/') ? url.substring(1) : url;
  return `http://localhost:5001/${cleanUrl}`;
};
