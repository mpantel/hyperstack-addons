class FontAwesome < Base::Component
  param :icon
  param modifiers: ''
  param text: ''
  param show_description: false
  param size: 'fa-1x'
  param tool_tip_title: ""
  render(SPAN) do
    SPAN({ className: ["fa", icon, modifiers, size].join(' ') }.merge!(tool_tip_title.blank? ? {} : { 'data-bs-toggle': "tooltip", title: tool_tip_title }) )
     SPAN(show_description ? {} : {className: "sr-only"}) {' '+ text}
  end
end