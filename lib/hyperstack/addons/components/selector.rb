class Selector < Base::Component

  param :value, default: nil, allow_nil: true
  param :external_value, default: nil, allow_nil: true
  param :look_up, default: nil, allow_nil: true
  param :options, default: [], allow_nil: true
  param :empty_description, default: [nil, ' -- επιλέξτε -- ']
  fires :change
  param :limit, default: 100
  param :limit_by_default, default: false
  param :width, default: ""
  param :form_class, default: "form-row"
  param :filter_values, default: {}
  param :no_sorting, default: nil, allow_nil: true
  param :disabled, default: nil, allow_nil: true

  before_mount do
    @selected_text = ''
    @temp = ''
    # @options = options_local(@selected_text)
  end

  # after_mount do
  #   every(1) do
  #     if @temp != @selected_text
  #       puts @selected_text
  #       mutate @options = options_local(@selected_text)
  #     @temp = @selected_text
  #     end
  #   end
  # end

  def normalize_options
    return nil unless look_up[:options]
    if look_up[:options].is_a?(Array)
      mutate @normalize_options = look_up[:options]
    else
      look_up[:options][:operation].run(look_up[:options][:params] || {}).then do |result|
        mutate @normalize_options = result
      end
    end unless @normalize_options
    @normalize_options
  end

  def options_local(selected_text)
    all_options = (
      (options || []) +
        (look_up_options(selected_text) || []) +
        (look_up ? normalize_options || [] : [])
    )&.uniq&.select { |o| selected_text.blank? || (o[1]&.strip =~ /#{escape_characters_in_string(selected_text)}/i) }
    no_sorting ? all_options : all_options.sort_by { |o| o[1] } rescue all_options
  end

  def look_up_options(selected_text)

    return [] unless look_up && look_up[:source]
    temp = source_with_includes.apply_filter(
      (look_up[:column][:filter] || {}).merge(limit_local ? { limit: limit_local } : {}).
        merge((look_up[:column][:custom_filter] && !selected_text.blank?) ?
                { look_up[:column][:custom_filter] => selected_text, :limit => limit_local } : {}).
        merge((look_up[:column][:external_filter]) ?
                { look_up[:column][:external_filter].first[0].to_sym => external_value, :limit => limit_local } : {}).
        reject { |k, v| v.blank? }
    ).all.to_a
    #temp = temp.sort_by {|i| i.send(look_up[:column].first[1].to_sym)} rescue temp
    temp.map do |option|
      [option.send(look_up[:column].first[0].to_sym),
       option.send(look_up[:column].first[1].to_sym)&.strip,
       look_up[:column][:tooltip] ? option.send(look_up[:column][:tooltip].to_sym) : '']
    end
  end

  def source_with_includes
    if look_up[:column][:dependencies].blank?
      look_up[:source]
    else
      look_up[:column][:dependencies].inject(look_up[:source]) do |m, dependency|
        if filter_values[dependency[:external_scope].to_s]
          if dependency[:external_class].blank?
            m.where(dependency[:foreign_key].to_sym => filter_values[dependency[:external_scope].to_s] )
          else
            fk_values = dependency[:external_class].send(dependency[:external_scope], filter_values[dependency[:external_scope].to_s]).pluck(dependency[:foreign_key].to_sym)
            m.where(m.primary_key.to_sym => fk_values )
          end
        else
          m
        end
      end
    end
  end

  def selected_text
    @selected_text = (source_with_includes.find(value)&.send(look_up[:column].first[1].to_sym)&.strip) if (look_up && look_up[:source] && !value.blank?)
    options_local(@selected_text).select { |o| o[0].to_s == value.to_s }.first&.[](1) || @selected_text
  end

  def loading?
    look_up && look_up[:source] && look_up[:source].loading?
  end

  def limit_local
    look_up[:column][:custom_filter] ? (((@selected_text&.size || 0) < 4) && !limit_by_default ? 100 : limit) : nil
  end

  render do
    DIV(className: form_class || "form-row") do
      DIV(className: width) do
        DIV(className: "input-group", "data-bs-toggle" => "tooltip", "data-bs-placement" => "bottom", "title" => selected_text) do
          INPUT({ className: "dropdown-toggle form-control input-sm",
                  "data-bs-toggle": "dropdown",
                  type: "text",
                  #defaultValue: selected_text,
                  value: selected_text,
                  disabled: !!disabled
                } #.  merge(look_up ? {} : {readOnly: 'true'})
          ).
            on(:change) do |e|
            #if look_up
            value = if ['΄', '¨', '΅'].include? e.target.value[-2]
                      find_what = e.target.value[-2..-1]
                      replace_with = {
                        '΄α' => 'ά', '΄ε' => 'έ', '΄η' => 'ή', '΄ι' => 'ί', '¨ι' => 'ϊ', '΅ι' => 'ΐ', '΄ο' => 'ό', '΄υ' => 'ύ', '¨υ' => 'ϋ', '΅υ' => 'ΰ', '΄ω' => 'ώ',
                        '΄Α' => 'Ά', '΄Ε' => 'Έ', '΄Η' => 'Ή', '΄Ι' => 'Ί', '¨Ι' => 'Ϊ', '΄Ο' => 'Ό', '΄Υ' => 'Ύ', '¨Υ' => 'Ϋ', '΄Ω' => 'Ώ',
                      }[find_what]
                      e.target.value.sub(/#{find_what}/, replace_with)
                    end

            mutate @selected_text = value.blank? ? e.target.value : value
            # mutate @options = options_local(@selected_text)
            #change!('')

            #end
          end
          BUTTON(className: "btn btn-outline-secondary dropdown-toggle", "data-bs-toggle": "dropdown", type: "button", style: { borderRadius: 0, zIndex: 0 })
          BUTTON(className: "btn btn-outline-secondary", type: "button", style: { zIndex: 0 }) { FontAwesome(icon: 'fa-times') }.
            on(:click) do
            mutate @selected_text = ''
            change!('')
          end #size: "32",
          UL(className: "dropdown-menu", style: {
            "maxHeight": "340px",
            "overflowY": "scroll",
            "maxWidth": "100%",
            "width":"calc(100% - 37px)"
          }) do

            LI { A(href: "#",
                   className: "dropdown-item",
                   value: empty_description.first) { loading? ? 'Παρακαλώ περιμένετε...' : empty_description.last } }
            options_local(@selected_text).each do |option|
              # LI("data-bs-toggle": "tooltip", "data-bs-placement": "bottom", "title": option[2].blank? ? option[1] : option[2]) { A(href: "#", className: "dropdown-item", 'data-value': option[0], 'data-text': option[1]) { option[1] } }
              LI("data-bs-toggle": "tooltip", "data-bs-placement": "bottom", "title": option[2].blank? ? option[1] : option[2]) { A(dangerously_set_inner_HTML: { __html: option[1] }, href: "#", className: "dropdown-item", 'data-value': option[0], 'data-text': option[1]) }
            end
            #   LI(className: "dropdown-item divider")
          end.on(:click) do |evt|
            evt.prevent_default
            mutate @selected_text = evt.target.dataset['text']
            change!(evt.target.dataset['value'])
          end unless disabled
        end
      end

      if look_up && look_up[:source]
        options_size = options_local(@selected_text)&.size
        DIV(className: "") do
          "Στη λίστα εμφανίζονται μόνο τα πρώτα #{options_size}. Εξειδικεύστε το φίλτρο για να εμφανιστούν και άλλα."
        end if (limit_local || 0) > 0 && (limit_local || 0) < (options_size || 0)
      end
    end
  end
end