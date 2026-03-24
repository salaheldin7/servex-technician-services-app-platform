import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { usersApi } from '../services/api';
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Ban,
  CheckCircle,
  MoreVertical,
  User,
  Trash2,
  KeyRound,
  X,
  Eye,
} from 'lucide-react';
import toast from 'react-hot-toast';

const ROLES = ['all', 'customer', 'technician', 'admin'];

const UsersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [actionMenu, setActionMenu] = useState<string | null>(null);
  const [menuPos, setMenuPos] = useState<{ top: number; right: number } | null>(null);
  const [selectedUser, setSelectedUser] = useState<any | null>(null);
  const [resetPasswordDialog, setResetPasswordDialog] = useState<string | null>(null);
  const [newPassword, setNewPassword] = useState('');
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const limit = 20;

  const { data, isLoading } = useQuery({
    queryKey: ['users', page, roleFilter],
    queryFn: () =>
      usersApi.list({
        page,
        limit,
        role: roleFilter !== 'all' ? roleFilter : undefined,
      }),
  });

  const banMutation = useMutation({
    mutationFn: (id: string) => usersApi.ban(id),
    onSuccess: () => {
      toast.success('User banned successfully');
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
    onError: () => toast.error('Failed to ban user'),
  });

  const unbanMutation = useMutation({
    mutationFn: (id: string) => usersApi.unban(id),
    onSuccess: () => {
      toast.success('User unbanned successfully');
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
    onError: () => toast.error('Failed to unban user'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => usersApi.delete(id),
    onSuccess: () => {
      toast.success('User deleted successfully');
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setDeleteConfirm(null);
    },
    onError: () => toast.error('Failed to delete user'),
  });

  const resetPasswordMutation = useMutation({
    mutationFn: ({ id, password }: { id: string; password: string }) =>
      usersApi.resetPassword(id, password),
    onSuccess: () => {
      toast.success('Password reset successfully');
      setResetPasswordDialog(null);
      setNewPassword('');
    },
    onError: () => toast.error('Failed to reset password'),
  });

  const users = data?.data?.users || [];
  const total = data?.data?.total || 0;
  const totalPages = Math.ceil(total / limit);

  const filteredUsers = search
    ? users.filter(
        (u: any) =>
          u.full_name?.toLowerCase().includes(search.toLowerCase()) ||
          u.email?.toLowerCase().includes(search.toLowerCase()) ||
          u.phone?.includes(search)
      )
    : users;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Users</h1>
        <p className="text-gray-500 text-sm mt-1">Manage platform users</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name, email, or phone..."
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
          />
        </div>
        <div className="flex gap-2">
          {ROLES.map((role) => (
            <button
              key={role}
              onClick={() => {
                setRoleFilter(role);
                setPage(1);
              }}
              className={`px-3 py-2 rounded-lg text-sm font-medium capitalize transition-colors ${
                roleFilter === role
                  ? 'bg-primary-100 text-primary-700'
                  : 'bg-white border border-gray-300 text-gray-600 hover:bg-gray-50'
              }`}
            >
              {role}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-gray-200">
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
                    User
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Phone
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Role
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Status
                  </th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Joined
                  </th>
                  <th className="text-right px-6 py-3 text-xs font-medium text-gray-500 uppercase">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filteredUsers.length === 0 ? (
                  <tr>
                    <td
                      colSpan={6}
                      className="px-6 py-8 text-center text-gray-400"
                    >
                      No users found
                    </td>
                  </tr>
                ) : (
                  filteredUsers.map((user: any) => (
                    <tr key={user.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center">
                            <User className="w-4 h-4" />
                          </div>
                          <div>
                            <p className="font-medium text-gray-900">
                              {user.full_name}
                            </p>
                            <p className="text-xs text-gray-500">{user.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-gray-600">{user.phone}</td>
                      <td className="px-6 py-4">
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize ${
                            user.role === 'admin'
                              ? 'bg-red-100 text-red-700'
                              : user.role === 'technician'
                              ? 'bg-purple-100 text-purple-700'
                              : 'bg-blue-100 text-blue-700'
                          }`}
                        >
                          {user.role}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        {user.is_active ? (
                          <span className="inline-flex items-center gap-1 text-xs text-green-600">
                            <CheckCircle className="w-3.5 h-3.5" /> Active
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-xs text-red-600">
                            <Ban className="w-3.5 h-3.5" /> Banned
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-gray-500 text-xs">
                        {user.created_at
                          ? new Date(user.created_at).toLocaleDateString()
                          : '-'}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="relative inline-block">
                          <button
                            onClick={(e) => {
                              if (actionMenu === user.id) {
                                setActionMenu(null);
                                setMenuPos(null);
                              } else {
                                const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
                                setMenuPos({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
                                setActionMenu(user.id);
                              }
                            }}
                            className="p-1 text-gray-400 hover:text-gray-600 rounded"
                          >
                            <MoreVertical className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
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

      {/* Fixed-position Action Menu (rendered outside table to avoid overflow clipping) */}
      {actionMenu && menuPos && (() => {
        const user = users.find((u: any) => u.id === actionMenu);
        if (!user) return null;
        return (
          <>
            <div className="fixed inset-0 z-30" onClick={() => { setActionMenu(null); setMenuPos(null); }} />
            <div
              className="fixed w-44 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-40"
              style={{ top: menuPos.top, right: menuPos.right }}
            >
              <button
                onClick={() => {
                  setSelectedUser(user);
                  setActionMenu(null);
                  setMenuPos(null);
                }}
                className="w-full flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
              >
                <Eye className="w-4 h-4" /> View Details
              </button>
              <button
                onClick={() => {
                  setResetPasswordDialog(user.id);
                  setNewPassword('');
                  setActionMenu(null);
                  setMenuPos(null);
                }}
                className="w-full flex items-center gap-2 px-3 py-2 text-sm text-blue-600 hover:bg-blue-50"
              >
                <KeyRound className="w-4 h-4" /> Reset Password
              </button>
              {user.is_active ? (
                <button
                  onClick={() => {
                    banMutation.mutate(user.id);
                    setActionMenu(null);
                    setMenuPos(null);
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2 text-sm text-orange-600 hover:bg-orange-50"
                >
                  <Ban className="w-4 h-4" /> Ban User
                </button>
              ) : (
                <button
                  onClick={() => {
                    unbanMutation.mutate(user.id);
                    setActionMenu(null);
                    setMenuPos(null);
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2 text-sm text-green-600 hover:bg-green-50"
                >
                  <CheckCircle className="w-4 h-4" /> Unban
                </button>
              )}
              <div className="border-t border-gray-100 my-1" />
              <button
                onClick={() => {
                  setDeleteConfirm(user.id);
                  setActionMenu(null);
                  setMenuPos(null);
                }}
                className="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50"
              >
                <Trash2 className="w-4 h-4" /> Delete User
              </button>
            </div>
          </>
        );
      })()}

      {/* User Detail Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl max-w-md w-full">
            <div className="flex items-center justify-between px-6 py-4 border-b">
              <h3 className="text-lg font-semibold">User Details</h3>
              <button onClick={() => setSelectedUser(null)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center">
                  <User className="w-7 h-7" />
                </div>
                <div>
                  <h4 className="text-lg font-semibold text-gray-900">{selectedUser.full_name}</h4>
                  <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize ${
                    selectedUser.role === 'admin' ? 'bg-red-100 text-red-700' :
                    selectedUser.role === 'technician' ? 'bg-purple-100 text-purple-700' :
                    'bg-blue-100 text-blue-700'
                  }`}>{selectedUser.role}</span>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div>
                  <p className="text-gray-400 text-xs uppercase">Email</p>
                  <p className="text-gray-800">{selectedUser.email}</p>
                </div>
                <div>
                  <p className="text-gray-400 text-xs uppercase">Phone</p>
                  <p className="text-gray-800">{selectedUser.phone || '-'}</p>
                </div>
                <div>
                  <p className="text-gray-400 text-xs uppercase">Status</p>
                  <p className={selectedUser.is_active ? 'text-green-600' : 'text-red-600'}>
                    {selectedUser.is_active ? 'Active' : 'Banned'}
                  </p>
                </div>
                <div>
                  <p className="text-gray-400 text-xs uppercase">Joined</p>
                  <p className="text-gray-800">
                    {selectedUser.created_at ? new Date(selectedUser.created_at).toLocaleDateString() : '-'}
                  </p>
                </div>
              </div>
              <div className="flex gap-2 pt-2">
                <button
                  onClick={() => {
                    setResetPasswordDialog(selectedUser.id);
                    setNewPassword('');
                    setSelectedUser(null);
                  }}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-50 text-blue-700 rounded-lg text-sm font-medium hover:bg-blue-100"
                >
                  <KeyRound className="w-4 h-4" /> Reset Password
                </button>
                {selectedUser.is_active ? (
                  <button
                    onClick={() => {
                      banMutation.mutate(selectedUser.id);
                      setSelectedUser(null);
                    }}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-orange-50 text-orange-700 rounded-lg text-sm font-medium hover:bg-orange-100"
                  >
                    <Ban className="w-4 h-4" /> Ban
                  </button>
                ) : (
                  <button
                    onClick={() => {
                      unbanMutation.mutate(selectedUser.id);
                      setSelectedUser(null);
                    }}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-green-50 text-green-700 rounded-lg text-sm font-medium hover:bg-green-100"
                  >
                    <CheckCircle className="w-4 h-4" /> Unban
                  </button>
                )}
                <button
                  onClick={() => {
                    setDeleteConfirm(selectedUser.id);
                    setSelectedUser(null);
                  }}
                  className="flex items-center justify-center gap-2 px-4 py-2 bg-red-50 text-red-700 rounded-lg text-sm font-medium hover:bg-red-100"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Reset Password Dialog */}
      {resetPasswordDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl max-w-sm w-full">
            <div className="flex items-center justify-between px-6 py-4 border-b">
              <h3 className="text-lg font-semibold">Reset Password</h3>
              <button onClick={() => { setResetPasswordDialog(null); setNewPassword(''); }} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <p className="text-sm text-gray-500">Enter a new password for this user.</p>
              <input
                type="text"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="New password (min 8 characters)"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
              />
              <div className="flex gap-3">
                <button
                  onClick={() => { setResetPasswordDialog(null); setNewPassword(''); }}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    if (newPassword.length < 8) {
                      toast.error('Password must be at least 8 characters');
                      return;
                    }
                    resetPasswordMutation.mutate({ id: resetPasswordDialog, password: newPassword });
                  }}
                  disabled={resetPasswordMutation.isPending}
                  className="flex-1 px-4 py-2 bg-primary-600 text-white rounded-lg text-sm font-medium hover:bg-primary-700 disabled:opacity-50"
                >
                  {resetPasswordMutation.isPending ? 'Resetting...' : 'Reset Password'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Dialog */}
      {deleteConfirm && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-xl max-w-sm w-full">
            <div className="p-6 space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                  <Trash2 className="w-5 h-5 text-red-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">Delete User</h3>
                  <p className="text-sm text-gray-500">This action cannot be undone.</p>
                </div>
              </div>
              <p className="text-sm text-gray-600">
                Are you sure you want to permanently delete this user and all their associated data?
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setDeleteConfirm(null)}
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={() => deleteMutation.mutate(deleteConfirm)}
                  disabled={deleteMutation.isPending}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50"
                >
                  {deleteMutation.isPending ? 'Deleting...' : 'Delete'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UsersPage;
