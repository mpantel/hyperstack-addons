module ListComponents
  class RenderForSubmission < ListComponents::Render

    param :list_template

    def set_placeholders
      @placeholders = list_template.first
    end

    def show_inner_row_actions
      false
    end

    def inner_push; end

    def internal_render_call(index)
      ListComponents::RenderForSubmission(key: [index].join("_"),
                                          list: @_list[index],
                                          content_component: content_component,
                                          list_type: :inputs_list,
                                          row_actions: show_inner_row_actions,
                                          list_template: list_template,
                                          per_field_content_component: per_field_content_component,
      ).
        on(:update_list) do |sub_list|
        @_list[index] = sub_list
        update_list!(@_list)
      end
    end

    def select_type_field_controls(index)
      ;
    end

    def other_option_selected(other_value, options_simple)
      other_value == other_option_identifier || !(options_simple + [nil, '']).include?(rendered_value(other_value))
    end

    def rendering_cell(index)
      return if @_list[index].include?(hidden_field_identifier)
      if @placeholders[index] =~ select_regex
        selected_option_and_options = @placeholders[index].split(select_identifier)
        options = selected_option_and_options[1].split(options_separator).map { |o| [o, o] }
        options_simple = selected_option_and_options[1].split(options_separator)
        if selected_option_and_options[0].blank? && @_list[index].blank?
          @_list[index] = options.first.first
          update_list!(@_list)
        end
        SPAN() { "#{selected_option_and_options[0]}: " } unless selected_option_and_options[0].blank?
        SELECT(key: @placeholders[index], name: @placeholders[index],
               className: "form-select form-control",
               defaultValue: other_option_selected(@_list[index], options_simple) ? other_option_identifier : rendered_value(@_list[index]),
               disabled: identify_regex(@_list[index]) == read_only_field_identifier
        ) do
          OPTION(value: nil) { " -- επιλογές για: #{selected_option_and_options[0]} -- " } unless selected_option_and_options[0].blank?
          options.each do |option|
            OPTION({ value: option[0] }) { other_option_selected(option[1], options_simple) ? "Άλλο" : option[1] }
          end
        end.on(:change) do |e|
          @_list[index] = e.target.value
          update_list!(@_list)
        end
        if other_option_selected(@_list[index], options_simple)
          text_rendering(index, true, :input)
        end
      else
        SPAN() { "#{ rendered_value(@placeholders[index])}: " } unless @placeholders[index].blank? || identify_regex(@placeholders[index]) == read_only_field_identifier
        text_rendering(index)
      end
    end

    def text_rendering(index, reset_placeholder = false, custom_content_component = nil)
      _content_component = custom_content_component || (identify_regex(@placeholders[index]).blank? ? content_component : component_key_by_regex(identify_regex(@placeholders[index])))
      text_rendering_case(index, _content_component, reset_placeholder)
    end

    render do
      initialization
      base_render
    end

  end
end