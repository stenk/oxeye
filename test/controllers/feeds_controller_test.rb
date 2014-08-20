require 'test_helper'

class FeedsControllerTest < ActionController::TestCase
  test 'index action returns proper feed list' do
    feeds = []
    feeds << FactoryGirl.create(:feed)
    feeds << FactoryGirl.create(:feed)

    get :index
    assert_response :success

    json_array = JSON.parse(@response.body)['feeds']
    json_array.sort_by { |feed| feed[:id] }

    assert_equal feeds.size, json_array.size
    feeds.zip(json_array).each do |feed, feed_dict|
      assert_proper_feed_json feed, feed_dict
    end
  end

  test 'create action returns existing feed (with properly set attributes and initial entries) if specified URL already exists in the database' do
    feed = FactoryGirl.create(:feed)

    post :create, feed: {url: feed.url}
    assert_response :success

    feed.reload
    feed_dict = JSON.parse(@response.body)['feed']

    assert_proper_feed_json feed, feed_dict
    assert_proper_entries_json feed.entries.reader_initial, feed_dict['entries']
  end

  test 'create action creates and returns a feed if new URL specified' do
    feeds_count_before = Feed.count

    post :create, feed: {url: 'http://foo'}
    assert_response :success

    feed_dict = JSON.parse(@response.body)['feed']
    feed = Feed.find(feed_dict['id'])

    assert_equal feeds_count_before + 1, Feed.count
    assert_proper_feed_json feed, feed_dict
  end

  test 'update action updates a feed and returns new attributes' do
    feed = FactoryGirl.create(:feed)

    patch :update, id: feed.id, feed: {position: 10}
    assert_response :success

    feed.reload
    assert_equal 10, feed.position
  end

  test 'destroy action destroys a feed' do
    feeds_count = Feed.count
    feed = FactoryGirl.create(:feed)

    delete :destroy, id: feed.id
    assert_response :success

    assert_equal feeds_count, Feed.count
  end

  test 'refresh action refreshes a feed' do
    feed = FactoryGirl.create(:feed)
    FeedsFetcher.any_instance.expects(:fetch).at_least_once.returns(feed)

    post :refresh, id: 1
    assert_response :success
  end

end
