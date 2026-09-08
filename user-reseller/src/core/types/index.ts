export interface Variation {
  _id?: string;
  title?: string;
  size?: string;
  color?: string;
  material?: string;
  weight?: string;
  price: number;
  oldPrice?: number;
  stock?: number;
  image?: string;
  images?: string[];
}

export interface Product {
  _id: string;
  name: string;
  title: string;
  price: number;
  discountPrice?: number;
  sellingPrice: number;
  originalPrice?: number;
  description?: string;
  shortDescription?: string;
  image?: string;
  gallery?: string[];
  category: string;
  brand?: string;
  stock: number;
  gst?: number;
  rating?: number;
  numReviews?: number;
  variations?: Variation[];
  specs?: { key: string; value: string }[];
  resellerCode?: string;
  resellerMarkup?: number;
  moq?: number;
  moqDiscount?: number;
  moqTiers?: string;
}

export interface CollectionItem {
  _id: string;
  product: Product;
  markupAmount: number;
}

export interface Collection {
  _id: string;
  name: string;
  description: string;
  products: CollectionItem[];
  shareCode: string;
}

export interface User {
  _id: string;
  name: string;
  email: string;
  mobile: string;
  role: string;
}

export interface Address {
  _id?: string;
  name: string;
  mobile: string;
  buildingName: string;
  street: string;
  area: string;
  landmark?: string;
  city: string;
  state: string;
  zipCode: string;
  isDefault?: boolean;
}

export interface CartItem {
  product: Product;
  variation?: Variation;
  quantity: number;
  referralCode?: string;
}
