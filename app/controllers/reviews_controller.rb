class ReviewsController < ApplicationController
  def create
    booking = Booking.find_by!(code: params[:code])

    unless booking.customer_email.casecmp?(params[:email].to_s.strip)
      flash[:alert] = t("booking_lookups.not_found")
      redirect_to(new_booking_lookup_path) and return
    end

    unless booking.reviewable?
      flash[:alert] = t("reviews.errors.not_reviewable")
      redirect_to(new_booking_lookup_path) and return
    end

    review = booking.build_review(review_params)

    if review.save
      flash[:booking_id] = booking.id
      redirect_to booking_confirmation_path
    else
      flash[:alert] = review.errors.full_messages.to_sentence
      redirect_to new_booking_lookup_path
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
