import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '../services/api';
import {
  Calendar,
  Download,
  DollarSign,
  CalendarCheck,
  TrendingUp,
} from 'lucide-react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  AreaChart,
  Area,
} from 'recharts';

const ReportsPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'revenue' | 'bookings'>('revenue');
  const [startDate, setStartDate] = useState(() => {
    const d = new Date();
    d.setMonth(d.getMonth() - 1);
    return d.toISOString().split('T')[0];
  });
  const [endDate, setEndDate] = useState(() => {
    return new Date().toISOString().split('T')[0];
  });

  const { data: revenueData, isLoading: loadingRevenue } = useQuery({
    queryKey: ['report-revenue', startDate, endDate],
    queryFn: () =>
      adminApi.getRevenueReport({
        start_date: startDate,
        end_date: endDate,
      }),
    enabled: activeTab === 'revenue',
  });

  const { data: bookingData, isLoading: loadingBookings } = useQuery({
    queryKey: ['report-bookings', startDate, endDate],
    queryFn: () =>
      adminApi.getBookingReport({
        start_date: startDate,
        end_date: endDate,
      }),
    enabled: activeTab === 'bookings',
  });

  const revenue = revenueData?.data || {};
  const bookings = bookingData?.data || {};

  const isLoading = activeTab === 'revenue' ? loadingRevenue : loadingBookings;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reports</h1>
          <p className="text-gray-500 text-sm mt-1">
            Analytics and performance reports
          </p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50">
          <Download className="w-4 h-4" />
          Export CSV
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-gray-100 rounded-lg p-1 w-fit">
        <button
          onClick={() => setActiveTab('revenue')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeTab === 'revenue'
              ? 'bg-white text-gray-900 shadow-sm'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Revenue Report
        </button>
        <button
          onClick={() => setActiveTab('bookings')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
            activeTab === 'bookings'
              ? 'bg-white text-gray-900 shadow-sm'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Booking Report
        </button>
      </div>

      {/* Date Range */}
      <div className="flex items-center gap-3 bg-white rounded-xl border border-gray-200 p-4">
        <Calendar className="w-5 h-5 text-gray-400" />
        <div className="flex items-center gap-2">
          <input
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
          />
          <span className="text-gray-400">to</span>
          <input
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
          />
        </div>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
        </div>
      ) : activeTab === 'revenue' ? (
        <RevenueReport data={revenue} />
      ) : (
        <BookingReport data={bookings} />
      )}
    </div>
  );
};

// ---- Revenue Report ----

const RevenueReport: React.FC<{ data: any }> = ({ data }) => {
  const daily = data.daily || [];
  const summary = data.summary || {};

  return (
    <div className="space-y-6">
      {/* Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <ReportCard
          title="Total Revenue"
          value={`$${(summary.total_revenue || 0).toLocaleString()}`}
          icon={<DollarSign className="w-5 h-5" />}
          color="bg-emerald-100 text-emerald-600"
        />
        <ReportCard
          title="Commission Earned"
          value={`$${(summary.total_commission || 0).toLocaleString()}`}
          icon={<TrendingUp className="w-5 h-5" />}
          color="bg-indigo-100 text-indigo-600"
        />
        <ReportCard
          title="Avg. Transaction"
          value={`$${(summary.avg_transaction || 0).toFixed(2)}`}
          icon={<DollarSign className="w-5 h-5" />}
          color="bg-blue-100 text-blue-600"
        />
        <ReportCard
          title="Total Transactions"
          value={(summary.total_transactions || 0).toLocaleString()}
          icon={<CalendarCheck className="w-5 h-5" />}
          color="bg-purple-100 text-purple-600"
        />
      </div>

      {/* Revenue Area Chart */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Daily Revenue
        </h3>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={daily}>
              <defs>
                <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#4f46e5" stopOpacity={0.1} />
                  <stop offset="95%" stopColor="#4f46e5" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorCommission" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.1} />
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <Tooltip
                contentStyle={{
                  borderRadius: '8px',
                  border: '1px solid #e5e7eb',
                }}
              />
              <Legend />
              <Area
                type="monotone"
                dataKey="revenue"
                stroke="#4f46e5"
                fillOpacity={1}
                fill="url(#colorRevenue)"
                strokeWidth={2}
              />
              <Area
                type="monotone"
                dataKey="commission"
                stroke="#10b981"
                fillOpacity={1}
                fill="url(#colorCommission)"
                strokeWidth={2}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Revenue by Payment Method */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Revenue by Payment Method
        </h3>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data.by_method || []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="method" tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <Tooltip
                contentStyle={{
                  borderRadius: '8px',
                  border: '1px solid #e5e7eb',
                }}
              />
              <Bar dataKey="amount" fill="#4f46e5" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

// ---- Booking Report ----

const BookingReport: React.FC<{ data: any }> = ({ data }) => {
  const daily = data.daily || [];
  const summary = data.summary || {};
  const byStatus = data.by_status || [];
  const byCategory = data.by_category || [];

  return (
    <div className="space-y-6">
      {/* Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <ReportCard
          title="Total Bookings"
          value={(summary.total_bookings || 0).toLocaleString()}
          icon={<CalendarCheck className="w-5 h-5" />}
          color="bg-blue-100 text-blue-600"
        />
        <ReportCard
          title="Completed"
          value={(summary.completed || 0).toLocaleString()}
          icon={<CalendarCheck className="w-5 h-5" />}
          color="bg-green-100 text-green-600"
        />
        <ReportCard
          title="Cancelled"
          value={(summary.cancelled || 0).toLocaleString()}
          icon={<CalendarCheck className="w-5 h-5" />}
          color="bg-red-100 text-red-600"
        />
        <ReportCard
          title="Completion Rate"
          value={`${summary.completion_rate || 0}%`}
          icon={<TrendingUp className="w-5 h-5" />}
          color="bg-emerald-100 text-emerald-600"
        />
      </div>

      {/* Daily Bookings Chart */}
      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">
          Daily Booking Volume
        </h3>
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={daily}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <YAxis tick={{ fontSize: 12 }} stroke="#9ca3af" />
              <Tooltip
                contentStyle={{
                  borderRadius: '8px',
                  border: '1px solid #e5e7eb',
                }}
              />
              <Legend />
              <Line
                type="monotone"
                dataKey="total"
                name="Total"
                stroke="#4f46e5"
                strokeWidth={2}
                dot={{ r: 3 }}
              />
              <Line
                type="monotone"
                dataKey="completed"
                name="Completed"
                stroke="#10b981"
                strokeWidth={2}
                dot={{ r: 3 }}
              />
              <Line
                type="monotone"
                dataKey="cancelled"
                name="Cancelled"
                stroke="#ef4444"
                strokeWidth={2}
                dot={{ r: 3 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Two column layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* By Status */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            By Status
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={byStatus} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 12 }} stroke="#9ca3af" />
                <YAxis
                  dataKey="status"
                  type="category"
                  tick={{ fontSize: 12 }}
                  stroke="#9ca3af"
                  width={80}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: '8px',
                    border: '1px solid #e5e7eb',
                  }}
                />
                <Bar dataKey="count" fill="#4f46e5" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* By Category */}
        <div className="bg-white rounded-xl border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">
            By Category
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={byCategory} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis type="number" tick={{ fontSize: 12 }} stroke="#9ca3af" />
                <YAxis
                  dataKey="category"
                  type="category"
                  tick={{ fontSize: 12 }}
                  stroke="#9ca3af"
                  width={100}
                />
                <Tooltip
                  contentStyle={{
                    borderRadius: '8px',
                    border: '1px solid #e5e7eb',
                  }}
                />
                <Bar dataKey="count" fill="#10b981" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

// ---- Shared ----

const ReportCard: React.FC<{
  title: string;
  value: string;
  icon: React.ReactNode;
  color: string;
}> = ({ title, value, icon, color }) => (
  <div className="bg-white rounded-xl border border-gray-200 p-5">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm text-gray-500">{title}</p>
        <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
      </div>
      <div
        className={`w-10 h-10 rounded-xl flex items-center justify-center ${color}`}
      >
        {icon}
      </div>
    </div>
  </div>
);

export default ReportsPage;
