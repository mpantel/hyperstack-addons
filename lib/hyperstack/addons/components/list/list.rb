module ListComponents
  class List < Base::Component
    include Base::CommonMethods

    param :list, default: []
    param :list_title, default: "Λίστα"
    param :content_component, default: :input # :input, :editor
    fires :update_list
    param :list_type, default: :inputs_list #:inputs_list, :inputs_grid
    param :header_push_for_finite_items, default: nil, allow_nil: true
    param :gsub_list_prefixes, default: false
    param :hide_toggle_view_btn, default: false
    param :show_select_controls, default: false
    param :per_field_content_component, default: false
    param :include_read_only, default: true
    param show_sort_buttons: true #false
    param show_remove_button: true
    param show_add_button: true
    param push_with_options: false
    param accepted_push_options: nil

    LIST_VIEW_HASH = {
      inputs_list: 'Λίστα',
      textarea: 'Πεδίο Κειμένου',
      # inputs_grid: 'Πίνακας',
      inputs_grid: 'Λίστα',
    }

    before_mount do
      set_current_type
    end

    def set_current_type
      @current_type = (list_depth(list) >= 2 ? :inputs_grid : list_type)
    end

    def list_in_textarea
      list.map { |item| item.is_a?(String) ? item : item.join(tab_separator) }.join(line_break)
    end

    def toggle_view_btn
      return nil if hide_toggle_view_btn || list_depth(list) > 2 || list.is_a?(Hash)
      BUTTON(className: 'btn btn-primary') do
        "Μετάβαση σε: #{@current_type == :textarea ? LIST_VIEW_HASH[list_type] : "Πεδίο Κειμένου"}".span
      end.on(:click) do |e|
        e.prevent_default
        mutate @current_type = (@current_type == list_type ? :textarea : list_type)
      end
    end

    def list_title_local
      SPAN { "#{list_title}" } unless list_title.blank?
    end

    def header_push
      SPAN do
        Hyperstack::Component::ReactAPI.create_element(
          push_with_options ? ListComponents::ItemPushWithOptions : ListComponents::ItemPush,
          { key: "header_push", list: list }.merge(accepted_push_options || {})
        ).on(:update_list) do |new_item|
          update_list!(list.is_a?(Hash) ? list.merge!(new_item) : list << new_item)
        end if [:inputs_list, :inputs_grid].include?(@current_type)
      end
    end

    def header
      TR(style: { marginLeft: 0 }) do
        TD(className: "col-sm-12", colSpan: 4) do
          list_title_local unless header_push_for_finite_items.nil? || header_push_for_finite_items.to_i == 0 || list.to_a.count < header_push_for_finite_items
          toggle_view_btn unless hide_toggle_view_btn || list_depth(list) > 2 || list.is_a?(Hash)
        end
      end
    end

    def footer
      TR(style: { marginLeft: 0 }) do
        TD(className: "col-sm-12") do
          if header_push_for_finite_items.nil? || header_push_for_finite_items.to_i == 0 || list.to_a.count < header_push_for_finite_items
            list_title_local
            header_push
          end
        end
      end
    end

    def textarea
      TR(scope: "row") do
        TD(scope: "col-sm-12") do
          TEXTAREA(key: [Time.now.to_i, Random.rand(1000)].map(&:to_s).compact.join('_'),
                   defaultValue: list_in_textarea, placeholder: "#{list_title}", className: 'form-control input-sm').
            on(:blur) do |e|
            _list = e.target.value
            _list = _list.gsub(/^\s*(?:\d*|[A-Z]{0,3}|[a-z]{0,3}|[\u0370-\u03ff]{0,3}|[\u1f00-\u1fff]{0,3}|[IVX]{0,4}|[ivx]{0,4})\s*[•.)]{1}\s*/m, "") if gsub_list_prefixes
            _list = _list.split(line_break)
            _list.map! { |item| item.split(tab_separator) } if list_depth(list) == 2 #if [:inputs_grid].include?(list_type)
            update_list!(_list)
          end
        end
      end
    end

    def list_render_params
      {
        key: list.to_s,
        list: list,
        content_component: content_component,
        list_type: list_type,
        show_select_controls: show_select_controls,
        per_field_content_component: per_field_content_component,
        include_read_only: include_read_only,
        show_sort_buttons: show_sort_buttons,
        show_remove_button: show_remove_button,
        show_add_button: show_add_button,
        push_with_options: push_with_options,
        accepted_push_options: accepted_push_options,
      }
    end

    def mount_render_component
      ListComponents::Render(list_render_params).on(:update_list) do |_list|
        update_list!(_list)
      end
    end

    def base_render
      TABLE(class: 'table table-bordered table-sm') do
        THEAD() { header }

        TBODY do
          @current_type == :textarea ? textarea : TR { TD { mount_render_component } }
        end
        TFOOT() { footer }
      end
    end

    render do
      base_render
    end

  end
end
