describe 'PagerNavigation', js: true  do
  xit 'can mount the pager navigation' do
    n1=20
    n2=60
    n3=1
    mount 'PagerNavigation1', page_size: n1, rows_found: n2, current_page: n3 do
      class PagerNavigation1 < HyperComponent
        param :page_size
        param :rows_found
        param :current_page
        fires :set_page
        param :btn_css, default: "btn-secondary" #btn-primary, btn-secondary

        before_mount do
          @current_page = 1
        end

        render(DIV) do
          PagerNavigation(page_size: page_size, rows_found: rows_found, current_page: @current_page).
            on(:set_page) { |page_number| mutate { @current_page = page_number } unless page_number == @current_page }
        end
      end
    end

    pager_navigation = page.all('.btn-group>span')
    pager_navigation[1].click
    expect(page).to have_text('Σύνολο: 60 εγγραφών')
    # byebug
    check = page.all('.btn-group>input')
    puts "#{check}"
    expect(check).to have_selector('.btn-dark')
    # val = check[:value]
    # puts "#{val}"
    byebug
  end
end
