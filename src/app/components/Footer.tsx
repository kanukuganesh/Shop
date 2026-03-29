import { Leaf, MapPin, Phone, Mail } from 'lucide-react';
import { Link } from 'react-router';

export function Footer() {
  return (
    <footer className="bg-white border-t mt-16">
      <div className="container mx-auto px-4 py-12">
        <div className="grid md:grid-cols-3 gap-8">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <Leaf className="h-6 w-6 text-green-600" />
              <span className="text-xl font-semibold">Nagaraju Fruits Shop</span>
            </div>
            <p className="text-gray-600 text-sm">
              Fresh fruits delivered to your doorstep. Quality and freshness guaranteed.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-4">Contact Us</h3>
            <div className="space-y-3 text-sm">
              <div className="flex items-start gap-2 text-gray-600">
                <Phone className="h-4 w-4 mt-1 flex-shrink-0" />
                <span>+91 7780738364</span>
              </div>
              <div className="flex items-start gap-2 text-gray-600">
                <Mail className="h-4 w-4 mt-1 flex-shrink-0" />
                <span>nagarajufruits@example.com</span>
              </div>
            </div>
          </div>

          <div>
            <h3 className="font-semibold mb-4">Our Location</h3>
            <div className="flex items-start gap-2 text-sm text-gray-600">
              <MapPin className="h-4 w-4 mt-1 flex-shrink-0" />
              <div>
                <p>Ternekal Village</p>
                <p>Devanakonda Mandal</p>
                <p>Kurnool District, Andhra Pradesh</p>
              </div>
            </div>
          </div>
        </div>

        <div className="border-t mt-8 pt-8 text-center text-sm text-gray-600">
          <p>&copy; {new Date().getFullYear()} Nagaraju Fruits Shop. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
}
