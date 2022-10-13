class DatePickerInput < Base::Component
  param :selected, default: ''
  param :className, default: nil
  param :with_time, default: false
  param :only_time, default: false
  param :withPortal, default: false
  param :custom_time_intervals, default: false

  fires :change
  fires :blur
  fires :key_down

  render do
    # alert "event_date: #{@event_date}"
    # alert "selected: #{selected}"
    # alert "with_time: #{with_time}"
    DatePicker({
                 className: className || "form-control",
                 placeholderText: with_time ? "HH/MM/EEEE ΩΩ:ΛΛ" : "HH/MM/EEEE",
                 isClearable: true,
                 dateFormat: [with_time ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy'],
                 timeFormat: "HH:mm",
                 todayButton: "Σήμερα",
                 onBlur: lambda { blur! },
                 onKeyDown: lambda { |key| key_down!(`#{key}.keyCode`,@current_value) },
                 onChange: lambda do |date|
                   # fix react date time zone difference
                   @current_value = date#(with_time || date.blank?) ? date : Time.parse(date.strftime('%Y-%m-%d'))
                   #mutate @event_date = normalized_date
                   change!(@current_value)
                   # change!(date)
                 end
               }.
      merge(with_time ? { showTimeSelect: true } : {}).
      merge(only_time ? { showTimeSelectOnly: true } : {}).
      merge(withPortal ? { withPortal: withPortal } : {}).
      merge(custom_time_intervals ? { timeIntervals: custom_time_intervals } : {}).
      merge(selected.blank? ? {} : { selected: @current_value =Time.parse(selected) && `new Date(#{Time.parse(selected)})` })#.
    #merge(@event_date.blank? ? {} : { selected: `new Date(#{Time.parse(@event_date).iso8601})` || '' })
    )

    # on(:change_raw)  {|e| mutate.event_date Time.parse(e.target.value)
    # alert "change! #{e.target.value}" }

  end
end
