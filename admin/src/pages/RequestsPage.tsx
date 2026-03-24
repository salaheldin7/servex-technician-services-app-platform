import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { techniciansApi } from '../services/api';
import {
  Search,
  ChevronLeft,
  ChevronRight,
  CheckCircle,
  AlertTriangle,
  Wrench,
  Eye,
  X,
  Camera,
  FileText,
  Shield,
  ShieldCheck,
  ShieldX,
  Clock,
  Mail,
  Phone,
} from 'lucide-react';
import toast from 'react-hot-toast';

const API_BASE = import.meta.env.VITE_API_URL?.replace('/api/v1', '') || '';

const RequestsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [selectedTech, setSelectedTech] = useState<any | null>(null);
  const [verificationDetail, setVerificationDetail] = useState<any | null>(null);
  const [activeTab, setActiveTab] = useState<'info' | 'verification'>('verification');
  const [showRejectDialog, setShowRejectDialog] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const limit = 20;

  const { data, isLoading } = useQuery({
    queryKey: ['technician-requests', page],
    queryFn: () =>
      techniciansApi.list({
        page,
        limit,
        verified: false,
        status: 'none,pending,face_done,docs_done',
      }),
  });

  const verifyMutation = useMutation({
    mutationFn: (id: string) => techniciansApi.verify(id),
    onSuccess: () => {
      toast.success('Technician approved');
      queryClient.invalidateQueries({ queryKey: ['technician-requests'] });
      queryClient.invalidateQueries({ queryKey: ['technicians'] });
      setSelectedTech(null);
      setVerificationDetail(null);
    },
    onError: () => toast.error('Approval failed'),
  });

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) =>
      techniciansApi.reject(id, reason),
    onSuccess: () => {
      toast.success('Technician rejected');
      queryClient.invalidateQueries({ queryKey: ['technician-requests'] });
      queryClient.invalidateQueries({ queryKey: ['technicians'] });
      setSelectedTech(null);
      setVerificationDetail(null);
      setShowRejectDialog(null);
      setRejectReason('');
    },
    onError: () => toast.error('Rejection failed'),
  });

  const technicians = data?.data?.technicians || [];
  const total = data?.data?.total || 0;
  const totalPages = Math.ceil(total / limit);

  const filteredTechnicians = search
    ? technicians.filter(
        (t: any) =>
          t.full_name?.toLowerCase().includes(search.toLowerCase()) ||
          t.phone?.includes(search) ||
          t.email?.toLowerCase().includes(search.toLowerCase())
      )
    : technicians;

  const openDetails = (tech: any) => {
    setSelectedTech(tech);
    setActiveTab('verification');
    techniciansApi
      .getVerification(tech.id)
      .then((res) => setVerificationDetail(res.data))
      .catch(() => setVerificationDetail(null));
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Verification Requests</h1>
        <p className="text-gray-500 text-sm mt-1">
          Review and approve technician verification requests
        </p>
      </div>

      {/* Search */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search by name, phone, or email..."
          className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
        />
      </div>

      {/* Stats */}
      <div className="flex items-center gap-4">
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg px-4 py-3 flex items-center gap-3">
          <Clock className="w-5 h-5 text-yellow-600" />
          <div>
            <p className="text-2xl font-bold text-yellow-700">{total}</p>
            <p className="text-xs text-yellow-600">Pending Requests</p>
          </div>
        </div>
      </div>

      {/* Cards grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {isLoading ? (
          <div className="col-span-full flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
          </div>
        ) : filteredTechnicians.length === 0 ? (
          <div className="col-span-full flex flex-col items-center justify-center h-64 text-gray-400">
            <CheckCircle className="w-12 h-12 mb-3 text-green-300" />
            <p className="text-lg font-medium text-gray-500">No pending requests</p>
            <p className="text-sm">All technician verifications are up to date</p>
          </div>
        ) : (
          filteredTechnicians.map((tech: any) => (
            <div
              key={tech.id}
              className="bg-white rounded-xl border border-gray-200 p-5 hover:border-primary-300 hover:shadow-md transition-all cursor-pointer"
              onClick={() => openDetails(tech)}
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className={`w-11 h-11 rounded-full flex items-center justify-center ${
                    tech.verification_status === 'rejected'
                      ? 'bg-red-100 text-red-700'
                      : 'bg-yellow-100 text-yellow-700'
                  }`}>
                    <Wrench className="w-5 h-5" />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900">{tech.full_name}</p>
                    {tech.verification_status === 'rejected' ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">
                        <ShieldX className="w-3 h-3" /> Rejected
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700">
                        <AlertTriangle className="w-3 h-3" /> Pending Verification
                      </span>
                    )}
                  </div>
                </div>
              </div>

              {tech.rejection_reason && (
                <div className="mb-3 p-2 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-xs text-red-600 font-medium">Rejection Reason:</p>
                  <p className="text-xs text-red-700 mt-0.5">{tech.rejection_reason}</p>
                </div>
              )}

              <div className="space-y-2 text-sm">
                <div className="flex items-center gap-2 text-gray-600">
                  <Mail className="w-3.5 h-3.5 text-gray-400" />
                  <span className="truncate">{tech.email || 'No email'}</span>
                </div>
                <div className="flex items-center gap-2 text-gray-600">
                  <Phone className="w-3.5 h-3.5 text-gray-400" />
                  <span>{tech.phone || 'No phone'}</span>
                </div>
              </div>

              <div className="flex gap-2 mt-4 pt-3 border-t border-gray-100">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    verifyMutation.mutate(tech.id);
                  }}
                  className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-sm text-white bg-green-600 rounded-lg hover:bg-green-700 transition-colors"
                >
                  <ShieldCheck className="w-3.5 h-3.5" /> Approve
                </button>
                {tech.verification_status !== 'rejected' && (
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowRejectDialog(tech.id);
                  }}
                  className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-sm text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors"
                >
                  <ShieldX className="w-3.5 h-3.5" /> Reject
                </button>
                )}
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    openDetails(tech);
                  }}
                  className="flex items-center justify-center gap-1.5 px-3 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  <Eye className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-gray-500">
            Showing {(page - 1) * limit + 1}-{Math.min(page * limit, total)} of {total}
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

      {/* Detail Modal */}
      {selectedTech && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">
                Verification Request Details
              </h3>
              <button
                onClick={() => {
                  setSelectedTech(null);
                  setVerificationDetail(null);
                }}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Tabs */}
            <div className="flex border-b border-gray-200">
              <button
                onClick={() => setActiveTab('info')}
                className={`flex-1 py-3 text-sm font-medium text-center border-b-2 transition-colors ${
                  activeTab === 'info'
                    ? 'border-primary-600 text-primary-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                Profile Info
              </button>
              <button
                onClick={() => setActiveTab('verification')}
                className={`flex-1 py-3 text-sm font-medium text-center border-b-2 transition-colors ${
                  activeTab === 'verification'
                    ? 'border-primary-600 text-primary-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700'
                }`}
              >
                <div className="flex items-center justify-center gap-1.5">
                  <Shield className="w-4 h-4" />
                  Verification Data
                </div>
              </button>
            </div>

            <div className="p-6">
              {activeTab === 'info' ? (
                <div className="space-y-4">
                  <div className="flex items-center gap-4">
                    <div className="w-14 h-14 bg-yellow-100 text-yellow-700 rounded-full flex items-center justify-center">
                      <Wrench className="w-7 h-7" />
                    </div>
                    <div>
                      <h4 className="text-lg font-semibold text-gray-900">
                        {selectedTech.full_name}
                      </h4>
                      <p className="text-sm text-gray-500">
                        {selectedTech.email} • {selectedTech.phone}
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <InfoCard label="Email" value={selectedTech.email || 'N/A'} />
                    <InfoCard label="Phone" value={selectedTech.phone || 'N/A'} />
                    <InfoCard
                      label="Status"
                      value={selectedTech.is_verified ? '✅ Verified' : selectedTech.verification_status === 'rejected' ? '❌ Rejected' : '⏳ Pending'}
                    />
                    <InfoCard
                      label="Online"
                      value={selectedTech.is_online ? '🟢 Online' : '⚫ Offline'}
                    />
                  </div>

                  {selectedTech.bio && (
                    <div>
                      <label className="text-xs font-medium text-gray-500 uppercase">
                        Bio
                      </label>
                      <p className="text-sm text-gray-700 mt-1">{selectedTech.bio}</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="space-y-6">
                  {!verificationDetail ? (
                    <div className="text-center py-8 text-gray-400">
                      <Shield className="w-12 h-12 mx-auto mb-3 opacity-50" />
                      <p>No verification data uploaded yet</p>
                    </div>
                  ) : (
                    <>
                      <div className="flex items-center gap-3 p-3 rounded-lg bg-gray-50">
                        <Shield
                          className={`w-5 h-5 ${
                            verificationDetail.verification_status === 'verified'
                              ? 'text-green-600'
                              : verificationDetail.verification_status === 'rejected'
                              ? 'text-red-600'
                              : 'text-yellow-600'
                          }`}
                        />
                        <div>
                          <p className="text-sm font-medium text-gray-900">
                            Status:{' '}
                            <span className="capitalize">
                              {verificationDetail.verification_status}
                            </span>
                          </p>
                          <p className="text-xs text-gray-500">
                            {verificationDetail.full_name} •{' '}
                            {verificationDetail.email}
                          </p>
                        </div>
                      </div>

                      {verificationDetail.rejection_reason && (
                        <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
                          <p className="text-xs font-medium text-red-600">Rejection Reason:</p>
                          <p className="text-sm text-red-700 mt-1">{verificationDetail.rejection_reason}</p>
                        </div>
                      )}

                      {/* Face Photos */}
                      <div>
                        <h4 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                          <Camera className="w-4 h-4" /> Face Verification Photos
                        </h4>
                        {verificationDetail.face_front_url ? (
                          <div className="grid grid-cols-3 gap-3">
                            {[
                              { label: 'Front', url: verificationDetail.face_front_url },
                              { label: 'Right', url: verificationDetail.face_right_url },
                              { label: 'Left', url: verificationDetail.face_left_url },
                            ].map((photo) => (
                              <div key={photo.label} className="space-y-1">
                                <p className="text-xs text-gray-500 font-medium text-center">
                                  {photo.label}
                                </p>
                                <div className="aspect-square rounded-lg border border-gray-200 overflow-hidden bg-gray-100">
                                  {photo.url ? (
                                    <img
                                      src={`${API_BASE}/${photo.url}`}
                                      alt={`Face ${photo.label}`}
                                      className="w-full h-full object-cover"
                                      onError={(e) => {
                                        (e.target as HTMLImageElement).style.display = 'none';
                                        (e.target as HTMLImageElement).parentElement!.innerHTML =
                                          '<div class="flex items-center justify-center h-full text-gray-400 text-xs">Not loaded</div>';
                                      }}
                                    />
                                  ) : (
                                    <div className="flex items-center justify-center h-full text-gray-400 text-xs">
                                      Not uploaded
                                    </div>
                                  )}
                                </div>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <p className="text-sm text-gray-400 text-center py-4">
                            No face photos uploaded
                          </p>
                        )}
                      </div>

                      {/* ID Documents */}
                      <div>
                        <h4 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                          <FileText className="w-4 h-4" /> National ID Documents
                        </h4>
                        {verificationDetail.documents &&
                        verificationDetail.documents.length > 0 ? (
                          <div className="grid grid-cols-2 gap-3">
                            {verificationDetail.documents.map((doc: any) => (
                              <div key={doc.id} className="space-y-1">
                                <p className="text-xs text-gray-500 font-medium text-center capitalize">
                                  {doc.doc_type.replace(/_/g, ' ')}
                                </p>
                                <div className="aspect-[4/3] rounded-lg border border-gray-200 overflow-hidden bg-gray-100">
                                  {doc.file_type === 'pdf' ? (
                                    <div className="flex flex-col items-center justify-center h-full">
                                      <FileText className="w-8 h-8 text-red-500 mb-1" />
                                      <a
                                        href={`${API_BASE}/${doc.file_url}`}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="text-xs text-primary-600 hover:underline"
                                      >
                                        View PDF
                                      </a>
                                    </div>
                                  ) : (
                                    <img
                                      src={`${API_BASE}/${doc.file_url}`}
                                      alt={doc.doc_type}
                                      className="w-full h-full object-cover"
                                      onError={(e) => {
                                        (e.target as HTMLImageElement).style.display = 'none';
                                        (e.target as HTMLImageElement).parentElement!.innerHTML =
                                          '<div class="flex items-center justify-center h-full text-gray-400 text-xs">Not loaded</div>';
                                      }}
                                    />
                                  )}
                                </div>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <p className="text-sm text-gray-400 text-center py-4">
                            No ID documents uploaded
                          </p>
                        )}
                      </div>
                    </>
                  )}

                  {/* Action buttons */}
                  <div className="flex gap-3 pt-4 border-t border-gray-200">
                    <button
                      onClick={() => verifyMutation.mutate(selectedTech.id)}
                      className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 text-sm text-white bg-green-600 rounded-lg hover:bg-green-700"
                    >
                      <ShieldCheck className="w-4 h-4" /> Approve Technician
                    </button>
                    {selectedTech.verification_status !== 'rejected' && (
                    <button
                      onClick={() => setShowRejectDialog(selectedTech.id)}
                      className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 text-sm text-white bg-red-600 rounded-lg hover:bg-red-700"
                    >
                      <ShieldX className="w-4 h-4" /> Reject Technician
                    </button>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
      {/* Rejection Reason Dialog */}
      {showRejectDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[60] p-4">
          <div className="bg-white rounded-xl max-w-md w-full p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">Reject Technician</h3>
            <p className="text-sm text-gray-500 mb-4">
              Please provide a reason for rejection. This will be sent to the technician.
            </p>
            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              placeholder="Enter rejection reason..."
              rows={3}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none resize-none mb-4"
            />
            <div className="flex gap-3">
              <button
                onClick={() => {
                  setShowRejectDialog(null);
                  setRejectReason('');
                }}
                className="flex-1 px-4 py-2 text-sm font-medium text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  if (!rejectReason.trim()) {
                    toast.error('Please provide a rejection reason');
                    return;
                  }
                  rejectMutation.mutate({
                    id: showRejectDialog,
                    reason: rejectReason.trim(),
                  });
                }}
                disabled={rejectMutation.isPending}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                <ShieldX className="w-4 h-4" />
                {rejectMutation.isPending ? 'Rejecting...' : 'Reject'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const InfoCard: React.FC<{ label: string; value: string | number }> = ({
  label,
  value,
}) => (
  <div className="bg-gray-50 rounded-lg p-3">
    <p className="text-xs text-gray-500">{label}</p>
    <p className="text-lg font-semibold text-gray-900 mt-0.5">{value}</p>
  </div>
);

export default RequestsPage;
