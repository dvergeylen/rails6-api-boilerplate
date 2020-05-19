FactoryBot.define do
  factory :game do
    user { nil }
    name { "MyString" }
    archived { false }
  end
end
