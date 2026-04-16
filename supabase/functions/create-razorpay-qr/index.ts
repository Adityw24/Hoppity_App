// Supabase Edge Function: create-razorpay-qr
// Called by the Flutter app after creating a pending booking.
// Creates a single-use, fixed-amount UPI QR code via Razorpay and returns its image URL.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS pre-flight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { booking_id, amount, tour_title } = await req.json() as {
      booking_id: string;
      amount: number;      // e.g. 1299.00
      tour_title: string;
    };

    if (!booking_id || !amount || !tour_title) {
      return new Response(
        JSON.stringify({ error: 'booking_id, amount, and tour_title are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const keyId = Deno.env.get('RAZORPAY_KEY_ID');
    const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET');
    if (!keyId || !keySecret) {
      return new Response(
        JSON.stringify({ error: 'Razorpay credentials not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const credentials = btoa(`${keyId}:${keySecret}`);
    // Razorpay amounts are in paise (100 paise = ₹1)
    const amountPaise = Math.round(amount * 100);
    // QR expires 15 minutes from now
    const closeBy = Math.floor(Date.now() / 1000) + 900;

    const razorpayRes = await fetch('https://api.razorpay.com/v1/payments/qr_codes', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${credentials}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        type: 'upi_qr',
        name: tour_title,
        usage: 'single_use',
        fixed_amount: true,
        payment_amount: amountPaise,
        description: `Hoppity booking ${booking_id}`,
        close_by: closeBy,
      }),
    });

    if (!razorpayRes.ok) {
      const errText = await razorpayRes.text();
      console.error('Razorpay error:', errText);
      return new Response(
        JSON.stringify({ error: `Razorpay API error: ${errText}` }),
        { status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const qr = await razorpayRes.json() as { id: string; image_url: string; close_by: number };

    // Persist the QR id on the booking so the webhook can match payments
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    const { error: dbError } = await supabase
      .from('Bookings')
      .update({ razorpay_qr_id: qr.id })
      .eq('id', booking_id);

    if (dbError) {
      console.error('DB update error:', dbError.message);
    }

    return new Response(
      JSON.stringify({ qr_id: qr.id, image_url: qr.image_url, close_by: qr.close_by }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('Unexpected error:', e);
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
