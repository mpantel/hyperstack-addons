module ListComponents
  class Render < Base::Component
    include Base::CommonMethods

    param :list, default: []
    param :list_type, default: :inputs_list
    param :content_component, default: :input # :input, :editor, :json
    fires :update_list
    param :row_actions, default: true
    param :show_select_controls, default: false
    param :per_field_content_component, default: false
    param :include_read_only, default: true
    param :include_hidden, default: true
    param show_sort_buttons: true #false
    param show_remove_button: true
    param show_add_button: true
    param push_with_options: false
    param accepted_push_options: nil

    before_mount do
      @editable_indices = []
      set_placeholders
    end

    def initialization
      initialize_list
    end

    def initialize_list
      @_list = if list.is_a?(Hash)
                 list.to_a.map.with_index do |i, index|
                   i.is_a?(Array) && (!i[0].blank? || !@editable_indices.include?(index)) ? ["#{i[0]}#{read_only_field_identifier}#{hash_key_field_identifier}", i[1]] : i
                 end
               else
                 list
               end
    end

    def restore_list
      if list.is_a?(Hash)
        @_list.map do |i|
          i.is_a?(Array) ? [i[0].to_s.gsub(read_only_field_identifier, '').gsub(hash_key_field_identifier, ''), i[1]] : i
        end.to_h
      else
        @_list
      end
    end

    def set_placeholders
      @placeholders = []
    end

    def show_inner_row_actions
      true
    end

    def row_actions_local(index)
      mount_item_remove(index) if show_remove_button
      mount_item_up(index) if show_sort_buttons
      mount_item_down(index) if show_sort_buttons
      mount_item_to_top(index) if show_sort_buttons
      mount_item_to_bottom(index) if show_sort_buttons
      mount_item_move(index) if show_sort_buttons
    end

    def mount_item_remove(index)
      TD(className: "col-sm-auto") do
        Base::ItemRemove(key: ["remove_", index].to_s, index: index).on(:update_list) do |index|
          @_list.delete_at(index)
          update_list!(restore_list)
        end
      end
    end

    def mount_item_to_top(index)
      TD(className: "col-sm-auto") do
        Base::ItemUp(key: ["top_", index].to_s, index: index, css_class: "fa-sort-amount-up-alt").on(:update_list) do |index|
          @_list = move_to_top(array: @_list, index: index)
          update_list!(restore_list)
        end
      end if index > 0
    end

    def mount_item_up(index)
      TD(className: "col-sm-auto") do
        Base::ItemUp(key: ["up_", index].to_s, index: index).on(:update_list) do |index|
          @_list = swap_array_elements(array: @_list, index: index, goes: :up)
          update_list!(restore_list)
        end
      end if index > 0
    end

    def mount_item_to_bottom(index)
      TD(className: "col-sm-auto") do
        Base::ItemDown(key: ["down_to_bottom", index].to_s, num_of_items: @_list.count, index: index, css_class: "fa-sort-amount-down-alt").on(:update_list) do |index|
          @_list = move_to_bottom(array: @_list, index: index)
          update_list!(restore_list)
        end
      end if index < @_list.count - 1
    end

    def mount_item_move(index)
      TD(className: "col-sm-auto") do
        Base::ItemMove(key: ["move_", index].to_s, index: index, num_of_elements: @_list.count).on(:update_list) do |new_index|
          @_list = swap_array_elements(array: @_list, index: index, goes: new_index)
          update_list!(restore_list)
        end
      end if @_list.count > 1
    end

    def mount_item_down(index)
      TD(className: "col-sm-auto") do
        Base::ItemDown(key: ["down_", index].to_s, num_of_items: @_list.count, index: index).on(:update_list) do |index|
          @_list = swap_array_elements(array: @_list, index: index, goes: :down)
          update_list!(restore_list)
        end
      end if index < @_list.count - 1
    end

    def render_read_only(index, reset_placeholder)
      value = (rendered_value(@placeholders[index]).blank? ? @_list[index] : @placeholders[index]).gsub(hash_key_field_identifier, '')
      reset_placeholder = true if rendered_value(@placeholders[index]).blank?
      DIV() do
        SPAN() { "#{reset_placeholder ? rendered_value(value) : rendered_value(@placeholders[index])}" }
        edit_hash_key(index) if (is_key_value_pair && !@editable_indices.include?(index)) #!@_list[index].blank?)
      end
    end

    def edit_hash_key(index)
      SPAN do
        " ".span
        A(href: '') do
          "".span
          FontAwesome(icon: "fa-pen text-secondary", modifiers: 'fa-fw', text: 'Επεξεργασία')
        end.on(:click) do |e|
          e.prevent_default
          mutate @_list[index] = @_list[index].to_s.gsub(read_only_field_identifier, '').gsub(hash_key_field_identifier, '')
          mutate @editable_indices << index
        end
      end
    end

    def render_input(index, reset_placeholder)
      ir = @_list[index].to_s.strip
      Input(key: ["input_", index].join, value: rendered_value(@_list[index]),
            className: 'form-control input-sm', name: index.to_s,
            placeholder: reset_placeholder ? nil : rendered_value(@placeholders[index])).
        on(:blur) do |v|
        @_list[index] = v.to_s.strip + (ir == other_option_identifier ? ir : identify_regex(@_list[index])).to_s
        @editable_indices.delete(index)
        update_list!(restore_list)
      end
    end

    def render_currency(index, reset_placeholder)
      Currency(key: ["currency_", index].join, value: rendered_value(@_list[index]).to_f,
               className: 'form-control input-sm', name: "currency_#{index.to_s}",
               placeholder: reset_placeholder ? nil : rendered_value(@placeholders[index])).
        on(:blur) do |v|
        @_list[index] = ((true if Float(v.to_s.strip) rescue false) ? v.to_s.strip : "0") + identify_regex(@_list[index]).to_s
        update_list!(restore_list)
      end
    end

    def render_editor(index, reset_placeholder)
      DIV do
        Editor(key: ["00", @placeholders[index], index].join,
               value: rendered_value(@_list[index]) || '',
               placeholder: reset_placeholder ? nil : rendered_value(@placeholders[index]), editor_type: :trix).
          on(:blur) { |value|
            @_list[index] = value.to_s.strip + identify_regex(@_list[index]).to_s
            update_list!(restore_list)
          }
      end
    end

    def inner_push
      Hyperstack::Component::ReactAPI.create_element(
        push_with_options ? ListComponents::ItemPushWithOptions : ListComponents::ItemPush,
        { key: "inner_push", list: list }.merge(accepted_push_options || {})
      ).on(:update_list) do |new_item|
        new_item.is_a?(Hash) && list.is_a?(Hash) ? @_list += new_item.to_a : @_list << new_item
        update_list!(restore_list)
      end if (show_add_button)
    end

    def internal_render_call(index)
      ListComponents::Render(key: [index, "I_R_C"].join("_").to_s,
                             list: @_list[index],
                             content_component: content_component,
                             list_type: :inputs_list,
                             row_actions: show_inner_row_actions,
                             show_select_controls: show_select_controls,
                             per_field_content_component: per_field_content_component,
                             include_read_only: include_read_only,
                             show_sort_buttons: !is_key_value_pair(index),
                             show_remove_button: !is_key_value_pair(index),
                             show_add_button: !is_key_value_pair(index),
                             push_with_options: push_with_options,
                             accepted_push_options: accepted_push_options,
      ).
        on(:update_list) do |sub_list|
        @_list[index] = sub_list
        update_list!(restore_list)
      end
    end

    def text_rendering(index, reset_placeholder = false)
      _content_component = if @_list[index].to_s.include?(read_only_field_identifier) && @_list[index].to_s.include?(hash_key_field_identifier)
                             :read_only
                           elsif @editable_indices.include?(index)
                             :input
                           else
                             content_component
                           end
      text_rendering_case(index, _content_component, reset_placeholder)
    end

    def text_rendering_case(index, cc, reset_placeholder = false)
      case cc.to_sym&.to_sym
      when :editor
        render_editor(index, reset_placeholder)
      when :currency
        render_currency(index, reset_placeholder)
      when :read_only
        render_read_only(index, reset_placeholder)
      when :hidden
        # render_read_only(index, reset_placeholder)
      else
        render_input(index, reset_placeholder)
      end
    end

    def rendering_cell(index)
      text_rendering(index)
      select_per_field_content_component(index) if per_field_content_component
    end

    def select_per_field_content_component(index)
      ' '.span
      SELECT(key: @_list[index], name: "επιλογές για τύπο πεδίου",
             className: "form-select form-control", defaultValue: identify_regex(@_list[index]).to_s) do
        OPTION(value: '') { " -- επιλογές για τύπο πεδίου -- " }
        content_component_hash.select { |k, v|
          (include_read_only || (k.to_s != 'read_only')) &&
            (include_hidden || (k.to_s != 'hidden'))
        }.each do |type, json|
          OPTION({ value: json[:regex] }) { json[:title] }
        end
      end.on(:change) do |e|
        @_list[index] = rendered_value(@_list[index]) + e.target.value
        update_list!(restore_list)
      end
    end

    def default_select_string_value
      "#{select_identifier}#{select_identifier}"
    end

    def other_option_selected(other_value, options_simple)
      false
    end

    def select_type_field_controls(index)
      ListComponents::SelectField(key: "select_field", field_value: @_list[index]).
        on(:update_field) do |field_value|
        @_list[index] = field_value
        update_list!(restore_list)
      end
    end

    def base_render
      TABLE(class: 'table table-borderless table-sm') do
        TBODY do
          @_list.each_with_index do |item, index|
            TR(style: { marginLeft: 0, marginRight: 0 }, className: "#{show_sort_buttons || show_remove_button ? "border" : ""} row") do
              row_actions_local(index) if row_actions
              TD(className: "col") do
                if item.is_a?(Array) || item.is_a?(Hash)
                  internal_render_call(index)
                else
                  rendering_cell(index) unless (@_list[index] =~ select_regex) && show_select_controls
                  select_type_field_controls(index) if show_select_controls
                end
              end
            end
          end
          TR(style: { marginLeft: 0, marginRight: 0 }, className: "row") do
            TD(className: "col") { inner_push }
          end
        end
      end
    end

    render do
      initialization
      base_render
    end

  end
end