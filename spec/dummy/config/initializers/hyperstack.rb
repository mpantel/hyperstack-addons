# transport controls how push (websocket) communications are
# implemented.  The default is :none.
# Other possibilities are :action_cable, :pusher (see www.pusher.com)
# or :simple_poller which is sometimes handy during system debug.

Hyperstack.transport = :action_cable # :pusher, :simple_poller or :none


# Hyperstack.import 'react/react-source-browser' # uncomment this line if you want hyperstack to use its copy of react
if Rails.env.development?
  Hyperstack.import 'hyperstack/hotloader', client_only: true
end

#class ReactiveRecord::Broadcast; def self.send_to_server(*args); end; end
Hyperstack.class_eval do
  def self.on_server?
    Rails.const_defined?('Server') || (Rails.const_defined?('Puma') && File.basename($0).present? && File.basename($0).include?('puma'))
  end
end

# server_side_auto_require will patch the ActiveSupport Dependencies module
# so that you can define classes and modules with files in both the
# app/hyperstack/xxx and app/xxx directories.  For example you can split
# a Todo model into server and client related definitions and place this
# in `app/hyperstack/models/todo.rb`, and place any server only definitions in
# `app/models/todo.rb`.

require "hyperstack/server_side_auto_require.rb"

# set the component base class

Hyperstack.component_base_class = 'HyperComponent' # i.e. 'ApplicationComponent'

# prerendering is default :off, you should wait until your
# application is relatively well debugged before turning on.

Hyperstack.prerendering = :off # or :on
# Hyperstack.configuration do |config|
#   # docker run -d --rm -p  6379:6379 redis # locally
#   # config.connection = { adapter: "redis", redis_url: 'redis://127.0.0.1:6379/2/Hyperstack' }
#
#   #   # config.prerendering_files = ["react-server.js", "react_ujs.js", "client_and_server.js",'jquery.js', "hyperstack-prerender-loader.js"]
#
#
#   config.connect_session = true
# end

# add this line if you need jQuery AND ARE NOT USING WEBPACK
# Hyperstack.import 'hyperstack/component/jquery', client_only: true

# change definition of on_error to control how errors such as validation
# exceptions are reported on the server
module Hyperstack
  def self.on_error(operation, err, params, formatted_error_message)
    ::Rails.logger.debug(
      "#{formatted_error_message}\n\n" +
        Pastel.new.red(
          'To further investigate you may want to add a debugging '\
        'breakpoint to the on_error method in config/initializers/hyperstack.rb'
        )
    )
  end
end if Rails.env.development?
