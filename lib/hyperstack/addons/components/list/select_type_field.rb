module ListComponents
  class SelectField < Base::Component
    include Base::CommonMethods

    param :field_value, default: []
    fires :update_field

    before_mount do
      initialization
    end

    def initialization
      @_field_value = field_value
      selected_option_and_options = @_field_value.split(select_identifier)
      @title = selected_option_and_options[0]
      @other_option = (@_field_value.include?("#{options_separator}#{other_option_identifier}") ? "#{options_separator}#{other_option_identifier}" : "")
      @options = (selected_option_and_options[1].blank? ? [] : selected_option_and_options[1].gsub(@other_option,"").split(options_separator))
      @new_item_added = false
    end

    def update_field_value
      @_field_value = "#{@title}#{select_identifier}#{@options.join(options_separator)}#{@other_option}#{select_identifier}"
    end

    def default_select_string_value
      "#{select_identifier}#{select_identifier}"
    end

    def new_option_btn
      SPAN do
        " ".span
        A(href: '') do
          FontAwesome(icon: 'fa-plus', modifiers: 'fa-fw', text: 'Προσθήκη Επιλογής')
        end.on(:click) do |e|
          e.prevent_default
          mutate @new_item_added = true
        end
      end
    end

    def show_options_inputs
      option_input = Proc.new do |option = nil, option_index = nil|
        Input(key: "select_option_#{option_index}", value: option, placeholder: "προσθέστε τιμή επιλογής", className: 'form-control input-sm').
          on(:blur) do |v|
          unless v.to_s&.strip.blank?
            option_index ? @options[option_index] = v.to_s.strip : @options << v.to_s.strip
            @new_item_added = false unless option_index
            update_field!(update_field_value)
          end
        end
      end
      @options.each_with_index do |option, option_index|
        next if option == other_option_identifier
        option_input.call(option, option_index)
        remove_option(option_index)
      end
      if @new_item_added
        option_input.call
        remove_option
      end
    end

    def select_type_toggle
      CheckBox(label: "Πεδίο Επιλογών", checked: !@_field_value.blank? && (@_field_value =~ select_regex) ? true : false, className: 'input-sm').
               on(:change) do |e|
                 if confirm("Αν αλλάξετε τύπο δεδομένων για το συγκεκριμένο πεδίο, οι προηγούμενες τιμές του πεδίου θα διαγραφούν. Είστε σίγουροι ότι θέλετε να αλλάξετε τύπο δεδομένων;")
                   @_field_value = (e.target.checked ? "#{default_select_string_value}" : "")
                   update_field!(@_field_value)
                 end
               end

    end

    def add_other_option
      CheckBox(label: "Επιλογή Άλλο", checked: @_field_value.include?("#{options_separator}#{other_option_identifier}") ? true : false,
               className: 'input-sm').
               on(:change) do |e|
                 @other_option = (e.target.checked ? "#{options_separator}#{other_option_identifier}" : "")
                 update_field!(update_field_value)
               end unless @options.blank?
    end

    def remove_option(option_index = nil)
      SPAN do
        " ".span
        A(href: '') do
          FontAwesome(icon: 'fa-minus', modifiers: 'fa-fw', text: 'Διαγραφή Επιλογής')
        end.on(:click) do |e|
          e.prevent_default
          if option_index
            @options.delete_at(option_index)
            update_field!(update_field_value)
          else
            mutate @new_item_added = false
          end
        end
      end
    end

    def field_title
      Input(key: "select_title", value: @title, placeholder: "Τίτλος Πεδίου Επιλογών", className: 'form-control input-sm').
        on(:blur) do |v|
        unless v.to_s&.strip.blank?
          @title = v.to_s&.strip
          update_field!(update_field_value)
        end
      end
    end

    render(DIV) do
      select_type_toggle
      if !@_field_value.blank? && (@_field_value =~ select_regex)
        field_title
        show_options_inputs
        new_option_btn
        add_other_option
      end
    end

  end
end