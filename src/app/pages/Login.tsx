import { useState } from 'react';
import { useNavigate, Link } from 'react-router';
import { Leaf, Eye, EyeOff, HelpCircle } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { Button } from '../components/ui/button';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '../components/ui/card';
import { Input } from '../components/ui/input';
import { Label } from '../components/ui/label';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '../components/ui/dialog';

export function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [forgotUsername, setForgotUsername] = useState('');
  const [showHintDialog, setShowHintDialog] = useState(false);
  const { login, getUserHint } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (login(username, password)) {
      toast.success('Login successful!');
      navigate('/');
    } else {
      toast.error('Invalid username or password');
    }
  };

  const handleForgotPassword = () => {
    if (!forgotUsername) {
      toast.error('Please enter your username');
      return;
    }

    const hint = getUserHint(forgotUsername);
    if (hint) {
      toast.success(hint, { duration: 8000 });
    } else {
      toast.error('Username not found');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-green-100 px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center mb-4">
            <div className="bg-green-600 p-3 rounded-full">
              <Leaf className="h-8 w-8 text-white" />
            </div>
          </div>
          <CardTitle className="text-2xl font-bold">Welcome Back</CardTitle>
          <CardDescription>Sign in to Nagaraju Fruits Shop</CardDescription>
        </CardHeader>
        <form onSubmit={handleSubmit}>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username">Username</Label>
              <Input
                id="username"
                placeholder="Enter your username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            <Dialog open={showHintDialog} onOpenChange={setShowHintDialog}>
              <DialogTrigger asChild>
                <Button type="button" variant="link" className="px-0 text-sm">
                  <HelpCircle className="h-4 w-4 mr-1" />
                  Forgot Password?
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Recover Your Password</DialogTitle>
                  <DialogDescription>
                    Enter your username to see your password hint
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 pt-4">
                  <div>
                    <Label htmlFor="forgot-username">Username</Label>
                    <Input
                      id="forgot-username"
                      placeholder="Enter your username"
                      value={forgotUsername}
                      onChange={(e) => setForgotUsername(e.target.value)}
                    />
                  </div>
                  <Button onClick={handleForgotPassword} className="w-full">
                    Show Hint
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </CardContent>
          <CardFooter className="flex flex-col space-y-4">
            <Button type="submit" className="w-full" size="lg">
              Sign In
            </Button>
            <div className="text-center text-sm text-gray-600">
              Don't have an account?{' '}
              <Link to="/signup" className="text-green-600 hover:underline font-semibold">
                Create Account
              </Link>
            </div>
          </CardFooter>
        </form>
      </Card>
    </div>
  );
}
