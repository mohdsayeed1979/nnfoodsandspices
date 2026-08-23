import { Suspense } from 'react';
import { createClient } from '@/lib/supabase/server';
import { ProductsClient } from '@/components/ProductsClient';
import type { Category } from '@/lib/types';

export const dynamic = 'force-dynamic';

export default async function ProductsPage() {
  const supabase = createClient();
  const { data } = await supabase
    .from('categories')
    .select('*')
    .order('sort_order', { ascending: true });

  const categories = (data ?? []) as Category[];

  return (
    <Suspense fallback={<div className="text-sm text-gray-500">Loading…</div>}>
      <ProductsClient categories={categories} />
    </Suspense>
  );
}
