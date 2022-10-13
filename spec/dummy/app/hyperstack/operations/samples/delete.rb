module Samples
  class Delete < Hyperstack::ServerOp
    param :acting_user
    param :row_id
    param :action_type, default: :delete

    step do
      Sample.find(params.row_id)
    end
    step do |sample|
      sample.destroy
    end

  end
end