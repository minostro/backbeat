role :utility,     'accounting-utility2-uat.snc1', :primary => true
role :delayed_job_backbeat, 'accounting-utility2-uat.snc1'

set :branch, ENV['branch'] if ENV['branch']
set :branch, ENV['BRANCH'] if ENV['BRANCH']
