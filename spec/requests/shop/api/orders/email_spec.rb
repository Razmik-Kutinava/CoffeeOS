require 'rails_helper'

RSpec.describe 'Shop::Api::Orders::Email', type: :request do
  let(:order) { create(:order) }

  describe 'POST /shop/api/orders/:order_id/email' do
    # ========== SUBTASK 8: Save email without OTP ==========
    it 'ST-8: saves email without OTP verification' do
      assert false, 'TODO: POST with valid email → OrderEmail.email saved'
    end

    it 'ST-8: returns 200 OK success response' do
      assert false, 'TODO: {success: true, email: "...", queued_receipt: true}'
    end

    it 'ST-8: accepts email without OTP code' do
      assert false, 'TODO: No OTP step required'
    end

    it 'ST-8: allows empty email (optional)' do
      assert false, 'TODO: POST empty email → 200 OK'
    end

    it 'ST-8: rejects invalid email format' do
      assert false, 'TODO: POST "invalid@" → 400 Bad Request'
    end

    # ========== SUBTASK 9: CRM integration ==========
    it 'ST-9: enqueues CRM job when marketing_consent=true' do
      assert false, 'TODO: SyncContactToCrmJob queued'
    end

    it 'ST-9: does NOT enqueue CRM job when marketing_consent=false' do
      assert false, 'TODO: SyncContactToCrmJob not queued'
    end

    it 'ST-9: saves email regardless of CRM consent' do
      assert false, 'TODO: OrderEmail exists even when consent=false'
    end

    # ========== SUBTASK 10: Async receipt send ==========
    it 'ST-10: enqueues SendOrderReceiptEmailJob' do
      assert false, 'TODO: Job queued when email saved'
    end

    it 'ST-10: returns response immediately (async)' do
      assert false, 'TODO: Response time < 500ms, job in background'
    end

    # ========== SUBTASK 14: Idempotency ==========
    it 'ST-14: prevents duplicate OrderEmail creation' do
      assert false, 'TODO: Unique constraint on (order_id, email)'
    end

    it 'ST-14: returns success on duplicate POST' do
      assert false, 'TODO: Second POST → 200 OK, not duplicate job'
    end

    it 'ST-14: does not enqueue duplicate CRM jobs' do
      assert false, 'TODO: Only one SyncContactToCrmJob for same email'
    end

    # ========== SUBTASK 17: Backend critical scenarios ==========
    it 'ST-17: saves email without OTP' do
      assert false, 'TODO: No verification required'
    end

    it 'ST-17: queues receipt email job' do
      assert false, 'TODO: SendOrderReceiptEmailJob enqueued'
    end

    it 'ST-17: respects marketing consent for CRM' do
      assert false, 'TODO: Only CRM job when marketing_consent=true'
    end

    # ========== SUBTASK 18: UX validation ==========
    it 'ST-18: validates email format on backend' do
      assert false, 'TODO: Backend validation redundant with frontend'
    end

    it 'ST-18: handles missing order gracefully' do
      assert false, 'TODO: 404 Not Found for missing order'
    end
  end
end
