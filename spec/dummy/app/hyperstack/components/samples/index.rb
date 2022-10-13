module Samples
  class Index < Base::Index
    def columns
      {
        id: { description: 'MK', key: true },
        description: { description: 'Περιγραφή', usage: :rw},
      }
    end

    def actions
      {
        :insert_fake_modal => { description: 'Προσθήκη', icon: 'fa-plus-circle', action: :insert_fake_modal, subject: Samples::EditInList, scope: :class },
        :edit_fake_modal => { description: 'Επεξεργασία', icon: 'fa-edit', action: :edit_fake_modal, subject: Samples::EditInList, scope: :row },
        :delete => { description: 'Διαγραφή', icon: 'fa-trash', action: :run, subject: Samples::Delete, custom_params: { action_type: :delete }, scope: :row  },

      }
    end

    render(DIV) do
      base_render(title: 'Samples', page_size: 20,
                  data_object: Sample,
                  columns: columns, actions: actions)
    end
  end
end