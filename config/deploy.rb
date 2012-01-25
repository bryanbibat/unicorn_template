$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require 'rvm/capistrano'
set :rvm_ruby_string, '1.9.3@rails32'
set :rvm_type, :user

require "bundler/capistrano"

set :deploy_via, :remote_cache
set :application, "unicorn_template"
set :repository, "git://github.com/bryanbibat/unicorn_template.git"
set :deploy_to, "/home/bry/capistrano/unicorn_template"

set :scm, :git

default_run_options[:pty] = true

server "bryanbibat.net", :app, :web, :db, :primary => true
set :user, "bry"
set :use_sudo, false

depend :remote, :gem, "bundler"

set :rails_env, :production
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"

namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && bundle exec unicorn -c #{unicorn_config} -E #{rails_env} -D"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "kill `cat #{unicorn_pid}`"
  end
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "kill -s QUIT `cat #{unicorn_pid}`"
  end
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "kill -s USR2 `cat #{unicorn_pid}`"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end

after "deploy:setup", :create_unicorn_socket
before "deploy:start", :symlink_unicorn_socket
before "deploy:finalize_update", :copy_production_database_configuration, :create_symlink_to_log 

task :create_unicorn_socket do
  run "mkdir #{shared_path}/sockets -p; touch #{shared_path}/sockets/unicorn.sock"
end

task :copy_production_database_configuration do
  run "cp #{shared_path}/config/database.yml #{release_path}/config/database.yml"
end

task :symlink_unicorn_socket do
  run "mkdir #{current_path}/tmp/sockets -p; ln -s #{shared_path}/sockets/unicorn.sock #{current_path}/tmp/sockets/unicorn.sock"
end

task :create_symlink_to_log do
  run "cd #{current_path}; rm -rf log; ln -s #{shared_path}/log log"
end
