source 'https://rubygems.org'

# use block to avoid dual gem source warning
source "https://michail:#{ENV['GEM_SERVER_KEY']}@gems.ru.aegean.gr" do
  gem 'rails-hyperstack'
  gem  'hyper-spec'
  gem 'hyper-i18n'
end

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in hyperstack-addons.gemspec.
gemspec

# group :development do
#   gem 'sqlite3'
# end

# To use a debugger
# gem 'byebug', group: [:development, :test]
