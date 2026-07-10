class SitemapsController < ApplicationController
  allow_unauthenticated_access if respond_to?(:allow_unauthenticated_access)
  skip_before_action :set_common_variables, raise: false
  caches_page :index, :features
  layout false

  FIDS_PER_SITEMAP = 50_000

  def index
    max_fid = base_feature_scope.maximum(:fid).to_i
    @feature_pages = max_fid.zero? ? 0 : sitemap_page_for_fid(max_fid)

    expires_in 12.hours, public: true
  end

  def features
    page = params[:page].to_i
    return head(:not_found) if page < 1

    @features = feature_scope_for_page(page)

    return head(:not_found) if @features.empty?

    expires_in 12.hours, public: true
  end

  private

  def sitemap_page_for_fid(fid)
    (fid.to_i / FIDS_PER_SITEMAP) + 1
  end

  def fid_range_for_page(page)
    first_fid = page == 1 ? 1 : (page - 1) * FIDS_PER_SITEMAP
    last_fid = (page * FIDS_PER_SITEMAP) - 1
    first_fid..last_fid
  end

  def base_feature_scope
    Feature
      .where(is_public: 1, is_blank: false)
      .where.not(fid: nil)
  end

  def feature_scope
    base_feature_scope
      .select(:id, :fid, :updated_at)
      .order(:fid)
  end

  def feature_scope_for_page(page)
    feature_scope.where(fid: fid_range_for_page(page))
  end
end
