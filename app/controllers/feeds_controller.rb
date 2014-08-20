class FeedsController < ApplicationController
  respond_to :json

  def index
    feeds = Feed.all
    feeds_json = FeedsJsonSerializer.feeds_to_json(feeds)
    render json: {feeds: feeds_json}
  end

  def show
    feed = Feed.find(params[:id])
    feed_json = FeedsJsonSerializer.feed_to_json(feed, feed.entries.reader_initial)
    render json: {feed: feed_json}
  end

  def create
    feed = Feed.new(feed_params_create)

    if feed.valid?
      fetcher = FeedsFetcher.new
      feed = fetcher.fetch(feed)
      feed_json = FeedsJsonSerializer.feed_to_json(feed, feed.entries.reader_initial)
      render json: {feed: feed_json}
    else
      render json: {errors: feed.errors}
    end
  end

  def update
    feed = Feed.find(params[:id])
    if feed.update(feed_params_update)
      feed_json = FeedsJsonSerializer.feed_to_json(feed, nil)
      render json: {feed: feed_json}
    else
      render json: {errors: feed.errors}
    end
  end

  def destroy
    feed = Feed.find(params[:id])
    Entry.delete_all(feed: feed)
    feed.destroy
    render nothing: true
  end

  def refresh
    fetcher = FeedsFetcher.new
    feed = fetcher.fetch(Feed.find(params[:id]))

    feed_json = FeedsJsonSerializer.feed_to_json(feed, feed.entries.reader_initial)
    render json: {feed: feed_json}
  end

  private

  def feed_params_create
    params.require(:feed).permit(:url, :position)
  end

  def feed_params_update
    params.require(:feed).permit(:position)
  end
end
