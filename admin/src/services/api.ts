import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - attach token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor - handle 401
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalUrl = error.config?.url || '';
    // Don't intercept 401 on login/refresh — let the caller handle it
    if (error.response?.status === 401 && !originalUrl.includes('/auth/login') && !originalUrl.includes('/auth/refresh')) {
      const refreshToken = localStorage.getItem('admin_refresh_token');
      if (refreshToken) {
        try {
          const res = await axios.post(`${API_BASE_URL}/auth/refresh`, {
            refresh_token: refreshToken,
          });
          localStorage.setItem('admin_token', res.data.access_token);
          localStorage.setItem('admin_refresh_token', res.data.refresh_token);
          error.config.headers.Authorization = `Bearer ${res.data.access_token}`;
          return api.request(error.config);
        } catch {
          localStorage.removeItem('admin_token');
          localStorage.removeItem('admin_refresh_token');
          window.location.href = '/login';
        }
      } else {
        localStorage.removeItem('admin_token');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// ---- Auth ----
export const authApi = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),
  logout: () => api.post('/settings/logout'),
  getMe: () => api.get('/users/me'),
};

// ---- Admin Dashboard ----
export const adminApi = {
  getDashboard: () => api.get('/admin/dashboard'),
  getRevenueReport: (params?: { start_date?: string; end_date?: string }) =>
    api.get('/admin/reports/revenue', { params }),
  getBookingReport: (params?: { start_date?: string; end_date?: string }) =>
    api.get('/admin/reports/bookings', { params }),
};

// ---- Users ----
export const usersApi = {
  list: (params?: { page?: number; limit?: number; role?: string }) =>
    api.get('/admin/users', { params }),
  get: (id: string) => api.get(`/admin/users/${id}`),
  ban: (id: string) => api.put(`/admin/users/${id}/ban`),
  unban: (id: string) => api.put(`/admin/users/${id}/unban`),
  delete: (id: string) => api.delete(`/admin/users/${id}`),
  resetPassword: (id: string, newPassword: string) =>
    api.post(`/admin/users/${id}/reset-password`, { new_password: newPassword }),
};

// ---- Technicians ----
export const techniciansApi = {
  list: (params?: { page?: number; limit?: number; verified?: boolean; status?: string }) =>
    api.get('/admin/technicians', { params }),
  get: (id: string) => api.get(`/admin/technicians/${id}`),
  getVerification: (id: string) => api.get(`/admin/technicians/${id}/verification`),
  verify: (id: string) =>
    api.put(`/admin/technicians/${id}/verify`, { verified: true }),
  reject: (id: string, reason?: string) =>
    api.put(`/admin/technicians/${id}/verify`, { verified: false, reason: reason || '' }),
  ban: (id: string) => api.put(`/admin/technicians/${id}/ban`),
  unban: (id: string) => api.put(`/admin/technicians/${id}/unban`),
};

// ---- Bookings ----
export const bookingsApi = {
  list: (params?: { page?: number; limit?: number; status?: string }) =>
    api.get('/admin/bookings', { params }),
  get: (id: string) => api.get(`/admin/bookings/${id}`),
  cancel: (id: string, reason: string) =>
    api.post(`/bookings/${id}/cancel`, { reason }),
};

// ---- Categories ----
export const categoriesApi = {
  list: () => api.get('/categories'),
  create: (data: {
    name_en: string;
    name_ar: string;
    icon?: string;
    type?: string;
    parent_id?: string;
  }) => api.post('/admin/categories', data),
  update: (
    id: string,
    data: { name_en?: string; name_ar?: string; icon?: string }
  ) => api.put(`/admin/categories/${id}`, data),
  delete: (id: string) => api.delete(`/admin/categories/${id}`),
};

// ---- Payments ----
export const paymentsApi = {
  list: (params?: { page?: number; limit?: number }) =>
    api.get('/admin/payments', { params }),
};

// ---- Support ----
export const supportApi = {
  listTickets: (params?: { page?: number; status?: string }) =>
    api.get('/admin/support/tickets', { params }),
  getTicket: (id: string) => api.get(`/support/tickets/${id}`),
  getMessages: (id: string) => api.get(`/support/tickets/${id}/messages`),
  reply: (id: string, message: string) =>
    api.post(`/admin/support/tickets/${id}/messages`, { content: message }),
  assign: (id: string, adminId: string) =>
    api.put(`/admin/support/tickets/${id}/assign`, { admin_id: adminId }),
  close: (id: string) => api.put(`/admin/support/tickets/${id}/close`),
};

export default api;
