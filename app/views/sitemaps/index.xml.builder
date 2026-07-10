xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.sitemapindex xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  1.upto(@feature_pages) do |page|
    xml.sitemap do
      xml.loc features_sitemap_url(page: page)
    end
  end
end
