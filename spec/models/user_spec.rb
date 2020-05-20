require 'rails_helper'


# 'User' is the subject we are describing
RSpec.describe User, type: :model do
  subject {
    # creates a new record from spec/factories/*
    create(:user) # build(:user) would have just build
                  # see other helpers here: https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md
                  # (attributes_for, create_list, attributes_for_list, ...)
  }

  context "with valid arguments" do
    it { is_expected.to be_valid }
  end

  context "with invalid arguments" do
    it "is invalid without a name" do
      user = build(:user)
      user.name = nil
      user.valid?
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "is invalid without an email" do
      user = build(:user)
      user.email = nil
      user.valid?
      expect(user.errors[:email]).to include("can't be blank")
    end
  end
end
