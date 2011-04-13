set :user, 'root'
set :application, "Lyrebird"
set :domain, "kav.la"
set :repository,  "gitosis@kav.la:lyrebd.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :deploy_subdir, "implementation/lyrebd"

role :web, domain                          # Your HTTP server, Apache/etc
role :app, domain                          # This may be the same as your `Web` server
role :db,  domain, :primary => true # This is where Rails migrations will run

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

 namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
 end

 require 'capistrano/recipes/deploy/strategy/remote_cache'

 class RemoteCacheSubdir < Capistrano::Deploy::Strategy::RemoteCache

   private

   def repository_cache_subdir
     if configuration[:deploy_subdir] then
       File.join(repository_cache, configuration[:deploy_subdir])
     else
       repository_cache
     end
   end

   def copy_repository_cache
     logger.trace "copying the cached version to #{configuration[:release_path]}"
     if copy_exclude.empty? 
       run "cp -RPp #{repository_cache_subdir} #{configuration[:release_path]} && #{mark}"
     else
       exclusions = copy_exclude.map { |e| "--exclude=\"#{e}\"" }.join(' ')
       run "rsync -lrpt #{exclusions} #{repository_cache_subdir}/* #{configuration[:release_path]} && #{mark}"
     end
   end

 end

