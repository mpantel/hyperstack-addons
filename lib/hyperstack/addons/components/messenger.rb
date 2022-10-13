class Messenger < Base::Component

  param :parent_component_name

  def new_toast(msg, key)
    DIV(className: "position-fixed bottom-0 end-0 p-1", "style": { "z-index": 11 }) do
      DIV(className: "toast show", role: "alert", "aria-live": "assertive", "aria-atomic": "true", "data-bs-autohide": "false", "data-bs-delay": "10000") do
        DIV(className: "d-flex bg-warning") do
          DIV(className: "toast-body") do
            "#{msg}"
          end
          BUTTON(type: "button", className: "btn-close me-2 m-auto", "data-bs-dismiss": "toast", "aria-label": "Close")
            .on(:click) do |e|
            e.prevent_default
            Messages.clear_message(parent_component_name, key)
          end
        end
      end
    end
  end

  def clear_all_messages
    BUTTON(className: 'btn btn-primary') {
      'Καθαρισμός'
    }.on(:click) { Messages.clear_all_messages } if Hyperstack.env.development?
  end

  def toast_club
    DIV(className: "toast-container") do
      unless Messages.message_hash[parent_component_name].blank?
        Messages.message_hash[parent_component_name].each do |key, msg|
          new_toast(msg, key)
        end
      end
    end
  end

  render(DIV) do
    toast_club if parent_component_name.loaded?
  end

end