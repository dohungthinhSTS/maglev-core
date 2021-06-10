# frozen_string_literal: true

module Maglev
  module SiteConcern
    extend ActiveSupport::Concern

    included do
      helper_method :preview_mode?
      helper_method :templates_root_path
    end

    private

    def fetch_site
      @fetch_site ||= services.fetch_site.call
    end

    def fetch_page
      @fetch_page ||= services.fetch_page.call(params: params)
    end

    def fetch_page_sections
      @fetch_page_sections ||= services.get_page_sections.call(page: fetch_page)
    end

    def fetch_theme
      @fetch_theme ||= services.fetch_theme.call
    end

    def preview_mode?
      params[:preview_mode].present?
    end

    def fetch_theme_layout
      @fetch_theme_layout ||= services.fetch_theme_layout.call
    end

    def templates_root_path
      @templates_root_path ||= services.templates_root_path.call
    end
  end
end
