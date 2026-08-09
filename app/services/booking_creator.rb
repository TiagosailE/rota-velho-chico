class BookingCreator
  def initialize(departure:, customer_name:, customer_email:, customer_phone:,
                 adults:, children_5_9:, children_0_4:)
    @departure = departure
    @customer_name = customer_name
    @customer_email = customer_email
    @customer_phone = customer_phone
    @adults = adults
    @children_5_9 = children_5_9
    @children_0_4 = children_0_4
  end

  def call
    party_error = validate_party
    return Result.new(false, nil, party_error) if party_error

    @departure.with_lock do
      return Result.new(false, nil, :departure_not_scheduled) unless @departure.scheduled?
      return Result.new(false, nil, :departure_in_the_past) if @departure.starts_at <= Time.current
      return Result.new(false, nil, :sold_out) if @departure.seats_taken + total_seats > @departure.capacity

      booking = Booking.create!(
        departure: @departure,
        customer_name: @customer_name,
        customer_email: @customer_email,
        customer_phone: @customer_phone,
        adults: @adults,
        children_5_9: @children_5_9,
        children_0_4: @children_0_4,
        unit_price_cents: @departure.unit_price_cents,
        total_cents: price.total_cents,
        deposit_cents: price.deposit_cents,
        status: :pending
      )
      @departure.increment!(:seats_taken, total_seats)

      Result.new(true, booking, nil)
    end
  end

  private

  # Criancas de 0 a 4 anos ocupam vaga (contagem de colete) mas nao pagam --
  # a assimetria com o PriceCalculator e intencional (CLAUDE.md).
  def total_seats
    @adults + @children_5_9 + @children_0_4
  end

  def price
    PriceCalculator.new(
      unit_price_cents: @departure.unit_price_cents,
      adults: @adults,
      children_5_9: @children_5_9,
      children_0_4: @children_0_4
    )
  end

  def validate_party
    return :invalid_party if [ @adults, @children_5_9, @children_0_4 ].any?(&:negative?)
    return :invalid_party if total_seats.zero?

    nil
  end
end
