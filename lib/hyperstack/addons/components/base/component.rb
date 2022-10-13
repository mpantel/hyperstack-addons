require 'hyperstack/addons/shared/images_import'
require 'hyperstack/addons/shared/base/common_methods'

module Base
  class Component < ::HyperComponent
    include ImagesImport
    include Common
    include CommonMethods
    #param :test
  end
end