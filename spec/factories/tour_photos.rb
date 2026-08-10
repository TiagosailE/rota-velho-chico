FactoryBot.define do
  factory :tour_photo do
    tour
    alt_text { "Vista do canion a partir do catamara" }
    image do
      Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/tour_photo.jpg"),
        "image/jpeg"
      )
    end
  end
end
