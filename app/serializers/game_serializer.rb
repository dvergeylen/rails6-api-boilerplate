class GameSerializer
  include FastJsonapi::ObjectSerializer

  set_type :game
  set_id :id
  attributes :name, :archived, :created_at, :updated_at
  belongs_to :user

  link :self do |game, params|
    Rails.application.routes.url_helpers.v1_user_game_url(game.user.id, game.id)
  end
end
