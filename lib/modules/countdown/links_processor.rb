require "#{Rails.root}/lib/modules/countdown/cacher"

# Process links on Countdown Website
module Countdown
  class LinksProcessor
    def initialize(doc, cache)
      @document = doc
      @cacher = Countdown::Cacher.new(cache)
    end

    def generate_aisle
      cat_links_fetch.each do |link|
        AisleLinks.perform_async(link, @cacher)
      end
    end

    private

    def cat_links_fetch
      print '.'
      @document.at_css('div.toolbar-links-children')
        .at_css('div.row-fluid.mrow-fluid')
        .css('a.toolbar-slidebox-link')
    end

    class AisleLinks
      include Sidekiq::Worker
      sidekiq_options queue: :countdown

      def perform(*args)
        puts args[0]
        Nokogiri::HTML::Document.parse(args[0]).each do |link|
          value = link.attr('href')

          if value.split('/').count > 5
            CountdownAisleJob.perform_in(rand(5.0..10.0).seconds, value)
            next
          end

          retrieve_and_process(value, args[1])
        end
      end

      private

      def retrieve_and_process(value, cache)
        resp = cache.retrieve_url(value)

        sub_links_fetch(resp.body).each do |link|
          AisleLinks.perform_in(rand(5.0..10.0).seconds, link, cache)
        end
      end

      def sub_links_fetch(doc)
        print '.'

        return nil if error?(Nokogiri::HTML(doc))

        Nokogiri::HTML(doc)
          .at_css('div.single-level-navigation.filter-container')
          .try(:css, 'a.browse-navigation-link')
      end

      def error?(doc)
        return true if doc.blank? || doc.title.blank?
        doc.title.strip.eql? 'Shop Error - Countdown NZ Ltd'
      end
    end

    private_constant :AisleLinks
  end
end
