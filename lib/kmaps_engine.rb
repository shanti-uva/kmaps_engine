require 'kmaps_engine/engine'
require 'kmaps_engine/feature_extension_for_name_positioning'
require 'kmaps_engine/simple_prop_cache'
require 'kmaps_engine/feature_pid_generator'
require 'kmaps_engine/has_timespan'
require 'kmaps_engine/is_citable'
require 'kmaps_engine/is_notable'
require 'kmaps_engine/session_manager'
require 'kmaps_engine/simple_props_controller_helper'
require 'kmaps_engine/application_settings'
require 'csv'

I18n.load_path += Dir[File.join(__dir__, '..', 'config', 'locales', '**', '*.yml')]

module KmapsEngine
end
