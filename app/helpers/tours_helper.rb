module ToursHelper
  def format_price_cents(cents)
    number_to_currency(cents / 100.0, unit: "R$", separator: ",", delimiter: ".")
  end

  def format_duration(minutes)
    hours, remaining_minutes = minutes.divmod(60)
    remaining_minutes.zero? ? "#{hours}h" : "#{hours}h#{format('%02d', remaining_minutes)}"
  end
end
