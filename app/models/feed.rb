class Feed < ActiveRecord::Base
  has_many :entries
  validate :validate_url

  def set_error(message)
    if message.nil?
      self.error_count = 0
      self.error = ''
    else
      self.error_count += 1
      self.error = message
    end
  end

  def set_entries_read_status(condition, value)
    count = entries
      .where(condition)
      .where(is_read: !value)
      .update_all(is_read: value)
    self.unread_entries_count += value ? -count : count
    save
  end

  def favicon_by_site_url
    return unless site_url && (host = URI(site_url).host)

    segments = host.split('.')[-2..-1] || []
    domain = segments.join('.')
    "http://#{domain}/favicon.ico"
  end

  protected

  def validate_url
    errors.add(:url, 'Invalid URL format') unless url_valid?
  end

  def url_valid?
    uri = URI(url)
    !!(uri.scheme && uri.host)
  end
end
