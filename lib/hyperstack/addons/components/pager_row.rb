class PagerRow < Base::Component
  include Base::Common

  param :row
  param :columns
  param :editable_columns
  param actions: {}

  fires :row_selected
  param :selected_row_id, default: nil, allow_nil: true
  fires :edit_fake_modal
  fires :show_details_modal
  fires :operation_run

  fires :action_result
  param :hide_no_actions_td, default: nil, allow_nil: true
  param :number_align_left, default: nil, allow_nil: true

  param :parse_html, default: nil, allow_nil: true

  before_mount do
    @show_details = nil
    @running = nil
    @context_visible = nil
    @context_x = 0
    @context_y = 0
    @edit_in_place = {}
  end

  def show_context
    DIV(class: 'dropdown-menu dropdown-menu-sm', style: { display: 'block', top: @context_y - 10, left: @context_x - 90 }) do
      show_actions(true).on(:click) do
        mutate @context_visible = false
      end
    end.on(:mouse_leave) do
      mutate @context_visible = false
    end if actions_local.count > 0 && @context_visible
  end

  def actions_local
    actions.select { |k, v| v[:scope] == :row && (v[:visible].blank? || (v[:visible].class == Array ? row.send(v[:visible][0], *v[:visible][1..-1]) : row.send(v[:visible]))) }
  end

  def show_actions(menu = false)
    DIV do

      #:show => {description: 'Προβολή', icon: 'eye', action: :render, subject: Invoices::Show, scope: :row},
      actions_local.each do |k, v|
        next if v[:disabled]
        SPAN("data-bs-toggle" => "tooltip", "data-bs-placement" => "bottom", "title" => "#{v[:description]}") do
          icon_body = Proc.new do |*params|
            if v[:subject] == @show_details
              mutate @show_details = nil
            else
              case v[:action]&.to_sym
              when :execute
                action_result!(v[:subject].call(row.send(v[:field] || :id), *params), k.to_sym)
              when :render
                show_details_modal!(v[:subject])
              when :edit_fake_modal
                edit_fake_modal!(k) #row
              when :run
                if @running.nil?
                  if v[:confirmation_message].blank?
                    v[:confirmation_message] = 'Η εγγραφή θα διαγραφεί. Είστε σίγουρη/ος;' if k.to_sym == :delete
                    v[:confirmation_message] = 'Η εγγραφή θα ξεκλειδωθεί. Είστε σίγουρη/ος;' if k.to_sym == :unlock
                    v[:confirmation_message] = 'Η εγγραφή θα αποϋποβληθεί. Είστε σίγουρη/ος;' if k.to_sym == :unsubmit
                  end

                  if v[:confirmation_message].blank? || confirm(v[:confirmation_message])
                    mutate @running = v[:subject]
                    # TODO: add delete operation
                    v[:subject].run({ row: row, row_id: row.id }.merge(v[:custom_params] || {})).then { |action_result|
                      mutate @running = nil
                      operation_run!(v[:reload])
                      action_result!(action_result, k.to_sym)
                    }.
                      fail { |e|
                        alert("Operation #{v[:subject]} failed for #{row.id}\n#{e.message}")
                        mutate @running = nil
                        operation_run! false
                      }

                  end
                end

              when :hide
                mutate @show_details = nil
              end
            end
          end

          if v[:icon].is_a?(Proc)
            return if row.id.to_s == '0' || row.id.blank?
            v[:icon].call(row.send(v[:field] || :id)).on(v[:icon_event] || :click) do |*params|
              icon_body.call(*params)
            end
          else
            AT((menu ? { class: "dropdown-item" } : {}).merge(
              {
                href: v[:action] == :link ? (v[:subject] || ->(o) { o }).call(row.send(v[:field] || :id)) : "",
                download: !!v[:download]
              }).
              merge(v[:action] == :link ? { className: "matomo_link", type: 'link' } : { className: "matomo_download", type: 'download' }).
              merge(v[:action] == :link ? { 'target' => "_blank" } : {}).
              merge(v[:action] == :modal ? { 'data-bs-toggle' => "modal", 'data-bs-target' => "#modal-window#{v[:subject].to_s.tr('::', '_')}" } : {})
            ) do
              row.loading? || (@running && @running == v[:subject]) ? Loading() : FontAwesome(icon: v[:icon], modifiers: "fa-fw", text: v[:description], show_description: menu)
            end.on(:click) do |e|
              e.prevent_default unless v[:action] == :link
              icon_body.call
            end
          end
        end
        make_div_for_action(v) if v[:action] == :modal
      end
    end
  end

  def make_div_for_action(v)
    DIV(className: "modal fade", id: "modal-window#{v[:subject].to_s.tr('::', '_')}", tabIndex: "-1", role: "dialog") do
      DIV(className: "modal-dialog modal-lg", role: "document") do
        DIV(className: "modal-content") do
          DIV(className: "modal-header") do
            H5(className: "modal-title") { v[:description] }
            BUTTON(type: "button", className: "close", 'data-bs-dismiss' => "modal") { 'X' }
          end
          DIV(className: "modal-body") do
            Hyperstack::Component::ReactAPI.create_element v[:subject], :row => row
          end
          DIV(className: "modal-footer") do
            BUTTON(type: "button", className: "btn btn-secondary", 'data-bs-dismiss' => "modal") { 'Κλείσιμο' }
            BUTTON(type: "button", className: "btn btn-primary") { "Αποδοχή" }
          end
        end
      end
    end
  end

  def update_edit_in_place(field, contents, value)
    if contents[:edit_in_place]
      # mutate @edit_in_place.merge!({field.to_sym => {edit_type: contents[:edit_in_place], user_value: value}})
      mutate @edit_in_place.merge!({ field.to_sym => { user_value: value } })
    end
  end

  def edit_in_place_btn(field, contents, display_value)
    if contents[:edit_in_place]
      " ".span
      A(href: '') do
        FontAwesome(icon: 'fa-edit', modifiers: 'fa-fw', text: 'Επεξεργασία')
      end.on(:click) do |e|
        e.prevent_default
        update_edit_in_place(field, contents, display_value)
      end
    end
  end

  def icon_link(icon)
    FontAwesome(icon: icon || "fa-save", modifiers: 'fa-fw', text: 'Αποθήκευση', size: 'fa-lg')
  end

  render do
    TR(key: row.respond_to?(:id) ? row.id : row['id'], className: "#{selected_row_id.blank? ? '' : 'table-info'}") {
      columns.each { |field, contents|
        # field = contents[:alias] unless contents[:alias].nil?
        # alert field, contents
        contents[:delegate] ?
          value = (contents[:parameters] ? row.send(contents[:delegate])&.send(field, contents[:parameters]) :
                     (row.is_a?(Hash) ? row.send(contents[:delegate])&.send(:[], field.to_s) : row.send(contents[:delegate])&.send(field))
          ) :
          value = (contents[:parameters] ? row.send(field, contents[:parameters]) :
                     (row.is_a?(Hash) ? row.send(:[], field.to_s) : row.send(field))
          )
        with_tooltip = false
        truncated = ''
        truncate = (contents[:truncate] || 0)
        display_value = case contents[:format]
                        when :date then
                          display_date(value)
                        when :datetime then
                          value.blank? ? 'ΔΕΝ ΕΧΕΙ ΟΡΙΣΘΕΙ' : display_date(value, true)
                        when :currency then
                          value ? display_currency(value) : 'ΔΕΝ ΕΧΕΙ ΟΡΙΣΘΕΙ'
                        when :boolean then
                          value ? 'ναι' : 'όχι'
                        when :look_up, :look_up2
                          unless value.nil?
                            local_value = value.send(contents[:column].first[1].to_sym).to_s
                            if local_value && local_value.is_a?(String) && truncate > 0
                              with_tooltip = (local_value.length > truncate)
                              truncated = local_value[0..truncate] + (with_tooltip ? '...' : '')
                            end
                            local_value
                          else
                            'ΔΕΝ ΕΧΕΙ ΟΡΙΣΘΕΙ'
                          end
                        when :editor
                          unless value.nil?
                            local_value = strip_html(value)
                            if local_value && local_value.is_a?(String) && truncate > 0
                              with_tooltip = (local_value.length > truncate)
                              truncated = local_value[0..truncate] + (with_tooltip ? '...' : '')
                            end
                            local_value
                          else
                            'ΔΕΝ ΕΧΕΙ ΟΡΙΣΘΕΙ'
                          end
                        when :links, :link

                          value

                        when :json then
                          'Σύνθετο Πεδίο'
                        else
                          if value && value.is_a?(String) && truncate > 0
                            with_tooltip = (value.length > truncate)
                            truncated = value[0..truncate] + (with_tooltip ? '...' : '')
                          end
                          value.blank? ? 'ΔΕΝ ΕΧΕΙ ΟΡΙΣΘΕΙ' : value
                        end
        className =
          if (contents[:format] == :currency || contents[:format] == :number) && !number_align_left
            'text-right'
          else
            ''
          end
        TD({ className: className }.merge(
          { key: [
            field.to_s,
            row.respond_to?(:id) ? row.id : row['id'],
            (!value.nil? && [:look_up, :look_up2].include?(contents[:format])) ? value.send(contents[:column].first[0].to_sym) : Random.rand
          ].join('_') })) {
          if row.loading? || value.loading?
            Loading()
          elsif @edit_in_place[field.to_sym]
            related_value = if contents[:edit_in_place][:driven_by] && !@edit_in_place[contents[:edit_in_place][:driven_by].to_sym].nil?
                              @edit_in_place[contents[:edit_in_place][:driven_by].to_sym][:user_value]
                            elsif contents[:edit_in_place][:drives] && !@edit_in_place[contents[:edit_in_place][:drives].to_sym].nil?
                              @edit_in_place[contents[:edit_in_place][:drives].to_sym][:user_value]
                            else
                              nil
                            end
            Hyperstack::Component::ReactAPI.create_element(
              (contents[:edit_in_place][:subject].nil? ? ::Base::EditInPlace : contents[:edit_in_place][:subject]),
              {
                key: (row.respond_to?(:id) ? row.id : row['id']),
                editable_columns: { field => contents },
                row: row,
                value: @edit_in_place[field.to_sym][:user_value],
                related_value: related_value,
                changed: @edit_in_place[field.to_sym][:changed] || nil,
              },
            ).
              on(:close_edit_in_place) do |result = nil|
              row[field.to_sym] = result unless result.blank?
              mutate @edit_in_place.delete(field.to_sym)
              mutate @edit_in_place.delete(contents[:edit_in_place][:drives].to_sym) if contents[:edit_in_place][:drives]
            end
              .on(:feed_edit_in_place) do |result|
              temp = { field.to_sym => { user_value: result, changed: true } }
              temp.merge!({ contents[:edit_in_place][:drives].to_sym => { user_value: nil } }) if contents[:edit_in_place][:drives]
              mutate @edit_in_place.merge!(temp)
            end
          elsif contents[:format] == :links
            value.each do |l|
              AT(target: '_blank', type: 'link', href: l[2], className: "matomo_link") { l[1] }
              BR {}
            end if value.loaded?
          elsif contents[:format] == :link
            if value.is_a?(Array)

              visible_value = (value[1] || value[0])
              with_tooltip = (truncate > 0 && visible_value.length > truncate)
              truncated = visible_value[0..truncate] + (with_tooltip ? '...' : '')
              if with_tooltip
                DIV('data-bs-toggle': "tooltip", title: visible_value.to_s) do
                  AT(target: '_blank', href: value[0], className: "matomo_link", type: 'link') { contents[:icon] ? icon_link(contents[:icon]) : truncated }
                end
              else
                AT(target: '_blank', href: value[0], className: "matomo_link", type: 'link') { contents[:icon] ? icon_link(contents[:icon]) : visible_value }
              end
            else
              with_tooltip = (truncate > 0 && value.length > truncate)
              truncated = value[0..truncate] + (with_tooltip ? '...' : '')
              if with_tooltip
                DIV('data-bs-toggle': "tooltip", title: value.to_s) do
                  AT(target: '_blank', href: value.to_s, className: "matomo_link", type: 'link') { contents[:icon] ? icon_link(contents[:icon]) : truncated }
                end
              else
                AT(target: '_blank', href: value.to_s, className: "matomo_link", type: 'link') { contents[:icon] ? icon_link(contents[:icon]) : value.to_s }
              end

            end if value.loaded?
          else
            className = if [:date, :datetime, :currency].include?(contents[:format])
                          'text-nowrap'
                        else
                          "text-wrap text-break"
                        end

            if with_tooltip
              DIV('data-bs-toggle': "tooltip", title: display_value.to_s) do
                (contents[:format] == :url && value != 'ΔΕΝ ΑΠΑΙΤΕΙΤΑΙ') ? AT(target: '_blank', type: 'link', className: "matomo_link", href: row.send("#{field}_url".to_sym, value)) { truncated } : DIV(style: { whiteSpace: 'pre', maxWidth: '100%', minWidth: '5vw' }, class: className) do
                  parse_html ? DIV(dangerously_set_inner_HTML: { __html: truncated }) : DIV() { "#{truncated.to_s}" }
                  DIV() { edit_in_place_btn(field, contents, display_value) }
                end
              end
            else
              (contents[:format] == :url && value != 'ΔΕΝ ΑΠΑΙΤΕΙΤΑΙ') ? AT(target: '_blank', type: 'link', className: "matomo_link", href: row.send("#{field}_url".to_sym, value)) { value } : DIV(style: { whiteSpace: 'pre', maxWidth: '100%', minWidth: '5vw' }, class: className) do
                parse_html ? DIV(dangerously_set_inner_HTML: { __html: display_value }) : DIV() { "#{display_value.to_s}" }
                DIV() { edit_in_place_btn(field, contents, display_value) }
              end
            end
          end
        }

      }
      if actions_local.count > 0
        TD { row.loading? ? Loading() : show_actions
        show_context
        }
      else
        TD {} unless hide_no_actions_td
      end
    }.
      on(:click) { |e|
        row_selected!(row) if e.ctrl_key
      }.
      on(:context_menu) do |e|
      e.prevent_default
      mutate @context_visible = true
      mutate @context_x = e.page_x
      mutate @context_y = e.page_y
    end
    # TR(key: row.respond_to?(:id) ? row.id : row['id']) {
    #   TD(colSpan: columns.size + (actions_local.count > 0 ? 1 : 0)) {
    #     Hyperstack::Component::ReactAPI.create_element @show_details, :row => row, :editable_columns => editable_columns
    #   }
    # } if @show_details
  end

end


