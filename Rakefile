require "bundler/setup"

require "bundler/gem_tasks"

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec => 'spec:prepare')

desc "Start Postgresql for Dev/Test"
namespace :db do
  task :start do
    unless ENV['DB_ADAPTER'] == 'sqlite'
      sh('(docker stop postgresql || true) &&  (docker rm postgresql || true)')
      sh('docker-compose up -d postgresql')
    end
  end
end

desc "Publish to private gem server"
task :publish do
  require './lib/hyperstack/addons/version'
  sh 'gem', 'build', "hyperstack-addons.gemspec"
  sh 'gem', 'inabox', "hyperstack-addons-#{Hyperstack::Addons::VERSION.tr("'", '')}.gem", '-g', "https://michail:#{ENV['GEM_SERVER_KEY']}@gems.ru.aegean.gr"
end
task :default => :spec

namespace :spec do
  desc "create/migrate/prepare dummy apd db"
  task :prepare => 'db:start' do
    Dir.chdir('spec/dummy') do
      sh('yarn')
      sh('bundle')
      # sh("bundle exec rake assets:clobber")
      sh("rm -rf tmp/cache public/assets public/packs*")
      # sh("bundle exec rake assets:precompile")
      sh("bundle exec rake db:create db:migrate db:test:prepare")
    end
    # rakefile = File.expand_path('../spec/dummy/Rakefile', __FILE__)
    # #sh("rake -f #{rakefile} my_engine:install:migrations")
    # sh("bundle exec rake -f #{rakefile} db:create db:migrate db:test:prepare")
  end
end