module Base
  module CommonMethods

    # module ListComponents

    def options_separator
      "***"
    end

    def select_identifier
      "$$"
    end

    def other_option_identifier
      "??()??"
    end

    def input_field_identifier
      "!!i!!"
    end

    def currency_field_identifier
      "!!cur!!"
    end

    def editor_field_identifier
      "&&e&&"
    end

    def read_only_field_identifier
      "((r(("
    end

    def hash_key_field_identifier
      "))hk))"
    end

    def hidden_field_identifier
      "(-hdd-)"
    end

    def content_component_hash
      ActiveSupport::HashWithIndifferentAccess.new(
        {
          input: {
            title: 'Πεδίο Εισαγωγής',
            regex: input_field_identifier
          },
          editor: {
            title: 'Πεδίο Κειμένου',
            regex: editor_field_identifier
          },
          read_only: {
            title: 'Πεδίο Μόνο για Ανάγνωση',
            regex: read_only_field_identifier
          },
          hidden: {
            title: 'Κρυφό Πεδίο',
            regex: hidden_field_identifier
          },
          currency: {
            title: 'Πεδίο Χρηματικού Ποσού',
            regex: currency_field_identifier
          }
          # json: 'Πίνακας',
        }
      )
    end

    def rendered_value(val)
      v = (val.to_s.include?(other_option_identifier) ? val.to_s.gsub(other_option_identifier, '') : val.to_s)
      content_component_hash.each do |type, hash|
        if v.to_s.include?(hash[:regex])
          v = v.to_s.gsub(hash[:regex], '')
          break
        end
      end
      v
    end

    def identify_regex(val)
      content_component_hash.each do |type, hash|
        return hash[:regex] if val.to_s.include?(hash[:regex])
      end
      nil
    end

    def component_key_by_regex(regex)
      return nil if regex.blank?
      content_component_hash.each do |type, hash|
        return type if hash[:regex] == regex
      end
    end

    def normalize_list_template(list_template, inline_bold: false)
      list_template.map { |i| i.map { |e|
        normalized_value = e =~ select_regex ? e.split(select_identifier)[0] : e
        inline_bold ? "<b>#{normalized_value}</b>" : normalized_value
      } }
    end

    def select_regex
      /(.*?)\$\$(.*?)\$\$/m
    end

    def list_depth(array, pivot_depth = 1)
      return 0 unless array.is_a?(Array) || array.is_a?(Hash)
      p_d = pivot_depth
      array.to_a.each do |item|
        inner_p_d = list_depth(item, pivot_depth + 1)
        p_d = inner_p_d if inner_p_d > p_d
      end
      p_d
    end

    def is_key_value_pair(index = nil, l = @_list)
      list_item = (index.blank? ? l : l[index])
      (list_item.is_a?(Array) || list_item.is_a?(Hash)) &&
        list_item.count == 2 &&
        ((list_item.is_a?(Array) && list_item[0].to_s.include?(read_only_field_identifier) && list_item[0].to_s.include?(hash_key_field_identifier)))
    end

    def calculate_by_item_max_length(l)
      l.inject(0) { |m, row| m = (m > (row.count rescue 1) ? m : (row.count rescue 1)) }.times.inject([]) { |mi, i| mi << "" }
    end


    # end module ListComponents

    def sanitize_string(str)
      # str.gsub(/(\/|\\|\?|\*|\:|\||\"|\<|\>)/, "_")
      str.gsub(/[\/\\\?\*\:\|\"\<\>]/, "_")
    end

    def init_filter
      filters.inject({}) { |filter, (filter_key, filter_value)|
        filter.merge!(
          if filter_value["initial_value"].blank?
            set_filter_value("", filter_value)
          else
            set_filter_value(filter_value["initial_value"], filter_value)
          end
        )
      }
    end

    def set_filter_value(value, filter, position = nil, filter_values: {})
      value = value.strftime('%Y-%m-%d') if !value.blank? && [:date, :datetime, :single_date].include?(filter[:format]&.to_sym)
      new_filter = case position
                   when :first
                     { filter[:scope].to_sym => [value, (filter_values)[filter[:scope].to_sym].try(:last) || ''] }
                   when :second
                     { filter[:scope].to_sym => [(filter_values)[filter[:scope].to_sym].try(:first) || '', value] }
                   else
                     { filter[:scope].to_sym => value }
                   end
      if (position.nil? ? value.blank? : new_filter[filter[:scope].to_sym].all?(&:blank?))
        filter_values.reject { |k, v| k == filter[:scope].to_sym }
      else
        filter_values.merge(new_filter)
      end
    end

    def swap_array_elements(array:, index:, goes: :up)
      begin
        move = { up: -1, down: 1 }[goes]
         return array if (move ? (index + move) : goes) < 0 || (move ? (index + move) : goes) >= array.count
         # raise "u r out of limits, sugar" if (move ? (index + move) : goes) < 0 || (move ? (index + move) : goes) >= array.count
        if move
          array[index], array[index + move] = array[index + move], array[index]
        else
          array.insert(goes, array.delete_at(index))
        end
        array
      rescue StandardError => e
        puts e.message
      end
    end

    def show_order_arrows(ids, direction)
      index = ids.index(self.id)
      !( (index==0 && direction == :up) || (index == ids.size-1 && direction == :down))
    end

    def move_to_top(array:, index:)
      array.unshift(array.delete_at(index))
    end

    def move_to_bottom(array:, index:)
      array.push(array.delete_at(index))
    end

    def delete_item(array:, index:)
      array.delete_at(index)
      array
    end

    def line_break
      "\n"
    end

    def tab_separator
      "\t"
    end

    def json_parse(json)
      JSON.parse(json) rescue {}
    end

  end
end