class EntriesController < ApplicationController
  def index
    feed = Feed.find(params[:feed_id])

    limit = params[:limit] || 30

    entries = if params[:after]
      feed.entries.where('id > :after', params).limit(limit)
    elsif params[:before]
      feed.entries.where('id < :before', params).order('id DESC').limit(limit)
    else
      feed.entries.reader_initial
    end

    entries_json = FeedsJsonSerializer.entries_to_json(entries)
    render json: {entries: entries_json}
  end

  def favorites
    entries = Entry.where(is_favorite: true).order('updated_at')
    entries_json = FeedsJsonSerializer.entries_to_json(entries)
    render json: {entries: entries_json}
  end

  def set_read_status
    feed = Feed.find(params[:feed_id])
    feed.set_entries_read_status({id: params[:ids]}, params[:value])
    render nothing: true
  end

  def update
    entry = Entry.find(params[:id])
    entry.update(entry_params_update)
    render nothing: true
  end

  def mark_all_as_read
    feed = Feed.find(params[:feed_id])
    feed.set_entries_read_status(['id <= ?', params[:before]], true)
    render nothing: true
  end

  protected

  def entry_params_update
    params.require(:entry).permit(:is_favorite, :is_read)
  end
end
