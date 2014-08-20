ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/mini_test'

class ActiveSupport::TestCase

  protected

  def assert_proper_feed_json(feed, feed_dict)
    assert_equal feed[:id], feed_dict['id'], 'feed: ids are not equal'
    assert_equal feed[:title], feed_dict['title'], 'feed: titles are not equal'
    assert_equal feed[:site_url], feed_dict['siteUrl'], 'feed: site urls are not equal'
    assert_equal feed[:url], feed_dict['url'], 'feed: urls are not equal'
    assert_equal feed[:unread_entries_count], feed_dict['unreadEntriesCount'], 'feed: unread entries counters are not equal'
    assert_equal feed[:error], feed_dict['error'], 'feed: errors are not equal'
    assert_equal feed[:error_count], feed_dict['errorCount'], 'feed: error count are not equal'
    assert_equal feed[:last_entry_id], feed_dict['lastEntryId'], 'feed: last entry ids are not equal'
    assert_equal feed[:position], feed_dict['position'], 'feed: positions are not equal'
  end

  def assert_proper_entries_json(entries, entry_dict_array)
    assert_equal entries.size, entry_dict_array.size

    entries.zip(entry_dict_array).each do |entry, entry_dict|
      assert_equal entry[:id], entry_dict['id'], 'entry: ids are not equal'
      assert_equal entry[:url], entry_dict['url'], 'entry: urls are not equal'
      assert_equal entry[:title], entry_dict['title'], 'entry: titles are not equal'
      assert_equal entry[:content], entry_dict['content'], 'entry: contents are not equal'
      assert_equal entry[:author], entry_dict['author'], 'entry: authors are not equal'
      assert_equal entry[:is_read], entry_dict['isRead'], 'entry: isRead flags are not equal'
      assert_equal entry[:is_favorite], entry_dict['isFavorite'], 'entry: isFavorite flags are not equal'
      assert_equal entry[:published_at], entry_dict['publishedAt'], 'entry: isRead flags are not equal'
      assert_equal entry[:created_at].as_json, entry_dict['createdAt'], 'entry: creation dates are not equal'
    end
  end

end
