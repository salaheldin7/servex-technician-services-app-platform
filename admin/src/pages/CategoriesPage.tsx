import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { categoriesApi } from '../services/api';
import {
  Plus,
  Edit2,
  Trash2,
  Wrench,
  Home,
  X,
  Save,
  Zap,
  Droplets,
  Hammer,
  Paintbrush,
  Snowflake,
  SprayCan,
  Refrigerator,
  Shield,
  Monitor,
  Bug,
  Trees,
  Waves,
  Lock,
  Pencil,
  Car,
  Wind,
  HardHat,
  Truck,
  Satellite,
  Camera,
  Sun,
  Leaf,
  Droplet,
  BatteryCharging,
  Sparkles,
  CircleDot,
  Shirt,
  Microwave,
  ArrowUpDown,
  AppWindow,
  DoorOpen,
  Building2,
  Store,
  Factory,
  Landmark,
  GraduationCap,
  Hotel,
  Heart,
  UtensilsCrossed,
  Users,
  Church,
  CarFront,
  Banknote,
  type LucideIcon,
} from 'lucide-react';
import toast from 'react-hot-toast';

// Icon + color mapping for category icon keys
const SERVICE_ICONS: Record<string, { icon: LucideIcon; color: string; bg: string }> = {
  electrical_services: { icon: Zap, color: 'text-amber-600', bg: 'bg-amber-50' },
  plumbing: { icon: Droplets, color: 'text-blue-600', bg: 'bg-blue-50' },
  carpenter: { icon: Hammer, color: 'text-amber-800', bg: 'bg-amber-50' },
  format_paint: { icon: Paintbrush, color: 'text-violet-600', bg: 'bg-violet-50' },
  ac_unit: { icon: Snowflake, color: 'text-cyan-600', bg: 'bg-cyan-50' },
  cleaning_services: { icon: SprayCan, color: 'text-emerald-600', bg: 'bg-emerald-50' },
  kitchen: { icon: Refrigerator, color: 'text-orange-600', bg: 'bg-orange-50' },
  security: { icon: Shield, color: 'text-blue-700', bg: 'bg-blue-50' },
  computer: { icon: Monitor, color: 'text-indigo-600', bg: 'bg-indigo-50' },
  pest_control: { icon: Bug, color: 'text-red-600', bg: 'bg-red-50' },
  yard: { icon: Trees, color: 'text-lime-600', bg: 'bg-lime-50' },
  pool: { icon: Waves, color: 'text-teal-600', bg: 'bg-teal-50' },
  lock: { icon: Lock, color: 'text-slate-600', bg: 'bg-slate-50' },
  design_services: { icon: Pencil, color: 'text-pink-600', bg: 'bg-pink-50' },
  handyman: { icon: Wrench, color: 'text-orange-700', bg: 'bg-orange-50' },
  car_repair: { icon: Car, color: 'text-red-700', bg: 'bg-red-50' },
  build: { icon: HardHat, color: 'text-purple-700', bg: 'bg-purple-50' },
  roofing: { icon: Home, color: 'text-amber-800', bg: 'bg-amber-50' },
  water_damage: { icon: Droplets, color: 'text-blue-800', bg: 'bg-blue-50' },
  local_shipping: { icon: Truck, color: 'text-emerald-800', bg: 'bg-emerald-50' },
  air: { icon: Wind, color: 'text-sky-600', bg: 'bg-sky-50' },
  satellite: { icon: Satellite, color: 'text-slate-700', bg: 'bg-slate-50' },
  camera_outdoor: { icon: Camera, color: 'text-gray-700', bg: 'bg-gray-100' },
  solar_power: { icon: Sun, color: 'text-yellow-600', bg: 'bg-yellow-50' },
  grass: { icon: Leaf, color: 'text-green-600', bg: 'bg-green-50' },
  shower: { icon: Droplet, color: 'text-blue-600', bg: 'bg-blue-50' },
  electric_car: { icon: BatteryCharging, color: 'text-green-700', bg: 'bg-green-50' },
  local_car_wash: { icon: Sparkles, color: 'text-blue-500', bg: 'bg-blue-50' },
  tire_repair: { icon: CircleDot, color: 'text-gray-700', bg: 'bg-gray-100' },
  iron: { icon: Shirt, color: 'text-rose-600', bg: 'bg-rose-50' },
  microwave: { icon: Microwave, color: 'text-orange-700', bg: 'bg-orange-50' },
  elevator: { icon: ArrowUpDown, color: 'text-indigo-700', bg: 'bg-indigo-50' },
  window: { icon: AppWindow, color: 'text-sky-700', bg: 'bg-sky-50' },
  door_front: { icon: DoorOpen, color: 'text-amber-700', bg: 'bg-amber-50' },
};

const CUSTOMER_ICONS: Record<string, { icon: LucideIcon; color: string; bg: string }> = {
  home: { icon: Home, color: 'text-emerald-600', bg: 'bg-emerald-50' },
  office: { icon: Monitor, color: 'text-blue-600', bg: 'bg-blue-50' },
  residential: { icon: Home, color: 'text-green-600', bg: 'bg-green-50' },
  commercial: { icon: HardHat, color: 'text-indigo-600', bg: 'bg-indigo-50' },
  apartment: { icon: Building2, color: 'text-slate-600', bg: 'bg-slate-50' },
  villa: { icon: Home, color: 'text-amber-700', bg: 'bg-amber-50' },
  store: { icon: Store, color: 'text-purple-600', bg: 'bg-purple-50' },
  factory: { icon: Factory, color: 'text-gray-700', bg: 'bg-gray-100' },
  warehouse: { icon: Landmark, color: 'text-orange-700', bg: 'bg-orange-50' },
  building: { icon: Building2, color: 'text-blue-700', bg: 'bg-blue-50' },
  personal_residential: { icon: Home, color: 'text-blue-600', bg: 'bg-blue-50' },
  residential_compounds: { icon: Building2, color: 'text-emerald-600', bg: 'bg-emerald-50' },
  offices: { icon: Monitor, color: 'text-violet-600', bg: 'bg-violet-50' },
  banks: { icon: Banknote, color: 'text-amber-600', bg: 'bg-amber-50' },
  government_buildings: { icon: Landmark, color: 'text-cyan-700', bg: 'bg-cyan-50' },
  schools_universities: { icon: GraduationCap, color: 'text-pink-600', bg: 'bg-pink-50' },
  hospitals_clinics: { icon: Heart, color: 'text-red-600', bg: 'bg-red-50' },
  hotels: { icon: Hotel, color: 'text-purple-600', bg: 'bg-purple-50' },
  retail_shops: { icon: Store, color: 'text-orange-600', bg: 'bg-orange-50' },
  factories_warehouses: { icon: Factory, color: 'text-gray-600', bg: 'bg-gray-100' },
  restaurants_cafes: { icon: UtensilsCrossed, color: 'text-yellow-700', bg: 'bg-yellow-50' },
  community_centers: { icon: Users, color: 'text-teal-600', bg: 'bg-teal-50' },
  religious_buildings: { icon: Church, color: 'text-indigo-700', bg: 'bg-indigo-50' },
  car_owners_garages: { icon: CarFront, color: 'text-blue-700', bg: 'bg-blue-50' },
};

interface Category {
  id: string;
  name_en: string;
  name_ar: string;
  icon?: string;
  type?: string;
  parent_id?: string;
  sort_order?: number;
  children?: Category[];
}

const CategoryIcon: React.FC<{ iconKey?: string; type: string }> = ({ iconKey, type }) => {
  const map = type === 'technician_role' ? SERVICE_ICONS : CUSTOMER_ICONS;
  const key = iconKey?.toLowerCase() ?? '';
  const style = map[key];
  if (style) {
    const Icon = style.icon;
    return (
      <div className={`w-10 h-10 ${style.bg} rounded-lg flex items-center justify-center`}>
        <Icon className={`w-5 h-5 ${style.color}`} />
      </div>
    );
  }
  // Fallback
  const FallbackIcon = type === 'technician_role' ? Wrench : Home;
  const fallbackBg = type === 'technician_role' ? 'bg-gray-100' : 'bg-gray-100';
  const fallbackColor = type === 'technician_role' ? 'text-gray-500' : 'text-gray-500';
  return (
    <div className={`w-10 h-10 ${fallbackBg} rounded-lg flex items-center justify-center`}>
      <FallbackIcon className={`w-5 h-5 ${fallbackColor}`} />
    </div>
  );
};

const CategoriesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [editingCat, setEditingCat] = useState<Category | null>(null);
  const [isCreating, setIsCreating] = useState(false);
  const [createType, setCreateType] = useState<string>('technician_role');
  const [formData, setFormData] = useState({
    name_en: '',
    name_ar: '',
    icon: '',
  });

  const { data, isLoading } = useQuery({
    queryKey: ['categories'],
    queryFn: () => categoriesApi.list(),
  });

  const createMutation = useMutation({
    mutationFn: (newCat: {
      name_en: string;
      name_ar: string;
      icon?: string;
      type?: string;
      parent_id?: string;
    }) => categoriesApi.create(newCat),
    onSuccess: () => {
      toast.success('Category created');
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      resetForm();
    },
    onError: () => toast.error('Failed to create category'),
  });

  const updateMutation = useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: string;
      data: { name_en?: string; name_ar?: string; icon?: string };
    }) => categoriesApi.update(id, data),
    onSuccess: () => {
      toast.success('Category updated');
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      resetForm();
    },
    onError: () => toast.error('Failed to update category'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => categoriesApi.delete(id),
    onSuccess: () => {
      toast.success('Category deleted');
      queryClient.invalidateQueries({ queryKey: ['categories'] });
    },
    onError: () => toast.error('Failed to delete category'),
  });

  const categories: Category[] = data?.data?.categories || data?.data || [];

  // Split by type
  const techServices = categories.filter(
    (c) => c.type === 'technician_role' && !c.parent_id
  );
  const customerTypes = categories.filter(
    (c) => c.type === 'customer_type' && !c.parent_id
  );

  const resetForm = () => {
    setIsCreating(false);
    setEditingCat(null);
    setFormData({ name_en: '', name_ar: '', icon: '' });
  };

  const openCreate = (type: string) => {
    resetForm();
    setIsCreating(true);
    setCreateType(type);
  };

  const openEdit = (cat: Category) => {
    resetForm();
    setEditingCat(cat);
    setFormData({
      name_en: cat.name_en,
      name_ar: cat.name_ar,
      icon: cat.icon || '',
    });
  };

  const handleSubmit = () => {
    if (!formData.name_en.trim() || !formData.name_ar.trim()) {
      toast.error('Both English and Arabic names are required');
      return;
    }

    if (editingCat) {
      updateMutation.mutate({
        id: editingCat.id,
        data: {
          name_en: formData.name_en,
          name_ar: formData.name_ar,
          icon: formData.icon || undefined,
        },
      });
    } else {
      createMutation.mutate({
        name_en: formData.name_en,
        name_ar: formData.name_ar,
        icon: formData.icon || undefined,
        type: createType,
      });
    }
  };

  const renderCategoryList = (
    items: Category[],
    type: string,
    title: string,
    subtitle: string,
    icon: React.ReactNode,
    accentColor: string
  ) => (
    <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
      {/* Section header */}
      <div className={`flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gradient-to-r ${accentColor}`}>
        <div className="flex items-center gap-3">
          {icon}
          <div>
            <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
            <p className="text-xs text-gray-500">{subtitle}</p>
          </div>
        </div>
        <button
          onClick={() => openCreate(type)}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-white text-gray-700 border border-gray-200 rounded-lg text-sm font-medium hover:bg-gray-50 transition-colors shadow-sm"
        >
          <Plus className="w-4 h-4" />
          Add
        </button>
      </div>

      {items.length === 0 ? (
        <div className="p-8 text-center">
          <p className="text-sm text-gray-400">No items yet. Click Add to create one.</p>
        </div>
      ) : (
        <div className="divide-y divide-gray-50">
          {items.map((cat) => (
            <div
              key={cat.id}
              className="flex items-center justify-between px-6 py-3.5 hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <CategoryIcon iconKey={cat.icon} type={type} />
                <div>
                  <p className="font-medium text-gray-900 text-sm">{cat.name_en}</p>
                  <p className="text-xs text-gray-500 font-arabic">{cat.name_ar}</p>
                </div>
              </div>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => openEdit(cat)}
                  className="p-2 text-gray-400 hover:text-blue-600 rounded-lg hover:bg-blue-50 transition-colors"
                  title="Edit"
                >
                  <Edit2 className="w-4 h-4" />
                </button>
                <button
                  onClick={() => {
                    if (confirm('Delete this category? This cannot be undone.')) {
                      deleteMutation.mutate(cat.id);
                    }
                  }}
                  className="p-2 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50 transition-colors"
                  title="Delete"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Categories</h1>
        <p className="text-gray-500 text-sm mt-1">
          Manage technician services and customer type definitions
        </p>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600" />
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {renderCategoryList(
            techServices,
            'technician_role',
            'Technician Services',
            'Services that technicians provide and customers can book',
            <Wrench className="w-5 h-5 text-blue-600" />,
            'from-blue-50 to-white'
          )}

          {renderCategoryList(
            customerTypes,
            'customer_type',
            'Customer Definitions',
            'Property types like Home, Office, etc.',
            <Home className="w-5 h-5 text-emerald-600" />,
            'from-emerald-50 to-white'
          )}
        </div>
      )}

      {/* Create/Edit Modal */}
      {(isCreating || editingCat) && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">
                {editingCat
                  ? 'Edit Category'
                  : createType === 'technician_role'
                  ? 'Add Service'
                  : 'Add Customer Type'}
              </h3>
              <button
                onClick={resetForm}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Name (English)
                </label>
                <input
                  type="text"
                  value={formData.name_en}
                  onChange={(e) =>
                    setFormData({ ...formData, name_en: e.target.value })
                  }
                  placeholder={createType === 'technician_role' ? 'e.g. Plumbing' : 'e.g. Home'}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Name (Arabic)
                </label>
                <input
                  type="text"
                  value={formData.name_ar}
                  onChange={(e) =>
                    setFormData({ ...formData, name_ar: e.target.value })
                  }
                  placeholder={createType === 'technician_role' ? 'e.g. سباكة' : 'e.g. منزل'}
                  dir="rtl"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-primary-500 outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">
                  Icon
                </label>
                <div className="grid grid-cols-6 gap-2 max-h-48 overflow-y-auto p-2 border border-gray-300 rounded-lg">
                  {Object.entries(createType === 'technician_role' ? SERVICE_ICONS : CUSTOMER_ICONS).map(
                    ([key, style]) => {
                      const Icon = style.icon;
                      const isSelected = formData.icon === key;
                      return (
                        <button
                          key={key}
                          type="button"
                          onClick={() => setFormData({ ...formData, icon: key })}
                          title={key}
                          className={`w-10 h-10 rounded-lg flex items-center justify-center border-2 transition-all ${
                            isSelected
                              ? 'border-primary-500 ring-2 ring-primary-200'
                              : 'border-transparent hover:border-gray-300'
                          } ${style.bg}`}
                        >
                          <Icon className={`w-5 h-5 ${style.color}`} />
                        </button>
                      );
                    }
                  )}
                </div>
                {formData.icon && (
                  <p className="mt-1 text-xs text-gray-500">
                    Selected: <span className="font-medium">{formData.icon}</span>
                  </p>
                )}
              </div>
              <div className="flex gap-3 justify-end pt-2">
                <button
                  onClick={resetForm}
                  className="px-4 py-2 text-sm text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSubmit}
                  className="flex items-center gap-2 px-4 py-2 text-sm text-white bg-primary-600 rounded-lg hover:bg-primary-700"
                >
                  <Save className="w-4 h-4" />
                  {editingCat ? 'Update' : 'Create'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CategoriesPage;
