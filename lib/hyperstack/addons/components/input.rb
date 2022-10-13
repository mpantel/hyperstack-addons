class Input < Base::Input
  param :number_step, default: 1

  render do
    #TODO: check key here
    INPUT(key: name || key,
          type: type,
          defaultValue: value,
          className: className,
          min: min,
          max: max,
          placeholder: placeholder,
          name: name,
          step: number_step
    ).
      on(:change) { |e| @current_value = e.target.value; change!(@current_value) }.
      on(:key_down) { |e| key_down!(e.key_code, @current_value) }.
      on(:blur) { |e| @current_value = e.target.value; blur!(@current_value) }
  end
end