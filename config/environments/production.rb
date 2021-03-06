# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

require 'configuration'

ProjectsMigration.new.migrate_data_if_needed

config.after_initialize do
  require CRUISE_DATA_ROOT + '/site_config' if File.exists?(CRUISE_DATA_ROOT + "/site_config.rb")
  require RAILS_ROOT + '/config/dashboard_initialize' 
  BuilderStarter.start_builders 
end
