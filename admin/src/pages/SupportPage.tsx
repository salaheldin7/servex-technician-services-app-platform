import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supportApi } from '../services/api';
import {
  ChevronLeft,
  ChevronRight,
  MessageSquare,
  Clock,
  CheckCircle,
  XCircle,
  Send,
  X,
  User,
} from 'lucide-react';
import toast from 'react-hot-toast';

const STATUS_FILTERS = ['all', 'open', 'in_progress', 'closed'];

const STATUS_STYLES: Record<string, string> = {
  open: 'bg-yellow-100 text-yellow-700',
  in_progress: 'bg-blue-100 text-blue-700',
  closed: 'bg-green-100 text-green-700',
};

const STATUS_ICONS: Record<string, React.ReactNode> = {
  open: <Clock className="w-3 h-3" />,
  in_progress: <MessageSquare className="w-3 h-3" />,
  closed: <CheckCircle className="w-3 h-3" />,
};

const SupportPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedTicket, setSelectedTicket] = useState<any | null>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [replyText, setReplyText] = useState('');
  const [loadingMessages, setLoadingMessages] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['support-tickets', page, statusFilter],
    queryFn: () =>
      supportApi.listTickets({
        page,
        status: statusFilter !== 'all' ? statusFilter : undefined,
      }),
  });

  const replyMutation = useMutation({
    mutationFn: ({ id, message }: { id: string; message: string }) =>
      supportApi.reply(id, message),
    onSuccess: () => {
      toast.success('Reply sent');
      if (selectedTicket) loadMessages(selectedTicket.id);
      setReplyText('');
      queryClient.invalidateQueries({ queryKey: ['support-tickets'] });
    },
    onError: (error: any) => {
      const msg = error?.response?.data?.error || 'Failed to send reply';
      toast.error(msg);
    },
  });

  const closeMutation = useMutation({
    mutationFn: (id: string) => supportApi.close(id),
    onSuccess: () => {
      toast.success('Ticket closed');
      queryClient.invalidateQueries({ queryKey: ['support-tickets'] });
      setSelectedTicket(null);
    },
    onError: () => toast.error('Failed to close ticket'),
  });

  const tickets = data?.data?.tickets || [];
  const total = data?.data?.total || 0;
  const totalPages = Math.ceil(total / 20);

  const loadMessages = async (ticketId: string) => {
    setLoadingMessages(true);
    try {
      const res = await supportApi.getMessages(ticketId);
      setMessages(res.data?.messages || []);
    } catch {
      toast.error('Failed to load messages');
    }
    setLoadingMessages(false);
  };

  const openTicket = async (ticket: any) => {
    setSelectedTicket(ticket);
    await loadMessages(ticket.id);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Support Tickets</h1>
        <p className="text-gray-500 text-sm mt-1">
          Manage customer support requests
        </p>
      </div>

      {/* Filters */}
      <div className="flex gap-2">
        {STATUS_FILTERS.map((s) => (
          <button
            key={s}
            onClick={() => {
              setStatusFilter(s);
              setPage(1);
            }}
            className={`px-3 py-2 rounded-lg text-sm font-medium capitalize transition-colors ${
              statusFilter === s
                ? 'bg-primary-100 text-primary-700'
                : 'bg-white border border-gray-300 text-gray-600 hover:bg-gray-50'
            }`}
          >
            {s.replace('_', ' ')}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
        {/* Ticket List */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
            {isLoading ? (
              <div className="flex items-center justify-center h-64">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
              </div>
            ) : tickets.length === 0 ? (
              <div className="p-8 text-center text-gray-400">
                <MessageSquare className="w-10 h-10 mx-auto mb-3 text-gray-300" />
                <p>No tickets found</p>
              </div>
            ) : (
              <div className="divide-y divide-gray-100">
                {tickets.map((ticket: any) => (
                  <button
                    key={ticket.id}
                    onClick={() => openTicket(ticket)}
                    className={`w-full text-left px-4 py-4 hover:bg-gray-50 transition-colors ${
                      selectedTicket?.id === ticket.id ? 'bg-primary-50' : ''
                    }`}
                  >
                    <div className="flex items-start justify-between mb-1">
                      <h4 className="font-medium text-gray-900 text-sm line-clamp-1">
                        {ticket.subject}
                      </h4>
                      <span
                        className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-xs font-medium flex-shrink-0 ml-2 ${
                          STATUS_STYLES[ticket.status] ||
                          'bg-gray-100 text-gray-700'
                        }`}
                      >
                        {STATUS_ICONS[ticket.status]}
                        {ticket.status?.replace('_', ' ')}
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 line-clamp-2">
                      {ticket.message || ticket.description || '-'}
                    </p>
                    <div className="flex items-center justify-between mt-2">
                      <span className="text-xs text-gray-400">
                        {ticket.user_name || 'Unknown user'}
                      </span>
                      <span className="text-xs text-gray-400">
                        {ticket.created_at
                          ? new Date(ticket.created_at).toLocaleDateString()
                          : ''}
                      </span>
                    </div>
                  </button>
                ))}
              </div>
            )}

            {totalPages > 1 && (
              <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="p-1 rounded text-gray-500 hover:bg-gray-100 disabled:opacity-30"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <span className="text-xs text-gray-500">
                  {page} / {totalPages}
                </span>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="p-1 rounded text-gray-500 hover:bg-gray-100 disabled:opacity-30"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Ticket Detail / Messages */}
        <div className="lg:col-span-3">
          {selectedTicket ? (
            <div className="bg-white rounded-xl border border-gray-200 flex flex-col h-[600px]">
              {/* Ticket Header */}
              <div className="px-6 py-4 border-b border-gray-200">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="font-semibold text-gray-900">
                      {selectedTicket.subject}
                    </h3>
                    <div className="flex items-center gap-3 mt-1">
                      <span className="text-xs text-gray-500">
                        #{selectedTicket.id?.slice(0, 8)}
                      </span>
                      <span className="text-xs text-gray-500">
                        {selectedTicket.category}
                      </span>
                      <span
                        className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-xs font-medium ${
                          STATUS_STYLES[selectedTicket.status] ||
                          'bg-gray-100 text-gray-700'
                        }`}
                      >
                        {selectedTicket.status?.replace('_', ' ')}
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {selectedTicket.status !== 'closed' && (
                      <button
                        onClick={() => closeMutation.mutate(selectedTicket.id)}
                        className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-red-600 border border-red-200 rounded-lg hover:bg-red-50"
                      >
                        <XCircle className="w-3.5 h-3.5" />
                        Close
                      </button>
                    )}
                    <button
                      onClick={() => setSelectedTicket(null)}
                      className="text-gray-400 hover:text-gray-600"
                    >
                      <X className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {/* Original message */}
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 bg-blue-100 text-blue-700 rounded-full flex items-center justify-center flex-shrink-0">
                    <User className="w-4 h-4" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-sm font-medium text-gray-900">
                        {selectedTicket.user_name || 'Customer'}
                      </span>
                      <span className="text-xs text-gray-400">
                        {selectedTicket.created_at
                          ? new Date(
                              selectedTicket.created_at
                            ).toLocaleString()
                          : ''}
                      </span>
                    </div>
                    <div className="bg-gray-100 rounded-lg rounded-tl-sm p-3 text-sm text-gray-700">
                      {selectedTicket.message ||
                        selectedTicket.description ||
                        '-'}
                    </div>
                  </div>
                </div>

                {loadingMessages ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-600" />
                  </div>
                ) : (
                  messages.map((msg: any) => {
                    const isAdmin = msg.is_admin === true;
                    return (
                      <div
                        key={msg.id}
                        className={`flex items-start gap-3 ${
                          isAdmin ? 'flex-row-reverse' : ''
                        }`}
                      >
                        <div
                          className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                            isAdmin
                              ? 'bg-primary-100 text-primary-700'
                              : 'bg-blue-100 text-blue-700'
                          }`}
                        >
                          <User className="w-4 h-4" />
                        </div>
                        <div className={`flex-1 ${isAdmin ? 'text-right' : ''}`}>
                          <div
                            className={`flex items-center gap-2 mb-1 ${
                              isAdmin ? 'justify-end' : ''
                            }`}
                          >
                            <span className="text-sm font-medium text-gray-900">
                              {isAdmin ? 'Admin' : msg.sender_name || 'User'}
                            </span>
                            <span className="text-xs text-gray-400">
                              {msg.created_at
                                ? new Date(msg.created_at).toLocaleString()
                                : ''}
                            </span>
                          </div>
                          <div
                            className={`inline-block rounded-lg p-3 text-sm max-w-[85%] ${
                              isAdmin
                                ? 'bg-primary-50 text-primary-900 rounded-tr-sm'
                                : 'bg-gray-100 text-gray-700 rounded-tl-sm'
                            }`}
                          >
                            {msg.content}
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>

              {/* Reply Input */}
              {selectedTicket.status !== 'closed' && (
                <div className="px-4 py-3 border-t border-gray-200">
                  <div className="flex items-end gap-2">
                    <textarea
                      value={replyText}
                      onChange={(e) => setReplyText(e.target.value)}
                      placeholder="Type your reply..."
                      rows={2}
                      className="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none resize-none"
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && !e.shiftKey) {
                          e.preventDefault();
                          if (replyText.trim()) {
                            replyMutation.mutate({
                              id: selectedTicket.id,
                              message: replyText,
                            });
                          }
                        }
                      }}
                    />
                    <button
                      onClick={() => {
                        if (replyText.trim()) {
                          replyMutation.mutate({
                            id: selectedTicket.id,
                            message: replyText,
                          });
                        }
                      }}
                      disabled={!replyText.trim() || replyMutation.isPending}
                      className="p-2.5 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 transition-colors"
                    >
                      <Send className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-gray-200 flex items-center justify-center h-[600px]">
              <div className="text-center">
                <MessageSquare className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                <p className="text-gray-500 text-sm">
                  Select a ticket to view details
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default SupportPage;
