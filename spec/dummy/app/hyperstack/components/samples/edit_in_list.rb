module Samples
  class EditInList < Base::EditInList

    before_mount do
      # @list = { a: 1, b: 2, c: { x: 111, z: 333 }, d: [7, 9], e: [{ k: 100, l: 200 }, 10, 20], x: [["y", 90]] }#[["y", 90, 90],[2, 3, 90],[2, 3, 90]]#{ c: [2, 3], d: { x: "eks" } }#[[]]#[]#
      # @list_template = [["value with default content type", "value with input content type!!i!!", "value with trix content type&&e&&", "value with read-only content type((r((", "value with currency content type!!cur!!", "title of select field$$option 1***option 2***??()??$$"]]
      # @list = @list_template.map { |i| i.map { |e| "" } }
    end

    def prepend_extra_fields
      TR do
        TD(col_span: 2) do
          SPAN() { @list.to_s }
        end
      end
      # TR do
      #   TD(col_span: 2) do
      #     ListComponents::ListForSubmission(
      #       list: @list,
      #       list_template: @list_template,
      #       list_title: "list for submission",
      #       content_component: :editor,
      #       header_push_for_finite_items: 2,
      #
      #       hide_toggle_view_btn: true,
      #       show_sort_buttons: false
      #     ).on(:update_list) { |l| mutate @list = l }
      #   end
      # end
      # TR do
      #   TD(col_span: 2) do
      #     ListComponents::List(
      #       list_type: :inputs_list,
      #     # list: @list,
      #       # push_with_options: true,
      #       # content_component: :editor,
      #     ).on(:update_list) { |list| mutate @list = list }
      #   end
      # end
    end

    render(DIV) do
      base_render
    end
  end
end

