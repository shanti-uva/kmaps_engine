xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @features.each do |feature|
    xml.url do
      xml.loc feature_url(feature.fid)
      xml.lastmod feature.updated_at.to_date.iso8601 if feature.updated_at.present?
      xml.changefreq "yearly"
    end
  end
end
