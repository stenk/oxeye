require 'open-uri'
require 'set'

class FeedsFetcher
  HTTP_USER_AGENT = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36'

  def fetch(feed)
    if feed.new_record?
      feed = Feed.find_by(url: feed.url) || feed
    end

    feed.is_initialized ? refresh_feed(feed) : initialize_feed(feed)
  end

  def refresh_all
    Feed.all.each { |feed| fetch(feed) }
  end

  protected

  def initialize_feed(feed)
    response, error = get_response(feed.url)

    if error
      feed.set_error(error.message)
      feed.save
    elsif rss_or_atom?(response)
      refresh_feed_with_response(feed, response)
    elsif feed_url = find_feed_url(response)
      feed.url = feed_url
      feed = Feed.find_by(url: feed_url) || feed
      refresh_feed(feed)
    else
      feed.set_error("Can't find any feed with provided URL")
      feed.save
    end

    feed

  end

  def refresh_feed(feed)
    response, error = get_response(feed.url)
    if error
      feed.set_error(error.message)
      feed.save
      return feed
    end
    refresh_feed_with_response(feed, response)
  end

  def refresh_feed_with_response(feed, response)
    begin
      feed_data = Feedjira::Feed.parse(response)
    rescue => e
      feed.set_error('Content parsing error: ' + e.message)
      feed.save
      return feed
    end

    feed.title = feed_data.title
    feed.site_url = feed_data.url
    feed.set_error(nil)
    feed.is_initialized = true
    feed.save

    new_entries =
      select_new_entries(feed, feed_data.entries)
      .sort_by { |e| e.published }

    last_entry = nil
    new_entries.each do |entry_data|
      last_entry = feed.entries.create(
        title: entry_data.title || '(no title)',
        content: entry_data.content || entry_data.summary || '',
        url: entry_data.url,
        author: entry_data.author || '',
        is_read: false,
        published_at: entry_data.published,
      )
    end

    feed.unread_entries_count += new_entries.size
    feed.last_entry_id = last_entry.id if last_entry
    feed.save

    feed

  end

  def rss_or_atom?(response)
    atom_namespace = 'http://www.w3.org/2005/Atom'

    root = Nokogiri.XML(response).root
    root && (root.name == 'rss' || root['xmlns'] == atom_namespace)
  end

  def find_feed_url(response)
    rss_selector = 'link[type="application/rss+xml"]'
    atom_selector = 'link[type="application/atom+xml"]'

    doc = Nokogiri.HTML(response)
    feeds = doc.css(rss_selector) + doc.css(atom_selector)

    if feeds.size > 0
      href = feeds[0]['href']
      URI.join(response.args[:url], href).to_s
    end
  end

  def select_new_entries(feed, entries_data)
    recent = feed.entries.recent(entries_data.size * 3)
    url_set = Set.new(recent.map(&:url))

    entries_data.reject { |e| url_set.include?(e.url) }
  end

  def get_response(url)
    begin
      response = RestClient.get(url, user_agent: HTTP_USER_AGENT)
      error = nil
    rescue SocketError, SystemCallError, RestClient::Exception => error
      response = nil
    end
    [response, error]
  end

end
