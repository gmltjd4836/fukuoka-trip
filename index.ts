/**
 * Supabase Edge Function: map-link-lookup
 * Follows Google Maps share-URL HTTP redirects ONLY. It does not scrape pages,
 * call paid Google APIs, access Supabase tables, or write user data.
 *
 * Deploy with Verify JWT ON. Browser invokes through the logged-in Supabase
 * anonymous session. Never deploy using a secret/service_role key in the app.
 */
const allowedHosts = new Set([
  'maps.app.goo.gl', 'goo.gl',
  'google.com', 'www.google.com', 'maps.google.com',
  'google.co.jp', 'www.google.co.jp',
]);
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, x-client-info, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function isGoogleMapsUrl(input: string): boolean {
  try {
    const u = new URL(input);
    if (u.protocol !== 'https:' || u.username || u.password || !allowedHosts.has(u.hostname.toLowerCase())) return false;
    if (u.hostname === 'goo.gl') return u.pathname.startsWith('/maps');
    if (u.hostname === 'maps.app.goo.gl') return /^\/[a-zA-Z0-9_-]{5,120}\/?$/.test(u.pathname);
    if (u.hostname === 'maps.google.com') return true;
    return u.pathname.startsWith('/maps') || u.pathname.startsWith('/place');
  } catch { return false; }
}
function response(data: Record<string, unknown>, code = 200) {
  return new Response(JSON.stringify(data), { status: code, headers: { ...cors, 'Content-Type': 'application/json; charset=utf-8' } });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (req.method !== 'POST') return response({ error: 'POST only' }, 405);
  let url = '';
  try {
    const data = await req.json();
    url = String(data?.url || '').trim();
  } catch { return response({ error: 'JSON body is required' }, 400); }
  if (url.length > 2048 || !isGoogleMapsUrl(url)) return response({ error: 'Google Maps 공유 링크만 사용할 수 있어요.' }, 400);

  // Full links already contain all information available without a paid API.
  const hostname = new URL(url).hostname.toLowerCase();
  if (hostname !== 'maps.app.goo.gl' && hostname !== 'goo.gl') return response({ resolvedUrl: url });

  let current = url;
  try {
    const visited = new Set<string>();
    for (let n = 0; n < 6; n++) {
      if (!isGoogleMapsUrl(current) || visited.has(current)) break;
      visited.add(current);
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 6500);
      let res: Response;
      try {
        res = await fetch(current, {
          method: 'GET', redirect: 'manual', signal: controller.signal,
          headers: { 'Accept': 'text/html,application/xhtml+xml' },
        });
      } finally { clearTimeout(timer); }
      if (![301, 302, 303, 307, 308].includes(res.status)) break;
      const location = res.headers.get('location');
      if (!location) break;
      const next = new URL(location, current).toString();
      if (!isGoogleMapsUrl(next)) break; // Stop open redirects / untrusted targets.
      current = next;
    }
    return response({
      resolvedUrl: current,
      warning: current === url ? '이 링크가 자동으로 펼쳐지지 않았어요. 이름은 직접 입력해 주세요.' : '',
    });
  } catch (_e) {
    // Never fabricate business names or addresses in a failed lookup.
    return response({ resolvedUrl: current, warning: '링크 자동 해석에 실패했어요. 이름과 주소를 직접 확인해 주세요.' });
  }
});
