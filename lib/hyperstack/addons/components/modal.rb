#https://react-popup.elazizi.com/component-api/

class Modal < Base::Component
  param :static, default: true #to not close the value should be false or "static"
  param :keyboard_close, default: false
  param :with_trigger_button, default: true
  param :trigger, default: nil
  # param :for_id, default: "modal_id"
  param :trigger_button_text, default: nil
  param :large_modal, default: false
  param :xl_modal, default: false
  param :fullscreen, default: false
  param :scrollable, default: true #
  fires :trigger_button_clicked
  param portfolio: false

  # imports 'Popup'

  render do
    BUTTON(className: "btn btn-primary") do
      #",data-bs-toggle": "modal", "data-bs-target": "##{for_id}"
      SPAN { trigger_button_text }
    end.on(:click) {
      trigger_button_clicked!
    } if with_trigger_button
    DIV(className: "modal-backdrop fade show") { } if trigger
    # if trigger
    #   `document.body.style.overflowY = "hidden";`
    # else
    #   `document.body.style.overflowY = "";`
    # end

    DIV(className: "#{portfolio ? "portfolio-modal" : ""}{ modal fade #{trigger ? "d-block show" : ""} ", "data-bs-backdrop": static ? "static" : true, "data-bs-keyboard": !keyboard_close, tabIndex: "-1", "aria-labelledby": "staticBackdropLabel", "aria-hidden": true) do
      DIV(className: "modal-dialog modal-dialog-centered #{scrollable ? "modal-dialog-scrollable" : ""} #{large_modal ? "modal-xl" : ""}  #{fullscreen ? "modal-fullscreen" : ""}", style: {}.merge(xl_modal ? { maxWidth: "90%" } : {}).merge(large_modal ? { maxWidth: "70%" } : {})) {
        DIV(className: "modal-content") {
          children.each(&:render)
        }
      }
    end.on(:key_up) do |e|
      if e.key_code == 27
      trigger_button_clicked!
    end
    end
  end

  #   do
  #   children.each(&:render)
  # end

  # render do
  # butt : BUTTON(class:"btn btn-primary") do
  #         SPAN {"click"}
  #       end.on(:click) {
  #         mutate @toggle : !@toggle
  #       }.as_node
  #
  # Modal(trigger: butt.to_n, position: "center center", modal: true, closeOnDocumentClick: false,style:{maxHeight: '80vh',maxWidth: '80vw'}){DIV(style:{maxHeight: '80vh',maxWidth: '80vw', overflowY: "scroll"}){ Calls::Invitations::Index()}}
  # end

end
