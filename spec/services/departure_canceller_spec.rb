require "rails_helper"

RSpec.describe DepartureCanceller do
  include ActiveJob::TestHelper

  describe "#call" do
    it "cancela a saida, zera seats_taken e cancela as reservas ativas" do
      departure = create(:departure, status: :scheduled, capacity: 10, seats_taken: 5)
      pending_booking = create(:booking, departure:, status: :pending)
      confirmed_booking = create(:booking, departure:, status: :confirmed)

      result = described_class.new(departure:).call

      expect(result.success?).to be(true)
      expect(result.value).to eq(2)
      expect(departure.reload).to be_cancelled
      expect(departure.seats_taken).to eq(0)
      expect(pending_booking.reload.status).to eq("cancelled")
      expect(confirmed_booking.reload.status).to eq("cancelled")
      expect(pending_booking.reload.cancelled_at).to be_present
    end

    it "nao mexe em reservas que ja estavam canceladas ou estornadas" do
      departure = create(:departure, status: :scheduled)
      already_cancelled = create(:booking, departure:, status: :cancelled, cancelled_at: 2.days.ago)
      already_refunded = create(:booking, departure:, status: :refunded, cancelled_at: 2.days.ago)

      result = described_class.new(departure:).call

      expect(result.value).to eq(0)
      expect(already_cancelled.reload.cancelled_at).to be_within(1.second).of(2.days.ago)
      expect(already_refunded.reload.status).to eq("refunded")
    end

    it "enfileira um RefundBookingJob por reserva ativa" do
      departure = create(:departure, status: :scheduled)
      booking_a = create(:booking, departure:, status: :pending)
      booking_b = create(:booking, departure:, status: :confirmed)

      expect do
        described_class.new(departure:).call
      end.to have_enqueued_job(RefundBookingJob).with(booking_a.id)
         .and have_enqueued_job(RefundBookingJob).with(booking_b.id)
    end

    it "recusa com :already_cancelled quando a saida ja esta cancelada" do
      departure = create(:departure, status: :cancelled)
      booking = create(:booking, departure:, status: :confirmed)

      result = described_class.new(departure:).call

      expect(result.success?).to be(false)
      expect(result.error).to eq(:already_cancelled)
      expect(booking.reload.status).to eq("confirmed")
    end
  end
end
