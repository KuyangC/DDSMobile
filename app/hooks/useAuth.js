import { useState, useEffect } from 'react';
import { authService } from '../services/authService';

export const useAuth = () => {
  const [state, setState] = useState({
    user: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    const unsubscribe = authService.onAuthStateChanged((user) => {
      setState({
        user,
        loading: false,
        error: null,
      });
    });

    return () => unsubscribe();
  }, []);

  const login = async (email, password) => {
    try {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      const result = await authService.login(email, password);

      if (result.success) {
        setState({
          user: result.data,
          loading: false,
          error: null,
        });
        return { success: true };
      } else {
        throw new Error(result.message);
      }
    } catch (error) {
      const errorMessage = error.message || 'Login failed';
      setState((prev) => ({
        ...prev,
        loading: false,
        error: errorMessage,
      }));
      return { success: false, error: errorMessage };
    }
  };

  const register = async (email, password) => {
    try {
      setState((prev) => ({ ...prev, loading: true, error: null }));
      const result = await authService.register(email, password);

      if (result.success) {
        setState({
          user: result.data,
          loading: false,
          error: null,
        });
        return { success: true };
      } else {
        throw new Error(result.message);
      }
    } catch (error) {
      const errorMessage = error.message || 'Registration failed';
      setState((prev) => ({
        ...prev,
        loading: false,
        error: errorMessage,
      }));
      return { success: false, error: errorMessage };
    }
  };

  const logout = () => {
    authService.logout();
    setState({
      user: null,
      loading: false,
      error: null,
    });
  };

  const clearError = () => {
    setState((prev) => ({ ...prev, error: null }));
  };

  return {
    ...state,
    login,
    register,
    logout,
    isAuthenticated: !!state.user,
    clearError,
  };
};