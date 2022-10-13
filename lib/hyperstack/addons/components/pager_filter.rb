class PagerFilter < Base::Component

  param :filters, default: {}
  param :filter_values, default: {}
  param :loading, default: nil
  param :show_in_menu, default: nil
  param :open_modal, default: false
  param :quick_filter_key, default: nil, allow_nil: true
  fires :filter
  fires :reset_filter
  fires :set_quick_filter

  # before_mount do
  #   puts "------------"
  # end

  def has_init_filter?
    filters.each { |filter_key, filter_value|
      return true unless filter_value["initial_value"].blank?
    }
    return false
    end

  def place_holder(format)
    case format&.to_sym
    when :date then
      "ΗΗ/ΜΜ/ΕΕΕΕ"
    when :currency then
      "*.**"
    else
      ''
    end
  end

  def get_filter_value(filter, position = nil)
    case position&.to_sym
    when :first
      filter_values[filter[:scope].to_sym].try(:first) || ''
    when :second
      filter_values[filter[:scope].to_sym].try(:last) || ''
    else
      filter_values[filter[:scope].to_sym]
    end
  end

  def apply_filter!(v, filter, position)
    filter!(set_filter_value(v, filter, position, filter_values: filter_values))
  end
  def input_for_filter(filter, position = nil)
    if [:date, :datetime, :single_date].include? filter[:format]
      DatePickerInput({ className: "form-control", selected: get_filter_value(filter, position) }).
        on(:change) { |v| apply_filter!(v, filter, position) }.
        on(:key_down) {|key_code,v| apply_filter!(v, filter, position) if key_code==13}
    else
      case filter[:format]&.to_sym
      when :filter_look_up
        Selector(key: [filter[:source], filter[:column]&.values&.first, filter[:format], position].join,
                 value: get_filter_value(filter, position),
                 look_up: filter,
                 filter_values: filter_values).
          on(:change) { |v| apply_filter!(v, filter, position) }
      when :boolean
        Selector(key: [filter[:source], filter[:column]&.values&.first, filter[:format], position].join,
                 value: get_filter_value(filter, position),
                 options: [[true, 'ναι'], [false, 'όχι']]).
          on(:change) { |v| apply_filter!(v, filter, position)}
      else
        Input(value: get_filter_value(filter, position),
              placeholder: place_holder(filter[:format]),
              className: "form-control").
          on(:blur) { |v| apply_filter!(v, filter, position) }.
          on(:key_down) {|key_code,v| apply_filter!(v, filter, position) if key_code==13}
      end
    end
  end

  def active_filter
    af = []
    if filters.count > 0
      af += filters.reject { |_, filter| [:filter_look_up, :date, :currency, :datetime].include? filter[:format] }.values.map do |filter|
        [filter[:description], ':', get_filter_value(filter)].join(' ') unless get_filter_value(filter).blank?
      end

      af += filters.select { |_, filter| [:date, :currency, :datetime].include? filter[:format] }.values.map do |filter|
        [filter[:description], ':', 'από:', get_filter_value(filter, :first), 'έως:', get_filter_value(filter, :second)].join(' ') unless [:first, :second].map { |pos| get_filter_value(filter, pos) }.reject(&:blank?).blank?
      end
      af += filters.select { |_, filter| [:filter_look_up].include? filter[:format] }.values.map do |filter|
        [filter[:description], ':', get_filter_value(filter)].join(' ') unless get_filter_value(filter).blank?
      end
    end
    af.reject(&:nil?).join(', ')
  end

  def set_quick_filter#(filter_key)

    SELECT(key: quick_filter_key.to_s, className: "form-select", value: quick_filter_key) do
      OPTION(value: '') { 'Χωρίς Γρήγορο Φίλτρο ' }
      filters.each do |filter_key, filter|
        OPTION(value: filter_key) { filter[:description] }
      end
    end.on(:change) do |e|

      # mutate @quick_filter_key = e.target.value unless e.target.value.blank?
      set_quick_filter!(e.target.value.to_s) #unless e.target.value.blank?
      # quick_filter
      # UserPreference.new(
      # user_id: ::User.current.id,
      # component_name: component_name,
      # preference_type: preference_type,
      # preference_json: attributes[:initial_preference].call(default_values[preference_type.to_s][:default_value]).to_json,
      # description: "νέα προτίμηση"
      # )
    end
  end

  def display_filters(quick_filter: false)
    selected_filters = filters.select { |filter_key, filter| quick_filter ? filter_key.to_s == quick_filter_key.to_s : true }
    span_display_class = (quick_filter ? "d-flex" : "")
    margin_bottom = "mb-3" unless quick_filter

    selected_filters.reject { |_, filter| [:filter_look_up, :date, :currency, :datetime].include? filter[:format] }.values.in_groups_of(2).each do |g|
      DIV(className: 'row col-md-12') do
        g.reject(&:nil?).each do |filter|
          DIV(className: "row col-12 #{margin_bottom}") do
            SPAN(className: "#{span_display_class}") do
              LABEL(className: 'col-form-label text-nowrap', style:{marginRight:"1em"}) { [filter[:description], ':'].join }
              DIV(className: '') do
                input_for_filter(filter)
              end
            end

          end

        end
      end
    end

    selected_filters.select { |_, filter| [:date, :currency, :datetime].include? filter[:format] }.values.each do |filter|
      DIV(className: "row col-12 #{margin_bottom}") do
        SPAN(className: "#{span_display_class}") do
          LABEL(className: 'col-form-label text-nowrap', style:{marginRight:"1em"}) { [filter[:description], ':'].join }
          SPAN(className: "input-group  ") do
            SPAN(className: "input-group-text") { 'από:' }
            input_for_filter(filter, :first)
            SPAN(className: "input-group-text") { 'έως:' }
            input_for_filter(filter, :second)
          end
        end
      end
    end

    selected_filters.select { |_, filter| filter[:format] == :filter_look_up }.values.each do |filter|
      DIV(className: "row col-12 #{margin_bottom}") do
        SPAN(className: "#{span_display_class}") do
          # DIV(className: '') do
          LABEL(className: 'col-form-label text-nowrap') { [filter[:description], ':'].join }
          # end
          DIV(className: '') do
            input_for_filter(filter)
          end
        end

      end
    end
  end

  def filter_body
    Modal(
      with_trigger_button: false,
      trigger: !!@open_filter_modal ^ open_modal, #use XOR to open modal with parent parameter and close it with instance variable @@open_filter_modal
      large_modal: true,
      scrollable: false,) {
      DIV(className: "modal-header", style: { fontSize: "1rem" }) {
        H5(className: "modal-title") { "Φίλτρα" }
        inner_filter_body
      }
      DIV(className: "modal-body", style: { fontSize: "1rem" }) {
        display_filters_container
      }
    }.on(:trigger_button_clicked) {
      mutate @open_filter_modal = !@open_filter_modal
    }

  end

  def display_filters_container
    DIV(className: 'col-lg-12 row', &method(:display_filters))
  end

  def inner_filter_body
    SPAN(className: "mr-2",) do
      set_quick_filter
    end
      DIV(className: "btn-group btn-group-sm ", "role" => "group") do
        search_btn
        restore_filter_btn
        no_filter_btn
      end
    close_modal_btn

  end

  def restore_filter_btn(style: "btn-primary")
    BUTTON(className: "btn #{style} btn-sm", 'data-bs-toggle': "tooltip", title: active_filter) { 'Επαναφορά' }.on(:click) {
      reset_filter!
    } if has_init_filter?
  end

  def no_filter_btn(style: "btn-primary")
    BUTTON(className: "btn #{style} btn-sm", 'data-bs-toggle': "tooltip", title: active_filter) { 'Χωρίς Φίλτρο' }.on(:click) {
      filter!({}, true)
    }
  end

  def search_btn
    BUTTON(className: ['btn btn-primary btn-sm', loading ? ' disabled' : ''].join, 'data-bs-toggle': "tooltip", title: active_filter, "data-bs-dismiss": "modal") do
      'Αναζήτηση'.span
      Loading() if loading
    end.
      on(:click) {
        mutate @open_filter_modal = !@open_filter_modal
      }
  end

  def close_modal_btn
    BUTTON(className: "btn-close h2", "data-bs-dismiss": "modal",style:{marginLeft: "5px", marginTop: "5px"}, "aria-label": "Close").on(:click) {
      mutate @open_filter_modal = !@open_filter_modal
    }
  end

  def reset_filters_body
      SPAN(className: "align-top mr-2", style: { fontSize: "1rem" }) do
        unless active_filter.blank?
          SPAN(className:"btn-group", style: { marginRight: "5px" }) {
            restore_filter_btn(style: "btn-secondary")
            no_filter_btn(style: "btn-secondary")
          }
        end
        SPAN(className:"", style: { fontSize: "1rem", position: "relative",
        left: "250px", top: "-35px"}){
          display_filters(quick_filter: true)
        }
      end
  end

  def loaded
    filters.loaded? && filter_values.loaded? && loading.loaded? && show_in_menu.loaded? && open_modal.loaded? && quick_filter_key.loaded?
  end

  render do
    filter_body if loaded && filters.count > 0
    reset_filters_body
  end
end