class User < ApplicationRecord
  has_many :games

  validates :email, presence: true
  validates :name,  presence: true
end
