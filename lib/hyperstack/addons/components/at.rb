class AT < Base::Component
  param :type, default: nil, allow_nil: true
  collect_other_params_as :attributes
  render do
    # we just pass along any incoming attributes and render each children
    A(attributes) { children.each(&:render) }
  end
end

