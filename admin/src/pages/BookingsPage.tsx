import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { bookingsApi } from '../services/api';
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Eye,
  XCircle,
  X,
  Calendar,
  MapPin,
  User,
  Wrench,
  DollarSign,
  Clock,
} from 'lucide-react';
import toast from 'react-hot-toast';

const STATUSES = [
  'all',
  'searching',
  'assigned',
  'driving',
  'arrived',
  'active',
  'completed',
  'cancelled',
];

const STATUS_COLORS: Record<string, string> = {
  searching: 'bg-yellow-100 text-yellow-700',
  assigned: 'bg-blue-100 text-blue-700',
  driving: 'bg-indigo-100 text-indigo-700',
  arrived: 'bg-purple-100 text-purple-700',
  active: 'bg-cyan-100 text-cyan-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-700',
};

const STATUS_AR: Record<string, string> = {
  all: 'الكل',
  searching: 'جاري البحث',
  assigned: 'تم التعيين',
  driving: 'في الطريق',
  arrived: 'وصل',
  active: 'نشط',
  completed: 'مكتمل',
  cancelled: 'ملغي',
};

const BookingsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedBooking, setSelectedBooking] = useState<any | null>(null);
  const [cancelDialog, setCancelDialog] = useState<string | null>(null);
  const [cancelReason, setCancelReason] = useState('');
  const limit = 20;

  const { data, isLoading } = useQuery({
    queryKey: ['bookings', page, statusFilter],
    queryFn: () =>
      bookingsApi.list({
        page,
        limit,
        status: statusFilter !== 'all' ? statusFilter : undefined,
      }),
  });

  const cancelMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      bookingsApi.cancel(id, reason),
    onSuccess: () => {
      toast.success('Booking cancelled');
      queryClient.invalidateQueries({ queryKey: ['bookings'] });
      setCancelDialog(null);
      setCancelReason('');
    },
    onError: () => toast.error('Failed to cancel booking'),
  });

  const bookings = data?.data?.bookings || [];
  const total = data?.data?.total || 0;
  const totalPages = Math.ceil(total / limit);

  const filteredBookings = search
    ? bookings.filter(
        (b: any) =>
          b.id?.toLowerCase().includes(search.toLowerCase()) ||
          b.customer_name?.toLowerCase().includes(search.toLowerCase()) ||
          b.technician_name?.toLowerCase().includes(search.toLowerCase())
      )
    : bookings;

  const viewBooking = async (id: string) => {
    try {
      const res = await bookingsApi.get(id);
      setSelectedBooking(res.data);
    } catch {
      toast.error('Failed to load booking details');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Bookings / الحجوزات</h1>
        <p className="text-gray-500 text-sm mt-1">
          View and manage all bookings / عرض وإدارة جميع الحجوزات
        </p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by ID, customer, or technician... / ابحث بالمعرف أو العميل أو الفني..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
          />
        </div>
      </div>

      <div className="flex gap-2 flex-wrap">
        {STATUSES.map((s) => (
          <button
            key={s}
            onClick={() => {
              setStatusFilter(s);
              setPage(1);
            }}
            className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize transition-colors ${
              statusFilter === s
                ? 'bg-primary-100 text-primary-700'
                : 'bg-white border border-gray-300 text-gray-600 hover:bg-gray-50'
            }`}
          >
            {s} {STATUS_AR[s] ? `/ ${STATUS_AR[s]}` : ''}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        {isLoading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50">
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Booking ID
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Customer
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Technician
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
                  <th className="text-right px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredBookings.length === 0 ? (
                  <tr>
                    <td
                      colSpan={8}
                      className="px-6 py-8 text-center text-gray-400"
                    >
                      No bookings found
                    </td>
                  </tr>
                ) : (
                  filteredBookings.map((booking: any) => (
                    <tr key={booking.id} className="hover:bg-gray-50">
                      <td className="px-6 py-3 text-gray-600 font-mono text-xs">
                        {booking.id?.slice(0, 8)}...
                      </td>
                      <td className="px-6 py-3 text-gray-900">
                        {booking.user_name || booking.customer_name || '-'}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {booking.technician_name || 'Unassigned'}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {booking.category_name || '-'}
                      </td>
                      <td className="px-6 py-3">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize ${
                            STATUS_COLORS[booking.status] ||
                            'bg-gray-100 text-gray-700'
                          }`}
                        >
                          {booking.status} / {STATUS_AR[booking.status] || ''}
                        </span>
                      </td>
                      <td className="px-6 py-3 text-gray-900 font-medium">
                        ${booking.estimated_cost || booking.price || 0}
                      </td>
                      <td className="px-6 py-3 text-gray-500 text-xs">
                        {booking.created_at
                          ? new Date(booking.created_at).toLocaleDateString()
                          : '-'}
                      </td>
                      <td className="px-6 py-3 text-right">
                        <div className="flex items-center justify-end gap-1">
                          <button
                            onClick={() => viewBooking(booking.id)}
                            className="p-1.5 text-gray-400 hover:text-primary-600 rounded"
                            title="View details"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
                          {!['completed', 'cancelled'].includes(
                            booking.status
                          ) && (
                            <button
                              onClick={() => setCancelDialog(booking.id)}
                              className="p-1.5 text-gray-400 hover:text-red-600 rounded"
                              title="Cancel booking"
                            >
                              <XCircle className="w-4 h-4" />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {totalPages > 1 && (
          <div className="flex items-center justify-between px-6 py-3 border-t border-gray-200">
            <p className="text-sm text-gray-500">
              Showing {(page - 1) * limit + 1}-
              {Math.min(page * limit, total)} of {total}
            </p>
            <div className="flex items-center gap-1">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 rounded text-gray-500 hover:bg-gray-100 disabled:opacity-30"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="px-3 py-1 text-sm text-gray-700">
                {page} / {totalPages}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded text-gray-500 hover:bg-gray-100 disabled:opacity-30"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Booking Detail Modal */}
      {selectedBooking && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">
                Booking Details
              </h3>
              <button
                onClick={() => setSelectedBooking(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 space-y-5">
              <div className="flex items-center justify-between">
                <span className="font-mono text-sm text-gray-500">
                  #{selectedBooking.id?.slice(0, 12)}
                </span>
                <span
                  className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium capitalize ${
                    STATUS_COLORS[selectedBooking.status] ||
                    'bg-gray-100 text-gray-700'
                  }`}
                >
                  {selectedBooking.status}
                </span>
              </div>

              <div className="space-y-3">
                <DetailRow
                  icon={<User className="w-4 h-4" />}
                  label="Customer"
                  value={selectedBooking.user_name || selectedBooking.customer_name || '-'}
                />
                <DetailRow
                  icon={<Wrench className="w-4 h-4" />}
                  label="Technician"
                  value={selectedBooking.technician_name || 'Unassigned'}
                />
                <DetailRow
                  icon={<Calendar className="w-4 h-4" />}
                  label="Category"
                  value={selectedBooking.category_name || '-'}
                />
                <DetailRow
                  icon={<MapPin className="w-4 h-4" />}
                  label="Address"
                  value={selectedBooking.address || '-'}
                />
                <DetailRow
                  icon={<DollarSign className="w-4 h-4" />}
                  label="Estimated Cost"
                  value={`$${selectedBooking.estimated_cost || selectedBooking.price || 0}`}
                />
                <DetailRow
                  icon={<DollarSign className="w-4 h-4" />}
                  label="Payment"
                  value={selectedBooking.payment_method || '-'}
                />
                <DetailRow
                  icon={<Clock className="w-4 h-4" />}
                  label="Created"
                  value={
                    selectedBooking.created_at
                      ? new Date(selectedBooking.created_at).toLocaleString()
                      : '-'
                  }
                />
              </div>

              {selectedBooking.description && (
                <div>
                  <label className="text-xs font-medium text-gray-500 uppercase">
                    Description
                  </label>
                  <p className="text-sm text-gray-700 mt-1">
                    {selectedBooking.description}
                  </p>
                </div>
              )}

              {selectedBooking.arrival_code && (
                <div>
                  <label className="text-xs font-medium text-gray-500 uppercase">
                    Arrival Code
                  </label>
                  <p className="text-xl font-mono font-bold text-primary-600 mt-1">
                    {selectedBooking.arrival_code}
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Cancel Dialog */}
      {cancelDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">
                Cancel Booking
              </h3>
              <button
                onClick={() => {
                  setCancelDialog(null);
                  setCancelReason('');
                }}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <p className="text-sm text-gray-600">
                Please provide a reason for cancelling this booking.
              </p>
              <textarea
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                placeholder="Cancellation reason..."
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none resize-none"
              />
              <div className="flex gap-3 justify-end">
                <button
                  onClick={() => {
                    setCancelDialog(null);
                    setCancelReason('');
                  }}
                  className="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Back
                </button>
                <button
                  onClick={() =>
                    cancelMutation.mutate({
                      id: cancelDialog,
                      reason: cancelReason,
                    })
                  }
                  disabled={!cancelReason.trim()}
                  className="px-4 py-2 text-sm text-white bg-red-600 rounded-lg hover:bg-red-700 disabled:opacity-50"
                >
                  Cancel Booking
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const DetailRow: React.FC<{
  icon: React.ReactNode;
  label: string;
  value: string;
}> = ({ icon, label, value }) => (
  <div className="flex items-center gap-3">
    <div className="text-gray-400">{icon}</div>
    <div className="flex-1">
      <p className="text-xs text-gray-500">{label}</p>
      <p className="text-sm text-gray-900">{value}</p>
    </div>
  </div>
);

export default BookingsPage;
