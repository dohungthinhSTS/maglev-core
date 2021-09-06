# frozen_string_literal: true

module Maglev
  class Page < ApplicationRecord
    ## concerns ##
    include Maglev::Page::SectionsConcern
    include Translatable

    ## translations ##
    translates :seo_title, :meta_description
    translates :title, presence: true

    ## scopes ##
    scope :by_id_or_path, ->(id_or_path) { where(id: id_or_path).or(by_path(id_or_path)) }
    scope :home, -> { by_path('index') }
    scope :by_path, ->(path) { joins(:paths).where(paths: { locale: Translatable.current_locale, value: path }) }

    ## associations ##
    has_many :paths,
             class_name: '::Maglev::PagePath',
             dependent: :delete_all,
             foreign_key: 'maglev_page_id',
             inverse_of: 'page',
             autosave: true

    ## callbacks ##
    before_save :spawn_redirection, if: :spawn_redirection?

    ## methods ##

    def index?
      path == 'index'
    end

    def canonical_path
      return path if current_path.canonical? 

      paths.find_by(canonical: true).value
    end

    def path
      current_path.value
    end

    def current_path
      @memoized_paths ||= {}
      @memoized_paths[Translatable.current_locale] ||= paths.find_or_initialize_by(locale: Translatable.current_locale)
    end

    def path=(value)
      current_path.value = value
    end

    def self.search(keyword)
      return [] if keyword.blank?

      current_title = Arel.sql("title_translations->>'#{Translatable.current_locale}'")
      query = all.order(current_title => :asc).joins(:paths)
      matching = "%#{keyword}%"
      path = PagePath.arel_table[:value]
      query.where(
        arel_table[current_title].matches(matching).or(
          path.matches(matching).and(path.eq(Translatable.current_locale))
        )
      )
    end

    private

    def spawn_redirection
      paths.build(canonical: false, value: current_path.value_in_database)
    end

    def spawn_redirection?
      current_path.persisted? && current_path.will_save_change_to_value?
    end
  end
end
