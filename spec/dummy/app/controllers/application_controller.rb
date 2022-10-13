class ApplicationController < ActionController::Base
  def acting_user
     Sample.find_or_create_by(description: 'sample acting user')
  end
end
