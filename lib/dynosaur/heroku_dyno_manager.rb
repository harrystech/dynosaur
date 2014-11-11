module Dynosaur
  class HerokuDynoManager < HerokuManager

    def retrieve
      @state = @heroku.get_app(@app_name).body
      return @state["dynos"]
    end

    def set(value)
      Dynosaur.log "Setting current dynos to #{value}"
      if !@dry_run
        @heroku.post_ps_scale(@app_name, 'web', value)
      end
      @current_value = value
    end

  end # HerokuDynoManager
end # Dynosaur
