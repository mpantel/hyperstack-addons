module Base
  class Index < ComponentRouter
    include Base::CommonMethods

    def init
      Hyperstack::Model.load do
        x =  columns_with_translation( columns || { id: { description: 'MK', key: true } })
        x
      end.then do |result|
        mutate @columns = result
      end
    end

    before_mount do
      @columns = columns_with_translation(columns || { id: { description: 'MK', key: true } })
    end

    def columns
      {}
    end

    fires :row_selected
    fires :show_modal
    fires :close_modal
    param :is_select, default: false, allow_nil: true
    param :inline, default: false, allow_nil: true
    param :export_enabled, default: true, allow_nil: true
    param :default_filter, default: {}, allow_nil: true
    param :default_sorting, default: {}, allow_nil: true
    param :reload, default: {}, allow_nil: true
    param :parent, default: {}, allow_nil: true
    param :parent_column, default: {}, allow_nil: true
    param :page_size, default: 10, allow_nil: true

    fires :action_result
    param :hide_no_actions_td, default: nil, allow_nil: true
    param :hide_navigator_section, default: false, allow_nil: true
    param :number_align_left, default: false, allow_nil: true
    param :non_sql_sorting, default: nil, allow_nil: true

    param :no_filters, default: nil, allow_nil: true
    param :no_modal, default: nil, allow_nil: true

    def default_filter_local
      {}
    end

    def default_sorting_local
      columns&.keys&.include?('id') ? Hash[:id, :desc] : {}
    end

    def columns_with_translation(columns)
      columns.inject(columns) { |m, (k, v)| m.merge!({ k => v.merge({ translation:  v[:description]}) }) } #t(v[:description])
    end

    def base_render(args)
      Pager(
        key: "#{args[:data_object]},#{object_id} ",
        title: args[:title],
        page_size: args[:page_size] || 10,
        data_object: args[:data_object],
        columns:@columns,
        actions: args[:actions] || {},
        default_filter: default_filter_local.merge(default_filter),
        default_sorting: default_sorting_local.merge(default_sorting),
        reload: reload,
        parent: parent,
        parent_column: parent_column,
        export_enabled: export_enabled,
        #opens_modal: args[:opens_modal],
        export_limit: args[:export_limit] || 20000,
        inline: inline,
        no_columns_headers: args[:no_columns_headers] || nil,
        title_style: args[:title_style] || { className: 'h3' },
        parse_html: args[:parse_html] || nil,
        no_results_msg: args[:no_results_msg] || "(δεν υπάρχουν δεδομένα)",
        no_refresh_button: args[:no_refresh_button] || nil,
        hide_navigator_section: args[:hide_navigator_section] || nil,
        number_align_left: args[:number_align_left] || nil,
        non_sql_sorting: args[:non_sql_sorting] || nil,
        hide_no_actions_td: args[:hide_no_actions_td] || nil,
        no_filters: args[:no_filters],
        no_modal: args[:no_modal],
        no_preferences: args[:no_preferences],
        parent_component_name: self.class).
        on(:row_selected) { |response| row_selected!(response) if is_select }.
        on(:show_modal) { show_modal! }.
        on(:close_modal) { close_modal! }.
        on(:action_result) { |action_result, action_key| action_result!(action_result, action_key) }
    end
  end
end

