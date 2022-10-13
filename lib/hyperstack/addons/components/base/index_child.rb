module Base
  class IndexChild < Base::Index

    param :row
    param :editable_columns, default: nil, allow_nil: true
    fires :close_modal
    param :action_title, default: nil
    param :parent, default: nil, allow_nil: true
    param :parent_column, default: nil, allow_nil: true

  end
end