module ListComponents
  class ItemPushWithOptions < Base::Component
    include Base::CommonMethods

    param :list
    param accepted_push_options: nil
    fires :update_list

    def push_options
      {
        empty_string: {
          value: "",
          text: "Κενή συμβολοσειρά",
        },
        empty_array: {
          value: [],
          text: "Κενός πίνακας",
        },
        empty_2d_array: {
          value: [[]],
          text: "Κενός δισδιάστατος πίνακας",
        },
        key_value_pair: {
          value: { "": "" },
          text: "Ζευγάρι κλειδί - κενή συμβολοσειρά",
        },
        key_array_pair: {
          value: { "": [] },
          text: "Ζευγάρι κλειδί - κενός πίνακας",
        },
        key_2d_array_pair: {
          value: { "": [[]] },
          text: "Ζευγάρι κλειδί - κενός δισδιάστατος πίνακας",
        },
        calculate_by_item_max_length: {
          value: calculate_by_item_max_length(list),
          text: "Υπολογισμός βάσει μέγιστου μήκους στοιχείου",
        },
      }
    end

    def loaded
      list.loaded? && accepted_push_options.loaded?
    end

    render do
      if loaded
        options = push_options.select do |k, v|
          list.is_a?(Hash) ? [:key_value_pair, :key_array_pair, :key_2d_array_pair].include?(k) : true
        end.select do |k1, v1|
          accepted_push_options ? accepted_push_options.include?(k1) : true
        end.map { |k2, v2| [k2, v2[:text]] }
        Select(key: "push_options",
               options: options).
          on(:change) do |new_option|
          update_list!(push_options[new_option.to_sym][:value]) unless new_option.blank?
        end
      end
    end

  end
end