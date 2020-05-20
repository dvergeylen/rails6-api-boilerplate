require 'rails_helper'

RSpec.describe Game, type: :model do
  subject {
    create(:game)
  }

  context "with valid arguments" do
    it { is_expected.to be_valid }
  end

  context "with invalid arguments" do
    it "is invalid without a name" do
      game = build(:game)
      game.name = nil
      game.valid?
      expect(game.errors[:name]).to include("can't be blank")
    end
  end
end
