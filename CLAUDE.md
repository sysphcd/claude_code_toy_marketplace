# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev          # start Vite dev server (localhost:5173)
npm run build        # production build
npm run build:dev    # development build
npm run lint         # ESLint
npm run preview      # preview the built app
```

There are no tests. There is no test runner configured.

## Local Supabase Development

```bash
supabase db reset    # re-apply all migrations to local DB
supabase start       # start local Supabase (Studio at http://localhost:54323)
```

To add a migration:
```bash
supabase migration new <name>
# edit the generated SQL file
supabase db reset
```

To deploy to production:
```bash
supabase link --project-ref <PROJECT_REF>
supabase db push
```

The Supabase client in `src/integrations/supabase/client.ts` auto-selects local (`http://127.0.0.1:54321`) vs production (`https://aonhrhzuntjkskglqdwv.supabase.co`) based on `window.location.hostname`.

## Architecture

**React 18 + TypeScript + Vite** SPA with Supabase as the backend. No SSR.

### Routing (`src/App.tsx`)
React Router v6. All routes are defined at the top level — new routes go above the `*` catch-all. The app is wrapped in `QueryClientProvider` → `TooltipProvider` → `PresenceProvider`.

### Data Fetching
- **TanStack Query** (`@tanstack/react-query`) is used for server state in hooks under `src/hooks/`.
- Complex queries use **Supabase RPC functions** (DB-side PostgreSQL functions). When calling RPCs, cast the client to `any` to bypass TypeScript's strict typing: `(supabase as any).rpc('function_name', { arg })`.
- `src/integrations/supabase/types.ts` is **auto-generated** — never edit it directly. Use the helper types it exports: `Tables<'tablename'>`, `TablesInsert<'tablename'>`, `TablesUpdate<'tablename'>`.

### Authentication
`src/hooks/useAuth.tsx` — a self-contained hook (no context provider). It subscribes to Supabase auth state changes. Google OAuth is the configured provider. Import and call directly in any component that needs the current user.

### Realtime
- **Presence** (`src/contexts/PresenceProvider.tsx`): wraps the entire app; tracks which users are online via a `global-presence` Supabase channel. Use `usePresence()` to check if a user is online.
- **Messages** (`src/pages/ConversationDetail.tsx`): subscribes to `postgres_changes` on the `messages` table filtered by `conversation_id` for live chat.

### Database Schema (key tables)
| Table | Purpose |
|---|---|
| `profiles` | User profile (first_name, last_name, email) |
| `products` | Toy listings (product_name, price, color, leather, stamp, year_purchased, location) |
| `product_images` | Multiple images per product (stored URL) |
| `conversations` | Buyer–seller thread tied to a product |
| `participants` | Many-to-many: users in a conversation |
| `messages` | Chat messages (body text only; image upload is not yet implemented) |
| `message_status` | Per-user read receipts for messages |
| `saved_products` | Bookmarked products per user |

Key RPC functions: `get_public_products`, `get_public_product_detail`, `get_user_conversations`, `get_conversation_details`, `get_conversation_messages_with_read_status`, `create_conversation`, `toggle_saved_product`, `mark_message_read`.

### Image Handling
Product images are uploaded to Supabase Storage, resized client-side first via `src/lib/imageUtils.ts` (`resizeImage()` — max 400×400px, Canvas API). Max file size: 5MB. Up to 5 images per product.

### UI Conventions
- **shadcn/ui** components live in `src/components/ui/` — use these primitives, not raw HTML/Radix.
- **Font**: `font-orator` (Orator Std) is used project-wide. Apply it to all user-facing text.
- **Background color**: `bg-[#f8f4f1]` for page backgrounds.
- **Accent color**: `rgb(60,164,199)` (blue) for sent message bubbles and key interactive elements.
- Toasts: use `useToast` from `@/hooks/use-toast` (shadcn toast) or `sonner`.

### MCP Servers
`.mcp.json.example` shows the available MCP servers: Supabase, Playwright, Context7, Sentry. Copy and populate credentials into `.mcp.json` (gitignored).

## Known Pending Work
- Image upload in conversation (the camera button in `ConversationDetail` is UI-only; the feature is not yet wired up).
