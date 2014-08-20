require 'test_helper'

class EntryTest < ActiveSupport::TestCase
  test 'reader_initial returns an array of successive entries where first N entries are old and later M entries are new' do
    feed = FactoryGirl.create(:feed)
    feed.entries.where('id < 5').update_all(is_read: true)

    entries = feed.entries.reader_initial(3, 10)
    read = entries.take(3)
    unread = entries.drop(3)

    entries.each_with_index do |entry, index|
      next if index == 0
      assert_equal entry.id - 1, entries[index - 1].id
    end

    assert 3, read.size
    assert read.all?(&:is_read)

    assert 10, unread.size
    assert unread.none?(&:is_read)
  end
end
