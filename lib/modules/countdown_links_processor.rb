require "#{Rails.root}/lib/modules/cacher"

# Process links on Countdown Website
module CountdownLinksProcessor
  extend Cacher

  def cat_links_fetch(doc)
    print '.'
    doc.at_css('div.toolbar-links-children')\
      .at_css('div.row-fluid.mrow-fluid').css('a.toolbar-slidebox-link')
  end

  def sub_links_fetch(doc)
    print '.'

    return nil if error?(Nokogiri::HTML(doc))

    Nokogiri::HTML(doc)\
      .at_css('div.single-level-navigation.filter-container')\
      .css('a.browse-navigation-link')
  end

  def error?(doc)
    return true if doc.blank? || doc.title.blank?
    doc.title.strip.eql? 'Shop Error - Countdown NZ Ltd'
  end

  def generate_aisle(doc, cache)
    aisle_array = []

    links = cat_links_fetch(doc)

    links.each do |link|
      # category
      value = link.attr('href')

      resp = Cacher.cache_retrieve_url(cache, value)

      next if resp.blank?

      sub_links = sub_links_fetch(resp)

      next if sub_links.nil?

      sub_links.each do |sub|
        value = sub.attr('href')

        sub_resp = Cacher.cache_retrieve_url(cache, value)

        next if sub_resp.blank?

        sub_sub_links = sub_links_fetch(sub_resp)

        next if sub_sub_links.nil?

        sub_sub_links.each do |sub_sub|
          value = sub_sub.attr('href')

          if value.split('/').count >= 5
            aisle_array << value
          end
        end
      end
    end

    puts ''

    aisle_array.compact
  end

  module_function :generate_aisle, :sub_links_fetch, :cat_links_fetch, :error?
end
