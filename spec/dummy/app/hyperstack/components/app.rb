
require 'hyperstack/addons/components'
require 'hyperstack/addons/pager'
require 'hyperstack/addons/list'
require 'hyperstack/addons/components/select'
require 'hyperstack/addons/components/check_box'
require 'hyperstack/addons/components/currency'
require 'hyperstack/addons/editors'

class App < HyperComponent
  include Hyperstack::Router
  history :browser
  render do
    DIV do
      'App'
      # define routes using the Route psuedo component.  Examples:
      # Route('/foo', mounts: Foo)                : match the path beginning with /foo and mount component Foo here
      # Route('/foo') { Foo(...) }                : display the contents of the block
      # Route('/', exact: true, mounts: Home)     : match the exact path / and mount the Home component
      # Route('/user/:id/name', mounts: UserName) : path segments beginning with a colon will be captured in the match param
      # see the hyper-router gem documentation for more details
    end
    Samples::Index()
  end
end

