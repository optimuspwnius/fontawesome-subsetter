module FontawesomeSubsetter

  class Engine < ::Rails::Engine

    initializer "fontawesome_subsetter.helpers" do
      ActiveSupport.on_load(:action_view) do
        include FontawesomeSubsetter::IconHelper
      end
    end

    rake_tasks do
      load File.expand_path("../tasks/fontawesome_subsetter.rake", __dir__)
    end

  end

end
