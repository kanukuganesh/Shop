import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface User {
  username: string;
  passwordHint: string;
  usernameHint: string;
  isAdmin: boolean;
}

interface AuthContextType {
  currentUser: User | null;
  login: (username: string, password: string) => boolean;
  signup: (username: string, password: string, usernameHint: string, passwordHint: string) => boolean;
  logout: () => void;
  getUserHint: (username: string) => string | null;
  isAdmin: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}

const ADMIN_ACCOUNT = {
  username: 'Ganesh',
  password: 'Ganesh@7780',
  passwordHint: 'ganesh and ur email password',
  usernameHint: 'Shop owner name',
  isAdmin: true,
};

export function AuthProvider({ children }: { children: ReactNode }) {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [users, setUsers] = useState<Array<User & { password: string }>>([]);

  useEffect(() => {
    const storedUsers = localStorage.getItem('fruitshop_users');
    if (storedUsers) {
      setUsers(JSON.parse(storedUsers));
    } else {
      // Initialize with admin account
      const initialUsers = [ADMIN_ACCOUNT];
      setUsers(initialUsers);
      localStorage.setItem('fruitshop_users', JSON.stringify(initialUsers));
    }

    const storedCurrentUser = localStorage.getItem('fruitshop_current_user');
    if (storedCurrentUser) {
      setCurrentUser(JSON.parse(storedCurrentUser));
    }
  }, []);

  const login = (username: string, password: string): boolean => {
    const user = users.find(
      (u) => u.username.toLowerCase() === username.toLowerCase() && u.password === password
    );

    if (user) {
      const userWithoutPassword = {
        username: user.username,
        passwordHint: user.passwordHint,
        usernameHint: user.usernameHint,
        isAdmin: user.isAdmin,
      };
      setCurrentUser(userWithoutPassword);
      localStorage.setItem('fruitshop_current_user', JSON.stringify(userWithoutPassword));
      return true;
    }
    return false;
  };

  const signup = (
    username: string,
    password: string,
    usernameHint: string,
    passwordHint: string
  ): boolean => {
    if (users.some((u) => u.username.toLowerCase() === username.toLowerCase())) {
      return false;
    }

    const newUser = {
      username,
      password,
      usernameHint,
      passwordHint,
      isAdmin: false,
    };

    const updatedUsers = [...users, newUser];
    setUsers(updatedUsers);
    localStorage.setItem('fruitshop_users', JSON.stringify(updatedUsers));

    const userWithoutPassword = {
      username: newUser.username,
      passwordHint: newUser.passwordHint,
      usernameHint: newUser.usernameHint,
      isAdmin: newUser.isAdmin,
    };
    setCurrentUser(userWithoutPassword);
    localStorage.setItem('fruitshop_current_user', JSON.stringify(userWithoutPassword));
    return true;
  };

  const logout = () => {
    setCurrentUser(null);
    localStorage.removeItem('fruitshop_current_user');
  };

  const getUserHint = (username: string): string | null => {
    const user = users.find((u) => u.username.toLowerCase() === username.toLowerCase());
    return user ? `Username Hint: ${user.usernameHint}\nPassword Hint: ${user.passwordHint}` : null;
  };

  return (
    <AuthContext.Provider
      value={{
        currentUser,
        login,
        signup,
        logout,
        getUserHint,
        isAdmin: currentUser?.isAdmin || false,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}
