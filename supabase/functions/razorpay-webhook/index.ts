// Supabase Edge Function: razorpay-webhook
// Razorpay calls this URL after a QR code payment is credited.
// Verifies the HMAC-SHA256 signature, then marks the booking as 'confirmed'.
//
// Register this URL in your Razorpay Dashboard:
//   Settings → Webhooks → Add new webhook
//   URL: https://<your-project-ref>.supabase.co/functions/v1/razorpay-webhook
//   Events: qr_code.credited   ← tick this
//   Secret: set RAZORPAY_WEBHOOK_SECRET env var to the same value

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { crypto } from 'https://deno.land/std@0.168.0/crypto/mod.ts';
import { encodeHex } from 'https://deno.land/std@0.168.0/encoding/hex.ts';

serve(async (req) => {
  try {
    const body = await req.text();
    const signature = req.headers.get('x-razorpay-signature') ?? '';
    const webhookSecret = Deno.env.get('RAZORPAY_WEBHOOK_SECRET');

    if (!webhookSecret) {
      console.error('RAZORPAY_WEBHOOK_SECRET not set');
      return new Response('Server misconfigured', { status: 500 });
    }

    // ── Verify HMAC-SHA256 signature ────────────────────────────
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(webhookSecret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign'],
    );
    const rawMac = await crypto.subtle.sign(
      'HMAC',
      keyMaterial,
      new TextEncoder().encode(body),
    );
    const expectedSig = encodeHex(new Uint8Array(rawMac));

    if (expectedSig !== signature) {
      console.warn('Webhook signature mismatch');
      return new Response('Unauthorized', { status: 401 });
    }

    // ── Process event ───────────────────────────────────────────
    const event = JSON.parse(body) as { event: string; payload: Record<string, unknown> };

    if (event.event === 'qr_code.credited') {
      // deno-lint-ignore no-explicit-any
      const qrEntity = (event.payload as any)?.qr_code?.entity as { id: string } | undefined;
      const qrId = qrEntity?.id;

      if (qrId) {
        const supabase = createClient(
          Deno.env.get('SUPABASE_URL')!,
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
        );

        const { error } = await supabase
          .from('Bookings')
          .update({ status: 'confirmed' })
          .eq('razorpay_qr_id', qrId);

        if (error) {
          console.error('Failed to confirm booking:', error.message);
          return new Response('DB error', { status: 500 });
        }

        console.log(`Booking confirmed for QR ${qrId}`);
      }
    }

    return new Response('OK', { status: 200 });
  } catch (e) {
    console.error('Webhook handler error:', e);
    return new Response((e as Error).message, { status: 500 });
  }
});
