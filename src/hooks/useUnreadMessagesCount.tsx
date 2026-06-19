import { useState, useEffect } from "react";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "./useAuth";

export const useUnreadMessagesCount = () => {
  const { user, loading: authLoading } = useAuth();
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(true);

  const fetchUnreadCount = async () => {
    if (!user) {
      setUnreadCount(0);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const { data, error } = await (supabase as any).rpc('get_total_unread_count');
      if (error) throw error;
      setUnreadCount(Number(data) || 0);
    } catch (error) {
      console.error('Error fetching unread messages count:', error);
      setUnreadCount(0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!authLoading) {
      fetchUnreadCount();
    }
  }, [user, authLoading]); // eslint-disable-line react-hooks/exhaustive-deps

  // Keep badge in sync as new messages arrive
  useEffect(() => {
    if (!user) return;

    const channel = supabase
      .channel('unread-count-updates')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'messages' },
        () => { fetchUnreadCount(); } // eslint-disable-line react-hooks/exhaustive-deps
      )
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [user]); // eslint-disable-line react-hooks/exhaustive-deps

  return {
    unreadCount,
    loading: loading || authLoading,
    refetch: fetchUnreadCount
  };
};