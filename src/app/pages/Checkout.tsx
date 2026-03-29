import { useState } from 'react';
import { useNavigate } from 'react-router';
import { CreditCard, MapPin, User, CheckCircle, Smartphone, Wallet, Banknote } from 'lucide-react';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Separator } from '../components/ui/separator';
import { RadioGroup, RadioGroupItem } from '../components/ui/radio-group';
import { toast } from 'sonner';

type PaymentMethod = 'cod' | 'upi' | 'card' | 'wallet';

export function Checkout() {
  const { cartItems, getCartTotal, clearCart } = useCart();
  const { currentUser } = useAuth();
  const navigate = useNavigate();
  const [isProcessing, setIsProcessing] = useState(false);
  const [orderComplete, setOrderComplete] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('cod');
  const total = getCartTotal();

  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    address: '',
    city: '',
    zipCode: '',
    cardNumber: '',
    expiryDate: '',
    cvv: '',
    upiId: '',
    selectedUpiApp: 'phonepe',
    selectedWallet: 'amazonpay',
  });

  if (cartItems.length === 0 && !orderComplete) {
    navigate('/');
    return null;
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsProcessing(true);

    // Simulate payment processing
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Generate order ID
    const orderId = `#NF-${Math.floor(1000 + Math.random() * 9000)}`;

    // Create order object
    const order = {
      orderId,
      customerName: `${formData.firstName} ${formData.lastName}`,
      customerMobile: currentUser?.username || 'Guest',
      date: new Date().toISOString(),
      status: 'processing' as const,
      totalAmount: total,
      items: cartItems.map(item => `${item.quantity} ${item.product.unit} ${item.product.name}`).join(', '),
      itemCount: cartItems.length,
      deliveryAddress: `${formData.address}, ${formData.city}`,
      paymentMethod,
    };

    // Save order to user's order history
    if (currentUser) {
      const existingOrders = localStorage.getItem(`orders_${currentUser.username}`);
      const orders = existingOrders ? JSON.parse(existingOrders) : [];
      orders.unshift(order);
      localStorage.setItem(`orders_${currentUser.username}`, JSON.stringify(orders));
    }

    setIsProcessing(false);
    setOrderComplete(true);
    clearCart();
    toast.success('Order placed successfully!');
  };

  if (orderComplete) {
    return (
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-md mx-auto text-center">
          <CheckCircle className="mx-auto h-20 w-20 text-green-600 mb-4" />
          <h1 className="text-3xl font-bold mb-2">Order Confirmed!</h1>
          <p className="text-gray-600 mb-6">
            Thank you for your order. We'll send you a confirmation email shortly.
          </p>
          <Button onClick={() => navigate('/')}>Continue Shopping</Button>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Checkout</h1>

      <div className="grid lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2">
          <form onSubmit={handleSubmit} className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <User className="h-5 w-5" />
                  Contact Information
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid sm:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="firstName">First Name</Label>
                    <Input
                      id="firstName"
                      name="firstName"
                      required
                      value={formData.firstName}
                      onChange={handleInputChange}
                    />
                  </div>
                  <div>
                    <Label htmlFor="lastName">Last Name</Label>
                    <Input
                      id="lastName"
                      name="lastName"
                      required
                      value={formData.lastName}
                      onChange={handleInputChange}
                    />
                  </div>
                </div>
                <div>
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    required
                    value={formData.email}
                    onChange={handleInputChange}
                  />
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <MapPin className="h-5 w-5" />
                  Shipping Address
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <Label htmlFor="address">Street Address</Label>
                  <Input
                    id="address"
                    name="address"
                    required
                    value={formData.address}
                    onChange={handleInputChange}
                  />
                </div>
                <div className="grid sm:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="city">City</Label>
                    <Input
                      id="city"
                      name="city"
                      required
                      value={formData.city}
                      onChange={handleInputChange}
                    />
                  </div>
                  <div>
                    <Label htmlFor="zipCode">PIN Code</Label>
                    <Input
                      id="zipCode"
                      name="zipCode"
                      required
                      value={formData.zipCode}
                      onChange={handleInputChange}
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Payment Method</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <RadioGroup value={paymentMethod} onValueChange={(value) => setPaymentMethod(value as PaymentMethod)}>
                  <div className="space-y-3">
                    <div className="flex items-center space-x-3 border rounded-lg p-4 hover:bg-gray-50 cursor-pointer">
                      <RadioGroupItem value="cod" id="cod" />
                      <Label htmlFor="cod" className="flex items-center gap-3 cursor-pointer flex-1">
                        <Banknote className="h-5 w-5 text-green-600" />
                        <div>
                          <div className="font-semibold">Cash on Delivery</div>
                          <div className="text-sm text-gray-500">Pay when you receive your order</div>
                        </div>
                      </Label>
                    </div>

                    <div className="flex items-center space-x-3 border rounded-lg p-4 hover:bg-gray-50 cursor-pointer">
                      <RadioGroupItem value="upi" id="upi" />
                      <Label htmlFor="upi" className="flex items-center gap-3 cursor-pointer flex-1">
                        <Smartphone className="h-5 w-5 text-purple-600" />
                        <div>
                          <div className="font-semibold">UPI Payment</div>
                          <div className="text-sm text-gray-500">PhonePe, Google Pay, Paytm</div>
                        </div>
                      </Label>
                    </div>

                    <div className="flex items-center space-x-3 border rounded-lg p-4 hover:bg-gray-50 cursor-pointer">
                      <RadioGroupItem value="wallet" id="wallet" />
                      <Label htmlFor="wallet" className="flex items-center gap-3 cursor-pointer flex-1">
                        <Wallet className="h-5 w-5 text-orange-600" />
                        <div>
                          <div className="font-semibold">Wallets</div>
                          <div className="text-sm text-gray-500">Amazon Pay, Flipkart, Meesho</div>
                        </div>
                      </Label>
                    </div>

                    <div className="flex items-center space-x-3 border rounded-lg p-4 hover:bg-gray-50 cursor-pointer">
                      <RadioGroupItem value="card" id="card" />
                      <Label htmlFor="card" className="flex items-center gap-3 cursor-pointer flex-1">
                        <CreditCard className="h-5 w-5 text-blue-600" />
                        <div>
                          <div className="font-semibold">Credit / Debit Card</div>
                          <div className="text-sm text-gray-500">Visa, MasterCard, RuPay</div>
                        </div>
                      </Label>
                    </div>
                  </div>
                </RadioGroup>

                {paymentMethod === 'upi' && (
                  <div className="space-y-4 pt-4 border-t">
                    <Label>Select UPI App</Label>
                    <RadioGroup value={formData.selectedUpiApp} onValueChange={(value) => setFormData({ ...formData, selectedUpiApp: value })}>
                      <div className="grid grid-cols-3 gap-3">
                        <div className="border rounded-lg p-3 hover:bg-gray-50 cursor-pointer">
                          <RadioGroupItem value="phonepe" id="phonepe" className="sr-only" />
                          <Label htmlFor="phonepe" className="cursor-pointer text-center block">
                            <div className="text-purple-600 font-semibold text-lg mb-1">PhonePe</div>
                            <div className="text-xs text-gray-500">Instant</div>
                          </Label>
                        </div>
                        <div className="border rounded-lg p-3 hover:bg-gray-50 cursor-pointer">
                          <RadioGroupItem value="googlepay" id="googlepay" className="sr-only" />
                          <Label htmlFor="googlepay" className="cursor-pointer text-center block">
                            <div className="text-blue-600 font-semibold text-lg mb-1">Google Pay</div>
                            <div className="text-xs text-gray-500">Instant</div>
                          </Label>
                        </div>
                        <div className="border rounded-lg p-3 hover:bg-gray-50 cursor-pointer">
                          <RadioGroupItem value="paytm" id="paytm" className="sr-only" />
                          <Label htmlFor="paytm" className="cursor-pointer text-center block">
                            <div className="text-blue-500 font-semibold text-lg mb-1">Paytm</div>
                            <div className="text-xs text-gray-500">Instant</div>
                          </Label>
                        </div>
                      </div>
                    </RadioGroup>
                    <div>
                      <Label htmlFor="upiId">UPI ID (Optional)</Label>
                      <Input
                        id="upiId"
                        name="upiId"
                        placeholder="yourname@upi"
                        value={formData.upiId}
                        onChange={handleInputChange}
                      />
                      <p className="text-xs text-gray-500 mt-1">Or scan QR code on next page</p>
                    </div>
                  </div>
                )}

                {paymentMethod === 'wallet' && (
                  <div className="space-y-4 pt-4 border-t">
                    <Label>Select Wallet</Label>
                    <RadioGroup value={formData.selectedWallet} onValueChange={(value) => setFormData({ ...formData, selectedWallet: value })}>
                      <div className="space-y-3">
                        <div className="flex items-center space-x-3 border rounded-lg p-3 hover:bg-gray-50 cursor-pointer">
                          <RadioGroupItem value="amazonpay" id="amazonpay" />
                          <Label htmlFor="amazonpay" className="flex items-center gap-2 cursor-pointer flex-1">
                            <div className="text-orange-500 font-semibold">Amazon Pay</div>
                          </Label>
                        </div>
                        <div className="flex items-center space-x-3 border rounded-lg p-3 hover:bg-gray-50 cursor-pointer">
                          <RadioGroupItem value="flipkart" id="flipkart" />
                          <Label htmlFor="flipkart" className="flex items-center gap-2 cursor-pointer flex-1">
                            <div className="text-blue-600 font-semibold">Flipkart Wallet</div>
                          </Label>
                        </div>
                        <div className="flex items-center space-x-3 border rounded-lg p-3 hover:bg-gray-50 cursor-pointer">
                          <RadioGroupItem value="meesho" id="meesho" />
                          <Label htmlFor="meesho" className="flex items-center gap-2 cursor-pointer flex-1">
                            <div className="text-pink-600 font-semibold">Meesho Wallet</div>
                          </Label>
                        </div>
                      </div>
                    </RadioGroup>
                    <p className="text-sm text-gray-500">You'll be redirected to complete the payment</p>
                  </div>
                )}

                {paymentMethod === 'card' && (
                  <div className="space-y-4 pt-4 border-t">
                    <div>
                      <Label htmlFor="cardNumber">Card Number</Label>
                      <Input
                        id="cardNumber"
                        name="cardNumber"
                        placeholder="1234 5678 9012 3456"
                        required={paymentMethod === 'card'}
                        value={formData.cardNumber}
                        onChange={handleInputChange}
                      />
                    </div>
                    <div className="grid sm:grid-cols-2 gap-4">
                      <div>
                        <Label htmlFor="expiryDate">Expiry Date</Label>
                        <Input
                          id="expiryDate"
                          name="expiryDate"
                          placeholder="MM/YY"
                          required={paymentMethod === 'card'}
                          value={formData.expiryDate}
                          onChange={handleInputChange}
                        />
                      </div>
                      <div>
                        <Label htmlFor="cvv">CVV</Label>
                        <Input
                          id="cvv"
                          name="cvv"
                          placeholder="123"
                          required={paymentMethod === 'card'}
                          value={formData.cvv}
                          onChange={handleInputChange}
                        />
                      </div>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>

            <Button type="submit" size="lg" className="w-full" disabled={isProcessing}>
              {isProcessing ? 'Processing...' : paymentMethod === 'cod' ? `Place Order - ₹${total.toFixed(0)}` : `Pay ₹${total.toFixed(0)}`}
            </Button>
          </form>
        </div>

        <div className="lg:col-span-1">
          <Card className="sticky top-20">
            <CardHeader>
              <CardTitle>Order Summary</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                {cartItems.map((item) => (
                  <div key={item.product.id} className="flex justify-between text-sm">
                    <span className="text-gray-600">
                      {item.product.name} x {item.quantity}
                    </span>
                    <span className="font-semibold">
                      ₹{(item.product.price * item.quantity).toFixed(0)}
                    </span>
                  </div>
                ))}
              </div>
              <Separator />
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Subtotal</span>
                <span className="font-semibold">₹{total.toFixed(0)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Shipping</span>
                <span className="font-semibold">FREE</span>
              </div>
              <Separator />
              <div className="flex justify-between text-lg">
                <span className="font-bold">Total</span>
                <span className="font-bold text-green-600">₹{total.toFixed(0)}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
