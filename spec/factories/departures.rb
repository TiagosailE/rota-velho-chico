FactoryBot.define do
  factory :departure do
    tour
    sequence(:starts_at) { |n| n.days.from_now.change(hour: 8) }
    capacity { 10 }
    seats_taken { 0 }
    status { :scheduled }
  end
end
