import type { APIRoute } from 'astro';
import { catalog } from '../lib/catalog';

/**
 * The catalog as data, for anything that would rather fetch than parse HTML:
 * a later one-click install in the admin, a script, a directory listing.
 */
export const GET: APIRoute = ({ site }) => {
  const data = catalog();
  const base = site ?? new URL('http://localhost:4321');
  const body = {
    ...data,
    components: data.components.map((entry) => ({
      ...entry,
      url: new URL(`/components/${entry.type}/`, base).href,
      download: new URL(`/download/${entry.type}.zip`, base).href,
    })),
  };

  return new Response(JSON.stringify(body, null, 2), {
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  });
};
