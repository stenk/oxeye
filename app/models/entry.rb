class Entry < ActiveRecord::Base
  belongs_to :feed

  def self.recent(count)
    order('id DESC').limit(count)
  end

  def self.reader_initial(prefix_size = 20, postfix_size = 100)
    if fst_unread = find_by(is_read: false)
      before_cond = ['id < ?', fst_unread.id]
      after_cond = ['id >= ?', fst_unread.id]

      before = where(before_cond).order('id DESC').limit(prefix_size)
      after = where(after_cond).limit(postfix_size)
      before.sort_by(&:id) + after
    else
      order('id DESC')
        .limit(prefix_size + postfix_size)
        .sort_by(&:id)
    end
  end
end
