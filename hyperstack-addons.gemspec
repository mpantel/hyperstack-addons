require_relative "lib/hyperstack/addons/version"

Gem::Specification.new do |spec|
  spec.name = "hyperstack-addons"
  spec.version = Hyperstack::Addons::VERSION
  spec.authors = ["Michail Pantelelis, Yiannis Koutzamanis, Sotiris Aggelis"]
  spec.email = ["mpantel@aegean.gr"]
  spec.homepage = "https://github.com/mpantel/hyperstack-addons/"
  spec.summary = "Summary of Hyperstack::Addons."
  spec.description = "Description of Hyperstack::Addons."
  spec.license = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "gems.ru.aegean.gr:9292"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md","spec/helpers.rb"]
  # spec.require_paths = ["lib"]

  spec.add_dependency "rails", "~> 6.1.5", ">= 6.1.5.1" #, "< 6.1.6"
  # spec.add_dependency "sprockets", "~> 4.0.3", "< 4.1.0"
  # spec.add_dependency "zeitwerk", "~> 2.5.4", "< 2.6.0"
  spec.add_dependency "opal-browser", "> 0.2.0"

  spec.add_dependency 'rails-hyperstack' #,'1.0.alpha1.8.0002'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'hyper-spec' #,'1.0.alpha1.8.0002'
  spec.add_development_dependency 'webpacker'
  spec.add_development_dependency 'foreman'
  #spec.add_dependency  'hyper-i18n','1.0.alpha1.8.0002'

  spec.add_development_dependency 'database_cleaner' # optional but we find it works best due to the concurrency of hyperstack
  spec.add_development_dependency 'database_cleaner-active_record'

  spec.add_development_dependency 'rspec-rails'

  spec.add_development_dependency 'unparser'
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency 'cucumber'
  spec.add_development_dependency 'syntax'

  spec.add_development_dependency 'rubocop' #, require: false # follow hyper-spec .gemspec def
  spec.add_development_dependency 'rubocop-rspec' #, require: false
  spec.add_development_dependency 'brakeman'

  spec.add_development_dependency 'highline'
  spec.add_development_dependency 'geminabox'

  # SimpleCov with Selenium/Rails
  # https://everydayrails.com/2018/03/23/rails-spec-coverage-simplecov.html
  # simplecov author here. Whenever you launch SimpleCov, it applies the coverage analysis to the currently running process. Therefore, you would need to launch SimpleCov inside your Rails server process. I would recommend adding the SimpleCov setup as a conditional to your Rails app's config/boot.rb (at the very top), like so:
  #
  # # config/boot.rb
  # if ENV["SELENIUM"]
  #   require 'simplecov'
  #   SimpleCov.start 'rails'
  # end
  #
  # Before booting your Rails test server, set that environment variable. You should now receive a coverage report once the test server is shut down. Please check out the config options if you want to move it to another directory so it does not interfere with your regular (unit/functional) coverage report.
  #
  # I am not sure that boot.rb is the right place though. The fact is that SimpleCov needs to be loaded before anything else in your app is required or it won't be able to track coverage for those files. You might need to experiment or have a look into the rails boot process to find that place, but as the Bundler setup is part of boot.rb (if I remember correctly...), putting the mentioned config above the Bundler.setup should be fine.
  spec.add_development_dependency 'simplecov'

  spec.add_development_dependency 'bullet'
  spec.add_development_dependency 'webdrivers' #, "~>4.7"
  spec.add_development_dependency 'selenium-webdriver', "~>3"

  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'sqlite3' if ENV['DB_ADAPTER'] == 'sqlite'
  spec.add_development_dependency 'puma'
  # MacOS notes, before bundle:
  # brew install libpq
  # bundle config build.pg --with-pg-config=/usr/local/opt/libpq/bin/pg_config
  spec.add_development_dependency 'pg' unless ENV['DB_ADAPTER'] == 'sqlite'

end
