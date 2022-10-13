describe 'Pager', js: true do
  before(:example) do
    @table_row1 = FactoryBot.create(:change_data)
    @table_row2 = FactoryBot.create(:delete_data)
  end

  # before(:each, js: true) do |spec|
  #   # client_option raise_on_js_errors: :show
  #   # client_option layout: 'application'
  # end
  #
  it "is valid with valid attributes" do
    expect(@table_row1).to be_valid
    expect(@table_row2).to be_valid
  end
  # let(:change_data) { build(:change_data) }
  # let(:delete_data) { build(:delete_data) }

  it 'can insert one row' do
    visit "/"
    expect(page).to have_title('Dummy')
    page.find('.fa-plus-circle').click
    modal = page.find('.modal-dialog')
    expect(page).to have_content('Προσθήκη')
    input = modal.find('input.form-control')
    input.click
    input.set(@table_row1)
    save = page.all('.modal-header>div>a').first
    save.click
    expect(page).to have_content(@table_row1)
  end

  #TODO na to kano me ena factory
  xit 'can delete the first row' do
    visit "/"
    expect(page).to have_title('Dummy')
    table_body = page.find('.table>tbody')
    expect(table_body.all('tr').count).to be > 0
    first_row = table_body.all('tr').first
    last_column = first_row.all('td').last
    delete_button = last_column.all('div>span').last
    expect(delete_button[:title]).to eq('Διαγραφή')
    delete_button.click
    text_alert = page.driver.browser.switch_to.alert.text
    page.driver.browser.switch_to.alert.accept
  end

  xit 'can change the desc from the first row' do
    visit "/"
    expect(page).to have_title('Dummy')
    table_body = page.find('.table>tbody')
    first_row = table_body.all('tr').first
    last_column = first_row.all('td').last
    change_button = last_column.all('div>span').first
    change_button.click
    expect(page).to have_content('Επεξεργασία')
    modal = page.find('.modal-dialog')
    input = modal.find('input.form-control')
    input.click
    input.set('Just change the description!')
    save = page.all('.modal-header>div>a').first
    save.click
    expect(page).to have_content('Just change the description!')
  end
end