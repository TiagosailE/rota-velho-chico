FactoryBot.define do
  factory :review do
    booking
    rating { 5 }
    comment { "Passeio otimo, recomendo!" }
  end
end
