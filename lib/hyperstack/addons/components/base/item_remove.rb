module Base
  class ItemRemove < Base::Component

    param :index
    fires :update_list

    render do
      SPAN(class: "mr-1") do
        A(href: '') do
          FontAwesome(icon: 'fa-minus-circle text-secondary', modifiers: 'fa-fw', text: 'Διαγραφή Στοιχείου Λίστας')
        end.on(:click) do |e|
          e.prevent_default
          update_list!(index)
        end
      end
    end

  end
end