class Currency < Base::Input
  param :precision, default: 2, allow_nil: true

  def add_trailing_zero(value)
    if value =~ /\./
      value
    else
      value + '.0'
    end
  end

  render do
    INPUT(key: key, type: type, defaultValue: value, class: className,
          min: min, max: max, placeholder: placeholder).
      on(:change) do |evt|
      caret_position = evt.target.selectionStart
      caret_position -= 1 if [',', '.'].include? evt.target.value[caret_position - 1]
      value_no_coma = evt.target.value.tr(',', '.')
      values = value_no_coma.split('.')
      last_point = (value_no_coma[-1] == '.')
      value = values.count > 1 ? [values[0...-1].join, values[-1]].join('.') : (values.first || '') + (last_point ? '.' : '')
      #alert(value)
      evt.target.value = (precision <= 0 || (values.count > 1 && values[-1].length > precision && (precision.times.all? { |p| value.length > p && value[-(p + 1)] != '.' }))) ? value.to_f.round(precision) : value
      caret_position += 1 if [',', '.'].include? evt.target.value[caret_position]
      evt.target.selectionStart = caret_position
      evt.target.selectionEnd = caret_position
      @current_value = add_trailing_zero(evt.target.value)
      change!(@current_value)
    end.
      on(:blur) do |evt|
      evt.target.value = evt.target.value[0...-1] if evt.target.value[-1] == '.'
      @current_value = evt.target.value.blank? ? nil : add_trailing_zero(evt.target.value)
      blur!(@current_value)
    end.
      on(:key_down) { |evt| key_down!(evt.key_code,@current_value) }
  end
end

