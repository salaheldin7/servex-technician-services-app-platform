import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { paymentsApi } from '../services/api';
import {
  DollarSign,
  TrendingUp,
  CreditCard,
  Banknote,
  ChevronLeft,
  ChevronRight,
  ArrowUpRight,
  ArrowDownRight,
} from 'lucide-react';

const PaymentsPage: React.FC = () => {
  const [page, setPage] = useState(1);
  const limit = 20;

  const { data, isLoading } = useQuery({
    queryKey: ['payments', page],
    queryFn: () => paymentsApi.list({ page, limit }),
  });

  const payments = data?.data?.payments || [];
  const total = data?.data?.total || 0;
  const summary = data?.data?.summary || {};
  const totalPages = Math.ceil(total / limit);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Payments</h1>
        <p className="text-gray-500 text-sm mt-1">
          Payment history and revenue tracking
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <SummaryCard
          title="Total Revenue"
          value={`$${(summary.total_revenue || 0).toLocaleString()}`}
          icon={<DollarSign className="w-6 h-6" />}
          color="bg-emerald-100 text-emerald-600"
          trend="+12.5%"
          trendUp
        />
        <SummaryCard
          title="Commission Earned"
          value={`$${(summary.total_commission || 0).toLocaleString()}`}
          icon={<TrendingUp className="w-6 h-6" />}
          color="bg-indigo-100 text-indigo-600"
          trend="+8.2%"
          trendUp
        />
        <SummaryCard
          title="Card Payments"
          value={`$${(summary.card_payments || 0).toLocaleString()}`}
          icon={<CreditCard className="w-6 h-6" />}
          color="bg-blue-100 text-blue-600"
        />
        <SummaryCard
          title="Cash Payments"
          value={`$${(summary.cash_payments || 0).toLocaleString()}`}
          icon={<Banknote className="w-6 h-6" />}
          color="bg-green-100 text-green-600"
        />
      </div>

      {/* Payments Table */}
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
                    Payment ID
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Booking
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Customer
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Technician
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Amount
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Commission
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Method
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Status
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Date
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {payments.length === 0 ? (
                  <tr>
                    <td
                      colSpan={9}
                      className="px-6 py-8 text-center text-gray-400"
                    >
                      No payments found
                    </td>
                  </tr>
                ) : (
                  payments.map((payment: any) => (
                    <tr key={payment.id} className="hover:bg-gray-50">
                      <td className="px-6 py-3 text-gray-600 font-mono text-xs">
                        {payment.id?.slice(0, 8)}...
                      </td>
                      <td className="px-6 py-3 text-gray-600 font-mono text-xs">
                        {payment.booking_id?.slice(0, 8)}...
                      </td>
                      <td className="px-6 py-3 text-gray-900">
                        {payment.customer_name || '-'}
                      </td>
                      <td className="px-6 py-3 text-gray-600">
                        {payment.technician_name || '-'}
                      </td>
                      <td className="px-6 py-3 text-gray-900 font-medium">
                        ${payment.amount || 0}
                      </td>
                      <td className="px-6 py-3 text-indigo-600 font-medium">
                        ${payment.commission || 0}
                      </td>
                      <td className="px-6 py-3">
                        <span
                          className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                            payment.method === 'card'
                              ? 'bg-blue-100 text-blue-700'
                              : 'bg-green-100 text-green-700'
                          }`}
                        >
                          {payment.method === 'card' ? (
                            <CreditCard className="w-3 h-3" />
                          ) : (
                            <Banknote className="w-3 h-3" />
                          )}
                          {payment.method}
                        </span>
                      </td>
                      <td className="px-6 py-3">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${
                            payment.status === 'completed'
                              ? 'bg-green-100 text-green-700'
                              : payment.status === 'pending'
                              ? 'bg-yellow-100 text-yellow-700'
                              : 'bg-red-100 text-red-700'
                          }`}
                        >
                          {payment.status}
                        </span>
                      </td>
                      <td className="px-6 py-3 text-gray-500 text-xs">
                        {payment.created_at
                          ? new Date(payment.created_at).toLocaleDateString()
                          : '-'}
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
    </div>
  );
};

const SummaryCard: React.FC<{
  title: string;
  value: string;
  icon: React.ReactNode;
  color: string;
  trend?: string;
  trendUp?: boolean;
}> = ({ title, value, icon, color, trend, trendUp }) => (
  <div className="bg-white rounded-xl border border-gray-200 p-5">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-sm text-gray-500">{title}</p>
        <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
        {trend && (
          <div
            className={`flex items-center gap-0.5 mt-1 text-xs font-medium ${
              trendUp ? 'text-green-600' : 'text-red-600'
            }`}
          >
            {trendUp ? (
              <ArrowUpRight className="w-3 h-3" />
            ) : (
              <ArrowDownRight className="w-3 h-3" />
            )}
            {trend}
          </div>
        )}
      </div>
      <div
        className={`w-12 h-12 rounded-xl flex items-center justify-center ${color}`}
      >
        {icon}
      </div>
    </div>
  </div>
);

export default PaymentsPage;
