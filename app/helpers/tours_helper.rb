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

  # Preserva os outros filtros ativos ao trocar um so facet -- clicar num
  # chip de categoria nao reseta a data/preco ja escolhidos. Valor nil/blank
  # no override remove o facet da URL (ex: "Todos"/"Qualquer data").
  def filter_link(overrides)
    tours_path(request.query_parameters.symbolize_keys.merge(overrides).compact_blank)
  end

  def chip_classes(active)
    base = "inline-flex items-center rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors border"
    return "#{base} bg-brand-600 text-white border-brand-600" if active

    "#{base} bg-white text-ink-600 border-ink-200 hover:border-brand-300 hover:text-brand-700"
  end

  def active_price_preset
    return :any if params[:min_price].blank? && params[:max_price].blank?
    return :under if params[:min_price].blank? && params[:max_price] == "150"
    return :mid if params[:min_price] == "150" && params[:max_price] == "300"
    :over if params[:min_price] == "300" && params[:max_price].blank?
  end

  def active_when_preset
    return :weekend if params[:weekend].present?
    return :custom if params[:date].present?

    :any
  end
end
