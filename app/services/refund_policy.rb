class RefundPolicy
  WINDOW = 48.hours

  def initialize(departure_starts_at:, cancelled_at:, cancelled_by_operator: false)
    @departure_starts_at = departure_starts_at
    @cancelled_at = cancelled_at
    @cancelled_by_operator = cancelled_by_operator
  end

  def refundable?
    return true if @cancelled_by_operator

    (@departure_starts_at - @cancelled_at) > WINDOW
  end
end
