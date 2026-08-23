import type { Metadata } from 'next';
import { getCategories } from '@/lib/catalog';
import { CategoryCard } from '@/components/CategoryCard';

export const dynamic = 'force-dynamic';

export const metadata: Metadata = {
  title: 'Categories',
  description: 'Browse NN Foods & Spices categories — Veg, Pure, Non-Veg and specialty spice blends.',
  alternates: { canonical: '/categories' },
};

export default async function CategoriesPage() {
  const categories = await getCategories();
  return (
    <div className="container-x py-10">
      <h1 className="font-display text-3xl font-bold text-gray-900">Categories</h1>
      <p className="mt-1 text-sm text-gray-500">Explore our spice collections</p>

      {categories.length === 0 ? (
        <div className="mt-16 text-center text-gray-500">Categories are loading. Please check back shortly.</div>
      ) : (
        <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {categories.map((c) => (
            <CategoryCard key={c.id} category={c} />
          ))}
        </div>
      )}
    </div>
  );
}
