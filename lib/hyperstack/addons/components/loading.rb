class Loading < Base::Component
  render do
    FontAwesome(icon: "fa-spinner", modifiers: "fa-spin fa-fw", text: "Loading...")
  end
end