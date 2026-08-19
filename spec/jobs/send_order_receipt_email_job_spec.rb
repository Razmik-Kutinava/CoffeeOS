require 'rails_helper'

RSpec.describe SendOrderReceiptEmailJob, type: :job do
  let(:order) { create(:order) }
  let(:email) { 'user@example.com' }

  # ========== SUBTASK 10: Async receipt send ==========
  it 'ST-10: enqueues job successfully' do
    assert false, 'TODO: SendOrderReceiptEmailJob.perform_later queues'
  end

  it 'ST-10: calls OrderReceiptMailer with order and email' do
    assert false, 'TODO: OrderReceiptMailer.send_receipt(order, email) called'
  end

  it 'ST-10: delivers email asynchronously' do
    assert false, 'TODO: Mail queued, not sent immediately'
  end

  it 'ST-10: handles missing order gracefully' do
    assert false, 'TODO: Job fails gracefully when order not found'
  end

  # ========== SUBTASK 17: Backend critical scenarios ==========
  it 'ST-17: queue receipt email job on email save' do
    assert false, 'TODO: Job created when OrderEmail saved'
  end

  it 'ST-17: uses existing OrderReceiptMailer' do
    assert false, 'TODO: Reuse existing mailer template'
  end
end
