module ListComponents
  class ListForSubmission < ListComponents::List

    param :list_template

    def set_current_type
      @current_type = list_type
    end

    def list_render_params
      super.merge({list_template: list_template, show_sort_buttons: show_sort_buttons, show_remove_button: show_remove_button, show_add_button: show_add_button})
    end

    # def toggle_view_btn;end

    def mount_render_component
      ListComponents::RenderForSubmission(list_render_params).on(:update_list) do |_list|
        update_list!(_list)
      end
    end

    render do
      base_render
    end

  end
end