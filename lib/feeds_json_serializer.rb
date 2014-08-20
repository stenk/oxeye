class FeedsJsonSerializer
  def self.feeds_to_json(feeds)
    feeds.map { |feed| feed_to_json(feed, nil) }
  end

  def self.feed_to_json(feed, entries)
    json = {
      id: feed.id,
      siteUrl: feed.site_url,
      url: feed.url,
      title: feed.title,
      error: feed.error,
      errorCount: feed.error_count,
      unreadEntriesCount: feed.unread_entries_count,
      lastEntryId: feed.last_entry_id,
      favicon: feed.favicon_by_site_url,
      position: feed.position,
    }
    if entries
      json[:entries] = entries_to_json(entries)
    end
    json
  end

  def self.entries_to_json(entries)
    entries.map { |entry| entry_to_json(entry) }
  end

  def self.entry_to_json(entry)
    {
      id: entry.id,
      url: entry.url,
      title: entry.title,
      content: entry.content,
      author: entry.author,
      isRead: entry.is_read,
      isFavorite: entry.is_favorite,
      publishedAt: entry.published_at,
      createdAt: entry.created_at,
      feedId: entry.feed_id,
    }
  end
end
