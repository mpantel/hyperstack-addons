#spec_helper.rb
ENV["RAILS_ENV"] ||= 'test'

# require 'rspec/autorun'
# require 'rubygems'
# require 'bundler/setup'

require 'opal'
#require 'opal-rspec'
# require 'opal-jquery'
require 'webpacker'

begin
  require File.expand_path('../spec/dummy/config/environment', File.dirname(__FILE__))
rescue LoadError
  abort 'Could not load dummy application. Please ensure you have run `bundle exec rake dummy`'
end
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/spec/dummy'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rails'
require 'factory_bot_rails'

require 'hyper-spec'
# require 'pry'
require 'byebug'
require 'opal-browser'
require 'timecop'
require 'helpers'

Rails.backtrace_cleaner.remove_silencers!
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.order = "random"
  config.example_status_persistence_file_path = ".rspec_status"

  config.color = true
  config.fail_fast = ENV['FAIL_FAST'] || false
  config.fixture_path = File.join(File.expand_path(File.dirname(__FILE__)), "fixtures")
  config.include FactoryBot::Syntax::Methods
  config.infer_spec_type_from_file_location!
  config.mock_with :rspec
  config.raise_errors_for_deprecations!

  config.include Helpers

  config.before(:all) do
    FactoryBot.reload
  end

  config.before(:each, js: true) do |spec|
    client_option raise_on_js_errors: :show #:off, :show, :debug
  end

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before :each do
    Rails.cache.clear
  end

  # config.before :suite do
  #   MiniRacer_Backup = MiniRacer
  #   Object.send(:remove_const, :MiniRacer)
  # end

  # config.around(:each, :prerendering_on) do |example|
  #   MiniRacer = MiniRacer_Backup
  #   example.run
  #   Object.send(:remove_const, :MiniRacer)
  # end

  # config.filter_run_including focus: true
  # config.filter_run_excluding opal: true
  # config.run_all_when_everything_filtered = true

  # Fail tests on JavaScript errors in Chrome Headless
  class JavaScriptError < StandardError; end

  config.after(:each, js: true) do |spec|
    logs = page.driver.browser.manage.logs.get(:browser)
    if spec.exception
      all_messages = logs.select { |e| e.message.present? }
                         .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
      puts "Javascript client console messages:\n" +
             all_messages.join("\n") if all_messages.present?
    end
    errors = logs.select { |e| e.level == "SEVERE" && e.message.present? }
                 .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
    if client_options[:deprecation_warnings] == :on
      warnings = logs.select { |e| e.level == "WARNING" && e.message.present? }
                     .map { |m| m.message.gsub(/\\n/, "\n") }.to_a
      puts "\033[0;33;1m\nJavascript client console warnings:\n" + warnings.join("\n") + "\033[0;30;21m" if warnings.present?
    end
    # if client_options[:raise_on_js_errors] == :show && errors.present?
    if errors.present?
      puts "\033[031m\nJavascript client console errors:\n" + errors.join("\n") + "\033[0;30;21m"
    # elsif client_options[:raise_on_js_errors] == :debug && errors.present?
    #   binding.pry
    # elsif client_options[:raise_on_js_errors] != :off && errors.present?
    #   raise JavaScriptError, errors.join("\n")
    end
  end
  HyperSpec::Helpers.alias_method :on_client, :before_mount

end

# If you are NOT using webpacker remove this block
# config.before(:suite) do
#   # compile front-end
#   Webpacker.compile
#   system('bundle exec rake assets:precompile')
# end unless ENV[ 'PRECOMPILED' ]

# unless Webpacker.compiler.fresh? #&& !ENV['PRECOMPILE'].blank?
#   #ENV['PRECOMPILE'] = 'PRECOMPILED'
#   puts "== Webpack compiling =="
#   Webpacker.compiler.compile
#   #system('bundle exec rake assets:precompile')
#   puts "== Webpack compiled =="
# end

#### run  bundle exec chromedriver-update 81.0.4044.138
# bundle exec chromedriver --version
#  google-chrome --version
# version = `chromium --version`.split(' ')[1]
# path = `which chromium`.chop
# puts "#{version} #{path} #{`bundle exec chromedriver --version`}"

#Webdrivers::Chromedriver.required_version = ENV['CHROME_DRIVER_VERSION'] unless ENV['CHROME_DRIVER_VERSION'].blank? #'81.0.4044.138'
#Selenium::WebDriver::Chrome.path = `which chromedriver`.chop
#Webdrivers::Chromedriver.update
# remove driver path from default travis config

require 'webdrivers'
Capybara.register_driver :chrome_headless_docker_travis do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--no-sandbox')
  options.add_argument('--headless')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--remote-debugging-port=9222')
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 240 # instead of the default 60
  client.open_timeout = 240 # instead of the default 60
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, http_client: client)
end
Webdrivers::Chromedriver.update
Webdrivers::Geckodriver.update

unless Webpacker.compiler.fresh? #&& !ENV['PRECOMPILE'].blank?
  #ENV['PRECOMPILE'] = 'PRECOMPILED'
  puts "== Webpack compiling =="
  Webpacker.compiler.compile
  #system('bundle exec rake assets:precompile')
  puts "== Webpack compiled =="
end

Capybara.default_max_wait_time = 15

#Capybara.javascript_driver = :chrome_headless_docker_travis

#options.addArguments("start-maximized"); // open Browser in maximized mode
#options.addArguments("disable-infobars"); // disabling infobars
#options.addArguments("--disable-extensions"); // disabling extensions
#options.addArguments("--disable-gpu"); // applicable to windows os only

# save browser console log ==> check_errors
# page.driver.browser.manage.logs.get(:browser) # :driver, etc.