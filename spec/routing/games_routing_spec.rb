require "rails_helper"

RSpec.describe GamesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/users/2/games").to route_to("games#index", "user_id"=>"2")
    end

    it "routes to #show" do
      expect(get: "/users/2/games/1").to route_to("games#show", id: "1", "user_id"=>"2")
    end


    it "routes to #create" do
      expect(post: "/users/2/games").to route_to("games#create", "user_id"=>"2")
    end

    it "routes to #update via PUT" do
      expect(put: "/users/2/games/1").to route_to("games#update", id: "1", "user_id"=>"2")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/users/2/games/1").to route_to("games#update", id: "1", "user_id"=>"2")
    end

    it "routes to #destroy" do
      expect(delete: "/users/2/games/1").to route_to("games#destroy", id: "1", "user_id"=>"2")
    end
  end
end
