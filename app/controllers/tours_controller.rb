class ToursController < ApplicationController
  def index
    @tours = filtered_tours
    @category = params[:category] if Tour.categories.key?(params[:category])
    @date = parsed_date
    @min_price = params[:min_price]
    @max_price = params[:max_price]
  end

  def show
    @tour = Tour.where(active: true).find_by!(slug: params[:slug])
    @departures = @tour.departures.scheduled.where("starts_at > ?", Time.current).order(:starts_at)
  end

  private

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
