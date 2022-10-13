module Base
  class ItemMove < Base::Component

    param :index
    param :num_of_elements
    fires :update_list

    render do
      SPAN(class: "mr-1") do
        SELECT(key: index, className: "form-select-padding-x", style: { backgroundColor: "white", color: :grey }, value: index + 1) do
          num_of_elements.times.each do |i|
            OPTION(value: i + 1) { "#{i + 1}" }
          end
        end.on(:change) do |e|
          e.prevent_default
          update_list!(e.target.value.to_i - 1)
        end
      end
    end

  end
end