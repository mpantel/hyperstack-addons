describe 'base-spec', js: true do

  before(:each, js: true) do |spec|
    #client_option layout: 'application'
    on_client do
      require 'hyperstack/addons/components'
      require 'hyperstack/addons/pager'

    end

  end

  it "can the mount a base component" do

    text = "sample text"

    mount 'Base1', value: text do
      class Base1 < HyperComponent
        param :value
        render(DIV) do
          Input(value: value)
        end
      end
    end
    input_value = find('input').value
    expect(input_value).to eq(text)
  end

  it "can the mount a input" do

    text = "sample text"
    mount 'Base12', value: text do
      class Base12 < HyperComponent
        param :value
        render(DIV) do
          Input(value: value)
        end
      end
    end

    input_value = find('input').value
    expect(input_value).to eq(text)
  end

  let!(:obj1) { Sample.create(description: 'description1') }
  # let!(:obj2) { SampleData.new(2, 'description2') }
  # let!(:obj3) { SampleData.new(3, 'description3') }
  # FactoryBot.find_definitions
  # FactoryBot.build(:sample_data)
  it "can the mount pager" do

    mount 'ShowPager' do

      class ShowPager < Base::Index
        def columns
          {
            id: { description: 'MK', key: true },
            description: { description: 'Περιγραφή' },
          }
        end

        def actions
          {
          }
        end

        render(DIV) do
          base_render(title: 'PagerTest', page_size: 20,
                      data_object: Sample,
                      columns: columns, actions: actions)
        end
      end
    end
    wait_for_ajax
    # input_value = find('input').value
    expect(page).to have_content('PagerTest')
  end
end



