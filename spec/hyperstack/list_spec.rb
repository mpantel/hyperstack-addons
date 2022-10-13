require 'spec_helper'

describe 'Basic functionality of list', :js do

  it 'mounts empty list with :inputs_grid list_type' do
    mount 'CheckList' do
      class CheckList < HyperComponent
        before_mount do
          @list = [[]]
        end
        render(DIV) do
          ListComponents::List(list: @list).on(:update_list) { |list| mutate @list = list }
        end
      end
    end
    expect(page).to have_content('Λίστα')
    expect(page).to have_content('Μετάβαση σε: Πεδίο Κειμένου')
    expect(all('.fa-plus-circle').count).to eq(3)
    find('button', text: "Μετάβαση σε: Πεδίο Κειμένου").click
    if page.has_selector?('button', text: "Μετάβαση σε: Πεδίο Κειμένου", wait: 3) # Σε περίπτωση που το έχει κλείσει μόνο του από bug του modal
      find('button', text: "Μετάβαση σε: Πεδίο Κειμένου").click
    end
    expect(page).to have_content('Μετάβαση σε: Λίστα')
    expect(page).to have_selector("textarea")
    find("textarea").set('value 1')
    find('button', text: "Μετάβαση σε: Λίστα").click
    expect(all('.fa-plus-circle').count).to eq(3)
    expect(all('.fa-minus-circle').count).to eq(2)
    expect(all('input').count).to eq(1)
    all('.fa-plus-circle')[0].click
    all('input').last.set("value 2")
    find('button', text: "Μετάβαση σε: Πεδίο Κειμένου").click
    expect(find("textarea").text).to eq("value 1 value 2")
    find('button', text: "Μετάβαση σε: Λίστα").click
    expect(all('input').count).to eq(2)
    expect(all('.fa-arrow-alt-circle-up').count).to eq(1)
    expect(all('.fa-arrow-alt-circle-down').count).to eq(1)
    expect(all('input').first.value).to eq("value 1")

    find('.fa-arrow-alt-circle-down').click
    expect(all('input').first.value).to eq("value 2")
    find('.fa-arrow-alt-circle-up').click
    expect(all('input').first.value).to eq("value 1")

    all('.fa-plus-circle').last.click
    expect(all('input').count).to eq(4)
    set_and_send_tab('input',2,"value 3")
    set_and_send_tab('input', 3,"value 4")
    all('.fa-plus-circle')[1].click
    set_and_send_tab('input',4,"value 5")
    all('.fa-plus-circle').last.click
    expect(all('input').count).to eq(8)
    expect(all('.fa-minus-circle').count).to eq(11)
    all('.fa-minus-circle')[7].click
    expect(all('input').count).to eq(5)
    find('button', text: "Μετάβαση σε: Πεδίο Κειμένου").click
    expect(find("textarea").text).to eq("value 1 value 2\nvalue 3 value 4 value 5")
    find('button', text: "Μετάβαση σε: Λίστα").click
    all('.fa-minus-circle').last.click
    expect(all('input').count).to eq(4)
    expect(all('.fa-arrow-alt-circle-up').count).to eq(3)
    all('.fa-arrow-alt-circle-up')[1].click
    expect(all('input').first.value).to eq("value 3")
  end

end

describe 'Mounts list with extra parameters', :js do

  it 'mounts empty list and checks extra functionality' do
    mount 'CheckList' do
      class CheckList < HyperComponent
        before_mount do
          @list = [["value 1", "value 2"]]
        end
        render(DIV) do
          ListComponents::List(
            list: @list,
            # list_type: :inputs_grid,
            content_component: :editor,
            header_push_for_finite_items: 2,
            hide_toggle_view_btn: true,
            list_title: 'Another list title',
          ).on(:update_list) { |list| mutate @list = list }
        end
      end
    end
    expect(page).to have_content('Another list title')
    expect(page).not_to have_content('Μετάβαση σε: Πεδίο Κειμένου', wait: 2)
    expect(page).not_to have_content('Μετάβαση σε: Λίστα', wait: 2)
    expect(all('.fa-plus-circle').count).to eq(3)
    expect(all(editor_selector).count).to eq(2)
    expect(all('input').count).to eq(0)
    all('.fa-plus-circle').last.click
    expect(all('.fa-plus-circle').count).to eq(3)
    expect(all(editor_selector).count).to eq(4)
    expect(all('input').count).to eq(0)
  end

end

describe 'Basic functionality of list for hash', :js do

  it 'mounts empty list with :inputs_grid list_type' do
    mount 'CheckList' do
      class CheckList < HyperComponent
        before_mount do
          @list = { a: 1, b: 2, c: [2, 3], d: { x: "eks", y: "why" } }
        end
        render(DIV) do
          ListComponents::List(
            list: @list,
          ).on(:update_list) { |list| mutate @list = list }
          SPAN() { "#{@list}" }
        end
      end
    end
    expect(page).to have_content('Λίστα')
    expect(page).not_to have_content('Μετάβαση σε: Πεδίο Κειμένου', wait: 2)
    expect(page).not_to have_content('Μετάβαση σε: Λίστα', wait: 2)
    expect(all('.fa-plus-circle').count).to eq(4)
    expect(all('.fa-pen').count).to eq(6)
    expect(all('input').count).to eq(6)
    all('.fa-pen').first.click
    expect(all('.fa-pen').count).to eq(5)
    expect(all('input').count).to eq(7)
    set_and_send_tab('input',:first,"a1")
    expect(all('.fa-pen').count).to eq(6)
    expect(all('input').count).to eq(6)
    all('.fa-plus-circle')[0].click
    expect(all('.fa-pen').count).to eq(6)
    expect(all('input').count).to eq(7)
    set_and_send_tab('input',4,"100")
    all('.fa-plus-circle')[1].click
    expect(all('.fa-pen').count).to eq(7)
    expect(all('input').count).to eq(8)
    all('.fa-pen').last.click
    expect(all('.fa-pen').count).to eq(6)
    expect(all('input').count).to eq(9)
    set_and_send_tab('input',7,"key")
    set_and_send_tab('input',7,"value")
    expect(page).to have_content('{"a1"=>1, "b"=>2, "c"=>[2, 3, "100"], "d"=>{"x"=>"eks", "y"=>"why", "key"=>"value"}}')
  end

  # @x = ["α", "1", "β", "2"]
  # @x = [["α","1"],["β","2"]]
  # @x = {"a"=>"1","b"=>"2", "c"=>{"x"=>"10","y"=>"11"}}
  # @x = { a: 1, b: 2, c: [3, 4], d: { x: "eks", y: "why" } }
  # @x = {a:1,b:2}
  # @x = [100,{"a":1,"b":2}]
  # @x = {}
  # @x = {"":""}
  # @x = [[]]
  # @x = {a:1,b:2, c:{x:111,z:333}, d:[7,{k:100,l:200},9]}
  # @x = {a:1,b:2, c:{x:111,z:333}, d:[7,9], e:[{k:100,l:200},10,20], x:[["y",90]]}
  # TR(scope: "row") do
  #   TD { "srhj" }
  #   TD do
  #     ListComponents::List(key: "srhj#{@x.to_s}", list: @x,
  #     # list_type: :inputs_grid,
  #                          ).
  #       on(:update_list) do |list|
  #       mutate @x = list #.to_h
  #     end
  #   end
  # end

end

describe 'Mounts list and then list for submission', :js, :no_reset do

  it 'mounts empty list to check extra functionality' do
    mount 'CheckList' do
      class CheckList < HyperComponent
        before_mount do
          @list = [[]]
        end
        render(DIV) do
          ListComponents::List(
            list: @list,
            header_push_for_finite_items: 1,
            show_add_button: false,
            show_select_controls: true,
            per_field_content_component: true,
            hide_toggle_view_btn: true,
          ).on(:update_list) { |l| mutate @list = l }
          SPAN() { @list.to_s }
        end
      end
    end

    expect(page).to have_content('Λίστα')
    expect(page).not_to have_content('Μετάβαση σε: Πεδίο Κειμένου', wait: 2)
    expect(page).not_to have_content('Μετάβαση σε: Λίστα', wait: 2)
    expect(all('.fa-plus-circle').count).to eq(1)
    all('.fa-plus-circle').last.click
    # all('.fa-plus-circle').first.click
    set_and_send_tab('input',0,"value with default content type")
    all('.fa-plus-circle').last.click
    all('input')[2].set("value with input content type")
    all('select.form-select')[1].select('Πεδίο Εισαγωγής')
    all('select.form-select')[1].select('Πεδίο Εισαγωγής')
    all('.fa-plus-circle').last.click
    set_and_send_tab('input',4,"value with trix content type")
    all('select.form-select')[2].select('Πεδίο Κειμένου')
    all('select.form-select')[2].select('Πεδίο Κειμένου')
    all('.fa-plus-circle').last.click
    set_and_send_tab('input',6,"value with read-only content type")
    all('select.form-select')[3].select('Πεδίο Μόνο για Ανάγνωση')
    all('.fa-plus-circle').last.click
    set_and_send_tab('input',8,"value with currency content type")
    all('select.form-select')[4].select('Πεδίο Χρηματικού Ποσού')

    all('.fa-plus-circle').last.click
    all('label', text: 'Πεδίο Επιλογών').last.sibling('input').click
    page.accept_alert #"Αν αλλάξετε τύπο δεδομένων για το συγκεκριμένο πεδίο, οι προηγούμενες τιμές του πεδίου θα διαγραφούν. Είστε σίγουροι ότι θέλετε να αλλάξετε τύπο δεδομένων;"
    set_and_send_tab("input[placeholder='Τίτλος Πεδίου Επιλογών']",:first, "title of select field")
    all('.fa-plus').first.click
    set_and_send_tab("input[placeholder='προσθέστε τιμή επιλογής']",0, "option 1")
    all('.fa-plus').first.click
    set_and_send_tab("input[placeholder='προσθέστε τιμή επιλογής']",1, "option temp")
    all('.fa-plus').first.click
    set_and_send_tab("input[placeholder='προσθέστε τιμή επιλογής']",2, "option 2")

    expect(all("input[placeholder='προσθέστε τιμή επιλογής']").count).to eq(3)
    all('.fa-minus')[1].click
    expect(all("input[placeholder='προσθέστε τιμή επιλογής']").count).to eq(2)
    all('label', text: 'Επιλογή Άλλο').last.sibling('input').click
    expect(page).to have_content('[["value with default content type", "value with input content type!!i!!", "value with trix content type&&e&&", "value with read-only content type((r((", "value with currency content type!!cur!!", "title of select field$$option 1***option 2***??()??$$"]]')
  end

  it 'mounts list for submission' do
    mount 'CheckList' do
      class CheckList < HyperComponent
        before_mount do
          @list_template = [["value with default content type", "value with input content type!!i!!", "value with trix content type&&e&&", "value with read-only content type((r((", "value with currency content type!!cur!!", "title of select field$$option 1***option 2***??()??$$"]]
          @list = @list_template.map { |i| i.map { |e| "" } }
        end
        render(DIV) do
          ListComponents::ListForSubmission(
            list: @list,
            list_template: @list_template,
            list_title: "list for submission",
            content_component: :editor,
            header_push_for_finite_items: 2,
            list_type: :inputs_grid,
            hide_toggle_view_btn: true,
            show_sort_buttons: false
          ).on(:update_list) { |l| mutate @list = l }
        end
      end
    end

    expect(page).to have_content('list for submission')
    expect(all('.fa-plus-circle').count).to eq(1)
    expect(all('.fa-minus-circle').count).to eq(1)
    expect(all(editor_selector).count).to eq(2)
    expect(all('input').count).to eq(2)
    expect(all('select').count).to eq(1)
    expect(page).to have_content('value with read-only content type')
    set_and_send_tab('input',0,'input value 1')
    set_and_send_tab('input',1,23.23)
    set_and_send_tab(editor_selector,0,'editor value 1')
    set_and_send_tab(editor_selector,1,'editor value 2')
    find('select.form-select').select('option 1')
    find('.fa-plus-circle').click
    expect(all('.fa-plus-circle').count).to eq(0)
    expect(all('.fa-minus-circle').count).to eq(2)
    expect(all(editor_selector).count).to eq(4)
    expect(all('input').count).to eq(4)
    expect(all('select').count).to eq(2)
    expect(page).not_to have_selector(".fa-arrow-alt-circle-down", wait: 2)
    expect(page).not_to have_selector(".fa-arrow-alt-circle-up", wait: 2)
    set_and_send_tab(editor_selector,2,'editor value 3')
    set_and_send_tab(editor_selector,3,'editor value 4')
    set_and_send_tab('input',2,'input value 2')
    set_and_send_tab('input',3,24.24)
    all('select.form-select')[1].select('Άλλο')
    expect(all('select.form-select')[1].value).to eq("??()??")
    all('select.form-select')[1].sibling('input').set('other value')

  end

end

describe 'Hash with editor', :js do

  it 'mounts hash with :inputs_grid list_type' do
    mount 'CheckList' do
      class CheckList < HyperComponent
        before_mount do
          @list = { a: 1 }
        end
        render(DIV) do
          ListComponents::List(
            list: @list,
            content_component: :editor,
          ).on(:update_list) { |list| mutate @list = list }
          SPAN() { "#{@list}" }
        end
      end
    end
    expect(page).to have_content('Λίστα')
    expect(all('.fa-plus-circle').count).to eq(2)
    expect(all('.fa-pen').count).to eq(1)
    expect(all('input').count).to eq(0)
    expect(all(editor_selector).count).to eq(1)
    find('body').click
    all('.fa-pen').first.click
    expect(all('input').count).to eq(1)
    all('input').first.click
    find('body').click
    expect(all('input').count).to eq(0)
    all('.fa-plus-circle').first.click
    expect(all(editor_selector).count).to eq(2)
    all('.fa-pen').last.click
    set_and_send_tab('input',:last,"b")
    set_and_send_tab(editor_selector,:last,"bbb")
    expect(page).to have_content('bbb')
    expect(page).to have_content('{"a"=>1, "b"=>"<div>bbb</div>"}')
  end

end

describe 'Push with options', :js do

  it 'mounts hash with :inputs_grid list_type' do
    mount 'CheckList' do
      class CheckList < HyperComponent
        before_mount do
          @list = { a: 1, b: 2, c: [2, 3], d: { x: "eks", y: "why" } }
        end
        render(DIV) do
          ListComponents::List(
            list: @list,
            push_with_options: true,
          ).on(:update_list) { |list| mutate @list = list }
          SPAN() { "#{@list}" }
        end
      end
    end

    expect(page).to have_content('Λίστα')
    expect(all('.fa-plus-circle').count).to eq(0)
    expect(all('.fa-pen').count).to eq(6)
    expect(all('input').count).to eq(6)
    all('.fa-pen').first.click
    expect(all('.fa-pen').count).to eq(5)
    expect(all('input').count).to eq(7)
    set_and_send_tab('input',:first,"a1")
    expect(all('.fa-pen').count).to eq(6)
    expect(all('input').count).to eq(6)
    expect(all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }.count).to eq(4)
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[0].select('Κενή συμβολοσειρά')
    expect(all('input').count).to eq(7)
    expect(all('.fa-pen').count).to eq(6)
    set_and_send_tab('input',4,"100")
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[0].select('Κενός πίνακας')
    expect(all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }.count).to eq(5)
    expect(all('input').count).to eq(7)
    expect(all('.fa-pen').count).to eq(6)
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[0].select('Κενή συμβολοσειρά')
    expect(all('input').count).to eq(8)
    expect(all('.fa-pen').count).to eq(6)
    set_and_send_tab('input', 5,"200")
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[0].select('Κενή συμβολοσειρά')
    expect(all('input').count).to eq(9)
    expect(all('.fa-pen').count).to eq(6)
    set_and_send_tab('input',6,"300")
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[1].select('Κενός δισδιάστατος πίνακας')
    expect(all('input').count).to eq(9)
    expect(all('.fa-pen').count).to eq(6)
    expect(all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }.count).to eq(7)
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[1].select('Κενή συμβολοσειρά')
    expect(all('input').count).to eq(10)
    expect(all('.fa-pen').count).to eq(6)
    expect(all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }.count).to eq(7)
    set_and_send_tab('input',7,"400")
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[1].select('Κενή συμβολοσειρά')
    set_and_send_tab('input',8,"500")
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[3].select('Ζευγάρι κλειδί - κενή συμβολοσειρά')
    expect(all('input').count).to eq(12)
    expect(all('.fa-pen').count).to eq(7)
    all('.fa-pen')[3].click
    expect(all('input').count).to eq(13)
    expect(all('.fa-pen').count).to eq(6)
    set_and_send_tab('input',9,'key')
    expect(all('input').count).to eq(12)
    expect(all('.fa-pen').count).to eq(7)
    set_and_send_tab('input',9,'value')
    expect(all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }.count).to eq(8)
    expect(all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[4].all('option').map(&:value)).to eq(["", "empty_string", "empty_array", "empty_2d_array", "key_value_pair", "key_array_pair", "key_2d_array_pair", "calculate_by_item_max_length"])
    expect(all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[5].all('option').map(&:value)).to eq(["", "key_value_pair", "key_array_pair", "key_2d_array_pair"])
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[5].select('Ζευγάρι κλειδί - κενός πίνακας')
    expect(all('input').count).to eq(12)
    expect(all('.fa-pen').count).to eq(8)
    # all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[5].select('Ζευγάρι κλειδί - κενός πίνακας')
    all('.fa-pen')[7].click
    set_and_send_tab('input',12,'z')
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[5].select('Κενή συμβολοσειρά')
    expect(all('input').count).to eq(13)
    expect(all('.fa-pen').count).to eq(8)
    set_and_send_tab('input',12,'zed')
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[5].select('Κενή συμβολοσειρά')
    set_and_send_tab('input',13,'zed2')
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[6].select('Ζευγάρι κλειδί - κενός δισδιάστατος πίνακας')
    expect(all('.fa-pen').count).to eq(9)
    all('.fa-pen')[8].click
    set_and_send_tab('input',14,'o')
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[6].select('Κενή συμβολοσειρά')
    set_and_send_tab('input',14,'not key')
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }[6].select('Κενή συμβολοσειρά')
    set_and_send_tab('input',15,'not value of key')
    all('select').select { |s| s.all('option').map(&:value).include?("key_value_pair") }.last.select('Ζευγάρι κλειδί - κενή συμβολοσειρά')
    expect(all('.fa-pen').count).to eq(10)
    expect(all('input').count).to eq(17)
    expect(all('.fa-minus-circle').count).to eq(26)
    expect(page).to have_content('{"a1"=>1, "b"=>2, "c"=>[2, 3, "100", ["200", "300"], [["400", "500"]], {"key"=>"value"}], "d"=>{"x"=>"eks", "y"=>"why", "z"=>["zed", "zed2"], "o"=>[["not key", "not value of key"]]}, ""=>""}')
  end

end