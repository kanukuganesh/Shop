import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useAuth } from '../context/AuthContext';
import { User, MapPin, Phone, Mail, ShoppingBag, Package, ArrowLeft } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../components/ui/tabs';
import { Badge } from '../components/ui/badge';
import { Separator } from '../components/ui/separator';
import { toast } from 'sonner';

interface UserProfile {
  fullName: string;
  mobileNumber: string;
  email: string;
  address: string;
  village: string;
  mandal: string;
  pincode: string;
}

interface Order {
  orderId: string;
  date: string;
  status: 'delivered' | 'processing' | 'cancelled';
  totalAmount: number;
  items: string;
  itemCount: number;
}

export function Profile() {
  const { currentUser } = useAuth();
  const navigate = useNavigate();
  const [isEditing, setIsEditing] = useState(false);

  const [profile, setProfile] = useState<UserProfile>(() => {
    const stored = localStorage.getItem(`profile_${currentUser?.username}`);
    if (stored) {
      return JSON.parse(stored);
    }
    return {
      fullName: currentUser?.username || '',
      mobileNumber: '',
      email: '',
      address: '',
      village: '',
      mandal: '',
      pincode: '',
    };
  });

  const [orders] = useState<Order[]>(() => {
    const stored = localStorage.getItem(`orders_${currentUser?.username}`);
    if (stored) {
      return JSON.parse(stored);
    }
    return [];
  });

  if (!currentUser) {
    navigate('/login');
    return null;
  }

  const handleSave = () => {
    localStorage.setItem(`profile_${currentUser.username}`, JSON.stringify(profile));
    toast.success('Profile updated successfully!');
    setIsEditing(false);
  };

  const handleOrderAgain = (order: Order) => {
    toast.success('Items added to cart!');
    navigate('/cart');
  };

  const getStatusColor = (status: Order['status']) => {
    switch (status) {
      case 'delivered':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'processing':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'cancelled':
        return 'bg-red-100 text-red-800 border-red-200';
    }
  };

  const getStatusIcon = (status: Order['status']) => {
    switch (status) {
      case 'delivered':
        return '🟢';
      case 'processing':
        return '🟡';
      case 'cancelled':
        return '🔴';
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <Button variant="ghost" onClick={() => navigate('/')} className="mb-6">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Shop
      </Button>

      <div className="max-w-4xl mx-auto">
        <div className="flex items-center gap-3 mb-8">
          <div className="bg-green-100 p-3 rounded-full">
            <User className="h-8 w-8 text-green-600" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">My Profile</h1>
            <p className="text-gray-600">Manage your account and view orders</p>
          </div>
        </div>

        <Tabs defaultValue="details" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="details">
              <User className="mr-2 h-4 w-4" />
              User Details
            </TabsTrigger>
            <TabsTrigger value="orders">
              <ShoppingBag className="mr-2 h-4 w-4" />
              Order History
            </TabsTrigger>
          </TabsList>

          <TabsContent value="details" className="mt-6">
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle>Personal Information</CardTitle>
                    <CardDescription>Update your profile details and delivery address</CardDescription>
                  </div>
                  <Button
                    variant={isEditing ? 'default' : 'outline'}
                    onClick={() => (isEditing ? handleSave() : setIsEditing(true))}
                  >
                    {isEditing ? 'Save Changes' : 'Edit Profile'}
                  </Button>
                </div>
              </CardHeader>
              <CardContent className="space-y-6">
                <div className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="fullName">Full Name</Label>
                    <Input
                      id="fullName"
                      value={profile.fullName}
                      onChange={(e) => setProfile({ ...profile, fullName: e.target.value })}
                      disabled={!isEditing}
                    />
                  </div>

                  <div className="grid md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="mobile" className="flex items-center gap-2">
                        <Phone className="h-4 w-4" />
                        Mobile Number
                      </Label>
                      <Input
                        id="mobile"
                        type="tel"
                        placeholder="+91 "
                        value={profile.mobileNumber}
                        onChange={(e) => setProfile({ ...profile, mobileNumber: e.target.value })}
                        disabled={!isEditing}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="email" className="flex items-center gap-2">
                        <Mail className="h-4 w-4" />
                        Email Address
                      </Label>
                      <Input
                        id="email"
                        type="email"
                        value={profile.email}
                        onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                        disabled={!isEditing}
                      />
                    </div>
                  </div>
                </div>

                <Separator />

                <div className="space-y-4">
                  <Label className="flex items-center gap-2">
                    <MapPin className="h-4 w-4" />
                    Delivery Address
                  </Label>

                  <div className="space-y-2">
                    <Label htmlFor="address">Street Address</Label>
                    <Input
                      id="address"
                      value={profile.address}
                      onChange={(e) => setProfile({ ...profile, address: e.target.value })}
                      disabled={!isEditing}
                    />
                  </div>

                  <div className="grid md:grid-cols-3 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="village">Village</Label>
                      <Input
                        id="village"
                        value={profile.village}
                        onChange={(e) => setProfile({ ...profile, village: e.target.value })}
                        disabled={!isEditing}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="mandal">Mandal</Label>
                      <Input
                        id="mandal"
                        value={profile.mandal}
                        onChange={(e) => setProfile({ ...profile, mandal: e.target.value })}
                        disabled={!isEditing}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="pincode">PIN Code</Label>
                      <Input
                        id="pincode"
                        value={profile.pincode}
                        onChange={(e) => setProfile({ ...profile, pincode: e.target.value })}
                        disabled={!isEditing}
                      />
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="orders" className="mt-6">
            <Card>
              <CardHeader>
                <CardTitle>Purchase History</CardTitle>
                <CardDescription>View all your orders from Nagaraju Fruits Shop</CardDescription>
              </CardHeader>
              <CardContent>
                {orders.length === 0 ? (
                  <div className="text-center py-12">
                    <Package className="mx-auto h-12 w-12 text-gray-300 mb-4" />
                    <h3 className="text-lg font-semibold mb-2">No Orders Yet</h3>
                    <p className="text-gray-600 mb-4">Start shopping to see your order history here</p>
                    <Button onClick={() => navigate('/')}>Browse Products</Button>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {orders.map((order) => (
                      <Card key={order.orderId} className="border-2">
                        <CardContent className="p-4">
                          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                            <div className="flex-1 space-y-2">
                              <div className="flex items-center gap-3">
                                <h3 className="font-semibold text-lg">{order.orderId}</h3>
                                <Badge className={`${getStatusColor(order.status)} border`}>
                                  {getStatusIcon(order.status)} {order.status.charAt(0).toUpperCase() + order.status.slice(1)}
                                </Badge>
                              </div>
                              <p className="text-sm text-gray-600">
                                {new Date(order.date).toLocaleDateString('en-IN', {
                                  day: 'numeric',
                                  month: 'long',
                                  year: 'numeric',
                                  hour: '2-digit',
                                  minute: '2-digit',
                                })}
                              </p>
                              <p className="text-sm text-gray-700">{order.items}</p>
                              <p className="text-lg font-bold text-green-600">₹{order.totalAmount}</p>
                            </div>
                            <div className="flex flex-col gap-2">
                              <Button
                                variant="outline"
                                onClick={() => handleOrderAgain(order)}
                                className="w-full md:w-auto"
                              >
                                <ShoppingBag className="mr-2 h-4 w-4" />
                                Order Again
                              </Button>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
