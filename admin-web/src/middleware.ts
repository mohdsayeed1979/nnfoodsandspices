import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

type CookieToSet = { name: string; value: string; options: CookieOptions };

function redirectToLogin(request: NextRequest, fromPath: string) {
  const url = request.nextUrl.clone();
  url.pathname = '/admin/login';
  url.search = '';
  url.searchParams.set('redirect', fromPath);
  return NextResponse.redirect(url);
}

function isPublicPath(path: string) {
  return (
    path === '/admin/login' ||
    path === '/admin/forgot-password' ||
    path.startsWith('/auth')
  );
}

/**
 * Refreshes the Supabase auth session and enforces the FIRST layer of route
 * protection: unauthenticated visitors to protected /admin/* routes are
 * redirected to /admin/login. (Layer 2 = server-side admin-role guard in the
 * protected layout; layer 3 = Postgres RLS.)
 *
 * Resilience: this runs on EVERY matched request, so it must never crash the
 * whole site. If the Supabase env vars are missing, or the auth call fails at
 * runtime, we FAIL SAFE — deny protected routes (redirect to login) and let
 * public routes through — instead of throwing MIDDLEWARE_INVOCATION_FAILED.
 */
export async function middleware(request: NextRequest) {
  const path = request.nextUrl.pathname;
  const publicPath = isPublicPath(path);

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  // Config unavailable → never crash. Deny protected routes, allow public.
  if (!supabaseUrl || !supabaseAnonKey) {
    return path.startsWith('/admin') && !publicPath
      ? redirectToLogin(request, path)
      : NextResponse.next({ request });
  }

  try {
    let response = NextResponse.next({ request });

    const supabase = createServerClient(supabaseUrl, supabaseAnonKey, {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    });

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (path.startsWith('/admin') && !publicPath && !user) {
      return redirectToLogin(request, path);
    }

    // Already signed in? Skip the login page.
    if (path === '/admin/login' && user) {
      const url = request.nextUrl.clone();
      url.pathname = '/admin/dashboard';
      url.search = '';
      return NextResponse.redirect(url);
    }

    return response;
  } catch {
    // Any runtime failure (network, Edge quirk, bad config) → fail safe.
    return path.startsWith('/admin') && !publicPath
      ? redirectToLogin(request, path)
      : NextResponse.next({ request });
  }
}

export const config = {
  matcher: ['/admin/:path*', '/auth/:path*'],
};
