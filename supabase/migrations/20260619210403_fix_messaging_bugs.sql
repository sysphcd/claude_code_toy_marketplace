-- Fix 1: get_user_conversations was missing buyer_id in its RETURNS TABLE,
--         so ConversationList always got buyer_id = '' from the RPC.
-- Must DROP first because PostgreSQL disallows changing return type via CREATE OR REPLACE.
DROP FUNCTION IF EXISTS public.get_user_conversations();
CREATE FUNCTION public.get_user_conversations()
RETURNS TABLE(
  id uuid,
  product_id uuid,
  seller_id uuid,
  buyer_id uuid,
  updated_at timestamptz,
  last_message_at timestamptz,
  product_name text,
  first_image_url text,
  seller_name text,
  buyer_name text,
  last_message text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    c.id,
    c.product_id,
    p.user_id AS seller_id,
    buyer.user_id AS buyer_id,
    c.updated_at,
    c.last_message_at,
    p.product_name,
    img.image_url AS first_image_url,
    COALESCE(NULLIF(TRIM(COALESCE(ps.first_name, '') || ' ' || COALESCE(ps.last_name, '')), ''), 'Anonymous') AS seller_name,
    COALESCE(NULLIF(TRIM(COALESCE(pb.first_name, '') || ' ' || COALESCE(pb.last_name, '')), ''), 'Anonymous') AS buyer_name,
    lm.body AS last_message
  FROM public.conversations c
  JOIN public.products p ON p.id = c.product_id
  LEFT JOIN LATERAL (
    SELECT pi.image_url
    FROM public.product_images pi
    WHERE pi.product_id = p.id
    ORDER BY pi.created_at ASC
    LIMIT 1
  ) img ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name
    FROM public.get_profile_names(ARRAY[p.user_id]) gp
  ) ps ON TRUE
  LEFT JOIN LATERAL (
    SELECT pa.user_id
    FROM public.participants pa
    WHERE pa.conversation_id = c.id AND pa.user_id != p.user_id
    LIMIT 1
  ) buyer ON TRUE
  LEFT JOIN LATERAL (
    SELECT gp.first_name, gp.last_name
    FROM public.get_profile_names(ARRAY[buyer.user_id]) gp
  ) pb ON TRUE
  LEFT JOIN LATERAL (
    SELECT m.body
    FROM public.messages m
    WHERE m.conversation_id = c.id
    ORDER BY m.created_at DESC
    LIMIT 1
  ) lm ON TRUE
  WHERE EXISTS (
    SELECT 1 FROM public.participants pa
    WHERE pa.conversation_id = c.id AND pa.user_id = auth.uid()
  )
  ORDER BY COALESCE(c.last_message_at, c.updated_at) DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_conversations() TO authenticated;

-- Fix 2: Replace N+1 per-conversation unread queries with a single aggregated count.
CREATE OR REPLACE FUNCTION public.get_total_unread_count()
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT COUNT(*)
  FROM public.messages m
  JOIN public.participants pa ON pa.conversation_id = m.conversation_id AND pa.user_id = auth.uid()
  WHERE m.sender_id != auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.message_status ms
      WHERE ms.message_id = m.id
        AND ms.user_id = auth.uid()
        AND ms.read_at IS NOT NULL
    );
$$;

GRANT EXECUTE ON FUNCTION public.get_total_unread_count() TO authenticated;

-- Fix 3: Missing table-level GRANTs for the authenticated role.
-- RLS policies exist but Postgres also requires explicit GRANT on the table.
-- Without these, any DML from the client returns 403 permission denied.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_images TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.conversations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.participants TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.message_status TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_products TO authenticated;
