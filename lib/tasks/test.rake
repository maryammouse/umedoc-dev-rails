# lib/tasts/test.rake
# Do not drop database for tests
# obtained from: http://stackoverflow.com/questions/1158407/how-to-keep-data-when-run-test-in-rails
if ENV['RAILS_ENV'] == 'test'
  Rake::TaskManager.class_eval do
    def delete_task(task_name)
      @tasks.delete(task_name.to_s)
    end
  end

  Rake.application.delete_task("db:test:load")

  namespace :db do
    namespace :test do
      task :load do
      end
    end
  end
end
