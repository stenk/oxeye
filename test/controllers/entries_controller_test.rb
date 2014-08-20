require 'test_helper'

class EntriesControllerTest < ActionController::TestCase
  test "index action returns reader's initial entries if no parameters specified" do
    feed = FactoryGirl.create(:feed)

    get :index, feed_id: feed.id
    assert_response :success

    entries_json = JSON.parse(@response.body)['entries']
    assert_proper_entries_json  feed.entries.reader_initial, entries_json
  end

  test "index action returns feed's entries with id < params[:before] if :before parameter is specified" do
    feed = FactoryGirl.create(:feed)

    get :index, feed_id: feed.id, before: 5, limit: 3
    assert_response :success

    entries_json = JSON.parse(@response.body)['entries']
    entries = feed.entries.where('id < 5').limit(3).order('id DESC')

    assert_proper_entries_json(entries, entries_json)
  end

  test "index action returns feed's entries with id > params[:after] if :after parameter is specified" do
    feed = FactoryGirl.create(:feed)

    get :index, feed_id: feed.id, after: 5, limit: 3
    assert_response :success

    entries_json = JSON.parse(@response.body)['entries']
    entries = feed.entries.where('id > 5').limit(3)

    assert_proper_entries_json(entries, entries_json)
  end

  test "set_read_status action sets entries is_read flag" do
    feed = FactoryGirl.create(:feed)

    post :set_read_status, feed_id: feed.id, ids: [1, 2, 3], value: true
    assert_response :success

    assert true, feed.entries[0].is_read
    assert true, feed.entries[1].is_read
    assert true, feed.entries[2].is_read
  end

  test "mark_all_as_read action marks all feed's entries as read" do
    feed = FactoryGirl.create(:feed)

    post :mark_all_as_read, feed_id: feed.id, before: 10
    assert_response :success

    entries = feed.entries
    id_less_or_eq_to_10 = entries.select { |e| e.id <= 10 }
    id_greater_than_10 = entries.select { |e| e.id > 10 }

    assert id_less_or_eq_to_10.entries.all?(&:is_read)
    assert id_greater_than_10.entries.none?(&:is_read)
  end
end
