class RemoveElementButton < Base::Component
  render(DIV) do
    A(href: '') do
      FontAwesome(icon: 'fa-minus', modifiers: 'fa-fw', text: 'Διαγραφή')
    end
  end
end
