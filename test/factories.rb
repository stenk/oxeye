FactoryGirl.define do
  factory :feed do
    sequence(:title) { |n| "Feed ##{n}" }
    sequence(:url) { |n| "http://host#{n}/.rss" }
    sequence(:site_url) { |n| "http://host#{n}" }
    sequence(:position)
    is_initialized true
    unread_entries_count { entries_count }

    ignore { entries_count 20 }

    after :create do |feed, evaluator|
      create_list :entry, evaluator.entries_count, feed: feed
    end
  end

  factory :entry do
    feed

    sequence(:url) { |n| "#{feed.site_url}/#{n}" }
    sequence(:title) { |n| "Entry ##{n}" }
    sequence(:content) { |n| "Content ##{n}" }
  end
end
