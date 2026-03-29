import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useAuth } from '../context/AuthContext';
import { Store, MapPin, Phone, User, Package, ArrowLeft } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '../components/ui/card';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { Separator } from '../components/ui/separator';
import { toast } from 'sonner';

const SHOP_INFO = {
  shopName: 'Nagaraju Fruits Shop',
  ownerName: 'K. Nagaraju',
  contactNumber: '+91 7780738364',
  village: 'Ternekal Village',
  mandal: 'Devanakonda Mandal',
  district: 'Kurnool District',
  state: 'Andhra Pradesh',
};

export function Admin() {
  const { isAdmin, currentUser } = useAuth();
  const navigate = useNavigate();
  const [shopInfo, setShopInfo] = useState(SHOP_INFO);
  const [isEditing, setIsEditing] = useState(false);

  if (!isAdmin) {
    navigate('/');
    return null;
  }

  const handleSave = () => {
    toast.success('Shop information updated successfully!');
    setIsEditing(false);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <Button variant="ghost" onClick={() => navigate('/')} className="mb-6">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Shop
      </Button>

      <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">Admin Dashboard</h1>
            <p className="text-gray-600 mt-1">Welcome, {currentUser?.username}!</p>
          </div>
          <div className="bg-green-100 text-green-800 px-4 py-2 rounded-full font-semibold">
            Shop Owner
          </div>
        </div>

        <div className="grid md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Package className="h-5 w-5" />
                Quick Stats
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Total Products</span>
                <span className="text-2xl font-bold">10</span>
              </div>
              <Separator />
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Products In Stock</span>
                <span className="text-2xl font-bold text-green-600">10</span>
              </div>
              <Separator />
              <div className="flex justify-between items-center">
                <span className="text-gray-600">Out of Stock</span>
                <span className="text-2xl font-bold text-red-600">0</span>
              </div>
              <Separator />
              <Button onClick={() => navigate('/admin/orders')} className="w-full">
                View All Orders
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <User className="h-5 w-5" />
                Account Information
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-sm text-gray-500">Username</p>
                <p className="font-semibold">{currentUser?.username}</p>
              </div>
              <Separator />
              <div>
                <p className="text-sm text-gray-500">Role</p>
                <p className="font-semibold">Administrator</p>
              </div>
              <Separator />
              <div>
                <p className="text-sm text-gray-500">Access Level</p>
                <p className="font-semibold text-green-600">Full Access</p>
              </div>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="flex items-center gap-2">
                  <Store className="h-5 w-5" />
                  Shop Information
                </CardTitle>
                <CardDescription>Manage your shop details and contact information</CardDescription>
              </div>
              <Button
                variant={isEditing ? 'default' : 'outline'}
                onClick={() => (isEditing ? handleSave() : setIsEditing(true))}
              >
                {isEditing ? 'Save Changes' : 'Edit Details'}
              </Button>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            <div className="grid md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="shopName">Shop Name</Label>
                <Input
                  id="shopName"
                  value={shopInfo.shopName}
                  onChange={(e) => setShopInfo({ ...shopInfo, shopName: e.target.value })}
                  disabled={!isEditing}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="ownerName">Owner Name</Label>
                <Input
                  id="ownerName"
                  value={shopInfo.ownerName}
                  onChange={(e) => setShopInfo({ ...shopInfo, ownerName: e.target.value })}
                  disabled={!isEditing}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="contactNumber" className="flex items-center gap-2">
                <Phone className="h-4 w-4" />
                Contact Number
              </Label>
              <Input
                id="contactNumber"
                value={shopInfo.contactNumber}
                onChange={(e) => setShopInfo({ ...shopInfo, contactNumber: e.target.value })}
                disabled={!isEditing}
              />
            </div>

            <Separator />

            <div className="space-y-4">
              <Label className="flex items-center gap-2">
                <MapPin className="h-4 w-4" />
                Shop Address
              </Label>
              <div className="grid md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="village">Village</Label>
                  <Input
                    id="village"
                    value={shopInfo.village}
                    onChange={(e) => setShopInfo({ ...shopInfo, village: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="mandal">Mandal</Label>
                  <Input
                    id="mandal"
                    value={shopInfo.mandal}
                    onChange={(e) => setShopInfo({ ...shopInfo, mandal: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="district">District</Label>
                  <Input
                    id="district"
                    value={shopInfo.district}
                    onChange={(e) => setShopInfo({ ...shopInfo, district: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="state">State</Label>
                  <Input
                    id="state"
                    value={shopInfo.state}
                    onChange={(e) => setShopInfo({ ...shopInfo, state: e.target.value })}
                    disabled={!isEditing}
                  />
                </div>
              </div>
            </div>

            <div className="bg-green-50 border border-green-200 rounded-lg p-4">
              <h4 className="font-semibold text-green-900 mb-2">Complete Shop Address</h4>
              <p className="text-green-800">
                {shopInfo.shopName}<br />
                {shopInfo.ownerName}<br />
                {shopInfo.village}, {shopInfo.mandal}<br />
                {shopInfo.district}, {shopInfo.state}<br />
                Contact: {shopInfo.contactNumber}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
