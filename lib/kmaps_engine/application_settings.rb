module KmapsEngine
  module ApplicationSettings
    def self.homepage_blurb
      blurb_code = Rails.cache.fetch('application_settings/homepage_blurb_code', :expires_in => 1.day) do
        str = InterfaceUtils::ApplicationSettings.settings['homepage.intro.blurb.code']
        str = nil if str.blank?
        str
      end
      Blurb.find_by_code(blurb_code.blank? ? 'homepage.intro' : blurb_code)
    end
  end
end