describe 'hyper-spec', js: true do

  before(:each, js: true) do |spec|
    #client_option layout: 'application'
  end

  it 'load root and save a screenshot' do
    visit "/"
    page.instance_variable_set("@hyper_spec_mounted", true)
    page.save_screenshot("spec/screenshot_#{__LINE__}_#{Time.now.iso8601.tr('-:+', '___')}.png")
    expect(page).to have_content('App')
    # wait_for_ajax
    #page.save_screenshot("spec/screenshot_#{__LINE__}_#{Time.now.iso8601.tr('-:+', '___')}.png")
  end

  it "can the mount a component defined in mounts code block" do

    mount 'ShowOff' do
      class ShowOff < HyperComponent
        render(DIV) { 'Now how cool is that???' }
      end
    end
    expect(page).to have_content('Now how cool is that???')
    end
  it "can the mount a component defined in mounts code block with param" do

    text = "sample text"
    mount 'ShowOff2',text: text do
      class ShowOff2 < HyperComponent
        param :text
        render(DIV) { "Now how cool is that??? with #{text}" }
      end
    end
    expect(page).to have_content("Now how cool is that??? with #{text}")
  end

end
