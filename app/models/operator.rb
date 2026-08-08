class Operator < ApplicationRecord
  has_many :tours

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
