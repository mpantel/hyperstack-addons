class Pager < Base::Component
  # include Base::CommonMethods

  param page_size: 10
  param title: ''
  param :data_object
  param :columns
  param actions: {}
  param default_filter: {}
  param default_sorting: {}

  param export_limit: 20000
  param :export_enabled, default: true, allow_nil: true
  param :inline, default: false, allow_nil: true

  param :reload, default: nil, allow_nil: true
  param :parent, default: nil, allow_nil: true
  param :parent_column, default: nil, allow_nil: true
  param :extra_fields, default: nil, allow_nil: true

  fires :row_selected
  fires :show_modal
  fires :close_modal

  param :no_columns_headers, default: nil, allow_nil: true
  param :title_style, default: { className: 'h3' }
  param :no_results_msg, default: "(δεν υπάρχουν δεδομένα)"
  param :parse_html, default: nil, allow_nil: true

  param :no_refresh_button, default: nil, allow_nil: true

  fires :action_result
  param :hide_no_actions_td, default: nil, allow_nil: true

  param :hide_navigator_section, default: nil, allow_nil: true
  param :number_align_left, default: nil, allow_nil: true

  param :non_sql_sorting, default: nil, allow_nil: true
  param :no_filters, default: nil, allow_nil: true
  param :no_preferences, default: nil, allow_nil: true
  param :no_modal, default: nil, allow_nil: true
  param :parent_component_name

  def default_sorting_local
    default_sorting.map { |k, v| [(k.to_s == 'id' ? @klass.primary_key : k), v] }.to_h
  end

  before_mount do
    @current_page = 1
    @exporting = false
    @klass, *@scopes = data_object.to_s.split('.')
    @klass = @klass.constantize
    @durl = ''
    @for_fake_modal = []
    @params_for_fake_modal = nil
    @subject_for_fake_modal = nil
    @local_filters = {} if @local_filters.nil?
    @columns = columns
    @sorting_hash = init_sorting_hash
    @local_filters = init_filter if @columns
    if data_object.is_a?(Array)
      Hyperstack.connect(data_object.map(&:class).uniq.select { |c| c.is_a?(Class) }.each { |c| Hyperstack.connect(c) })
    elsif data_object.is_a?(Class)
      Hyperstack.connect(data_object) unless (Object.const_defined?('AttachedFile') && data_object == AttachedFile)
    else
      Hyperstack.connect(@klass)
    end
    @context_visible = nil
    @context_x = 0
    @context_y = 0
    @open_filter_modal = false
    @modal_for_preferences = false
  end

  def preferences_icon(with_description = false)
    A(href: "",
      "title" => "Προβολή Προτιμήσεων",
      className: " #{'dropdown-item' if with_description} ") do
      FontAwesome(icon: 'fa-cogs', modifiers: 'far', text: 'Προβολή Προτιμήσεων', show_description: with_description)
    end.on(:click) do |e|
      e.prevent_default
      mutate @context_visible = false if @context_visible
      mutate @modal_for_preferences = !@modal_for_preferences
    end
  end

  def user_preferences_base_menu
    if Object.const_defined?('UserPreferences') && !no_preferences
      preferences_icon
      UserPreferences::BaseMenu(key: @user_component_prefs.to_s,
                                open_modal: @modal_for_preferences,
                                component_name: parent_component_name,
                                user_component_preferences: user_component_prefs,
                                current_preferences_ids: current_preferences.inject({}) { |m, (k, v)| m&.merge!({ k.to_sym => v[:id] }) },
                                default_values: {
                                  columns: {
                                    default_value: default_preferences[:columns][:value],
                                    initial_preference: default_preferences[:columns][:initial_preference],
                                  }
                                }.merge(filters&.count > 0 ? {
                                  filters: {
                                    default_value: default_preferences[:filters][:value],
                                    initial_preference: default_preferences[:filters][:initial_preference],
                                    filters_body: filters
                                  }
                                } : {}),
      )
        .on(:set_current_preference) do |preference_type, preference_json, preference_id|
        mutate set_current_preference(preference_type, json_parse(preference_json), preference_id)
      end
        .on(:preference_deleted) do |pref_type, pref_id, default|
        mutate set_current_preference(pref_type, {}, default ? 0 : nil) if current_preferences[pref_type][:id] == pref_id
        mutate @user_component_prefs = nil

      end
    end
  end

  def columns_preference_update(pref)
    return if pref.preference_json.blank?
    preference_json = json_parse(pref.preference_json)
    columns_via_descriptions = preference_json.reject { |c| c[2] == 'ΝΑΙ' }.inject({}) do |m, k|
      col = columns_for_read(columns).select { |k1, v1| v1[:description] == rendered_value(k[0]) }
      col.first[1].merge!({ :sort => (k[1].blank? ? true : sorting_description[k[1]]) }) unless col.blank?
      m.merge!(col.blank? ? {} : col)
    end
    hidden_cols_keys = preference_json.select { |c| c[2] == 'ΝΑΙ' }.inject({}) do |m, k|
      m.merge!(columns_for_read(columns).select { |k1, v1| v1[:description] == rendered_value(k[0]) } || {})
    end.keys
    columns_diff = columns_for_read(columns).reject { |k1, v1| (columns_via_descriptions.keys + hidden_cols_keys).include?(k1) }
    pref.preference_json = default_preferences[pref.preference_type.to_sym][:initial_preference].call(columns_via_descriptions.merge!(columns_diff)).to_json unless columns_diff.blank?
    @columns_updated ||= !columns_diff.blank?
  end

  def filters_preference_update(pref)
    return if pref.preference_json.blank?
    preference_json = json_parse(pref.preference_json)
    preference_json_keys = preference_json.keys
    existent_preference_keys = filters.values.map { |v| v[:scope] }.intersection(preference_json_keys)
    pref.preference_json = preference_json.select { |k, v| existent_preference_keys.include?(k) }.to_json unless existent_preference_keys.sort == preference_json_keys.sort
    @filters_updated ||= (existent_preference_keys.sort != preference_json_keys.sort)
  end

  def quick_filter_preference_update(pref)
    return if pref.preference_json.blank?
    pref.preference_json = nil unless (filters.keys.include?(pref.preference_json) || pref.preference_json.blank?)
    @quick_filter_updated = (!filters.keys.include?(pref.preference_json) && !pref.preference_json.blank?)
  end

  def update_preferences(preference_type)
    ups = user_component_prefs.select { |pr| pr.preference_type == preference_type.to_s }
    ups.each { |pref| method("#{preference_type}_preference_update".to_sym).call(pref) }
    if self.instance_variable_get("@#{preference_type}_updated")
      ups.each(&:save)
      Messages.add_message("Ενημερώθηκαν οι προτιμήσεις στην κατηρία: #{preference_type_description[preference_type.to_sym]}", parent_component_name.to_s, "#{preference_type}_preference_update")
    end
  end

  def current_user_preferences
    current_preferences.keys.each do |preference_type|
      update_preferences(preference_type)
      if current_preferences[preference_type][:id].nil?
        default_preference = user_component_prefs.select { |pr| pr.preference_type == preference_type.to_s && pr.default_preference == true }.first
        if preference_type.to_s == "quick_filter" && default_preference.loaded?
          @quick_filter = (default_preference || UserPreference.new(user_id: ::User.current.id, component_name: parent_component_name, preference_type: "quick_filter", preference_json: nil, description: "γρήγορο φίλτρο", default_preference: true))
          set_current_preference(:quick_filter, @quick_filter&.preference_json, @quick_filter&.id)
        elsif default_preference.loaded? && !default_preference&.preference_json.blank?
          preference_json = JSON.parse(default_preference&.preference_json)
          set_current_preference(preference_type, preference_json, default_preference.id)
        else
          set_current_preference(preference_type)
        end
      end
      current_preferences[preference_type][:id] = nil if current_preferences[preference_type][:id] == 0
    end
  end

  def set_current_preference(preference_type, preference_json = nil, preference_id = nil)
    current_preferences[preference_type][:id] = preference_id
    method("#{preference_type}_via_preference".to_sym).call(preference_json)
  end

  def current_preferences
    @current_preferences ||= default_preferences
  end

  def default_preferences
    {
      columns: {
        id: nil,
        value: columns_for_read(columns),
        initial_preference: Proc.new do |data|
          data.inject([]) do |m, (k, v)|
            temp = ["#{v[:description]}#{read_only_field_identifier}"]
            temp << (v[:sort].blank? ? "#{hidden_field_identifier}" : "")
            temp << ""
            m << temp
          end
        end,
      }
    }.merge(filters.count > 0 ? {
      filters: {
        id: nil,
        value: {},
        initial_preference: Proc.new { |data| data },
      }
    } : {})
     .merge({
              quick_filter: {
                id: nil,
                value: nil
              }
            })
  end

  def sorting_description
    {
      "ΑΥΞΟΥΣΑ" => :asc,
      "ΦΘΙΝΟΥΣΑ" => :desc,
    }
  end

  def preference_type_description
    {
      columns: "Στήλες",
      filters: "Φίλτρα",
      quick_filter: "Γρήγορο Φίλτρο",
    }
  end

  def init_sorting_hash
    @columns.select { |field, contents| contents[:sort] }&.inject({}) { |m, (k, v)| m&.merge!([:asc, :desc].include?(v[:sort]) ? { k => v[:sort] } : {}) }
  end

  def columns_via_preference(preference_json)
    if preference_json.blank?
      @columns = columns_for_read(columns)
    else
      @columns = preference_json.reject { |c| c[2] == 'ΝΑΙ' }.inject({}) do |m, k|
        col = columns.select { |k1, v1| v1[:description] == rendered_value(k[0]) }
        col.first[1].merge!({ :sort => (k[1].blank? ? true : sorting_description[k[1]]) })
        m.merge!(col)
      end
      # columns_via_descr, columns_updated = columns_preference_update(preference_json)
      # @columns = columns_via_descr
      @sorting_hash = init_sorting_hash
    end
    current_preferences[:columns][:value] = @columns
  end

  def filters_via_preference(preference_json)
    unless preference_json.nil?
      @local_filters = (preference_json.blank? ? {} : preference_json)
      current_preferences[:filters][:value] = @local_filters
    end
  end

  def quick_filter_via_preference(preference_json)
    current_preferences[:quick_filter][:value] = preference_json
  end

  def user_component_prefs
    if Object.const_defined?('UserPreference') && !no_preferences
      @user_component_prefs ||= UserPreference.user_component_preferences!(::User.current.id, parent_component_name.to_s)
    else
      @user_component_prefs ||= []
    end
  end

  def filters
    @filters ||= @columns&.select { |field, contents| contents[:filter] }&.map { |k, v| [k.to_s == 'id' ? @klass.primary_key : k, v] }.to_h&.map { |field, contents|
      case contents[:filter]
      when Symbol
        { field => { description: contents[:description], scope: contents[:filter], format: contents[:format] }.reject { |k, v| v.nil? } }
      when Hash
        contents[:filter]
      when Array
        contents[:filter].map do |f|
          if f.is_a?(Symbol)
            { field => { description: contents[:description], scope: f, format: contents[:format] }.reject { |k, v| v.nil? } }
          elsif f.is_a?(Hash)
            f
          else
            {}
          end
        end
      end
    }.flatten.inject(:merge) || {}
  end

  def data_filters
    @local_filters.reject { |f, v| v.blank? }&.merge(default_filter)
  end

  def rows_found
    return data_object.size if data_object.is_a? Array
    data = @scopes.inject(@klass) { |m, s| m.send(s.to_sym) }
    data.apply_filter(data_filters).count

  end

  def run_filter_export(operation, parameters = {})
    return if (@exporting)
    mutate @exporting = true
    operation.run(parameters&.merge({ acting_user: ::User.current })).
      then do |filename|
      mutate @exporting = false
      mutate @durl = ['/generated/', filename].join
    end.
      fail do |e|
      mutate @exporting = false
      alert(e.message)
    end
  end

  def generate_xlsx
    run_filter_export(PagerExportOperation, title: title,
                      data_object: data_object,
                      columns: columns_for_read,
                      filters: data_filters) if Object.const_defined?("PagerExportOperation")
  end

  # TODO: fix pager return to page one after reload
  def apply_filter_values
    return if filter_data.loading?
    Hyperstack::Component::IsomorphicHelpers.load_context
    mutate @durl = ''
    mutate @current_page = 1
  end

  def navigator_section
    PagerNavigation(page_size: page_size, rows_found: rows_found, current_page: @current_page).
      on(:set_page) { |page_number| mutate { @current_page = page_number } unless page_number == @current_page }
  end

  def filter_data
    return data_object[(@current_page - 1) * page_size, page_size] if data_object.is_a? Array

    data = @scopes.inject(@klass) { |m, s| m.send(s.to_sym) }
    data.sorting(@sorting_hash&.merge(default_sorting_local)).
      apply_filter(data_filters).
      limitter((@current_page - 1) * page_size, page_size).all
  end

  def change_sorting_hash(field)
    mutate @sorting_hash = @sorting_hash&.merge(Hash[field,
                                                     case @sorting_hash.delete(field)
                                                     when nil then
                                                       :asc
                                                     when :asc then
                                                       :desc
                                                     else
                                                       nil
                                                     end
                                                ].reject { |_, v| v.nil? })
  end

  def sorting_position(field)
    position = @sorting_hash.find_index { |k, _| k == field }
    return '' if position.nil?
    return position + 1
  end

  def sorting_icon(field)
    case @sorting_hash[field]&.to_sym
    when :asc then
      'fa-sort-alpha-up'
    when :desc then
      'fa-sort-alpha-down'
    else
      'fa-sort'
    end
  end

  def sort_link(field, contents)
    return unless contents[:sort]
    A(href: "") do
      FontAwesome(icon: sorting_icon(field), modifiers: "fa-fw", text: "Ταξινόμηση κατά: #{contents[:description]}")
      SUP { sorting_position(field).to_s }
    end.on(:click) do |e|
      e.prevent_default
      change_sorting_hash field
    end
  end

  def full_col_span
    columns_for_read.size + (actions.count > 0 ? 1 : 0)
  end

  def non_default_class_actions(menu = false, attached_to_column_header = nil)
    actions.select { |key, value| value[:scope] == :class && (value[:column]==attached_to_column_header) }.each do |k, v|
      next if v[:disabled]
      SPAN("data-bs-toggle" => "tooltip", "data-bs-placement" => "bottom", "title" => "#{v[:description]}") do

        AT(if v[:action] == :link
             {
               href: v[:subject].call,
               download: !v[:download].nil? ? v[:download] : true,
               'target' => "_blank",
               className: "matomo_download", type: 'download' }
           else
             { href: "", download: false }
           end.merge((menu ? { class: "dropdown-item" } : {}))
        ) do
          SPAN { "#{v[:description]}" } if v[:show_description]
          FontAwesome(icon: v[:icon], modifiers: "fa-fw", text: v[:description], show_description: menu)
        end.on(:click) do |e|
          e.prevent_default unless v[:action] == :link
          case v[:action]&.to_sym
          when :execute
            v[:subject].call
          when :insert_fake_modal
            unless data_object.is_a? Array
              mutate @for_fake_modal[0] = v[:subject]
              mutate @new_row = data_object.to_s.split('.').first.constantize.new
              mutate @for_fake_modal[1] = ({ row: @new_row,
                                             parent_column: parent_column,
                                             parent: parent,
                                             :editable_columns => columns_for_write,
                                             :action_title => v[:description] }.merge(v[:custom_params] || {}))
              show_modal!
            end
          when :run
            if @running.nil?
              #if k != :delete || confirm('Η εγγραφή θα διαγραφεί. Είστε σίγουρη/ος;')
              mutate @running = v[:subject]
              # TODO: add delete operation
              v[:subject].run((v[:custom_params] || {}).merge({ data_object: data_object, filters: data_filters })).then {
                mutate @running = nil
              }.
                fail { |e|
                  alert("Operation #{v[:subject]} failed\n#{e.message}")
                  mutate @running = nil
                }
            end

          end if !v[:disabled_visible] && (v[:confirm_msg].blank? || confirm(v[:confirm_msg]))
        end

      end.on(:click) do
        mutate @context_visible = false if @context_visible
      end

    end
  end

  def show_class_actions(menu = false, attached_to_column_header = nil)
    non_default_class_actions(menu, attached_to_column_header)
    unless filter_data.loading?

      A({ href: "" }.merge((menu ? { className: "dropdown-item" } : {}))) do
        FontAwesome(icon: "fa-sync-alt", modifiers: "fa-fw", text: "Ανανέωση", show_description: menu)
      end.
        on(:click) do |e|
        e.prevent_default
        apply_filter_values
        mutate @context_visible = false if @context_visible
      end unless no_refresh_button
    end
    if export_enabled == true && rows_found > 0 && rows_found < export_limit && (@exporting || !filter_data.loading?) # enable export of up to 5000 rows

      actions.select { |key, value| value[:scope] == :filter }.each do |k, v|
        next if v[:disabled]

        BUTTON(className: ['btn btn-secondary btn-sm', @exporting || filter_data.loading? ? ' disabled' : ''].join) do
          FontAwesome(icon: v[:icon], modifiers: "fa-fw", text: v[:description], show_description: menu)
        end.
          on(:click) {
            run_filter_export(v[:subject],
                              (v[:custom_params] || {}).merge({ acting_user: ::User.current, data_object: data_object, filters: data_filters })
            ) unless @exporting || filter_data.loading?
            mutate @context_visible = false if @context_visible
          }

      end
      if @durl == ''

        SPAN({ "data-bs-toggle" => "tooltip", "data-bs-placement" => "bottom", "title" => "Εξαγωγή" }) do

          A(href: "", className: [@exporting || filter_data.loading? ? ' disabled' : '', menu ? 'dropdown-item' : ''].join(' ')) do

            FontAwesome(icon: "fa-file-export", modifiers: "fa-fw", text: 'Εξαγωγή', show_description: menu)
            Loading() if @exporting

          end.
            on(:click) { |e|
              e.prevent_default
              generate_xlsx unless @exporting || filter_data.loading?
              mutate @context_visible = false if @context_visible
            }
        end
      else
        SPAN({ "data-bs-toggle" => "tooltip", "data-bs-placement" => "bottom", "title" => "Αποθήκευση Εξαγωγής" }) do
          AT(type: 'download', className: ['matomo_download ', menu ? 'dropdown-item' : ''].join(' '), href: @durl, download: true, target: "_blank") do
            #btn btn-secondary btn-sm
            FontAwesome(icon: "fa-save", modifiers: "fa-fw", text: 'Αποθήκευση Εξαγωγής', show_description: menu)
          end
        end.
          on(:click) do
          mutate @durl = ''
          mutate @context_visible = false if @context_visible
        end
      end
    end

  end

  def columns_for_read(cols = @columns)
    cols.select { |field, value| value[:usage] == :r || value[:usage] == :rw || !value[:usage] }
  end

  def columns_for_write
    columns.select { |field, value| value[:usage] == :w || value[:usage] == :rw }
  end

  def show_pager_row(row)
    PagerRow(key: [row.class.to_s, row.id.to_s].join('_'),
             row: row,
             columns: columns_for_read,
             editable_columns: columns_for_write,
             actions: actions.reject { |k, v| v[:scope] == :class },
             hide_no_actions_td: hide_no_actions_td,
             number_align_left: number_align_left,
             parse_html: parse_html,
    #selected_row_id:@selected_row_id
    ).
      on(:row_selected) { |response|
        row_selected!(response) }.
      on(:edit_fake_modal) do |action_key|
      action = action_key.to_sym
      object_description = actions[action][:object_description] ? row.send(actions[action][:object_description]) : ''
      mutate @for_fake_modal[0] = actions[action][:subject]
      mutate @for_fake_modal[1] = ({ row: row,
                                     parent_column: parent_column,
                                     parent: parent,
                                     :editable_columns => columns_for_write,
                                     :action_title => [actions[action][:description], object_description].reject(&:blank?).join(': ') }.merge(
        actions[action][:custom_params] || {}).merge(actions[action][:row_alias] ? { actions[action][:row_alias] => row } : {}))
      show_modal!
    end.
      on(:show_details_modal) do |subject|
      mutate @for_fake_modal[0] = subject
      mutate @for_fake_modal[1] = ({ row: row,
                                     :editable_columns => columns_for_write })
      show_modal!
    end.
      on(:action_result) { |action_result, action_key| action_result!(action_result, action_key) }
  end

  def filter_icon(with_description = false)
    A(href: "",
      "data-bs-target": "#filters_modal",
      "title" => "Φίλτρα", ##{active_filter.blank? ? '' : ': '}#{active_filter}
      className: "align-top #{'dropdown-item' if with_description} ") do
      #className: "#{active_filter.blank? ? "" : "text-danger"}"
      FontAwesome(icon: "fa-filter", modifiers: "fa-fw", text: 'Φίλτρα', show_description: with_description) #
    end.on(:click) { |e|
      e.prevent_default
      mutate @context_visible = false if @context_visible
      mutate @open_filter_modal = !@open_filter_modal
    }
  end

  def list_actions
    show_class_actions(true)
    filter_icon(true)
    preferences_icon(true)
  end

  def show_context
    DIV(class: 'dropdown-menu dropdown-menu-sm', style: { display: "#{@context_visible ? 'block' : 'none'}", top: @context_y - 10, left: @context_x - 90 }) do
      list_actions
    end.on(:mouse_leave) do
      mutate @context_visible = false
    end #if  @context_visible #actions_local.count > 0 &&
  end

  def base_render
    DIV(className: "text-wrap") do
      # text-break
      show_context
      TABLE(class: "table table-hover table-striped table-bordered table-sm align-middle") do
        THEAD(className: 'thead-light') do
          TR do
            TH({ colSpan: "#{full_col_span}" }.merge!(title_style)) do
              SPAN(className: "d-flex") {
                parse_html ? SPAN(dangerously_set_inner_HTML: { __html: title }) : title.span
                if filter_data.loading?
                  Loading()
                else
                  SPAN(key: "class_action_section") {
                    show_class_actions
                  }
                  SPAN(className: "col-8", key: "filter_section") {
                    filter_icon
                    PagerFilter(
                      filters: filters,
                      filter_values: @local_filters,
                      loading: filter_data.loading?,
                      open_modal: @open_filter_modal,
                      quick_filter_key: @quick_filter&.preference_json
                    )
                      .on(:filter) do |filter_values, go_to_default_preference = false|
                      mutate { @local_filters = filter_values }
                      set_current_preference(:filters) if go_to_default_preference
                      mutate @current_page = 1
                    end
                      .on(:reset_filter) do
                      mutate { @local_filters = (current_preferences[:filters][:id] && current_preferences[:filters][:id] != 0 ? current_preferences[:filters][:value] : init_filter) }
                      mutate @current_page = 1
                    end
                      .on(:set_quick_filter) do |quick_filter_key|
                      @quick_filter.preference_json = quick_filter_key
                      @quick_filter.save.then do |result|
                        set_current_preference(:quick_filter, quick_filter_key, @quick_filter.id) if result[:success]
                      end
                    end
                  } unless no_filters || filters.blank?
                  SPAN(key: "preferences_section", style: { marginLeft: "auto" }) {
                    user_preferences_base_menu
                  }
                end
              }
            end
          end unless inline
          # end
          # THEAD(className: 'thead-light') do
          TR do
            columns_for_read.each do |field, contents|
              TH() do
                DIV(className: "d-flex flex-nowrap") {
                  SPAN { contents[:translation] }
                  sort_link(field, contents)
                  non_default_class_actions(false, field)
                }
              end
            end
            TH do
              if filter_data.loading?
                Loading()
              else
                show_class_actions if inline
              end
            end if actions.select { |key, value| value[:scope] == :class && value[:column].blank? }.count > 0
          end unless no_columns_headers
        end.
          on(:context_menu) do |e|
          e.prevent_default
          mutate @context_visible = true
          mutate @context_x = e.page_x
          mutate @context_y = e.page_y
        end

        summary_row = Hash.new(0) if actions[:show_totals]

        TBODY { TR { TD { SPAN { "#{no_results_msg}" } } } } if filter_data.count == 0
        TBODY {
          filter_data.sort_by { |p| non_sql_sorting ? non_sql_sorting.index(p.id) : nil }.each do |row|

            columns_for_read.each do |k, v|
              if v[:format] == :currency
                summary_row[k] += row.send(k) if row.send(k).is_a? Numeric
              else
                summary_row[k] = ''
              end
            end if actions[:show_totals]
            show_pager_row(row)
          end
        }

        TFOOT do
          TR {
            TD { "Σύνολο (#{filter_data.count} γραμμ#{filter_data.count == 1 ? 'ή' : 'ες'})" }
            summary_columns = columns_for_read.dup
            summary_columns.delete(summary_columns.keys[0])
            summary_columns.each { |field, contents|
              value = (summary_row[field])
              #alert("#{field} - #{value}")
              display_value = case contents[:format]&.to_sym
                              when :currency then
                                value ? display_currency(value) : 'ΔΕΝ ΕΧΕΙ ΟΡΙΣΘΕΙ'
                              else
                                value
                              end
              className = contents[:format] == :currency ? 'text-right' : ''
              TD(className: className) {
                SPAN { display_value.to_s }
              }
            }
            TD {} if actions.count > 0
          } if actions[:show_totals]
          TR do
            TD(colSpan: "#{full_col_span}") do
              navigator_section
            end
          end unless hide_navigator_section
        end
      end
    end
  end

  render(DIV) do
    Modal(key: "pager_modal", with_trigger_button: false, trigger: @for_fake_modal[0], xl_modal: true) {
      DIV(className: "modal-body", style: { "padding": 0 }) {
        Hyperstack::Component::ReactAPI.create_element(@for_fake_modal[0], { key: "modal-content" }.
          merge(@for_fake_modal[1])
        ).on(:action_result){ |action_result|
          action_result!(action_result, "_from_modal")
        }.on(:close_modal) do
          (@new_row = nil) if @new_row
          mutate do
            @for_fake_modal[0] = nil
            @for_fake_modal[1] = nil
          end
        end
      } unless @for_fake_modal[0].blank?
    } unless no_modal
    current_user_preferences if Object.const_defined?('UserPreferences') && !no_preferences
    base_render unless @columns.blank?
    Messenger(parent_component_name: parent_component_name.to_s)
  end
end


