import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { Shell } from '@/components/Shell';

/**
 * Server-side authorization gate for all protected admin routes.
 * (Authentication is handled first by middleware; RLS is the final backstop.)
 * A signed-in user who is NOT an active admin is bounced to the login page.
 */
export default async function ProtectedLayout({ children }: { children: React.ReactNode }) {
  const supabase = createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/admin/login');

  const { data: profile } = await supabase
    .from('profiles')
    .select('role, is_active')
    .eq('id', user.id)
    .single();

  if (!profile || profile.role !== 'admin' || !profile.is_active) {
    redirect('/admin/login?error=not_admin');
  }

  return <Shell adminEmail={user.email ?? ''}>{children}</Shell>;
}
