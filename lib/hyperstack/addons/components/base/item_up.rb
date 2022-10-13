module Base
  class ItemUp < Base::Component

    param :index
    fires :update_list
    param :css_class, default: "fa-arrow-alt-circle-up" #fa-sort-amount-up-alt for top

    render do
      SPAN(class: "mr-1") do
        A(href: '') do
          FontAwesome(icon: "#{css_class} text-secondary", modifiers: 'fa-fw', text: 'Πάνω')
        end.on(:click) do |e|
          e.prevent_default
          update_list!(index)
        end
      end if index > 0
    end

  end
end