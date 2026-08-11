module ToursHelper
  def format_price_cents(cents)
    number_to_currency(cents / 100.0, unit: "R$", separator: ",", delimiter: ".")
  end

  def format_duration(minutes)
    hours, remaining_minutes = minutes.divmod(60)
    remaining_minutes.zero? ? "#{hours}h" : "#{hours}h#{format('%02d', remaining_minutes)}"
  end

  def star_rating(rating)
    full_stars = rating.round
    ("★" * full_stars) + ("☆" * (5 - full_stars))
  end

  # Grade de semanas (domingo a sabado) cobrindo o mes, com nil para os dias
  # das semanas de borda que pertencem ao mes anterior/seguinte.
  def calendar_weeks(month)
    first_day = month.beginning_of_month
    last_day = month.end_of_month
    leading_blanks = Array.new(first_day.wday)
    trailing_blanks = Array.new(6 - last_day.wday)

    (leading_blanks + (first_day..last_day).to_a + trailing_blanks).each_slice(7).to_a
  end
end
