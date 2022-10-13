# require 'react/router'
# require 'react/router/dom'
# require 'react/router/history'
# require 'hyperstack/internal/component'

require 'hyperstack/internal/router/isomorphic_methods'
require 'hyperstack/internal/router/class_methods'
require 'hyperstack/internal/router/helpers'
require 'hyperstack/internal/router/instance_methods'

require 'hyperstack/router/helpers'
#require 'hyperstack/router'

module Base
  class ComponentRouter < Component
      include Hyperstack::Router::Helpers


        after_mount do
          matomo_log
        end

        def matomo_log
          `
          if (typeof(_paq) !== 'undefined'){
            if ((typeof(currentUrl) == 'undefined') || currentUrl !== location.href) {
             if (typeof(currentUrl) !== 'undefined') _paq.push(['setReferrerUrl', currentUrl]);
             currentUrl = location.href;
             _paq.push(['setCustomUrl', currentUrl]);
             _paq.push(['setDocumentTitle']);  //, 'My New Title'
             // remove all previously assigned custom variables, requires Matomo (formerly Piwik) 3.0.2
             _paq.push(['deleteCustomVariables', 'page']);
             //_paq.push(['setGenerationTimeMs', 0]);
             _paq.push(['trackPageView']);
           }
        }
`
    end
  end
end
