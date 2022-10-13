module Base
  class ItemDown < Base::Component

    param :index
    param :num_of_items
    fires :update_list
    param :css_class, default: "fa-arrow-alt-circle-down" #fa-sort-amount-down-alt for top

    render do
      SPAN(class: "mr-1") do
        A(href: '') do
          FontAwesome(icon: "#{css_class} text-secondary", modifiers: 'fa-fw', text: 'Κάτω')
        end.on(:click) do |e|
          e.prevent_default
          update_list!(index)
        end
      end if index < num_of_items - 1
    end

  end
end