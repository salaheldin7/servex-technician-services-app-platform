import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { adminApi, bookingsApi } from '../services/api';
import {
  Users,
  Wrench,
  CalendarCheck,
  DollarSign,
  TrendingUp,
  Clock,
  AlertTriangle,
  Star,
} from 'lucide-react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

const STAT_ICONS: Record<string, React.ReactNode> = {
  total_users: <Users className="w-6 h-6" />,
  total_technicians: <Wrench className="w-6 h-6" />,
  total_bookings: <CalendarCheck className="w-6 h-6" />,
  active_bookings: <Clock className="w-6 h-6" />,
  today_bookings: <CalendarCheck className="w-6 h-6" />,
  total_revenue: <DollarSign className="w-6 h-6" />,
  month_revenue: <DollarSign className="w-6 h-6" />,
  total_commission: <TrendingUp className="w-6 h-6" />,
  pending_verifications: <AlertTriangle className="w-6 h-6" />,
  avg_rating: <Star className="w-6 h-6" />,
};

const STAT_COLORS: Record<string, string> = {
  total_users: 'bg-blue-100 text-blue-600',
  total_technicians: 'bg-purple-100 text-purple-600',
  total_bookings: 'bg-green-100 text-green-600',
  active_bookings: 'bg-yellow-100 text-yellow-600',
  today_bookings: 'bg-teal-100 text-teal-600',
  total_revenue: 'bg-emerald-100 text-emerald-600',
  month_revenue: 'bg-lime-100 text-lime-600',
  total_commission: 'bg-indigo-100 text-indigo-600',
  pending_verifications: 'bg-orange-100 text-orange-600',
  avg_rating: 'bg-pink-100 text-pink-600',
};

const STAT_LABELS: Record<string, string> = {
  total_users: 'Total Users',
  total_technicians: 'Technicians',
  total_bookings: 'Total Bookings',
  active_bookings: 'Active Bookings',
  today_bookings: 'Today\'s Bookings',
  total_revenue: 'Total Revenue',
  month_revenue: 'Monthly Revenue',
  total_commission: 'Commission Earned',
  pending_verifications: 'Pending Approvals',
  avg_rating: 'Avg Rating',
};

const PIE_COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899'];

const DashboardPage: React.FC = () => {
  const { data: dashboard, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => adminApi.getDashboard(),
    refetchInterval: 30000,
  });

  const { data: revenueData } = useQuery({
    queryKey: ['revenue-report'],
    queryFn: () => adminApi.getRevenueReport(),
  });

  const { data: bookingData } = useQuery({
    queryKey: ['booking-report'],
    queryFn: () => adminApi.getBookingReport(),
  });

  const { data: recentBookingsData } = useQuery({
    queryKey: ['recent-bookings'],
    queryFn: () => bookingsApi.list({ page: 1, limit: 10 }),
  });

  // Backend returns stats flat at top level (not wrapped in .stats)
  const stats = dashboard?.data || {};
  const recentBookings = recentBookingsData?.data?.bookings || [];
  const revenueChart = revenueData?.data?.daily || revenueData?.data?.data || [];
  const bookingsByStatus = bookingData?.data?.by_status || bookingData?.data?.data || [];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500 text-sm mt-1">
          Platform overview and analytics
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {Object.entries(stats).map(([key, value]) => (
          <div
            key={key}
            className="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-sm transition-shadow"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">
                  {STAT_LABELS[key] || key}
                </p>
                <p className="text-2xl font-bold text-gray-900 mt-1">
                  {key.includes('revenue') || key.includes('commission')
                    ? `$${Number(value).toLocaleString()}`
                    : key === 'avg_rating'
                    ? Number(value).toFixed(1)
                    : Number(value).toLocaleString()}
                </p>
              </div>
              <div
                className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                  STAT_COLORS[key] || 'bg-gray-100 text-gray-600'
                }`}
              >
                {STAT_ICONS[key] || <CalendarCheck className="w-6 h-6" />}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Revenue Chart */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Revenue Trend
          </h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={revenueChart}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="#9ca3af" />
                <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
                <Tooltip
                  contentStyle={{
                    borderRadius: '8px',
                    border: '1px solid #e5e7eb',
                  }}
                />
                <Line
                  type="monotone"
                  dataKey="revenue"
                  stroke="#4f46e5"
                  strokeWidth={2}
                  dot={false}
                />
                <Line
                  type="monotone"
                  dataKey="commission"
                  stroke="#10b981"
                  strokeWidth={2}
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Bookings by Status */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            Bookings by Status
          </h3>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={bookingsByStatus}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={90}
                  paddingAngle={2}
                  dataKey="count"
                  nameKey="status"
                >
                  {bookingsByStatus.map((_: any, index: number) => (
                    <Cell
                      key={`cell-${index}`}
                      fill={PIE_COLORS[index % PIE_COLORS.length]}
                    />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="flex flex-wrap gap-2 mt-2">
            {bookingsByStatus.map((item: any, index: number) => (
              <div key={item.status} className="flex items-center gap-1.5 text-xs">
                <div
                  className="w-2.5 h-2.5 rounded-full"
                  style={{
                    backgroundColor: PIE_COLORS[index % PIE_COLORS.length],
                  }}
                />
                <span className="text-gray-600 capitalize">{item.status}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Booking Volume Chart */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Daily Booking Volume
        </h3>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={revenueChart}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <Tooltip
                contentStyle={{
                  borderRadius: '8px',
                  border: '1px solid #e5e7eb',
                }}
              />
              <Bar dataKey="bookings" fill="#4f46e5" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent Bookings Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">
            Recent Bookings
          </h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50">
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                  ID
                </th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                  Customer
                </th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                  Service
                </th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                  Status
                </th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                  Amount
                </th>
                <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                  Date
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {recentBookings.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-gray-400">
                    No recent bookings
                  </td>
                </tr>
              ) : (
                recentBookings.map((booking: any) => (
                  <tr key={booking.id} className="hover:bg-gray-50">
                    <td className="px-6 py-3 text-gray-600 font-mono text-xs">
                      {booking.id?.slice(0, 8)}...
                    </td>
                    <td className="px-6 py-3 text-gray-900">
                      {booking.user_name || booking.customer_name || '-'}
                    </td>
                    <td className="px-6 py-3 text-gray-600">
                      {booking.category_name || '-'}
                    </td>
                    <td className="px-6 py-3">
                      <StatusBadge status={booking.status} />
                    </td>
                    <td className="px-6 py-3 text-gray-900 font-medium">
                      ${booking.estimated_cost || booking.price || 0}
                    </td>
                    <td className="px-6 py-3 text-gray-500 text-xs">
                      {booking.created_at
                        ? new Date(booking.created_at).toLocaleDateString()
                        : '-'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

const StatusBadge: React.FC<{ status: string }> = ({ status }) => {
  const styles: Record<string, string> = {
    searching: 'bg-yellow-100 text-yellow-700',
    assigned: 'bg-blue-100 text-blue-700',
    driving: 'bg-indigo-100 text-indigo-700',
    arrived: 'bg-purple-100 text-purple-700',
    active: 'bg-cyan-100 text-cyan-700',
    completed: 'bg-green-100 text-green-700',
    cancelled: 'bg-red-100 text-red-700',
  };

  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize ${
        styles[status] || 'bg-gray-100 text-gray-700'
      }`}
    >
      {status}
    </span>
  );
};

export default DashboardPage;
