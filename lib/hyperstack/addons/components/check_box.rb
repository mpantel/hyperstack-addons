class CheckBox < Base::Component
  param :checked
  param :className, default: nil, allow_nil: true
  fires :change
  param :value, default: nil, allow_nil: true
  param :label, default: nil, allow_nil: true
  render do
    DIV(className: "form-check #{className}") do
      LABEL(className:"form-check-label"){ label } if label
      INPUT(value: value, type: :checkbox, checked: checked, className: "form-check-input ml-2").
        on(:change) { |evt| change!(evt) }
      end
  end
end