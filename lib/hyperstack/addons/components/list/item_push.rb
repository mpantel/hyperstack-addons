module ListComponents
  class ItemPush < Base::Component
    include Base::CommonMethods

    param :list, default: []
    fires :update_list

    render do
      SPAN do
        " ".span
        A(href: '') do
          FontAwesome(icon: 'fa-plus-circle text-secondary', modifiers: 'fa-fw', text: 'Προσθήκη Στοιχείου Λίστας')
        end.on(:click) do |e|
          e.prevent_default
          new_item = if list_depth(list) == 1
                       ""
                     else
                       calculate_by_item_max_length(list)
                     end
          update_list!(new_item)
        end
      end
    end

  end
end