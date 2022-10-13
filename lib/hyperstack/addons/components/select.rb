class Select < Base::Component

  param :className, default: nil, allow_nil: true
  param :value, default: nil, allow_nil: true
  param :look_up, default: nil, allow_nil: true
  param :options, default: [], allow_nil: true
  param :empty_description, default: [nil, ' -- επιλέξτε -- ']
  fires :change

  before_mount do
    @look_up_options = []
    @custom_filter_value = ''
    @custom_filter = false
    @limit = nil

    if look_up && look_up[:column]
      mutate @custom_filter = (look_up[:column][:custom_filter_checkbox] == false)
    end
    mutate @look_up_options = []
    mutate @custom_filter_value = ''
      # @klass = look_up[:source].to_s.split('.').first.constantize  if look_up && look_up[:source]
    # mutate    look_up[:column] = look_up[:column].first.map{|k| k.to_s=='id' ? @klass.primary_key : k}.to_h.
    #     merge(look_up[:column].reject{|k,v| k.to_s=='id'})


  end

  def loading?
    unsorted_look_up_options.loading? # look_up && look_up[:source] && look_up[:source].loading?
  end

  def unsorted_look_up_options
    look_up[:source].apply_filter(
        (look_up[:column][:filter] || {}).merge(@limit ? {limit: @limit} : {}).
            merge((look_up[:column][:custom_filter] && !@custom_filter_value.blank?) ?
                      {look_up[:column][:custom_filter] => @custom_filter_value, limit: @limit} : {}).
            reject {|k, v| v.blank?}
    ).all.to_a if look_up && look_up[:source]

  end

  def look_up_options
    unsorted_look_up_options&.sort_by {|i| i.send(look_up[:column].first[1].to_sym)} rescue unsorted_look_up_options
  end

  render do
    DIV(className: "form-row") do
      DIV(className: "col-lg-auto") do
        if loading?
          Loading()
        else
          SELECT(value: value, className: ["form-select input-sm",className].reject(&:blank?).join(' ')) do
            OPTION(value: empty_description.first) {!loading? ? empty_description.last : 'Παρακαλώ περιμένετε...'}
            (options + @look_up_options + (look_up ? look_up[:options] || [] : [])
            )&.uniq.each do |option|
              OPTION({value: option[0]}.merge!(option[2].blank? ? {} : {'data-bs-toggle': "tooltip", title: "#{option[2]}"})) {option[1]}
            end
          end.on(:change) do |evt|
            @current_value = evt.target.value
            change!(@current_value)
          end
        end
      end

      if look_up && look_up[:source]

        if @custom_filter && look_up[:column][:custom_filter]
          DIV(className: "col-2") do
            INPUT(defaultValue: '', className: 'form-control input-sm', placeholder: 'Εισάγετε επιπλέον φίλτρο').
                on(:change) {|e|
                  mutate @custom_filter_value = e.target.value
                }
          end
        else
          mutate @custom_filter_value = ''
        end

        mutate @limit = (@custom_filter && look_up[:column][:custom_filter] ? (@custom_filter_value.size < 4 ? 50 : nil) : nil)

        mutate @look_up_options = look_up_options&.
            map {|option| [option.send(look_up[:column].first[0].to_sym), option.send(look_up[:column].first[1].to_sym)]} || []

        DIV(className: "form-check") do
          CheckBox(checked: @custom_filter, className: 'form-check-input').
            on(:change) {|e| mutate @custom_filter = e.target.checked}
          LABEL(className: "form-check-label") {'Φίλτρο'}
        end if look_up[:column][:custom_filter] && !(look_up[:column][:custom_filter_checkbox] == false)
        DIV(className: "") do
          "Στη λίστα εμφανίζονται μόνο τα πρώτα #{@look_up_options.size}. Εξειδικεύστε το φίλτρο για να εμφανιστούν και άλλα."
        end if @limit == @look_up_options.size
      end
    end
  end
end