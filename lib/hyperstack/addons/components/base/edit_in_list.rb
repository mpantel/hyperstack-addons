# frozen_string_literal: true

module Base
  class EditInList < Component

    param :row
    param :editable_columns
    fires :action_result
    fires :close_modal
    param :action_title, default: nil
    param :parent, default: nil, allow_nil: true
    param :parent_column, default: nil, allow_nil: true

    def validatable_columns
      editable_columns.select { |k, v| v[:validation] && v[:validation].is_a?(Array) }
    end

    def initialize_validation(_columns: validatable_columns, data_object: row)
      @validation = Base::Validation.new(columns: _columns, data_object: data_object) unless _columns.blank?
    end

    def prepend_extra_fields
    end

    def extra_fields
    end

    def look_up_value(field, value)
      row["#{field}_#{value[:column].first[0]}".to_sym]
    end

    def set_look_up_value(field, value, new_value)
      row["#{field}_#{value[:column].first[0]}".to_sym] = new_value
    end

    def base_render(show_actions = true)
      # (extra_fields=nil)
      DIV(className: "modal-header", style: { position: "sticky", top: 0, "backgroundColor": "white", zIndex: 2, "boxShadow": "rgba(0, 0, 0, 0.75) 0px 4px 7px 0px" }) do
        H4(className: "modal-title") { action_title } if action_title
        DIV { base_actions } if show_actions && !loading?
      end
      DIV(className: "modal-body") do
        TABLE(class: 'table table-hover table-striped table-bordered table-sm') do
          TBODY do
            prepend_extra_fields
            editable_columns.each do |field, value|
              unless parent_column.blank?
                if field.to_sym == parent_column || (parent_column && field.to_sym == (parent_column + '_id').to_sym)
                  row[field.to_sym] = parent.id
                end
              end
              next if value[:format].try(:to_sym) == :hidden
              TR do
                TD { "#{value[:description]}: " }
                TD(key: @key_on_validation_error) do
                  field_to_be_edited(field, value)
                end
              end
            end
            extra_fields #unless extra_fields.nil?
          end
        end
      end

      @key_on_validation_error = nil
    end

    def field_to_be_edited(field, value)
      case value[:format]&.to_sym
      when :editor, :simple_editor
        editor_type = (value[:format].to_s.split('_').first == 'simple' ? :trix : :sun)

        Editor(key: [row.to_key, field].join, editor_type: editor_type, # [:trix , :sun]
               value: row[field] || '').# , #placeholder: element_value[:placeholder]
        on(:blur) { |value| row[field] = value&.gsub(/&nbsp;/, ' ') }

      when :look_up
        Select(key: [row.to_key, field].join, look_up: value, value: look_up_value(field, value)).
          on(:change) do |new_value|
          set_look_up_value(field, value, new_value.blank? ? nil : (new_value.to_i > 0 ? new_value.to_i : new_value))
        end

      when :look_up2
        Selector(key: [row.to_key, field].join, look_up: value, value: look_up_value(field, value)).
          on(:change) do |new_value|
          set_look_up_value(field, value, new_value.blank? ? nil : (new_value.to_i.to_s == new_value && new_value.to_i > 0 ? new_value.to_i : new_value)) #new_value) #
        end
      when :currency
        Currency(key: [row.to_key, field].join, value: row[field] || 0, className: 'form-control input-sm').
          on(:blur) { |v| row[field] = v }
      when :boolean
        CheckBox(key: [row.to_key, field].join, checked: row[field], className: 'input-sm').
          on(:change) { |e| row[field] = e.target.checked }
      when :date, :datetime
        strftime_string = (value[:format] == :date ? '%Y-%m-%d' : '%Y-%m-%d %H:%M')
        #TODO: date_value = row[field] ? Time.parse(row[field], strftime_string).strftime(strftime_string) : ''
        date_value = row[field] ? Time.parse(row[field]).strftime(strftime_string) : ''
        DatePickerInput(
          key: [row.to_key, field, value[:format]].map(&:to_s).compact.join('_'),
          selected: date_value,
          with_time: value[:format] == :datetime).
          on(:change) { |v| row[field] = v }
        #   .on(:blur)  {|v| row[field] = v}

      when :json
        JsonEditor(
          key: [row.to_key, field, value[:format]].map(&:to_s).compact.join('_'),
          hash_data: row[field.to_sym].blank? ? nil : JSON.parse(row[field.to_sym].gsub(/\s+/, ' ').strip),
          meta_attributes: row.class.respond_to?(:table_jsons) ? row.class.table_jsons[field.to_sym] : {}).
          on(:blur) { |v| row[field] = v.to_json }.
          on(:delete_item) { |v| row[field] = v.to_json }
      else
        Input(key: [row.to_key, field.to_s].join, value: row[field], className: 'form-control input-sm', name: field).
          on(:blur) { |v| row[field] = v }
      end
    end

    def required_fields_error
      editable_columns.select { |field, value| value[:required] == :true }.map do |field, value|
        ['Το πεδίο ', value[:description], ' δεν μπορεί να είναι κενό'].join(' ') if row[field].blank?
      end.compact
    end

    def base_actions(with_titles = true)
      base_submit(with_titles)
      base_cancel(with_titles)
    end

    def base_submit(with_titles = true)
      A(href: '') do
        'Αποθήκευση'.span if with_titles
        FontAwesome(icon: 'fa-save', modifiers: 'fa-fw', text: 'Αποθήκευση') 
      end.on(:click) do |e|
        e.prevent_default
        initialize_validation
        if !required_fields_error.blank?
          alert(required_fields_error.join("\n"))
        elsif !@validation.nil? && !@validation.validate
          @validation.show_errors
          mutate @key_on_validation_error = Time.now.to_i
        else
          row.save.then do |result|

            if result[:success]

              close_modal!
            else
              alert("Error on save...#{result[:message]}")
            end
          end
        end
      end
    end

    def base_cancel(with_titles = true)
      A(href: '') do
        'Ακύρωση'.span if with_titles
        FontAwesome(icon: 'fa-undo', modifiers: 'fa-fw', text: 'Ακύρωση')
      end.on(:click) do |e|
        e.prevent_default
        row.revert
        close_modal!
      end
    end

    render(DIV) do
      base_render
    end
  end
end