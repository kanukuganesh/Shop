import { useState } from 'react';
import { useNavigate } from 'react-router';
import { useAuth } from '../context/AuthContext';
import { Package, ArrowLeft, Search, Filter } from 'lucide-react';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../components/ui/card';
import { Input } from '../components/ui/input';
import { Badge } from '../components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../components/ui/select';

interface Order {
  orderId: string;
  customerName: string;
  date: string;
  status: 'delivered' | 'processing' | 'cancelled';
  totalAmount: number;
  items: string;
  itemCount: number;
  customerMobile: string;
  deliveryAddress: string;
}

export function AdminOrders() {
  const { isAdmin } = useAuth();
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  // Load all orders from localStorage
  const [allOrders] = useState<Order[]>(() => {
    const orders: Order[] = [];
    // This would typically load from a database
    // For now, we'll show mock data
    return [
      {
        orderId: '#NF-1024',
        customerName: 'Rajesh Kumar',
        customerMobile: '+91 9876543210',
        date: new Date().toISOString(),
        status: 'processing',
        totalAmount: 450,
        items: '2kg Mangoes, 1 dozen Bananas',
        itemCount: 2,
        deliveryAddress: 'Ternekal Village, Devanakonda',
      },
      {
        orderId: '#NF-1023',
        customerName: 'Lakshmi Devi',
        customerMobile: '+91 9876543211',
        date: new Date(Date.now() - 86400000).toISOString(),
        status: 'delivered',
        totalAmount: 320,
        items: '1kg Apples, 500g Grapes',
        itemCount: 2,
        deliveryAddress: 'Kurnool Main Road',
      },
      {
        orderId: '#NF-1022',
        customerName: 'Venkat Rao',
        customerMobile: '+91 9876543212',
        date: new Date(Date.now() - 172800000).toISOString(),
        status: 'delivered',
        totalAmount: 280,
        items: '1kg Oranges, 1 Pineapple',
        itemCount: 2,
        deliveryAddress: 'Devanakonda Mandal',
      },
    ];
  });

  if (!isAdmin) {
    navigate('/');
    return null;
  }

  const filteredOrders = allOrders.filter((order) => {
    const matchesSearch =
      order.orderId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.customerMobile.includes(searchTerm);

    const matchesStatus = statusFilter === 'all' || order.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

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

  const stats = {
    total: allOrders.length,
    processing: allOrders.filter((o) => o.status === 'processing').length,
    delivered: allOrders.filter((o) => o.status === 'delivered').length,
    cancelled: allOrders.filter((o) => o.status === 'cancelled').length,
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <Button variant="ghost" onClick={() => navigate('/admin')} className="mb-6">
        <ArrowLeft className="mr-2 h-4 w-4" />
        Back to Dashboard
      </Button>

      <div className="max-w-6xl mx-auto">
        <div className="flex items-center gap-3 mb-8">
          <div className="bg-green-100 p-3 rounded-full">
            <Package className="h-8 w-8 text-green-600" />
          </div>
          <div>
            <h1 className="text-3xl font-bold">All Shop Orders</h1>
            <p className="text-gray-600">Manage and track customer orders</p>
          </div>
        </div>

        <div className="grid md:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold">{stats.total}</div>
              <div className="text-sm text-gray-600">Total Orders</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-yellow-600">{stats.processing}</div>
              <div className="text-sm text-gray-600">Processing</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-green-600">{stats.delivered}</div>
              <div className="text-sm text-gray-600">Delivered</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4">
              <div className="text-2xl font-bold text-red-600">{stats.cancelled}</div>
              <div className="text-sm text-gray-600">Cancelled</div>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Orders Management</CardTitle>
            <div className="flex flex-col sm:flex-row gap-4 mt-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Search by Order ID, Customer name or mobile..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-full sm:w-48">
                  <Filter className="mr-2 h-4 w-4" />
                  <SelectValue placeholder="Filter by status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Orders</SelectItem>
                  <SelectItem value="processing">Processing</SelectItem>
                  <SelectItem value="delivered">Delivered</SelectItem>
                  <SelectItem value="cancelled">Cancelled</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardHeader>
          <CardContent>
            {filteredOrders.length === 0 ? (
              <div className="text-center py-12">
                <Package className="mx-auto h-12 w-12 text-gray-300 mb-4" />
                <h3 className="text-lg font-semibold mb-2">No Orders Found</h3>
                <p className="text-gray-600">Try adjusting your search or filter</p>
              </div>
            ) : (
              <div className="space-y-4">
                {filteredOrders.map((order) => (
                  <Card key={order.orderId} className="border-2">
                    <CardContent className="p-4">
                      <div className="grid md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                          <div className="flex items-center gap-3">
                            <h3 className="font-semibold text-lg">{order.orderId}</h3>
                            <Badge className={`${getStatusColor(order.status)} border`}>
                              {getStatusIcon(order.status)} {order.status.charAt(0).toUpperCase() + order.status.slice(1)}
                            </Badge>
                          </div>
                          <div className="space-y-1 text-sm">
                            <p className="text-gray-600">
                              <span className="font-semibold">Customer:</span> {order.customerName}
                            </p>
                            <p className="text-gray-600">
                              <span className="font-semibold">Mobile:</span> {order.customerMobile}
                            </p>
                            <p className="text-gray-600">
                              <span className="font-semibold">Date:</span>{' '}
                              {new Date(order.date).toLocaleDateString('en-IN', {
                                day: 'numeric',
                                month: 'short',
                                year: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit',
                              })}
                            </p>
                          </div>
                        </div>
                        <div className="space-y-2">
                          <p className="text-sm text-gray-700">
                            <span className="font-semibold">Items:</span> {order.items}
                          </p>
                          <p className="text-sm text-gray-700">
                            <span className="font-semibold">Delivery:</span> {order.deliveryAddress}
                          </p>
                          <p className="text-lg font-bold text-green-600">Total: ₹{order.totalAmount}</p>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
