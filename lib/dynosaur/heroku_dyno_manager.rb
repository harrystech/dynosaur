module Dynosaur
  class HerokuDynoManager < HerokuManager

    def retrieve
      @state = @heroku_platform_api.formation.info(@app_name, 'web')
      return @state["quantity"]
    end

    def set(value)
      puts "Setting current dynos to #{value}"
      if !@dry_run
        @heroku_platform_api.formation.update(@app_name, 'web', {quantity: value})
      end
      @current_value = value
    end

  end # HerokuDynoManager
end # Dynosaur
