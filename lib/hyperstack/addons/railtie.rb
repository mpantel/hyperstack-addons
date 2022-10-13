module Hyperstack
  module Addons
    class Railtie < ::Rails::Railtie
       initializer 'hyperstack.addons.load.paths', :before => :set_autoload_paths  do |app|
      #    app.config.eager_load_paths <<  [Rails.root,'app','hyperstack','components']. join('/')
      #   app.config.autoload_paths <<  [Rails.root,'app','hyperstack','components']. join('/')
      #   app.config.eager_load_paths << [Gem.loaded_specs['hyperstack-addons'].full_gem_path,'lib','hyperstack','addons','components','base'].join('/')
      #   app.config.autoload_paths << [Gem.loaded_specs['hyperstack-addons'].full_gem_path,'lib','hyperstack','addons','components','base'].join('/')
      #    app.config.eager_load_paths << [Gem.loaded_specs['hyperstack-addons'].full_gem_path,'lib','hyperstack','addons','components'].join('/')
      #   app.config.autoload_paths << [Gem.loaded_specs['hyperstack-addons'].full_gem_path,'lib','hyperstack','addons','components'].join('/')
          app.config.eager_load_paths << [Gem.loaded_specs['hyperstack-addons'].full_gem_path,'lib','hyperstack','addons','shared'].join('/')
         app.config.autoload_paths << [Gem.loaded_specs['hyperstack-addons'].full_gem_path,'lib','hyperstack','addons','shared'].join('/')
       end
      initializer 'hyperstack.addons.assets.paths', :after => :append_assets_path do |app|
        #app.config.assets.paths <<  [Rails.root,'app','hyperstack','components']. join('/')
        app.config.assets.paths <<  [Gem.loaded_specs['hyperstack-addons'].full_gem_path,'lib'].join('/')
      end
    end
  end
end
