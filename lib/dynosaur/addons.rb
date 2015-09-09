
module Dynosaur
  module Addons
    class << self
      def all
        return @addons if @addons

        @addons = {}
        load_path = File.join(File.dirname(__FILE__), "addons", "plans", "*.yml")
        Gem.find_files(load_path).each do |path|
          plan_data = Psych.load(File.read(path))
          addon_name = plan_data['dynosaur']['addons'].keys.first
          @addons[addon_name] = plan_data['dynosaur']['addons'].values.first
        end
        return @addons
      end

      #
      # @params compare_field Field used to compare plans
      #
      def plans_for_addon(addon, compare_field = 'tier')
        return all[addon].map { |plan|
          AddonPlan.new(plan, compare_field)
        }
      end

    end
  end
end
