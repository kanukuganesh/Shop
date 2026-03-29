import { ShoppingCart } from 'lucide-react';
import { Link } from 'react-router';
import { Product } from '../types/product';
import { Button } from './ui/button';
import { Card, CardContent, CardFooter } from './ui/card';
import { Badge } from './ui/badge';
import { useCart } from '../context/CartContext';
import { toast } from 'sonner';

interface ProductCardProps {
  product: Product;
}

export function ProductCard({ product }: ProductCardProps) {
  const { addToCart } = useCart();

  const handleAddToCart = (e: React.MouseEvent) => {
    e.preventDefault();
    addToCart(product);
    toast.success(`${product.name} added to cart!`);
  };

  return (
    <Link to={`/product/${product.id}`}>
      <Card className="group overflow-hidden transition-all hover:shadow-lg">
        <div className="relative aspect-square overflow-hidden bg-gray-100">
          <img
            src={product.image}
            alt={product.name}
            className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
          />
          {product.inStock ? (
            <Badge className="absolute right-2 top-2 bg-green-600">In Stock</Badge>
          ) : (
            <Badge className="absolute right-2 top-2 bg-red-600">Out of Stock</Badge>
          )}
        </div>
        <CardContent className="p-4">
          <div className="mb-1 text-xs text-gray-500">{product.category}</div>
          <h3 className="mb-2 text-lg font-semibold">{product.name}</h3>
          <p className="mb-2 line-clamp-2 text-sm text-gray-600">{product.description}</p>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-bold text-green-600">₹{product.price.toFixed(0)}</span>
            <span className="text-sm text-gray-500">{product.unit}</span>
          </div>
        </CardContent>
        <CardFooter className="p-4 pt-0">
          <Button
            className="w-full"
            onClick={handleAddToCart}
            disabled={!product.inStock}
          >
            <ShoppingCart className="mr-2 h-4 w-4" />
            Add to Cart
          </Button>
        </CardFooter>
      </Card>
    </Link>
  );
}
