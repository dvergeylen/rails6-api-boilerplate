FactoryBot.define do
  factory :game do
    name { Faker::Marketing.buzzwords }
    archived { false }
    user { create(:user) }
  end

  factory :archived_game, class: Game do
    name { Faker::Marketing.buzzwords }
    archived { true }
    user { create(:user) }
  end
end
