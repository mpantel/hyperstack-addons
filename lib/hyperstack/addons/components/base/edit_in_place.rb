module Base
  class EditInPlace < EditInList

    fires :close_edit_in_place
    fires :feed_edit_in_place
    param :value, default: nil, allow_nil: true
    param :related_value, default: nil, allow_nil: true
    param :changed, default: nil, allow_nil: true

    render(DIV) do
      field_to_be_edited
      base_actions
    end

    before_mount do
      @new_option = value
    end

    def field_declared
      editable_columns.values[0][:edit_in_place][:field_name]
    end

    def field
      field_declared || editable_columns.keys[0].to_sym
    end

    def driven_field
      editable_columns.values[0][:edit_in_place][:drives] #.to_sym
    end

    def driver_field
      editable_columns.values[0][:edit_in_place][:driven_by] #.to_sym
    end

    def driver_field_boolean
      driver_field ? true : false
    end

    def target_model_declared
      editable_columns.values[0][:edit_in_place][:target_model]
    end

    def target_model
      target_model_declared || row.class.to_s
    end

    def format_declared
      editable_columns.values[0][:format]
    end

    def options_declared
      editable_columns.values[0][:edit_in_place][:options]
    end

    def options
      return nil unless options_declared
      options_declared.is_a?(Proc) ? options_declared.call : target_model.constantize.send(options_declared.to_sym)
    end

    def key_name
      editable_columns.values[0][:edit_in_place][:key_name] || row.primary_key
    end

    def operation
      editable_columns.values[0][:edit_in_place][:operation] || Rescom::BasicInPlaceOperation
    end

    def field_to_be_edited
      if format_declared == :lookup_options #target_model_declared && options_declared
        select_from_options(options)
      elsif format_declared == :currency
        input_in_place_currency
      else
        # super(field,editable_columns.values[0])
        input_in_place
      end
    end

    def base_actions
      if true #target_model
        save_or_cancel_in_place({ data_object: target_model, key_name: key_name.to_sym }.merge!(default_operation_params), return_nil_scenario: driver_field_boolean, hidden_button_scenario: driver_field_boolean)
      else
        super(false)
      end
    end

    def select_driver_first
      if row[driver_field.to_sym].nil? && related_value.nil?
        alert("Χρειάζεται πρώτα να επιλέξετε τιμή από το συσχετιζόμενο πεδίο!")
        close_edit_in_place!
        true
      else
        false
      end
    end

    def select_from_options options
      Select(key: [row.to_key, field].join,
             value: @new_option || row[field],
             options: options).
        on(:change) do |v|
               unless v.blank?
                 mutate @new_option = v
                 feed_edit_in_place!(v)
               end
             end
    end

    def input_in_place
      Input(value: @new_option || row[field], className: 'form-control input-sm').
        on(:blur)  do |v|
              mutate @new_option = v
              # row[field] = v unless target_model_declared
              # feed_edit_in_place!(v)#(target_model_declared ? false : true)
            end
    end

    def input_in_place_currency
      Currency(value: @new_option || row[field], className: 'form-control input-sm').
        on(:blur) do |v|
                 mutate @new_option = v
                 # row[field] = v unless target_model_declared
                 # feed_edit_in_place!(v, false)
               end
    end

    def default_operation_params
      { key_value: row.id, field_name: field, field_value: @new_option || row[field] }
        .merge!(driven_field ? { driven_field_name: driven_field.to_sym, driven_field_value: related_value } : {})
    end

    def save_or_cancel_in_place(operation_params, return_nil_scenario: false, hidden_button_scenario: false)
      (return nil if row[driver_field.to_sym].nil?) if return_nil_scenario
      save_in_place(operation_params, hidden_button_scenario: hidden_button_scenario)
      cancel_in_place hidden_button_scenario: hidden_button_scenario
    end

    def save_in_place(operation_params, hidden_button_scenario: false)
      # alert @new_option
      A(href: '') do
        FontAwesome(icon: 'fa-save', modifiers: 'fa-fw', text: 'Αποθήκευση')
      end.on(:click) do |e|
        e.prevent_default
        if @new_option.blank? #!changed ||
          alert("Δεν έχετε επιλέξει κάποια τιμή!")
        else
          operation.run(operation_params)
                   .then do
            close_edit_in_place!(target_model_declared || field_declared ? nil : @new_option)
          end
                   .fail { alert("Error on save...#{result[:message]}") }
        end
      end unless (hidden_button_scenario ? related_value : false)
    end

    def cancel_in_place hidden_button_scenario: false
      A(href: '') do
        FontAwesome(icon: 'fa-undo', modifiers: 'fa-fw', text: 'Ακύρωση')
      end.on(:click) do |e|
        e.prevent_default
        close_edit_in_place!
      end unless (hidden_button_scenario ? related_value : false)
    end

  end
end