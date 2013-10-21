

describe "HerokuManager" do
    before do
        @api_key = SecureRandom.uuid
        @app_name = SecureRandom.uuid
    end
    it "should only poll once a minute" do
        manager = HerokuManager.new(@api_key, @app_name, true, 0.1)
        manager.set(2)

        current = manager.get_current_dynos
        current.should eql 2

        manager.set(3)
        current = manager.get_current_dynos
        current.should eql 3
        manager.retrievals.should eql 1

        sleep 0.11
        current = manager.get_current_dynos
        current.should eql 3
        manager.retrievals.should eql 2

    end

    it "should re-check before modifying" do
        manager = HerokuManager.new(@api_key, @app_name, true, 30)
        manager.set(2)

        current = manager.get_current_dynos
        current.should eql 2
        manager.retrievals.should eql 1

        manager.ensure(2)
        current = manager.get_current_dynos
        current.should eql 2
        manager.retrievals.should eql 2

        manager.ensure(3)
        current = manager.get_current_dynos
        current.should eql 3
        manager.retrievals.should eql 3
    end
end
