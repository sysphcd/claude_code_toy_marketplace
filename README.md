# claude_code_toy_marketplace

A mobile-first toy marketplace SPA built with React 18 + TypeScript + Vite + Supabase.
![alt text](user-profile.png)
![alt text](user-signup-filled.png)
![alt text](end-to-end-conversation-001.png)
---

## MCP Servers

This project uses [Model Context Protocol (MCP)](https://modelcontextprotocol.io) servers to give Claude Code live browser control and up-to-date library documentation during development sessions.

### Configuration

MCP servers are declared in `.mcp.json` at the project root (gitignored — credentials stay local). Copy `.mcp.json.example` and fill in your values:

```bash
cp .mcp.json.example .mcp.json
# edit .mcp.json with your API keys and project refs
```

### Playwright

**Package:** `@playwright/mcp@latest`  
**Purpose:** Gives Claude Code a real browser it can drive — navigate pages, click, type, upload files, take screenshots, and assert UI state.

```json
{
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest", "--browser", "chrome"]
  }
}
```

Used in this project to:
- Take mobile-viewport screenshots (iPhone 12 Pro 390×844) at each development milestone
- Run end-to-end flows: sign up, create listings, send messages, verify realtime chat
- Upload product images via the file chooser during listing creation
- Verify UI changes (e.g., theme color swap from blue to purple) before committing

Playwright MCP sessions write page-state snapshots to `.playwright-mcp/` (gitignored).

### Context7

**Transport:** HTTP (`https://mcp.context7.com/mcp`)  
**Purpose:** Serves current library documentation (React, Supabase, TanStack Query, Vite, shadcn/ui, etc.) directly into Claude Code's context so answers reflect the actual installed versions, not training-data snapshots.

```json
{
  "context7": {
    "type": "http",
    "url": "https://mcp.context7.com/mcp",
    "args": ["--header", "CONTEXT7_API_KEY: <your-key>"]
  }
}
```

Get a free API key at [context7.com](https://context7.com). Used whenever Claude Code looks up Supabase RPC patterns, TanStack Query cache invalidation, or shadcn/ui component props to ensure the answers match the versions pinned in `package.json`.

---

## Session Log — Changes & Prompts

### 1. Homepage Screenshot (iPhone 12 Pro)

**Prompt:**
> restart the webserver. use the Dimensions: iPhone 12 Pro (390 x 844). go to the homepage, take a screenshot named homepage-001.png in the current folder. close the browser in the end.

**What was done:**
- Started the Vite dev server (`npm run dev`, port 8080)
- Resized Playwright browser to 390×844 (iPhone 12 Pro)
- Navigated to `http://localhost:8080/`
- Saved screenshot as `homepage-001.png`
- Closed the browser

---

### 2. Theme Color Change — Blue → Purple

**Prompt:**
> restart the webserver. use the Dimensions: iPhone 12 Pro (390 x 844). the current theme color is blue, change it to purple. go to the homepage, take a screenshot named "homepage-purple.png" to verify your change until you implement it correctly. close the browser in the end.

**What was done:**
- Changed `--marketplace-blue` CSS variable in `src/index.css` from HSL `194 57% 51%` (blue `#3CA4C7`) to HSL `270 60% 55%` (purple `#8C47D1 / rgb(140,71,209)`). All semantic design tokens (`--foreground`, `--primary`, `--accent`, `--border`, `--ring`, etc.) reference this single variable, so the entire theme flipped to purple automatically.
- Replaced two hardcoded `rgb(60,164,199)` Tailwind arbitrary values in `src/pages/ConversationDetail.tsx` (sent-message bubble background/border) with `rgb(140,71,209)`.
- Restarted the dev server, navigated to the homepage, verified the purple theme, and saved screenshot as `homepage-purple.png`.
- Closed the browser.

**Files changed:**
- `src/index.css` — `--marketplace-blue` HSL value updated to purple
- `src/pages/ConversationDetail.tsx` — two hardcoded blue RGB values replaced with purple

---

### 3. Sign Up + Profile Screenshot

**Prompt:**
> restart the webserver. use the Dimensions: iPhone 12 Pro (390 x 844). sign up as a new user with random name, random email, password as '11111111A'. Then, go to Profile page and take a screenshot. For each screenshot, use prefix naming 'user-'; store in the current project folder.

**What was done:**
- Navigated to `/auth`, switched to the Sign Up tab
- Signed up as **Jasper Holloway** (`jasper.holloway47@example.com`, password `11111111A`)
- Saved screenshots:
  - `user-signup-form.png` — empty sign-up form
  - `user-signup-filled.png` — form filled with credentials
  - `user-profile.png` — profile page after successful account creation
- Closed the browser

---

### 4. End-to-End Flow — Sign Up, Profile, Create & Publish Listing

**Prompt:**
> restart the webserver. use the Dimensions: iPhone 12 Pro (390 x 844). sign up as a new user with random name, random email, password as '11111111A'. Then, go to Profile page and take a screenshot. Then, create a new listing product to sell; use the src/assets/toy_bulldozer.png as the only image; use the product name "Toy BullDozer"; take a screenshot. Then, publish the product to sell. For each screenshot, use prefix naming 'end-to-end-'; store in the current project folder. close the browser in the end.

**What was done:**
- Signed out of the previous session, then signed up as **Marcus Vance** (`marcus.vance83@example.com`, password `11111111A`)
- Navigated to `/profile` and saved `end-to-end-profile.png`
- Navigated to `/create-listing/new`
- Uploaded `src/assets/toy_bulldozer.png` via Playwright file chooser
- Filled in the listing form:
  - Product name: `Toy BullDozer`
  - Price: `$45`
  - Color: `Yellow`
  - Leather: `Plastic`
  - Year purchased: `2023`
  - Stamp: `BD-2023-001`
  - Location: `San Francisco, CA`
  - Description: `Gently used toy bulldozer in great condition. Perfect for kids who love construction vehicles!`
- Saved `end-to-end-listing-form.png` showing the filled form with the bulldozer image
- **Fix applied:** Local Supabase DB was missing table-level `GRANT` permissions for the `authenticated` role on `products` and `product_images`. Applied:
  ```sql
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_images TO authenticated;
  ```
  > **Note:** Add these grants to `supabase/migrations/00000000_consolidated_migration.sql` so `supabase db reset` includes them automatically.
- Clicked Publish — product was created and the app redirected to `/create-listing` showing the live card
- Saved `end-to-end-published.png` showing "Toy BullDozer $45" in the active listings view
- Closed the browser

**Screenshots saved:**
| File | Content |
|---|---|
| `end-to-end-profile.png` | Profile page for Marcus Vance |
| `end-to-end-listing-form.png` | Listing form filled with bulldozer image |
| `end-to-end-published.png` | Active listings showing published "Toy BullDozer" card |

---

### 5. End-to-End Conversation Flow — Sign Up, Message Seller, Seller Reply

**Prompt:**
> restart the webserver. use the Dimensions: iPhone 12 Pro (390 x 844). sign out existing user. sign up as a new user with random name, random email, password as '11111111A'. Then, go to the "Toy Bear" product page. Send Message to the seller and send another message "Could you give me discount?" Then, sign out the current user. Then, sign in as the seller with password '11111111A'. Go to the conversation list and go in the conversation with the new user. Reply 'Sure. Happy to find a customer'. Take a screenshot named, use prefix naming 'end-to-end-conversation-001'; store in the current project folder. close the browser in the end.

**What was done:**
- **Seller setup:** "Toy Bear" did not yet exist in the local DB. Signed in as Marcus Vance (`marcus.vance83@example.com`) and created the listing at `/create-listing/new`:
  - Image: `src/assets/toy_bear.png`
  - Product name: `Toy Bear`, Price: `$199`, Color: `White`, Leather: `Cotton`, Year: `2025`, Location: `Mountain View, CA`
  - Published successfully → redirected to `/create-listing`
- Signed out Marcus Vance
- Signed up as new buyer **Priya Nair** (`priya.nair29@example.com`, password `11111111A`)
- Navigated to the homepage, clicked the Toy Bear card → `/product/<id>`
- Sent first message: `Hi, is this still available?` (pre-filled default)
- **Fix applied:** Local Supabase DB was missing table-level `GRANT` permissions for conversation-related tables. Applied:
  ```sql
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.participants TO authenticated;
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.message_status TO authenticated;
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
  GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_products TO authenticated;
  ```
  > **Note:** Add all these grants to `supabase/migrations/00000000_consolidated_migration.sql` so `supabase db reset` is fully self-contained.
- Clicked "See conversation" → entered `/conversation/<id>`
- Sent second message: `Could you give me discount?`
- Signed out Priya Nair
- Signed in as **Marcus Vance** (seller, `marcus.vance83@example.com`, password `11111111A`)
- Navigated to `/messages` → clicked the Toy Bear conversation (showing 2 unread from Priya Nair)
- Replied: `Sure. Happy to find a customer`
- Saved screenshot `end-to-end-conversation-001.png` showing the full 3-message thread

**Screenshots saved:**
| File | Content |
|---|---|
| `end-to-end-conversation-001.png` | Full conversation: buyer's 2 messages + seller's reply in purple bubble |
