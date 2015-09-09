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

  describe "#get_current_plan" do
    before do
      allow_any_instance_of(PlatformAPI::Addon).to receive(:list).and_return([{
        "config_vars"=>[
          "PAPERTRAIL_API_TOKEN"
        ],
        "created_at"=>"2015-04-23T01:56:26Z",
        "id"=>"af123",
        "name"=>"soaring-slyly-1234",
        "addon_service"=>{
          "id"=>"f6f28cb5-78ad-4ec7-896d-16462b8202fd",
          "name"=>"rediscloud"
        },
        "plan"=>{
          "id"=>"75e5e5d9-e71c-4693-818f-db1de34d761b",
          "name"=>"papertrail:choklad"
        },
        "app"=>{
          "id"=>"f00",
          "name"=>"#{@app_name}"
        },
        "provider_id"=>"123",
        "updated_at"=>"2015-04-23T01:56:26Z",
        "web_url"=>"https://addons-sso.heroku.com/asdfasfd"
      }])
    end

    it "returns an AddonPlan instance" do
      manager.get_current_plan.should be_an_instance_of(Hash)
    end
  end

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
