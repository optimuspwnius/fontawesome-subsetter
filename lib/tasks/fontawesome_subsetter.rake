namespace :fontawesome do

  desc "Build FontAwesome, subsetting icons and shaking out unused CSS."
  task :subset do
    require "fontawesome_subsetter"

    subsetter = FontawesomeSubsetter::Subsetter.new
    subsetter.build()

    puts "FontAwesome subset build completed successfully!"
  end

end

Rake::Task["assets:precompile"].enhance(["fontawesome:subset"])
