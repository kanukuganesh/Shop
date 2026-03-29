export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  image: string;
  unit: string;
  category: string;
  inStock: boolean;
}

export interface CartItem {
  product: Product;
  quantity: number;
}
