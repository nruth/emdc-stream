require 'sinatra'
require 'active_support'
require 'feedzirra'

class EntryWithFeedTitle < SimpleDelegator
  attr_accessor :feed_title
end

get '/' do
  page = "<ol>"
  entries_to_display.each do |e|
    begin
      page << "<li>#{e.published.to_s(:rfc822)} </br> <a href='#{e.url}'>#{e.feed_title}:: #{e.title}</a></li>\n"  
    rescue Exception => e
      #someone's blog crashed or went offline, but we don't really care, so just continue
    end
  end
  page << "</ol>"
  page
end

def entries_to_display
  # download the feeds
  feeds = Feedzirra::Feed.fetch_and_parse(feed_urls)
  # grab recent n entries from each feed and combine in a list
  entries_to_display = []
  feeds.each_pair do |name, feed|
    feed.entries[0..5].each do |entry|
      named_entry = EntryWithFeedTitle.new(entry)
      named_entry.feed_title = feed.title
      entries_to_display << named_entry
    end
  end
  # sort the list by date published, mixing the blogs in the list
  entries_to_display.sort! {|a, b| b.published <=> a.published }
  entries_to_display
end

def feed_urls
  YAML::load( File.open( 'feeds.yml' ) )
end
