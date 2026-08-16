class ToursController < ApplicationController
  def index
    @tours = filtered_tours
    @hero_photo = hero_photo
    @category = params[:category] if Tour.categories.key?(params[:category])
    @date = parsed_date
    @min_price = params[:min_price]
    @max_price = params[:max_price]
  end

  def show
    @tour = Tour.where(active: true).find_by!(slug: params[:slug])
    @month = parsed_month
    range_start = [ Time.current, @month.beginning_of_day ].max
    range_end = @month.end_of_month.end_of_day
    @departures_by_date = @tour.departures.scheduled
                                .where(starts_at: range_start..range_end)
                                .order(:starts_at)
                                .group_by { |departure| departure.starts_at.to_date }
  end

  private

  # Foto do hero da home. Nao depende dos filtros de proposito: o hero e a
  # capa do site, nao um resultado de busca -- filtrar deixaria a primeira
  # dobra piscando entre fotos a cada filtro aplicado. Determinista (menor
  # tour_id entre as capas de passeio ativo) para nao trocar a cada request,
  # e nil num banco sem foto, quando a view cai no fundo solido.
  def hero_photo
    TourPhoto.joins(:tour)
             .where(tours: { active: true }, position: 0)
             .order(:tour_id)
             .first
  end

  def parsed_month
    return Date.current.beginning_of_month if params[:month].blank?

    Date.strptime(params[:month], "%Y-%m").beginning_of_month
  rescue ArgumentError
    Date.current.beginning_of_month
  end

  def filtered_tours
    tours = Tour.where(active: true)
    tours = tours.where(category: params[:category]) if Tour.categories.key?(params[:category])
    tours = filter_by_date(tours)
    tours = filter_by_price(tours)
    tours.order(:title)
  end

  def filter_by_date(tours)
    return tours unless parsed_date

    range = parsed_date.beginning_of_day..parsed_date.end_of_day
    tours.joins(:departures).merge(Departure.scheduled.where(starts_at: range)).distinct
  end

  def filter_by_price(tours)
    tours = tours.where(base_price_cents: parsed_price(params[:min_price])..) if parsed_price(params[:min_price])
    tours = tours.where(base_price_cents: ..parsed_price(params[:max_price])) if parsed_price(params[:max_price])
    tours
  end

  def parsed_date
    return @parsed_date if defined?(@parsed_date)

    @parsed_date = Date.parse(params[:date]) if params[:date].present?
  rescue ArgumentError
    @parsed_date = nil
  end

  def parsed_price(value)
    return nil if value.blank?

    Integer(value) * 100
  rescue ArgumentError
    nil
  end
end
