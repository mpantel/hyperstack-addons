require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true
  # allowed request origins
  config.action_cable.allowed_request_origins = [
                                                 /(http|ws)s?\:\/\/127\.0\.0\.1\:?[0-9]*/,
                                                 /(http|ws)s?\:\/\/localhost\:?[0-9]*/,
                                                 /(http|ws)s?\:\/\/0\.0\.0\.0\:?[0-9]*/
  ]

  #config.action_cable.url = (RUBY_PLATFORM =~ /darwin/ ? "ws://127.0.0.1:#{ENV['PORT']}/cable" : "wss://w3.test.ru.aegean.gr/cable")
  #config.action_cable.url = (RUBY_PLATFORM =~ /darwin/ ? "ws://" + [Capybara.current_session.server.host, Capybara.current_session.server.port].reject(&:blank?).join(':')  + "/cable" : "wss://w3.test.ru.aegean.gr/cable")
  config.action_cable.mount_path = "/cable"

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # added by hyperstack installer
  config.assets.paths << Rails.root.join('public', 'packs-test', 'js').to_s
end
