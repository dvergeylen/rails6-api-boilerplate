class UserSerializer
  include FastJsonapi::ObjectSerializer

  set_type :user
  set_id :id
  attributes :name, :email, :created_at, :updated_at
  link :self do |user, params|
    Rails.application.routes.url_helpers.user_url(user.id)
  end

  has_many :games, lazy_load_data: true, links: {
    self: -> (user) {
      "https://doc.place2be.io/users/relationships/games"
    },
    related: -> (user) {
        Rails.application.routes.url_helpers.user_games_url(user.id)
      }
  }
end
