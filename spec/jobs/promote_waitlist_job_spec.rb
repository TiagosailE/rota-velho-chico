require "rails_helper"

RSpec.describe PromoteWaitlistJob do
  describe "#perform" do
    it "promove a entrada mais antiga da fila, criando uma reserva de verdade" do
      departure = create(:departure, capacity: 10, seats_taken: 9)
      entry = create(:waitlist_entry, departure:, customer_email: "ana@exemplo.com", adults: 1)

      described_class.new.perform(departure.id)

      expect(entry.reload).to be_promoted
      expect(entry.booking).to be_present
      expect(entry.booking.customer_email).to eq("ana@exemplo.com")
      expect(entry.booking).to be_pending
      expect(departure.reload.seats_taken).to eq(10)
    end

    it "promove mais de uma entrada quando a vaga liberada cabe pra varias" do
      departure = create(:departure, capacity: 10, seats_taken: 6)
      first_entry = create(:waitlist_entry, departure:, adults: 2, created_at: 2.hours.ago)
      second_entry = create(:waitlist_entry, departure:, adults: 2, created_at: 1.hour.ago)

      described_class.new.perform(departure.id)

      expect(first_entry.reload).to be_promoted
      expect(second_entry.reload).to be_promoted
      expect(departure.reload.seats_taken).to eq(10)
    end

    it "para na entrada mais antiga que nao cabe, sem pular pra uma menor atras dela" do
      departure = create(:departure, capacity: 10, seats_taken: 9)
      big_entry = create(:waitlist_entry, departure:, adults: 3, created_at: 2.hours.ago)
      small_entry = create(:waitlist_entry, departure:, adults: 1, created_at: 1.hour.ago)

      described_class.new.perform(departure.id)

      expect(big_entry.reload).to be_pending
      expect(small_entry.reload).to be_pending
      expect(departure.reload.seats_taken).to eq(9)
    end

    it "nao faz nada quando nao ha entrada pendente" do
      departure = create(:departure, capacity: 10, seats_taken: 5)

      expect { described_class.new.perform(departure.id) }.not_to raise_error
      expect(departure.reload.seats_taken).to eq(5)
    end

    it "nao promove quando a saida nao esta mais agendada" do
      departure = create(:departure, capacity: 10, seats_taken: 0, status: :cancelled)
      entry = create(:waitlist_entry, departure:)

      described_class.new.perform(departure.id)

      expect(entry.reload).to be_pending
    end

    it "ignora entrada ja promovida -- job reprocessavel" do
      departure = create(:departure, capacity: 10, seats_taken: 9)
      booking = create(:booking, departure:, adults: 1)
      entry = create(:waitlist_entry, departure:, adults: 1, status: :promoted, booking:)

      expect { described_class.new.perform(departure.id) }.not_to change { departure.reload.seats_taken }
      expect(entry.reload).to be_promoted
    end

    it "envia o e-mail de reserva registrada pra quem foi promovido" do
      departure = create(:departure, capacity: 10, seats_taken: 9)
      create(:waitlist_entry, departure:, adults: 1)

      expect { described_class.new.perform(departure.id) }
        .to have_enqueued_mail(BookingMailer, :booking_created)
    end
  end
end
