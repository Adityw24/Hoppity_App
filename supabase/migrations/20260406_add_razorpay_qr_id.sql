-- Run this once in: Supabase Dashboard → SQL Editor

-- 1. Add razorpay_qr_id column to track which QR code belongs to which booking
ALTER TABLE "Bookings"
  ADD COLUMN IF NOT EXISTS razorpay_qr_id TEXT;

-- 2. Index for fast webhook lookups (qr_code.credited → find booking)
CREATE INDEX IF NOT EXISTS idx_bookings_razorpay_qr_id
  ON "Bookings" (razorpay_qr_id);

-- 3. Enable Realtime on Bookings so the Flutter app gets live status updates
-- (Only needs to run once; idempotent)
ALTER PUBLICATION supabase_realtime ADD TABLE "Bookings";
