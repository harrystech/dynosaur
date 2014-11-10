require 'spec_helper'

describe Dynosaur::HerokuAddonManager do
  before do
    @api_key = SecureRandom.uuid
    @app_name = SecureRandom.uuid
    @addon_name = "rediscloud"
  end

  let(:manager) {
    Dynosaur::HerokuAddonManager.new(@addon_name, @api_key, @app_name, true)
  }

  describe "#retrieve" do
    before do
      # This is what the API returns
      manager.stub(:get_current_plan).and_return({
        "id"=>"9368f946-7c1b-40fc-97ea-abe8722a93d6",
        "name"=>"rediscloud:25",
      })
    end

    it "returns an AddonPlan instance" do
      manager.retrieve.should be_an_instance_of(AddonPlan)
    end
  end
end
